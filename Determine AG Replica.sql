
IF NOT EXISTS ( SELECT  1
            FROM    sys.dm_hadr_availability_group_states hags
            JOIN    sys.availability_groups ags ON hags.group_id = ags.group_id
            WHERE   hags.primary_replica = @@SERVERNAME
            AND     ags.name = 'AG-SQLCLSTR' --name of Availability Group
          )
BEGIN
    RAISERROR('Not the primary replica', 16, -1);
END;


--another method, which checks a certain database name and not the AG Name
SELECT sys.fn_hadr_is_primary_replica ('SomeDBThatShouldAlwaysBeInTheAG');  
GO  