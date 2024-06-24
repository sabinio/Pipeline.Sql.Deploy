CREATE TABLE [deploy].Deployment
(
	 DeploymentId INT identity(1,1) PRIMARY KEY,
     DeploymentCreated datetime not null default getutcdate(),
    [DeployPropertiesJSON] NVARCHAR(MAX) NULL,
    SessionId int  default  ((0))
)
