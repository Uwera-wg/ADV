CREATE TABLE IF NOT EXISTS Department (
    DeptID SERIAL PRIMARY KEY,
    DeptName VARCHAR(100) NOT NULL,
    FacultyHead VARCHAR(100),
    Contact VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Instructor (
    InstructorID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    DeptID INT REFERENCES Department(DeptID) ON DELETE SET NULL,
    Email VARCHAR(100),
    Experience INT
);

CREATE TABLE IF NOT EXISTS Course (
    CourseID SERIAL PRIMARY KEY,
    InstructorID INT REFERENCES Instructor(InstructorID) ON DELETE SET NULL,
    DeptID INT REFERENCES Department(DeptID) ON DELETE SET NULL,
    Title VARCHAR(100),
    CreditHours INT,
    Level VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Student (
    StudentID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Gender VARCHAR(10),
    Email VARCHAR(100),
    YearOfStudy INT
);

CREATE TABLE IF NOT EXISTS Feedback (
    FeedbackID SERIAL PRIMARY KEY,
    StudentID INT REFERENCES Student(StudentID) ON DELETE SET NULL,
    CourseID INT REFERENCES Course(CourseID) ON DELETE CASCADE,
    Rating NUMERIC(3,2) CHECK (Rating >= 0 AND Rating <= 5),
    Comment TEXT,
    DateSubmitted DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS EvaluationSummary (
    SummaryID SERIAL PRIMARY KEY,
    CourseID INT UNIQUE REFERENCES Course(CourseID) ON DELETE CASCADE,
    AvgRating NUMERIC(3,2),
    TotalResponses INT,
    EvaluationDate DATE
);

TRUNCATE TABLE EvaluationSummary RESTART IDENTITY CASCADE;
TRUNCATE TABLE Feedback RESTART IDENTITY CASCADE;
TRUNCATE TABLE Course RESTART IDENTITY CASCADE;
TRUNCATE TABLE Instructor RESTART IDENTITY CASCADE;
TRUNCATE TABLE Student RESTART IDENTITY CASCADE;
TRUNCATE TABLE Department RESTART IDENTITY CASCADE;

INSERT INTO Department (DeptName, FacultyHead, Contact)
VALUES 
('Computer Science', 'Dr. Alice Mugenzi', 'cs@university.edu'),
('Business Administration', 'Dr. John Hakizimana', 'ba@university.edu');

INSERT INTO Instructor (FullName, DeptID, Email, Experience)
VALUES
('Jane Doe', 1, 'jane@uni.edu', 5),
('Peter Smith', 1, 'peter@uni.edu', 8),
('Ann Uwase', 2, 'ann@uni.edu', 3),
('James Nkurunziza', 2, 'james@uni.edu', 6),
('Mary Umutoni', 1, 'mary@uni.edu', 2);

INSERT INTO Course (InstructorID, DeptID, Title, CreditHours, Level)
VALUES
(1, 1, 'Database Systems', 3, 'Year 2'),
(2, 1, 'Data Structures', 3, 'Year 2'),
(3, 2, 'Business Ethics', 2, 'Year 1'),
(4, 2, 'Marketing', 3, 'Year 3'),
(5, 1, 'Web Development', 4, 'Year 3');

INSERT INTO Student (FullName, Gender, Email, YearOfStudy)
VALUES
('Alice Rwema', 'Female', 'alice@student.edu', 2),
('John Mugabo', 'Male', 'john@student.edu', 2),
('Grace Umuhoza', 'Female', 'grace@student.edu', 3),
('Eric Hakizimana', 'Male', 'eric@student.edu', 1),
('Cynthia Uwera', 'Female', 'cynthia@student.edu', 3),
('Mark Niyonzima', 'Male', 'mark@student.edu', 1),
('Anna Nyirab', 'Female', 'anna@student.edu', 2),
('Theo Habimana', 'Male', 'theo@student.edu', 2),
('Diane Uwizeye', 'Female', 'diane@student.edu', 1),
('Chris Tuyisenge', 'Male', 'chris@student.edu', 3);

INSERT INTO Feedback (StudentID, CourseID, Rating, Comment, DateSubmitted)
VALUES
(1, 1, 4.50, 'Very good course', '2025-10-10'),
(2, 1, 4.00, 'Well explained', '2025-10-11'),
(3, 2, 3.80, 'Good but challenging', '2025-10-12'),
(4, 3, 2.50, 'Could be better', '2025-10-13'),
(5, 4, 5.00, 'Excellent instructor!', '2025-10-13'),
(6, 5, 4.20, 'Great content', '2025-10-14'),
(7, 1, 4.80, 'Loved it', '2025-10-14'),
(8, 2, 3.50, 'Average experience', '2025-10-14'),
(9, 3, 2.00, 'Needs improvement', '2025-10-14'),
(10, 5, 4.00, 'Good class', '2025-10-14');

INSERT INTO EvaluationSummary (CourseID, AvgRating, TotalResponses, EvaluationDate)
SELECT
    c.CourseID,
    ROUND(AVG(f.Rating)::numeric, 2) AS AvgRating,
    COUNT(f.FeedbackID) AS TotalResponses,
    CURRENT_DATE AS EvaluationDate
FROM Course c
LEFT JOIN Feedback f ON c.CourseID = f.CourseID
GROUP BY c.CourseID
ON CONFLICT (CourseID) DO UPDATE
SET AvgRating = EXCLUDED.AvgRating,
    TotalResponses = EXCLUDED.TotalResponses,
    EvaluationDate = EXCLUDED.EvaluationDate;

	SELECT 
    c.CourseID,
    c.Title,
    COALESCE(ROUND(AVG(f.Rating)::numeric, 2), 0) AS AvgRating,
    COUNT(f.FeedbackID) AS TotalResponses
FROM Course c
LEFT JOIN Feedback f ON c.CourseID = f.CourseID
GROUP BY c.CourseID, c.Title
ORDER BY c.CourseID;

INSERT INTO EvaluationSummary (CourseID, AvgRating, TotalResponses, EvaluationDate)
SELECT
    c.CourseID,
    ROUND(AVG(f.Rating)::numeric, 2),
    COUNT(f.FeedbackID),
    CURRENT_DATE
FROM Course c
LEFT JOIN Feedback f ON c.CourseID = f.CourseID
GROUP BY c.CourseID
ON CONFLICT (CourseID) DO UPDATE
SET AvgRating = EXCLUDED.AvgRating,
    TotalResponses = EXCLUDED.TotalResponses,
    EvaluationDate = EXCLUDED.EvaluationDate;

	SELECT i.InstructorID, i.FullName AS Instructor, c.CourseID, c.Title AS Course,
       ROUND(AVG(f.Rating)::numeric,2) AS AvgRating
FROM Instructor i
JOIN Course c ON i.InstructorID = c.InstructorID
LEFT JOIN Feedback f ON c.CourseID = f.CourseID
GROUP BY i.InstructorID, i.FullName, c.CourseID, c.Title
HAVING COUNT(f.FeedbackID) > 0
ORDER BY AvgRating ASC
LIMIT 3;

DROP VIEW IF EXISTS TopRatedCourses;
CREATE VIEW TopRatedCourses AS
WITH course_avg AS (
    SELECT c.CourseID, c.DeptID, c.Title,
           ROUND(AVG(f.Rating)::numeric, 2) AS AvgRating
    FROM Course c
    LEFT JOIN Feedback f ON c.CourseID = f.CourseID
    GROUP BY c.CourseID, c.DeptID, c.Title
)
SELECT d.DeptName, ca.CourseID, ca.Title AS CourseTitle, ca.AvgRating
FROM Department d
JOIN course_avg ca ON ca.DeptID = d.DeptID
WHERE ca.AvgRating = (
    SELECT MAX(ca2.AvgRating)
    FROM course_avg ca2
    WHERE ca2.DeptID = ca.DeptID
);

DROP TRIGGER IF EXISTS trg_feedback_after_insert ON Feedback;
DROP TRIGGER IF EXISTS trg_feedback_after_update ON Feedback;
DROP TRIGGER IF EXISTS trg_feedback_after_delete ON Feedback;
DROP FUNCTION IF EXISTS trgfn_update_evaluationsummary();

CREATE OR REPLACE FUNCTION trgfn_update_evaluationsummary()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    target_course INT;
BEGIN
    -- Example trigger logic
    IF TG_OP = 'INSERT' THEN
        target_course := NEW.courseid;
    ELSIF TG_OP = 'UPDATE' THEN
        target_course := NEW.courseid;
    END IF;

    RAISE NOTICE 'Trigger fired for course ID: %', target_course;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_feedback_after_insert
AFTER INSERT ON Feedback
FOR EACH ROW
EXECUTE FUNCTION trgfn_update_evaluationsummary();

CREATE TRIGGER trg_feedback_after_update
AFTER UPDATE ON Feedback
FOR EACH ROW
EXECUTE FUNCTION trgfn_update_evaluationsummary();

CREATE TRIGGER trg_feedback_after_delete
AFTER DELETE ON Feedback
FOR EACH ROW
EXECUTE FUNCTION trgfn_update_evaluationsummary();

DROP TRIGGER IF EXISTS trg_feedback_after_insert ON Feedback;

CREATE TRIGGER trg_feedback_after_insert
AFTER INSERT ON Feedback
FOR EACH ROW
EXECUTE FUNCTION trgfn_update_evaluationsummary();

SELECT tgname, tgrelid::regclass AS table_name
FROM pg_trigger
WHERE tgrelid::regclass::text = 'feedback';

INSERT INTO Feedback (StudentID, CourseID, Rating, Comment) 
VALUES (1, 2, 4.90, 'Testing trigger');

SELECT * FROM EvaluationSummary WHERE CourseID = 2;

SELECT * FROM EvaluationSummary ORDER BY CourseID;

SELECT * FROM TopRatedCourses ORDER BY DeptName;

DELETE FROM Course WHERE CourseID = 5;
SELECT * FROM Feedback WHERE CourseID = 5; -- should show no rows
SELECT * FROM EvaluationSummary WHERE CourseID = 5; -- should be removed

INSERT INTO Feedback (StudentID, CourseID, Rating, Comment) VALUES (2,1,5.0,'Extra great');
SELECT * FROM EvaluationSummary WHERE CourseID = 1;

SELECT 
    table_name AS name,
    'table' AS type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'

UNION ALL

-- 2️⃣ List all triggers
SELECT 
    tgname AS name,
    'trigger on ' || tgrelid::regclass AS type
FROM pg_trigger
WHERE NOT tgisinternal
ORDER BY type, name;

SELECT 
    t.table_name AS object_name,
    'TABLE' AS object_type,
    NULL AS related_table
FROM information_schema.tables t
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'

UNION ALL

-- 2️⃣ All triggers
SELECT 
    tg.tgname AS object_name,
    'TRIGGER' AS object_type,
    tg.tgrelid::regclass::text AS related_table
FROM pg_trigger tg
WHERE NOT tg.tgisinternal
ORDER BY object_type, related_table, object_name;

SELECT 
    t.table_name AS object_name,
    'TABLE' AS object_type,
    NULL AS related_to
FROM information_schema.tables t
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'

UNION ALL

-- 2️⃣ Triggers
SELECT 
    tg.tgname AS object_name,
    'TRIGGER' AS object_type,
    tg.tgrelid::regclass::text AS related_to
FROM pg_trigger tg
WHERE NOT tg.tgisinternal

UNION ALL

-- 3️⃣ Functions
SELECT 
    p.proname AS object_name,
    'FUNCTION' AS object_type,
    n.nspname AS related_to
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY object_type, related_to, object_name;











 
  











