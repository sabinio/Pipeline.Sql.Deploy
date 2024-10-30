CREATE TABLE [deploy].Deployment
(
	[DeploymentId]          int identity(1,1)   NOT NULL,
    [DeploymentCreated]     datetime            NOT NULL CONSTRAINT [df_deploy_deployment_deploymnentCreated] DEFAULT getutcdate(),
    [DeployPropertiesJSON]  nvarchar(MAX)           NULL,
    [SessionId]             int                 NOT NULL CONSTRAINT [df_deploy_deployment_SessionId] DEFAULT  ((0)),
    CONSTRAINT [pk_deploy_deployment] PRIMARY KEY ([DeploymentId])
)
