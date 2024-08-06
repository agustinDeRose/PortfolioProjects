/*
    Project Name: Data Integrity and Auditing with Triggers

    Description:
    This script demonstrates the use of triggers to enforce data integrity and perform auditing in a database. It includes:
    1. A trigger to validate hours assigned to a project before insertion, ensuring that the total does not exceed a maximum limit.
    2. A trigger to log changes in project assignments for auditing purposes.

    Skills Demonstrated:
    - Triggers: Automating data validation and auditing.
    - Data Integrity: Ensuring data accuracy and consistency through constraints and validations.

    Note: Ensure SQL_SAFE_UPDATES is handled properly in your environment to prevent unintended changes.
*/

-- Trigger: BeforeInsertAsignacion
-- Validates hours assigned to a project before insertion to ensure it does not exceed the maximum limit
DELIMITER //

CREATE TRIGGER BeforeInsertAsignacion
BEFORE INSERT ON AsignacionesDeProyectos
FOR EACH ROW
BEGIN
    DECLARE horasTotales INT DEFAULT 0;
    DECLARE horasMaximas INT DEFAULT 100;
    
    -- Calculate the total assigned hours for the project
    SELECT SUM(horas_asignadas) INTO horasTotales 
    FROM AsignacionesDeProyectos 
    WHERE proyecto_id = NEW.proyecto_id;
    
    -- Convert the result of SUM() to 0 if it is NULL (i.e., no previous assignments)
    SET horasTotales = IFNULL(horasTotales, 0) + NEW.horas_asignadas;
    
    -- Check if the total assigned hours exceed the maximum allowed limit
    IF horasTotales > horasMaximas THEN
        -- Signal an error if the limit is exceeded
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: The assignment exceeds the total allowed hours for the project.';
    END IF;
END //

DELIMITER ;

-- Trigger: AfterInsertAsignacion
-- Logs the details of each new assignment into an audit table for tracking changes
DELIMITER //

CREATE TRIGGER AfterInsertAsignacion
AFTER INSERT ON AsignacionesDeProyectos
FOR EACH ROW
BEGIN
    -- Insert a record into the audit table
    INSERT INTO AsignacionesDeProyectos_Audit (
        proyecto_id,
        empleado_id,
        horas_asignadas,
        fecha_asignacion
    ) VALUES (
        NEW.proyecto_id,
        NEW.empleado_id,
        NEW.horas_asignadas,
        NOW()
    );
END //

DELIMITER ;

-- Create Audit Table for Tracking Assignments
CREATE TABLE AsignacionesDeProyectos_Audit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proyecto_id INT,
    empleado_id INT,
    horas_asignadas INT,
    fecha_asignacion DATETIME
);

SELECT * FROM AsignacionesDeProyectos_Audit;