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
    description TEXT,
    "trackerType" TEXT NOT NULL DEFAULT 'maintain',
    rrule TEXT,
    "ruleStartDate" TIMESTAMPTZ NOT NULL,
    "ruleEndDate" TIMESTAMPTZ,
    exdate TIMESTAMPTZ[] DEFAULT '{}',
    "clientOffsetHours" INTEGER NOT NULL DEFAULT 0,
    "currentStreak" INTEGER NOT NULL DEFAULT 0,
    "longestStreak" INTEGER NOT NULL DEFAULT 0,
    "lastCompletedDate" TIMESTAMPTZ,
    "lastSlipUpDate" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Create TRACKER_HISTORY table
CREATE TABLE IF NOT EXISTS busy_bee.tracker_history (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL DEFAULT (auth.uid()::text),
    "trackerId" TEXT NOT NULL REFERENCES busy_bee.trackers(id) ON DELETE CASCADE,
    date TIMESTAMPTZ NOT NULL,
    type TEXT NOT NULL DEFAULT 'completion',
    value NUMERIC,
    note TEXT
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

-- --- TRIGGER FOR BACKFILLING MAINTAIN HABITS ON CREATION ---
CREATE OR REPLACE FUNCTION busy_bee.backfill_maintain_habit()
RETURNS TRIGGER AS $$
DECLARE
    -- Offset the database UTC now() by the client's timezone offset to determine their true "local today"
    current_date_ts TIMESTAMPTZ := date_trunc('day', now() + (NEW."clientOffsetHours" * interval '1 hour'));
    start_date_ts TIMESTAMPTZ;
    curr TIMESTAMPTZ;
BEGIN
    IF NEW."trackerType" = 'maintain' THEN
        start_date_ts := date_trunc('day', NEW."ruleStartDate");
        
        IF start_date_ts < current_date_ts THEN
            curr := start_date_ts;
            WHILE curr < current_date_ts LOOP
                INSERT INTO busy_bee.tracker_history (id, "userId", "trackerId", date, type)
                VALUES (gen_random_uuid()::text, NEW."userId", NEW.id, curr, 'completion');
                
                curr := curr + interval '1 day';
            END LOOP;
        END IF;
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
    target_user_id TEXT;
    target_type TEXT;
    start_date_ts TIMESTAMPTZ;
    client_offset INT;
    local_today TIMESTAMPTZ;
    local_yesterday TIMESTAMPTZ;
    rec RECORD;
    computed_streak INT := 0;
    computed_longest INT := 0;
    last_comp TIMESTAMPTZ := NULL;
    last_slip TIMESTAMPTZ := NULL;
    curr_streak INT := 0;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_tracker_id := OLD."trackerId";
        target_user_id := OLD."userId";
    ELSE
        target_tracker_id := NEW."trackerId";
        target_user_id := NEW."userId";
    END IF;

    -- Fetch tracker metadata
    SELECT "trackerType", "ruleStartDate", "clientOffsetHours", "longestStreak"
    INTO target_type, start_date_ts, client_offset, computed_longest
    FROM busy_bee.trackers
    WHERE id = target_tracker_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Calculate client local today and yesterday
    local_today := date_trunc('day', now() + (COALESCE(client_offset, 0) * interval '1 hour'));
    local_yesterday := local_today - interval '1 day';

    IF target_type = 'maintain' THEN
        -- Recompute streak and longest streak from ordered completion dates
        FOR rec IN
            SELECT DISTINCT date_trunc('day', date) AS comp_date
            FROM busy_bee.tracker_history
            WHERE "trackerId" = target_tracker_id AND type = 'completion'
            ORDER BY comp_date ASC
        LOOP
            IF last_comp IS NULL THEN
                curr_streak := 1;
            ELSIF rec.comp_date = last_comp + interval '1 day' THEN
                curr_streak := curr_streak + 1;
            ELSE
                curr_streak := 1;
            END IF;

            last_comp := rec.comp_date;

            IF curr_streak > computed_longest THEN
                computed_longest := curr_streak;
            END IF;
        END LOOP;

        -- Active streak must end on today or yesterday, otherwise streak is 0
        IF last_comp IS NOT NULL AND (last_comp = local_today OR last_comp = local_yesterday) THEN
            computed_streak := curr_streak;
        ELSE
            computed_streak := 0;
        END IF;

        -- Update tracker row
        UPDATE busy_bee.trackers
        SET "currentStreak" = computed_streak,
            "longestStreak" = GREATEST("longestStreak", computed_longest),
            "lastCompletedDate" = last_comp,
            "updatedAt" = now()
        WHERE id = target_tracker_id;

    ELSIF target_type = 'quit' THEN
        -- Fetch most recent slip-up date
        SELECT date_trunc('day', date)
        INTO last_slip
        FROM busy_bee.tracker_history
        WHERE "trackerId" = target_tracker_id AND type = 'slip_up'
        ORDER BY date DESC
        LIMIT 1;

        IF last_slip IS NOT NULL THEN
            computed_streak := EXTRACT(DAY FROM (local_today - last_slip));
            IF computed_streak < 0 THEN
                computed_streak := 0;
            END IF;
        ELSE
            computed_streak := EXTRACT(DAY FROM (local_today - date_trunc('day', start_date_ts)));
            IF computed_streak < 0 THEN
                computed_streak := 0;
            END IF;
        END IF;

        IF computed_streak > computed_longest THEN
            computed_longest := computed_streak;
        END IF;

        -- Update tracker row
        UPDATE busy_bee.trackers
        SET "currentStreak" = computed_streak,
            "longestStreak" = GREATEST("longestStreak", computed_longest),
            "lastSlipUpDate" = last_slip,
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
