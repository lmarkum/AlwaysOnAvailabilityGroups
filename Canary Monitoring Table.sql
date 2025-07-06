/*Every database in an AG gets this table and a process that updates the LastUpdated based on a job that runs every minute

The secondary database must be readable in order to check values on the secondary to deermine latency and alert on it if you want that

This idea of the canary table and how it is set up is from Brent Ozar.

*/
USE HelpDesk;

CREATE TABLE dbo.Canary
(
DatabaseName VARCHAR(255),
LastUpdated DATETIME
);

/*

To seed the table
INSERT dbo.Canary

(DatabaseName, LastUpdated)
VALUES
('HelpDesk', GETUTCDATE());


Then you have a job that does this on the primary every minute.  This data is then pushed to the seoncdaries

Could use a cursor to loop through all the database names from AG replica related DMV and run the following.  

UPDATE dbo.Canary
SET LastUpdated = GETUTCDATE()

you can use SELECT DatabaseName, DATEDIFF(ss, LastUpdated, GETUTCDATE()) as LatencySeconds FROM dbo.Canary
 to get latency

 For alerting, if the below returns a row then you know that database is at least 5 minutes behind

 SELECT DatabaseName, DATEDIFF(ss, LastUpdated, GETUTCDATE()) AS LatencySeconds
 FROM dbo.Canary
 WHERE DATEDIFF(ss,LastUpdated, GETUTCDATE()) > 300
*/