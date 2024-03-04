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
            SET holidayFound = true;
            #count number of work days for this period
            CALL countNumberOfWorkDays(curDTS, curDTE, userLogin, @nWorkDays0);
            SET vacationDuration = vacationDuration + @nWorkDays0;

            IF prevDTS AND prevDTE IS NOT NULL THEN
                #if prev vacation should be counted too count it too
                CALL countNumberOfWorkDays(prevDTE + INTERVAL 1 DAY, curDTS - INTERVAL 1 DAY, userLogin, @nWorkDays);
                IF @nWorkDays = 0 THEN
                    CALL countNumberOfWorkDays(prevDTS, prevDTE, userLogin, @nWorkDays);
                    SET vacationDuration = vacationDuration + @nWorkDays;
                END IF;
            END IF;
        ELSEIF holidayFound THEN
            #count number of work days for next after holiday period if it should be counted
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

CALL employeesVacationDurationByDate('user5678', '2023-03-15', @vacationDuration);
SELECT @vacationDuration;