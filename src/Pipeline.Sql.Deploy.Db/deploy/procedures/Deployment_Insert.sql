CREATE PROCEDURE [deploy].[Deployment_Insert]
	@DeployPropertiesJSON nvarchar(max)
AS
    SET @DeployPropertiesJSON= replace(@DeployPropertiesJSON,'@@','"') 
	SET @DeployPropertiesJSON= replace(@DeployPropertiesJSON,'&^','[')
	SET @DeployPropertiesJSON= replace(@DeployPropertiesJSON,'~$',']')
	Print '    Logging Starting of Deployment'	
	set @DeployPropertiesJSON = json_modify(@DeployPropertiesJSON,'$.extra',json_query(
	(select c.client_net_address ipAddress
	      ,s.program_name applicationName
	  from sys.dm_exec_sessions s 
      join sys.dm_exec_connections c on s.session_id = c.session_id
     where s.session_id = @@spid
     for json path, WITHOUT_ARRAY_WRAPPER )))

	insert into deploy.Deployment(DeployPropertiesJSON, SessionId)
	values (@DeployPropertiesJSON, @@spid)

	declare @DeploymentId INT
	set @DeploymentId = Scope_identity()
	
RETURN 0
