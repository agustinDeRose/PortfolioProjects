/*
    Procedure Name: AsignarHorasAProyecto

    Description:
    This stored procedure assigns hours to a specific project and employee, while ensuring that the total hours assigned to the project do not exceed a predefined maximum limit. The procedure starts a transaction to ensure data consistency and uses a savepoint to manage potential errors.

    Parameters:
    - proyectoId: Integer representing the ID of the project to which hours will be assigned.
    - empleadoId: Integer representing the ID of the employee who will receive the hours.
    - horasAsignadas: Integer representing the number of hours to be assigned.

    Functionality:
    1. Starts a transaction and sets a savepoint.
    2. Calculates the current total hours assigned to the specified project.
    3. Checks if adding the new hours exceeds the maximum allowed limit.
    4. If the limit is exceeded, rolls back to the savepoint and returns an error message.
    5. If within the limit, inserts the new hours assignment and commits the transaction.

    Error Handling:
    - Rolls back to the savepoint if the total hours exceed the limit and returns an error message.
*/

DELIMITER //

CREATE PROCEDURE AsignarHorasAProyecto(
    IN proyectoId INT,       -- Project ID to which hours will be assigned
    IN empleadoId INT,       -- Employee ID who will receive the assigned hours
    IN horasAsignadas INT    -- Number of hours to be assigned to the project
)
BEGIN
    DECLARE horasTotales INT DEFAULT 0;     -- Variable to store the total assigned hours
    DECLARE horasMaximas INT DEFAULT 100;   -- Maximum allowed hours per project

    -- Start a transaction to ensure all operations are atomic
    START TRANSACTION;
    
    -- Set a savepoint to rollback to in case of an error
    SAVEPOINT PreValidacion;
    
    -- Calculate the current total of hours assigned to the project
    SELECT SUM(horas_asignadas) INTO horasTotales 
    FROM AsignacionesDeProyectos 
    WHERE proyecto_id = proyectoId;
    
    -- Convert the result of SUM() to 0 if it is NULL (i.e., no previous assignments)
    SET horasTotales = IFNULL(horasTotales, 0) + horasAsignadas;
    
    -- Check if the total assigned hours exceed the maximum allowed limit
    IF horasTotales > horasMaximas THEN
        -- Rollback to the savepoint if the limit is exceeded
        ROLLBACK TO PreValidacion;
        
        -- Return an error message indicating that the limit has been exceeded
        SELECT 'Error: The assignment exceeds the total allowed hours for the project.' AS mensaje;
    ELSE
        -- Insert the new assignment if the total is within the allowed limit
        INSERT INTO AsignacionesDeProyectos (proyecto_id, empleado_id, horas_asignadas) 
        VALUES (proyectoId, empleadoId, horasAsignadas);
        
        -- Commit the transaction if all operations were successful
        COMMIT;
    END IF;
END //

DELIMITER ;