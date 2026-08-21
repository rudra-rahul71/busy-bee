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

-- 5. Create TRACKERS table (Custom)
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
