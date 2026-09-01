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
    "longestStreak" INTEGER NOT NULL DEFAULT 0,
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
    value NUMERIC
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

-- --- TRIGGER FOR BATCH BACKFILLING MAINTAIN HABITS ON CREATION ---
CREATE OR REPLACE FUNCTION busy_bee.backfill_maintain_habit()
RETURNS TRIGGER AS $$
DECLARE
    today_date DATE := CURRENT_DATE;
    start_date DATE := NEW."ruleStartDate";
    days_count INT;
BEGIN
    IF NEW."trackerType" = 'maintain' AND start_date < today_date THEN
        -- Batch insert past completions in a single set operation
        INSERT INTO busy_bee.tracker_history (id, "userId", "trackerId", date, type)
        SELECT 
            gen_random_uuid()::text,
            NEW."userId",
            NEW.id,
            d::date,
            'completion'
        FROM generate_series(start_date::timestamp, (today_date - interval '1 day')::timestamp, interval '1 day') AS d;

        days_count := (today_date - start_date);

        UPDATE busy_bee.trackers
        SET "currentStreak" = days_count,
            "longestStreak" = days_count,
            "lastEventDate" = today_date - 1,
            "updatedAt" = now()
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_tracker_created_backfill
    AFTER INSERT ON busy_bee.trackers
    FOR EACH ROW
    EXECUTE FUNCTION busy_bee.backfill_maintain_habit();

-- --- TRIGGER TO ATOMICALLY SYNCHRONIZE STREAKS ON HISTORY CHANGES ---
CREATE OR REPLACE FUNCTION busy_bee.sync_tracker_streak_on_history_change()
RETURNS TRIGGER AS $$
DECLARE
    target_tracker_id TEXT;
    target_type TEXT;
    start_date DATE;
    today_date DATE := CURRENT_DATE;
    rec RECORD;
    computed_streak INT := 0;
    computed_longest INT := 0;
    last_comp DATE := NULL;
    last_slip DATE := NULL;
    curr_streak INT := 0;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_tracker_id := OLD."trackerId";
    ELSE
        target_tracker_id := NEW."trackerId";
    END IF;

    -- Fetch tracker metadata
    SELECT "trackerType", "ruleStartDate", "longestStreak"
    INTO target_type, start_date, computed_longest
    FROM busy_bee.trackers
    WHERE id = target_tracker_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    IF target_type = 'maintain' THEN
        -- Recompute streak and longest streak from ordered completion dates
        FOR rec IN
            SELECT DISTINCT date AS comp_date
            FROM busy_bee.tracker_history
            WHERE "trackerId" = target_tracker_id AND type = 'completion'
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

            IF curr_streak > computed_longest THEN
                computed_longest := curr_streak;
            END IF;
        END LOOP;

        -- Active streak must end on today or yesterday
        IF last_comp IS NOT NULL AND (last_comp = today_date OR last_comp = today_date - 1) THEN
            computed_streak := curr_streak;
        ELSE
            computed_streak := 0;
        END IF;

        -- Update tracker row
        UPDATE busy_bee.trackers
        SET "currentStreak" = computed_streak,
            "longestStreak" = GREATEST(COALESCE("longestStreak", 0), computed_longest),
            "lastEventDate" = last_comp,
            "updatedAt" = now()
        WHERE id = target_tracker_id;

    ELSIF target_type = 'quit' THEN
        -- Fetch most recent slip-up date
        SELECT date
        INTO last_slip
        FROM busy_bee.tracker_history
        WHERE "trackerId" = target_tracker_id AND type = 'slip_up'
        ORDER BY date DESC
        LIMIT 1;

        IF last_slip IS NOT NULL THEN
            computed_streak := GREATEST(0, (today_date - last_slip));
        ELSE
            computed_streak := GREATEST(0, (today_date - start_date));
        END IF;

        IF computed_streak > computed_longest THEN
            computed_longest := computed_streak;
        END IF;

        -- Update tracker row
        UPDATE busy_bee.trackers
        SET "currentStreak" = computed_streak,
            "longestStreak" = GREATEST(COALESCE("longestStreak", 0), computed_longest),
            "lastEventDate" = last_slip,
            "updatedAt" = now()
        WHERE id = target_tracker_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_tracker_history_sync
    AFTER INSERT OR DELETE OR UPDATE OF date, type ON busy_bee.tracker_history
    FOR EACH ROW
    EXECUTE FUNCTION busy_bee.sync_tracker_streak_on_history_change();
