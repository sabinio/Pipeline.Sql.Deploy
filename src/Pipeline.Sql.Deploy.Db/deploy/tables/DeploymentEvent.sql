CREATE TABLE [deploy].DeploymentEvent
(
	 DeploymentId INT not null
	,Event varchar(100) not null   
	,EventDate Datetime not null DEFAULT getutcdate()
	,constraint PK_DeploymentEvent primary key (DeploymentId,Event)
)
