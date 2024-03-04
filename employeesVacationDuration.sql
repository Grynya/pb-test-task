USE testTaskPb;
CREATE PROCEDURE employeesVacationDurationByDate(IN userLogin nchar(36), IN inputDate date, OUT vacationDuration INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE curDTS DATE;
    DECLARE curDTE DATE;
    DECLARE prevDTS DATE DEFAULT NULL;
    DECLARE prevDTE DATE DEFAULT NULL;
    DECLARE holidayFound BOOL DEFAULT FALSE;
    DECLARE dateCursor CURSOR FOR SELECT DTS, DTE FROM Holidays WHERE login = userLogin ORDER BY DTS;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET vacationDuration = 0;

    OPEN dateCursor;
    #get first row
    FETCH dateCursor INTO curDTS, curDTE;
    loop_name:
    LOOP
        IF inputDate BETWEEN curDTS AND curDTE THEN
            #vacation period found
            SET holidayFound = true;
            #count the number of working days for this period
            CALL countNumberOfWorkDays(curDTS, curDTE, userLogin, @nWorkDays0);
            SET vacationDuration = vacationDuration + @nWorkDays0;

            IF prevDTS AND prevDTE IS NOT NULL THEN
                #if the previous vacation should also be counted, count it too
                CALL countNumberOfWorkDays(prevDTE + INTERVAL 1 DAY, curDTS - INTERVAL 1 DAY, userLogin, @nWorkDays);
                IF @nWorkDays = 0 THEN
                    CALL countNumberOfWorkDays(prevDTS, prevDTE, userLogin, @nWorkDays);
                    SET vacationDuration = vacationDuration + @nWorkDays;
                END IF;
            END IF;
        ELSEIF holidayFound THEN
            #count the number of working days in the period following the vacation, if it should be taken into account
            CALL countNumberOfWorkDays(prevDTE + INTERVAL 1 DAY, curDTS - INTERVAL 1 DAY, userLogin, @nWorkDays);
            IF @nWorkDays = 0 THEN
                CALL countNumberOfWorkDays(curDTS, curDTE, userLogin, @nWorkDays);
                SET vacationDuration = vacationDuration + @nWorkDays;
            ELSE
                LEAVE loop_name;
            END IF;
        END IF;
        SET prevDTS = curDTS;
        SET prevDTE = curDTE;
        FETCH dateCursor INTO curDTS, curDTE;
        IF done THEN
            LEAVE loop_name;
        END IF;
    END LOOP loop_name;
END;

CREATE PROCEDURE countNumberOfWorkDays(IN DTS date, IN DTE date, IN userLogin nchar(36), OUT nWorkDays INT)
BEGIN
    DECLARE dayStartOfVacation INT DEFAULT DAY(DTS);
    DECLARE periodLength INT DEFAULT DATEDIFF(DTE, DTS) + 1;
    DECLARE userSchedule nchar(36);
    SET userSchedule = SUBSTRING((SELECT C_DAYS
                                  FROM Calendar
                                  WHERE Cal_Id = (SELECT Cal_Id FROM Users WHERE login = userLogin)
                                    AND C_MONTH = MONTH(DTS)
                                    AND C_YEAR = YEAR(DTS)),
                                 dayStartOfVacation,
                                 periodLength);
    SET nWorkDays = CHAR_LENGTH(REPLACE(REPLACE(userSchedule, 'H', ''), 'W', ''));
END;

CALL employeesVacationDurationByDate('user1234', '2023-02-09', @vacationDuration);
SELECT @vacationDuration;