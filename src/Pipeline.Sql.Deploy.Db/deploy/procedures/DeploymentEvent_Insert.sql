CREATE PROCEDURE [deploy].[DeploymentEvent_Insert]
    @DeploymentId int = NULL,
	@Event        varchar(100),
	@EventDate    datetime = NULL
AS

	--Find the 
	if ( @DeploymentId IS NULL) 
	begin
		set @DeploymentId = (select top 1 DeploymentId from [deploy].Deployment where SessionId = @@spid order by DeploymentCreated desc)
	end
	
	insert deploy.DeploymentEvent (DeploymentId, Event, EventDate)
	values (@DeploymentId, @Event,isnull(@EventDate,getutcdate()))
	Print '    ' + @Event
RETURN 0
