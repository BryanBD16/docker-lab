-- =========================================================
-- SQL Initialization Script for Angular Task Manager
-- This file runs automatically when MySQL starts for the first time
-- =========================================================

-- USE the database that Docker Compose created for us
USE angular_db;

-- =========================================================
-- CREATE TASKS TABLE
-- =========================================================

CREATE TABLE IF NOT EXISTS tasks (
    -- ===== PRIMARY KEY =====
    id INT AUTO_INCREMENT PRIMARY KEY,
    -- AUTO_INCREMENT: Automatically assigns increasing numbers (1, 2, 3...)
    -- PRIMARY KEY: Unique identifier, no duplicates allowed

    -- ===== MAIN FIELDS =====
    title VARCHAR(255) NOT NULL,
    -- VARCHAR(255): Text field, max 255 characters
    -- NOT NULL: This field is REQUIRED, can't be empty
    -- What it stores: Task title like "Buy groceries" or "Fix login button"

    description TEXT,
    -- TEXT: Longer text field, up to 65,000 characters
    -- NULL by default: This field is OPTIONAL
    -- What it stores: Detailed description of the task

    is_completed BOOLEAN DEFAULT FALSE,
    -- BOOLEAN: True/False value (0 for false, 1 for true)
    -- DEFAULT FALSE: New tasks are not completed by default
    -- What it stores: Whether the task is done

    priority VARCHAR(50) DEFAULT 'medium',
    -- VARCHAR(50): Text, max 50 characters
    -- DEFAULT 'medium': If not specified, set to 'medium'
    -- What it stores: 'low', 'medium', 'high'

    -- ===== TIMESTAMP FIELDS =====
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- TIMESTAMP: Date and time
    -- CURRENT_TIMESTAMP: Automatically set to current date/time when row is created
    -- What it stores: When the task was created

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- ON UPDATE CURRENT_TIMESTAMP: Automatically updates when row changes
    -- What it stores: When the task was last modified

    due_date DATE,
    -- DATE: Only date, no time (YYYY-MM-DD format)
    -- NULL by default: Due date is optional
    -- What it stores: When the task should be completed

    -- ===== INDEXES FOR PERFORMANCE =====
    INDEX idx_completed (is_completed),
    -- INDEX: Speed up searching for completed/incomplete tasks

    INDEX idx_created (created_at)
    -- INDEX: Speed up sorting by creation date
);

-- =========================================================
-- INSERT SAMPLE DATA (Optional - for testing)
-- =========================================================

INSERT INTO tasks (title, description, priority, due_date, is_completed) VALUES
-- Sample Task 1
(
    'Set up Angular project',
    'Initialize a new Angular project with Docker and connect to MySQL database',
    'high',
    '2026-09-30',
    false
),

-- Sample Task 2
(
    'Create task API endpoints',
    'Build REST endpoints to fetch, create, update, and delete tasks',
    'high',
    '2026-10-05',
    false
),

-- Sample Task 3
(
    'Design task list UI',
    'Design the Angular component to display tasks in a nice format',
    'medium',
    '2026-10-10',
    false
),

-- Sample Task 4
(
    'Add database migrations',
    'Document and automate database schema changes',
    'low',
    '2026-10-15',
    false
),

-- Sample Task 5 (Already completed)
(
    'Create Docker Compose setup',
    'Set up MySQL and Angular in Docker containers',
    'high',
    '2026-09-25',
    true
);

-- =========================================================
-- VERIFICATION
-- =========================================================

-- Show the table structure (informational, not needed for functionality)
-- DESCRIBE tasks;

-- Show all the data we just created
-- SELECT * FROM tasks;