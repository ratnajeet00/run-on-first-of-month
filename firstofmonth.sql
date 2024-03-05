mysql> DELIMITER ;
mysql> DELIMITER //
mysql>
mysql> CREATE PROCEDURE MoveAndUpdateAttendance()
    -> BEGIN
    ->   -- Declare variables for counting present and absent days
    ->   DECLARE presentDays INT;
    ->   DECLARE absentDays INT;
    ->
    ->   -- Get current date
    ->   SET @currentDate = CURDATE();
    ->
    ->   -- Copy data from attendance to new_attendance
    ->   INSERT IGNORE INTO new_attendance (uid, username, password, name, phone_number, year)
    ->   SELECT uid, username, password, name, phone_number, YEAR(@currentDate) FROM attendance;
    ->
    ->   -- Update present and absent days for the current month
    ->   SELECT
    ->     SUM(CASE WHEN days_present > 0 THEN days_present ELSE 0 END) AS presentDays,
    ->     SUM(CASE WHEN days_absent > 0 THEN days_absent ELSE 0 END) AS absentDays
    ->   FROM attendance
    ->   WHERE MONTH(attendance_date) = MONTH(@currentDate)
    ->   AND YEAR(attendance_date) = YEAR(@currentDate);
    ->
    ->   UPDATE new_attendance
    ->   SET present = presentDays,
    ->     absent = absentDays
    ->   WHERE year = YEAR(@currentDate);
    ->
    ->   -- Delete data from the old attendance table for the current month
    ->   DELETE FROM attendance
    ->   WHERE MONTH(attendance_date) = MONTH(@currentDate)
    ->   AND YEAR(attendance_date) = YEAR(@currentDate);
    ->
    -> END //
Query OK, 0 rows affected (0.02 sec)

mysql>
mysql> DELIMITER ;
mysql> select * form new_sttendance;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'form new_sttendance' at line 1
mysql> select * form new_attendance;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'form new_attendance' at line 1
mysql> select * from new_attendance;
Empty set (0.00 sec)

mysql> start transaction;
Query OK, 0 rows affected (0.00 sec)

mysql> -- Create the event scheduler if not already enabled
mysql> SET GLOBAL event_scheduler = ON;
Query OK, 0 rows affected (0.00 sec)

mysql>
mysql> -- Create the event to run on the 1st day of every month
mysql> CREATE EVENT IF NOT EXISTS monthly_event
    -> ON SCHEDULE
    ->     EVERY 1 MONTH
    ->     STARTS TIMESTAMP(CURRENT_DATE, '00:00:00')
    -> DO
    ->     CALL MoveAndUpdateAttendance();
Query OK, 0 rows affected (0.01 sec)

mysql> SHOW VARIABLES LIKE 'event_scheduler';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| event_scheduler | ON    |
+-----------------+-------+
1 row in set (0.01 sec)

mysql> SET GLOBAL event_scheduler = ON;
Query OK, 0 rows affected (0.00 sec)
