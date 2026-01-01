-- Sample Data for Ghana School MIS
-- Insert sample students for testing

-- Sample General Science Students
INSERT INTO students (id, admission_number, first_name, last_name, gender, date_of_birth, programme, class, guardian_name, guardian_contact, admission_date) VALUES
('ST001', 'GS20240001', 'Kwame', 'Amoah', 'Male', '2008-05-15', 'General Science', 'SHS1', 'Yaw Amoah', '0241234567', '2024-09-01'),
('ST002', 'GS20240002', 'Ama', 'Mensah', 'Female', '2008-08-22', 'General Science', 'SHS1', 'Kofi Mensah', '0242345678', '2024-09-01'),
('ST003', 'GS20240003', 'Yaw', 'Owusu', 'Male', '2007-11-30', 'General Science', 'SHS2', 'Akua Owusu', '0243456789', '2023-09-01'),
('ST004', 'GS20240004', 'Esi', 'Asante', 'Female', '2007-03-10', 'General Science', 'SHS2', 'Kwaku Asante', '0244567890', '2023-09-01'),
('ST005', 'GS20240005', 'Kofi', 'Adjei', 'Male', '2006-07-25', 'General Science', 'SHS3', 'Ama Adjei', '0245678901', '2022-09-01');

-- Sample General Arts Students
INSERT INTO students (id, admission_number, first_name, last_name, gender, date_of_birth, programme, class, guardian_name, guardian_contact, admission_date) VALUES
('ST006', 'GA20240001', 'Akua', 'Ansah', 'Female', '2008-04-18', 'General Arts', 'SHS1', 'Yaw Ansah', '0246789012', '2024-09-01'),
('ST007', 'GA20240002', 'Kwasi', 'Boateng', 'Male', '2008-09-12', 'General Arts', 'SHS1', 'Esi Boateng', '0247890123', '2024-09-01'),
('ST008', 'GA20240003', 'Adwoa', 'Darko', 'Female', '2007-12-05', 'General Arts', 'SHS2', 'Kofi Darko', '0248901234', '2023-09-01'),
('ST009', 'GA20240004', 'Yaw', 'Frimpong', 'Male', '2007-02-28', 'General Arts', 'SHS2', 'Ama Frimpong', '0249012345', '2023-09-01'),
('ST010', 'GA20240005', 'Esi', 'Gyamfi', 'Female', '2006-06-15', 'General Arts', 'SHS3', 'Kwaku Gyamfi', '0240123456', '2022-09-01');

-- Sample Business Students
INSERT INTO students (id, admission_number, first_name, last_name, gender, date_of_birth, programme, class, guardian_name, guardian_contact, admission_date) VALUES
('ST011', 'BU20240001', 'Kofi', 'Acheampong', 'Male', '2008-03-22', 'Business', 'SHS1', 'Yaa Acheampong', '0241234567', '2024-09-01'),
('ST012', 'BU20240002', 'Ama', 'Baffour', 'Female', '2008-07-08', 'Business', 'SHS1', 'Kwame Baffour', '0242345678', '2024-09-01');

-- Sample Home Economics Students
INSERT INTO students (id, admission_number, first_name, last_name, gender, date_of_birth, programme, class, guardian_name, guardian_contact, admission_date) VALUES
('ST013', 'HE20240001', 'Adwoa', 'Kumi', 'Female', '2008-01-14', 'Home Economics', 'SHS1', 'Yaw Kumi', '0243456789', '2024-09-01'),
('ST014', 'HE20240002', 'Akua', 'Larbi', 'Female', '2008-10-30', 'Home Economics', 'SHS1', 'Kofi Larbi', '0244567890', '2024-09-01');

-- Sample Assessments
INSERT INTO assessments (id, student_id, academic_year, term, class_level, programme, subjects, total_aggregate, average_score) VALUES
(UUID(), 'ST001', '2024/2025', 'First Term', 'SHS1', 'General Science', 
 '[
   {"subjectCode": "ENG", "subjectName": "English Language", "classScore": 35, "examScore": 55, "totalScore": 90, "grade": "A1"},
   {"subjectCode": "MATH", "subjectName": "Mathematics", "classScore": 30, "examScore": 50, "totalScore": 80, "grade": "B2"},
   {"subjectCode": "IS", "subjectName": "Integrated Science", "classScore": 32, "examScore": 53, "totalScore": 85, "grade": "A1"},
   {"subjectCode": "SS", "subjectName": "Social Studies", "classScore": 28, "examScore": 47, "totalScore": 75, "grade": "B3"},
   {"subjectCode": "PHY", "subjectName": "Physics", "classScore": 25, "examScore": 45, "totalScore": 70, "grade": "C4"},
   {"subjectCode": "CHEM", "subjectName": "Chemistry", "classScore": 30, "examScore": 48, "totalScore": 78, "grade": "B2"},
   {"subjectCode": "BIO", "subjectName": "Biology", "classScore": 33, "examScore": 52, "totalScore": 85, "grade": "A1"},
   {"subjectCode": "EMATH", "subjectName": "Elective Mathematics", "classScore": 28, "examScore": 46, "totalScore": 74, "grade": "B3"},
   {"subjectCode": "ICT", "subjectName": "Information Technology", "classScore": 35, "examScore": 54, "totalScore": 89, "grade": "A1"}
 ]', 726, 80.67);
