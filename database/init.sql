-- Ghana School Management System Database
-- Version: 1.0.0
-- Created: 2024-01-01

-- Create Database
CREATE DATABASE IF NOT EXISTS school_mis_ghana;
USE school_mis_ghana;

-- Students Table
CREATE TABLE IF NOT EXISTS students (
    id VARCHAR(20) PRIMARY KEY,
    admission_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    other_names VARCHAR(100),
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    date_of_birth DATE NOT NULL,
    place_of_birth VARCHAR(100),
    nationality VARCHAR(50) DEFAULT 'Ghanaian',
    hometown VARCHAR(100),
    region_of_origin VARCHAR(50),
    residential_address TEXT,
    guardian_name VARCHAR(100) NOT NULL,
    guardian_relationship VARCHAR(50),
    guardian_contact VARCHAR(20) NOT NULL,
    guardian_email VARCHAR(100),
    guardian_occupation VARCHAR(50),
    emergency_contact VARCHAR(20),
    previous_school VARCHAR(100),
    previous_class VARCHAR(20),
    admission_date DATE NOT NULL,
    admission_type ENUM('Fresh', 'Transfer', 'Re-admission'),
    programme ENUM(
        'General Arts',
        'General Science',
        'Business',
        'Home Economics',
        'Visual Arts',
        'Agricultural Science'
    ) NOT NULL,
    class VARCHAR(20) NOT NULL,
    house VARCHAR(50),
    house_color VARCHAR(20),
    religion VARCHAR(50),
    denomination VARCHAR(50),
    medical_conditions TEXT,
    allergies TEXT,
    special_needs TEXT,
    photo_url VARCHAR(255),
    status ENUM('Active', 'Inactive', 'Graduated', 'Transferred', 'Expelled') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_admission_number (admission_number),
    INDEX idx_programme (programme),
    INDEX idx_class (class),
    INDEX idx_status (status)
);

-- Subjects Table
CREATE TABLE IF NOT EXISTS subjects (
    id VARCHAR(10) PRIMARY KEY,
    subject_code VARCHAR(10) UNIQUE NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    subject_type ENUM('Core', 'Elective', 'Practical') NOT NULL,
    programme VARCHAR(50),
    credit_hours INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Ghana SHS Subjects
INSERT INTO subjects (id, subject_code, subject_name, subject_type, programme) VALUES
-- Core Subjects (All Programmes)
('CORE001', 'ENG', 'English Language', 'Core', NULL),
('CORE002', 'MATH', 'Mathematics', 'Core', NULL),
('CORE003', 'IS', 'Integrated Science', 'Core', NULL),
('CORE004', 'SS', 'Social Studies', 'Core', NULL),

-- General Science Subjects
('SCI001', 'PHY', 'Physics', 'Elective', 'General Science'),
('SCI002', 'CHEM', 'Chemistry', 'Elective', 'General Science'),
('SCI003', 'BIO', 'Biology', 'Elective', 'General Science'),
('SCI004', 'EMATH', 'Elective Mathematics', 'Elective', 'General Science'),
('SCI005', 'ICT', 'Information Technology', 'Elective', 'General Science'),

-- General Arts Subjects
('ART001', 'ECON', 'Economics', 'Elective', 'General Arts'),
('ART002', 'GEO', 'Geography', 'Elective', 'General Arts'),
('ART003', 'GOVT', 'Government', 'Elective', 'General Arts'),
('ART004', 'HIST', 'History', 'Elective', 'General Arts'),
('ART005', 'FRENCH', 'French', 'Elective', 'General Arts'),
('ART006', 'TWI', 'Twi (Akan)', 'Elective', 'General Arts'),

-- Business Subjects
('BUS001', 'FACC', 'Financial Accounting', 'Elective', 'Business'),
('BUS002', 'COST', 'Cost Accounting', 'Elective', 'Business'),
('BUS003', 'BMGT', 'Business Management', 'Elective', 'Business'),
('BUS004', 'ECON', 'Economics', 'Elective', 'Business'),
('BUS005', 'ICT', 'Information Technology', 'Elective', 'Business'),

-- Home Economics Subjects
('HE001', 'FN', 'Food and Nutrition', 'Elective', 'Home Economics'),
('HE002', 'CT', 'Clothing and Textiles', 'Elective', 'Home Economics'),
('HE003', 'ML', 'Management in Living', 'Elective', 'Home Economics'),
('HE004', 'CHEM', 'Chemistry', 'Elective', 'Home Economics'),
('HE005', 'BIO', 'Biology', 'Elective', 'Home Economics'),

-- Visual Arts Subjects
('VA001', 'GKA', 'General Knowledge in Art', 'Elective', 'Visual Arts'),
('VA002', 'GD', 'Graphic Design', 'Elective', 'Visual Arts'),
('VA003', 'PM', 'Picture Making', 'Elective', 'Visual Arts'),
('VA004', 'SCULP', 'Sculpture', 'Elective', 'Visual Arts'),
('VA005', 'EMATH', 'Elective Mathematics', 'Elective', 'Visual Arts'),
('VA006', 'ICT', 'Information Technology', 'Elective', 'Visual Arts'),

-- Agricultural Science Subjects
('AGR001', 'CROP', 'Crop Husbandry', 'Elective', 'Agricultural Science'),
('AGR002', 'ANIMAL', 'Animal Husbandry', 'Elective', 'Agricultural Science'),
('AGR003', 'CHEM', 'Chemistry', 'Elective', 'Agricultural Science'),
('AGR004', 'PHY', 'Physics', 'Elective', 'Agricultural Science'),
('AGR005', 'EMATH', 'Elective Mathematics', 'Elective', 'Agricultural Science');

-- Assessments Table
CREATE TABLE IF NOT EXISTS assessments (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    student_id VARCHAR(20) NOT NULL,
    academic_year VARCHAR(9) NOT NULL,
    term ENUM('First Term', 'Second Term', 'Third Term') NOT NULL,
    class_level VARCHAR(20) NOT NULL,
    programme VARCHAR(50) NOT NULL,
    
    -- Subject scores (JSON structure for flexibility)
    subjects JSON NOT NULL,
    
    -- Overall performance
    total_aggregate DECIMAL(5,2),
    average_score DECIMAL(5,2),
    class_rank INT,
    overall_position INT,
    
    -- Attendance
    days_present INT,
    days_absent INT,
    days_school_opened INT,
    attendance_percentage DECIMAL(5,2),
    
    -- Conduct and remarks
    conduct ENUM('Excellent', 'Very Good', 'Good', 'Satisfactory', 'Poor'),
    teacher_remark TEXT,
    headteacher_remark TEXT,
    
    -- Promotion status
    promotion_status ENUM('Promoted', 'Repeat', 'Conditional', 'Pending') DEFAULT 'Pending',
    promotion_decision_date DATE,
    promotion_remarks TEXT,
    
    -- Metadata
    created_by VARCHAR(50),
    verified_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_student_year_term (student_id, academic_year, term),
    INDEX idx_class_year_term (class_level, academic_year, term),
    INDEX idx_promotion_status (promotion_status)
);

-- Attendance Records
CREATE TABLE IF NOT EXISTS attendance (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    student_id VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Late', 'Excused') NOT NULL,
    reason VARCHAR(100),
    recorded_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE KEY unique_student_date (student_id, date),
    INDEX idx_date (date),
    INDEX idx_status (status)
);

-- Classes Table
CREATE TABLE IF NOT EXISTS classes (
    id VARCHAR(10) PRIMARY KEY,
    class_name VARCHAR(20) UNIQUE NOT NULL,
    academic_year VARCHAR(9) NOT NULL,
    programme VARCHAR(50) NOT NULL,
    form_master_id VARCHAR(50),
    assistant_form_master_id VARCHAR(50),
    class_prefect_id VARCHAR(20),
    assistant_prefect_id VARCHAR(20),
    class_capacity INT DEFAULT 40,
    current_strength INT DEFAULT 0,
    class_location VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (class_prefect_id) REFERENCES students(id),
    FOREIGN KEY (assistant_prefect_id) REFERENCES students(id)
);

-- Users Table (Staff/Teachers)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    staff_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    other_names VARCHAR(100),
    gender ENUM('Male', 'Female'),
    date_of_birth DATE,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    
    -- Employment details
    employment_date DATE,
    staff_type ENUM('Teaching', 'Non-Teaching', 'Administrative'),
    position VARCHAR(100),
    department VARCHAR(100),
    qualifications TEXT,
    
    -- Account details
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Headmaster', 'Assistant Head', 'Teacher', 'Accountant', 'Admin', 'Viewer') NOT NULL,
    permissions JSON,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    login_attempts INT DEFAULT 0,
    account_locked BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_staff_id (staff_id),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active)
);

-- Promotion History
CREATE TABLE IF NOT EXISTS promotion_history (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    student_id VARCHAR(20) NOT NULL,
    from_class VARCHAR(20) NOT NULL,
    to_class VARCHAR(20) NOT NULL,
    academic_year VARCHAR(9) NOT NULL,
    term ENUM('First Term', 'Second Term', 'Third Term') NOT NULL,
    average_score DECIMAL(5,2),
    decision ENUM('Promoted', 'Repeat', 'Conditional') NOT NULL,
    decision_by VARCHAR(50),
    decision_date DATE,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_student (student_id),
    INDEX idx_academic_year (academic_year)
);

-- Report Templates
CREATE TABLE IF NOT EXISTS report_templates (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    template_name VARCHAR(100) NOT NULL,
    template_type ENUM('Report Card', 'Transcript', 'Promotion Letter', 'Transfer Certificate'),
    programme VARCHAR(50),
    class_level VARCHAR(20),
    template_content JSON NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_template_type (template_type),
    INDEX idx_programme (programme)
);

-- System Logs
CREATE TABLE IF NOT EXISTS system_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(36),
    action VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_module (module),
    INDEX idx_created_at (created_at)
);

-- Backups Table
CREATE TABLE IF NOT EXISTS backups (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    backup_name VARCHAR(100) NOT NULL,
    backup_type ENUM('Full', 'Partial', 'Automatic') NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    file_size BIGINT,
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_backup_type (backup_type),
    INDEX idx_created_at (created_at)
);

-- Performance Indicators
CREATE TABLE IF NOT EXISTS performance_indicators (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    indicator_name VARCHAR(100) NOT NULL,
    indicator_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    category ENUM('Academic', 'Attendance', 'Discipline', 'Extracurricular'),
    weight DECIMAL(5,2) DEFAULT 1.00,
    min_score DECIMAL(5,2) DEFAULT 0,
    max_score DECIMAL(5,2) DEFAULT 100,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_indicator_code (indicator_code),
    INDEX idx_category (category)
);

-- Insert default performance indicators
INSERT INTO performance_indicators (indicator_name, indicator_code, description, category, weight) VALUES
('Academic Performance', 'ACAD_001', 'Overall academic performance based on aggregate scores', 'Academic', 40.0),
('Subject Mastery', 'ACAD_002', 'Depth of understanding in core subjects', 'Academic', 25.0),
('Practical Skills', 'ACAD_003', 'Application of knowledge in practical situations', 'Academic', 15.0),
('Attendance & Punctuality', 'ATT_001', 'Regularity and timeliness', 'Attendance', 10.0),
('Conduct & Discipline', 'DISC_001', 'Behavior and adherence to school rules', 'Discipline', 10.0);

-- Views for Reporting

-- Student Performance Summary View
CREATE VIEW student_performance_summary AS
SELECT 
    s.id as student_id,
    s.admission_number,
    CONCAT(s.first_name, ' ', s.last_name) as student_name,
    s.programme,
    s.class,
    a.academic_year,
    a.term,
    a.average_score,
    a.class_rank,
    a.overall_position,
    a.promotion_status,
    a.attendance_percentage,
    COUNT(DISTINCT at.id) as total_attendance_days,
    SUM(CASE WHEN at.status = 'Present' THEN 1 ELSE 0 END) as days_present,
    SUM(CASE WHEN at.status = 'Absent' THEN 1 ELSE 0 END) as days_absent
FROM students s
LEFT JOIN assessments a ON s.id = a.student_id
LEFT JOIN attendance at ON s.id = at.student_id AND YEAR(at.date) = SUBSTRING(a.academic_year, 1, 4)
WHERE s.status = 'Active'
GROUP BY s.id, s.admission_number, s.first_name, s.last_name, s.programme, s.class, 
         a.academic_year, a.term, a.average_score, a.class_rank, a.overall_position, 
         a.promotion_status, a.attendance_percentage;

-- Class Performance View
CREATE VIEW class_performance AS
SELECT 
    c.class_name,
    c.academic_year,
    c.programme,
    COUNT(DISTINCT s.id) as total_students,
    AVG(a.average_score) as class_average,
    MAX(a.average_score) as highest_score,
    MIN(a.average_score) as lowest_score,
    STDDEV(a.average_score) as score_std_dev,
    SUM(CASE WHEN a.promotion_status = 'Promoted' THEN 1 ELSE 0 END) as promoted_count,
    SUM(CASE WHEN a.promotion_status = 'Repeat' THEN 1 ELSE 0 END) as repeat_count,
    AVG(a.attendance_percentage) as average_attendance
FROM classes c
LEFT JOIN students s ON c.class_name = s.class
LEFT JOIN assessments a ON s.id = a.student_id AND c.academic_year = a.academic_year
GROUP BY c.class_name, c.academic_year, c.programme;

-- Programme Performance View
CREATE VIEW programme_performance AS
SELECT 
    s.programme,
    a.academic_year,
    a.term,
    COUNT(DISTINCT s.id) as total_students,
    AVG(a.average_score) as programme_average,
    AVG(a.attendance_percentage) as programme_attendance,
    SUM(CASE WHEN a.promotion_status = 'Promoted' THEN 1 ELSE 0 END) as total_promoted,
    SUM(CASE WHEN a.promotion_status = 'Repeat' THEN 1 ELSE 0 END) as total_repeat,
    (SUM(CASE WHEN a.promotion_status = 'Promoted' THEN 1 ELSE 0 END) / COUNT(DISTINCT s.id)) * 100 as promotion_rate
FROM students s
JOIN assessments a ON s.id = a.student_id
GROUP BY s.programme, a.academic_year, a.term;

-- Stored Procedures

-- Procedure to calculate class rankings
DELIMITER //
CREATE PROCEDURE CalculateClassRankings(
    IN p_class_name VARCHAR(20),
    IN p_academic_year VARCHAR(9),
    IN p_term VARCHAR(20)
)
BEGIN
    DECLARE v_rank INT DEFAULT 1;
    DECLARE v_prev_score DECIMAL(5,2) DEFAULT NULL;
    DECLARE v_student_id VARCHAR(20);
    DECLARE v_score DECIMAL(5,2);
    DECLARE done INT DEFAULT FALSE;
    
    -- Cursor for students ordered by average score descending
    DECLARE cur CURSOR FOR 
        SELECT student_id, average_score
        FROM assessments
        WHERE class_level = p_class_name 
          AND academic_year = p_academic_year 
          AND term = p_term
        ORDER BY average_score DESC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_student_id, v_score;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Update rank in assessments table
        UPDATE assessments
        SET class_rank = v_rank,
            overall_position = v_rank
        WHERE student_id = v_student_id
          AND class_level = p_class_name
          AND academic_year = p_academic_year
          AND term = p_term;
        
        -- Increment rank
        SET v_rank = v_rank + 1;
        SET v_prev_score = v_score;
    END LOOP;
    
    CLOSE cur;
END//
DELIMITER ;

-- Procedure to calculate promotion decisions
DELIMITER //
CREATE PROCEDURE CalculatePromotionDecisions(
    IN p_class_name VARCHAR(20),
    IN p_academic_year VARCHAR(9),
    IN p_term VARCHAR(20)
)
BEGIN
    UPDATE assessments a
    JOIN (
        SELECT 
            student_id,
            COUNT(CASE WHEN JSON_EXTRACT(subjects, CONCAT('$[', idx, '].grade')) = 'F9' THEN 1 END) as failed_subjects,
            AVG(JSON_EXTRACT(subjects, CONCAT('$[', idx, '].total_score'))) as avg_score
        FROM assessments,
        JSON_TABLE(
            subjects,
            '$[*]' COLUMNS(
                idx FOR ORDINALITY,
                grade VARCHAR(10) PATH '$.grade',
                total_score DECIMAL(5,2) PATH '$.total_score'
            )
        ) as jt
        WHERE class_level = p_class_name 
          AND academic_year = p_academic_year 
          AND term = p_term
        GROUP BY student_id
    ) scores ON a.student_id = scores.student_id
    SET a.promotion_status = CASE
        WHEN scores.avg_score >= 50 AND scores.failed_subjects <= 2 THEN 'Promoted'
        WHEN scores.avg_score >= 40 AND scores.failed_subjects <= 3 THEN 'Conditional'
        ELSE 'Repeat'
    END,
    a.promotion_decision_date = CURDATE()
    WHERE a.class_level = p_class_name 
      AND a.academic_year = p_academic_year 
      AND a.term = p_term;
END//
DELIMITER ;

-- Function to generate student admission number
DELIMITER //
CREATE FUNCTION GenerateAdmissionNumber(
    p_programme VARCHAR(50),
    p_admission_year YEAR
) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_prefix CHAR(2);
    DECLARE v_sequence INT;
    DECLARE v_admission_number VARCHAR(20);
    
    -- Determine prefix based on programme
    SET v_prefix = CASE p_programme
        WHEN 'General Science' THEN 'GS'
        WHEN 'General Arts' THEN 'GA'
        WHEN 'Business' THEN 'BU'
        WHEN 'Home Economics' THEN 'HE'
        WHEN 'Visual Arts' THEN 'VA'
        WHEN 'Agricultural Science' THEN 'AG'
        ELSE 'ST'
    END;
    
    -- Get next sequence number
    SELECT COALESCE(MAX(CAST(SUBSTRING(admission_number, 7) AS UNSIGNED)), 0) + 1
    INTO v_sequence
    FROM students
    WHERE admission_number LIKE CONCAT(v_prefix, p_admission_year, '%');
    
    -- Generate admission number
    SET v_admission_number = CONCAT(v_prefix, p_admission_year, LPAD(v_sequence, 4, '0'));
    
    RETURN v_admission_number;
END//
DELIMITER ;

-- Triggers

-- Trigger to update student status
DELIMITER //
CREATE TRIGGER update_student_status
AFTER UPDATE ON assessments
FOR EACH ROW
BEGIN
    IF NEW.promotion_status = 'Promoted' AND OLD.promotion_status != 'Promoted' THEN
        -- Update student class (e.g., from SHS1 to SHS2)
        UPDATE students
        SET class = CONCAT('SHS', CAST(SUBSTRING(class, 4) AS UNSIGNED) + 1)
        WHERE id = NEW.student_id;
        
        -- Log promotion in history
        INSERT INTO promotion_history (student_id, from_class, to_class, academic_year, term, decision)
        VALUES (NEW.student_id, NEW.class_level, 
                CONCAT('SHS', CAST(SUBSTRING(NEW.class_level, 4) AS UNSIGNED) + 1),
                NEW.academic_year, NEW.term, 'Promoted');
    END IF;
END//
DELIMITER ;

-- Trigger to update class strength
DELIMITER //
CREATE TRIGGER update_class_strength
AFTER INSERT ON students
FOR EACH ROW
BEGIN
    UPDATE classes
    SET current_strength = current_strength + 1
    WHERE class_name = NEW.class 
      AND academic_year = YEAR(NEW.admission_date);
END//
DELIMITER ;

-- Trigger to log system changes
DELIMITER //
CREATE TRIGGER log_student_changes
AFTER UPDATE ON students
FOR EACH ROW
BEGIN
    INSERT INTO system_logs (action, module, description)
    VALUES ('UPDATE', 'Students', 
            CONCAT('Updated student: ', OLD.admission_number, 
                   '. Changes: ', 
                   CASE WHEN OLD.first_name != NEW.first_name THEN CONCAT('First name: ', OLD.first_name, ' → ', NEW.first_name, '; ') ELSE '' END,
                   CASE WHEN OLD.last_name != NEW.last_name THEN CONCAT('Last name: ', OLD.last_name, ' → ', NEW.last_name, '; ') ELSE '' END,
                   CASE WHEN OLD.class != NEW.class THEN CONCAT('Class: ', OLD.class, ' → ', NEW.class, '; ') ELSE '' END,
                   CASE WHEN OLD.status != NEW.status THEN CONCAT('Status: ', OLD.status, ' → ', NEW.status, '; ') ELSE '' END));
END//
DELIMITER ;

-- Insert sample data
INSERT INTO classes (id, class_name, academic_year, programme, class_capacity) VALUES
('C001', 'SHS1', '2024/2025', 'General Science', 40),
('C002', 'SHS2', '2024/2025', 'General Science', 40),
('C003', 'SHS3', '2024/2025', 'General Science', 40),
('C004', 'SHS1', '2024/2025', 'General Arts', 40),
('C005', 'SHS2', '2024/2025', 'General Arts', 40),
('C006', 'SHS3', '2024/2025', 'General Arts', 40);

-- Insert sample admin user (password: admin123)
INSERT INTO users (staff_id, first_name, last_name, email, username, password_hash, role) VALUES
('ADM001', 'Admin', 'User', 'admin@school.edu.gh', 'admin', '$2a$10$YourHashedPasswordHere', 'Admin');

-- Create indexes for performance
CREATE INDEX idx_students_class ON students(class);
CREATE INDEX idx_students_programme ON students(programme);
CREATE INDEX idx_assessments_student ON assessments(student_id);
CREATE INDEX idx_assessments_class ON assessments(class_level);
CREATE INDEX idx_attendance_student_date ON attendance(student_id, date);
CREATE INDEX idx_users_role ON users(role);

-- Grant permissions (example - adjust based on your setup)
-- CREATE USER 'school_mis_user'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON school_mis_ghana.* TO 'school_mis_user'@'localhost';
-- FLUSH PRIVILEGES;

COMMIT;
