CREATE TABLE [deploy].DeploymentEvent
(
	 [DeploymentId] int			 NOT NULL
	,[Event]        varchar(100) NOT NULL   
	,[EventDate]    datetime     NOT NULL CONSTRAINT [df_deploymentEvent_EventDate] DEFAULT getutcdate()
	,CONSTRAINT [PK_deploy_DeploymentEvent] PRIMARY KEY ([DeploymentId], [Event])
)
