-- Busy Bee Supabase Database Schema
-- Run this script in the Supabase SQL Editor

-- 0. CREATE SCHEMA AND GRANT USAGE
CREATE SCHEMA IF NOT EXISTS busy_bee;
GRANT USAGE ON SCHEMA busy_bee TO anon, authenticated, service_role;

-- 1. Create TASK_GROUPS table (Custom Categories)
CREATE TABLE IF NOT EXISTS busy_bee.task_groups (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL DEFAULT (auth.uid()::text),
    name TEXT NOT NULL,
    "colorValue" BIGINT NOT NULL DEFAULT 4283215696,
    rrule TEXT,
    "ruleStartDate" TIMESTAMPTZ,
    "ruleEndDate" TIMESTAMPTZ,
    exdate TIMESTAMPTZ[] DEFAULT '{}',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Create EVENTS table (VEVENT)
CREATE TABLE IF NOT EXISTS busy_bee.events (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL DEFAULT (auth.uid()::text),
    summary TEXT NOT NULL,
    description TEXT,
    location TEXT,
    dtstart TIMESTAMPTZ NOT NULL,
    dtend TIMESTAMPTZ NOT NULL,
    rrule TEXT,
    "ruleStartDate" TIMESTAMPTZ,
    "ruleEndDate" TIMESTAMPTZ,
    exdate TIMESTAMPTZ[] DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'CONFIRMED',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Create TASKS table (VTODO)
CREATE TABLE IF NOT EXISTS busy_bee.tasks (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL DEFAULT (auth.uid()::text),
    "groupId" TEXT REFERENCES busy_bee.task_groups(id) ON DELETE SET NULL,
    summary TEXT NOT NULL,
    description TEXT,
    location TEXT,
    steps JSONB NOT NULL DEFAULT '[]'::jsonb,
    dtstart TIMESTAMPTZ,
    due TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'NEEDS-ACTION',
    "completedAt" TIMESTAMPTZ,
    rrule TEXT,
    "ruleStartDate" TIMESTAMPTZ,
    "ruleEndDate" TIMESTAMPTZ,
    exdate TIMESTAMPTZ[] DEFAULT '{}',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Create TASK_HISTORY table
CREATE TABLE IF NOT EXISTS busy_bee.task_history (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL DEFAULT (auth.uid()::text),
    "taskId" TEXT NOT NULL REFERENCES busy_bee.tasks(id) ON DELETE CASCADE,
    date TIMESTAMPTZ NOT NULL,
    "completedSteps" JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- 5. Create TRACKERS table (Custom with O(1) Counter Cache Columns)
CREATE TABLE IF NOT EXISTS busy_bee.trackers (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL DEFAULT (auth.uid()::text),
    summary TEXT NOT NULL,
    "trackerType" TEXT NOT NULL DEFAULT 'maintain',
    rrule TEXT,
    "ruleStartDate" DATE NOT NULL,
    "ruleEndDate" DATE,
    "currentStreak" INTEGER NOT NULL DEFAULT 0,
    "lastEventDate" DATE,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Create TRACKER_HISTORY table
CREATE TABLE IF NOT EXISTS busy_bee.tracker_history (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL DEFAULT (auth.uid()::text),
    "trackerId" TEXT NOT NULL REFERENCES busy_bee.trackers(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    type TEXT NOT NULL DEFAULT 'completion',
    value NUMERIC,
    CONSTRAINT uq_tracker_history_tracker_date_type UNIQUE ("trackerId", date, type)
);

-- --- ENABLE ROW LEVEL SECURITY (RLS) ---
ALTER TABLE busy_bee.task_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE busy_bee.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE busy_bee.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE busy_bee.task_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE busy_bee.trackers ENABLE ROW LEVEL SECURITY;
ALTER TABLE busy_bee.tracker_history ENABLE ROW LEVEL SECURITY;

-- --- CREATE SECURITY POLICIES ---
CREATE POLICY "Users can access their own task_groups" ON busy_bee.task_groups
    FOR ALL USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Users can access their own events" ON busy_bee.events
    FOR ALL USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Users can access their own tasks" ON busy_bee.tasks
    FOR ALL USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Users can access their own task_history" ON busy_bee.task_history
    FOR ALL USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Users can access their own trackers" ON busy_bee.trackers
    FOR ALL USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

CREATE POLICY "Users can access their own tracker_history" ON busy_bee.tracker_history
    FOR ALL USING (auth.uid()::text = "userId") WITH CHECK (auth.uid()::text = "userId");

-- --- CREATE B-TREE INDEXES FOR PERFORMANCE & RLS ---
CREATE INDEX IF NOT EXISTS idx_tracker_history_tracker_date ON busy_bee.tracker_history ("trackerId", date DESC);
CREATE INDEX IF NOT EXISTS idx_tracker_history_lookup ON busy_bee.tracker_history ("trackerId", date, type);
CREATE INDEX IF NOT EXISTS idx_tracker_history_user_date ON busy_bee.tracker_history ("userId", date);
CREATE INDEX IF NOT EXISTS idx_trackers_user ON busy_bee.trackers ("userId");
CREATE INDEX IF NOT EXISTS idx_tasks_user ON busy_bee.tasks ("userId");
CREATE INDEX IF NOT EXISTS idx_events_user ON busy_bee.events ("userId");

-- --- GRANT PRIVILEGES TO AUTHENTICATED ROLE ---
GRANT ALL ON ALL TABLES IN SCHEMA busy_bee TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA busy_bee TO authenticated, service_role;

-- --- ENABLE REALTIME BROADCASTING ---
alter publication supabase_realtime add table busy_bee.task_groups;
alter publication supabase_realtime add table busy_bee.events;
alter publication supabase_realtime add table busy_bee.tasks;
alter publication supabase_realtime add table busy_bee.task_history;
alter publication supabase_realtime add table busy_bee.trackers;
alter publication supabase_realtime add table busy_bee.tracker_history;

-- --- ENABLE REALTIME DELETIONS (REPLICA IDENTITY FULL) ---
alter table busy_bee.task_groups replica identity full;
alter table busy_bee.events replica identity full;
alter table busy_bee.tasks replica identity full;
alter table busy_bee.task_history replica identity full;
alter table busy_bee.trackers replica identity full;
alter table busy_bee.tracker_history replica identity full;

-- --- VALIDATION TRIGGER: PREVENT FUTURE START DATES ---
CREATE OR REPLACE FUNCTION busy_bee.validate_tracker_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW."ruleStartDate" > CURRENT_DATE THEN
        RAISE EXCEPTION 'ruleStartDate cannot be in the future (ruleStartDate: %, CURRENT_DATE: %)', NEW."ruleStartDate", CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_tracker_dates_before_save ON busy_bee.trackers;
CREATE TRIGGER check_tracker_dates_before_save
    BEFORE INSERT OR UPDATE OF "ruleStartDate" ON busy_bee.trackers
    FOR EACH ROW
    EXECUTE FUNCTION busy_bee.validate_tracker_dates();

-- --- SHARED FUNCTION TO ATOMICALLY RECALCULATE A TRACKER'S STREAK ---
CREATE OR REPLACE FUNCTION busy_bee.recalculate_tracker_streak(p_tracker_id TEXT)
RETURNS VOID AS $$
DECLARE
    target_type TEXT;
    start_date DATE;
    today_date DATE := CURRENT_DATE;
    rec RECORD;
    computed_streak INT := 0;
    last_comp DATE := NULL;
    last_slip DATE := NULL;
    curr_streak INT := 0;
BEGIN
    SELECT "trackerType", "ruleStartDate"
    INTO target_type, start_date
    FROM busy_bee.trackers
    WHERE id = p_tracker_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    IF target_type = 'maintain' THEN
        -- Recompute streak from ordered completion dates on or after ruleStartDate
        FOR rec IN
            SELECT DISTINCT date AS comp_date
            FROM busy_bee.tracker_history
            WHERE "trackerId" = p_tracker_id 
              AND type = 'completion'
              AND date >= start_date
            ORDER BY comp_date ASC
        LOOP
            IF last_comp IS NULL THEN
                curr_streak := 1;
            ELSIF rec.comp_date = last_comp + 1 THEN
                curr_streak := curr_streak + 1;
            ELSE
                curr_streak := 1;
            END IF;

            last_comp := rec.comp_date;
        END LOOP;

        -- Active streak must end on today or yesterday
        IF last_comp IS NOT NULL AND (last_comp = today_date OR last_comp = today_date - 1) THEN
            computed_streak := curr_streak;
        ELSE
            computed_streak := 0;
        END IF;

        -- Update tracker row exactly once
        UPDATE busy_bee.trackers
        SET "currentStreak" = computed_streak,
            "lastEventDate" = last_comp,
            "updatedAt" = now()
        WHERE id = p_tracker_id;

    ELSIF target_type = 'quit' THEN
        -- Fetch most recent slip-up date on or after ruleStartDate
        SELECT date
        INTO last_slip
        FROM busy_bee.tracker_history
        WHERE "trackerId" = p_tracker_id 
          AND type = 'slip_up'
          AND date >= start_date
        ORDER BY date DESC
        LIMIT 1;

        -- For quit habits, streak is purely derived on the client from ruleStartDate or lastEventDate.
        -- We only update lastEventDate and leave currentStreak at 0.
        UPDATE busy_bee.trackers
        SET "currentStreak" = 0,
            "lastEventDate" = last_slip,
            "updatedAt" = now()
        WHERE id = p_tracker_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --- SYNCHRONIZE HISTORY AND RECALCULATE ON START DATE CREATION OR CHANGE ---
CREATE OR REPLACE FUNCTION busy_bee.sync_tracker_history_on_start_date_change()
RETURNS TRIGGER AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
BEGIN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW."ruleStartDate" <> OLD."ruleStartDate") THEN
        -- 1. Wipe any history records prior to the new start date
        -- (For quit trackers, this wipes all slip-ups before the new start date; for maintain, it removes orphaned completions)
        DELETE FROM busy_bee.tracker_history
        WHERE "trackerId" = NEW.id AND date < NEW."ruleStartDate";

        -- 2. For maintain trackers, backfill any missing completions from ruleStartDate to yesterday
        IF NEW."trackerType" = 'maintain' AND NEW."ruleStartDate" < today_date THEN
            INSERT INTO busy_bee.tracker_history (id, "userId", "trackerId", date, type)
            SELECT 
                gen_random_uuid()::text,
                NEW."userId",
                NEW.id,
                d::date,
                'completion'
            FROM generate_series(NEW."ruleStartDate"::timestamp, (today_date - interval '1 day')::timestamp, interval '1 day') AS d
            ON CONFLICT ("trackerId", date, type) DO NOTHING;
        END IF;

        -- 3. Atomically recalculate streak and lastEventDate
        PERFORM busy_bee.recalculate_tracker_streak(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_tracker_created_backfill ON busy_bee.trackers;
DROP TRIGGER IF EXISTS on_tracker_start_date_sync ON busy_bee.trackers;
CREATE TRIGGER on_tracker_start_date_sync
    AFTER INSERT OR UPDATE OF "ruleStartDate" ON busy_bee.trackers
    FOR EACH ROW
    EXECUTE FUNCTION busy_bee.sync_tracker_history_on_start_date_change();

-- --- STATEMENT-LEVEL TRIGGERS WITH TRANSITION TABLES (O(1) BATCH EXECUTION) ---

CREATE OR REPLACE FUNCTION busy_bee.sync_streak_on_history_insert()
RETURNS TRIGGER AS $$
DECLARE
    t_id TEXT;
BEGIN
    FOR t_id IN SELECT DISTINCT "trackerId" FROM new_table WHERE "trackerId" IS NOT NULL LOOP
        PERFORM busy_bee.recalculate_tracker_streak(t_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION busy_bee.sync_streak_on_history_update()
RETURNS TRIGGER AS $$
DECLARE
    t_id TEXT;
BEGIN
    FOR t_id IN 
        SELECT DISTINCT "trackerId" FROM (
            SELECT "trackerId" FROM new_table WHERE "trackerId" IS NOT NULL
            UNION
            SELECT "trackerId" FROM old_table WHERE "trackerId" IS NOT NULL
        ) AS affected
    LOOP
        PERFORM busy_bee.recalculate_tracker_streak(t_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION busy_bee.sync_streak_on_history_delete()
RETURNS TRIGGER AS $$
DECLARE
    t_id TEXT;
BEGIN
    FOR t_id IN SELECT DISTINCT "trackerId" FROM old_table WHERE "trackerId" IS NOT NULL LOOP
        PERFORM busy_bee.recalculate_tracker_streak(t_id);
    END LOOP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_tracker_history_sync ON busy_bee.tracker_history;

CREATE TRIGGER on_tracker_history_insert_sync
    AFTER INSERT ON busy_bee.tracker_history
    REFERENCING NEW TABLE AS new_table
    FOR EACH STATEMENT
    EXECUTE FUNCTION busy_bee.sync_streak_on_history_insert();

CREATE TRIGGER on_tracker_history_update_sync
    AFTER UPDATE ON busy_bee.tracker_history
    REFERENCING OLD TABLE AS old_table NEW TABLE AS new_table
    FOR EACH STATEMENT
    EXECUTE FUNCTION busy_bee.sync_streak_on_history_update();

CREATE TRIGGER on_tracker_history_delete_sync
    AFTER DELETE ON busy_bee.tracker_history
    REFERENCING OLD TABLE AS old_table
    FOR EACH STATEMENT
    EXECUTE FUNCTION busy_bee.sync_streak_on_history_delete();
