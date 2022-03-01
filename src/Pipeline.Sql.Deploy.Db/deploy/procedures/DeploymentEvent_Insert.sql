CREATE PROCEDURE [deploy].[DeploymentEvent_Insert]
    @DeploymentId int = NULl,
	@Event varchar(100),
	@EventDate datetime = null
AS
	--Find the 
	if ( @DeploymentId is null) 
	begin
		set @DeploymentId = (select top 1 DeploymentId from [deploy].Deployment order by DeploymentCreated desc)
	end
	
	insert deploy.DeploymentEvent (DeploymentId, Event, EventDate)
	values (@DeploymentId, @Event,isnull(@EventDate,getutcdate()))
	Print '    ' + @Event
RETURN 0
