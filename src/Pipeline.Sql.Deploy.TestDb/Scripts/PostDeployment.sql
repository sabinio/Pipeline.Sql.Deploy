
/*                                                
This is the standard postdeploy script. 

Do not modify this script.

Put Post-deployment scripts in the ProjectPostDeploy.sql file

*/

declare @deployStart datetime
if object_id('tempdb..#deploy')is not null set @deployStart = (select deployStart from #deploy)
exec deploy.[Deployment_Insert] '$(DeployProperties)'

exec deploy.DeploymentEvent_Insert @Event= "Deploy-Started", @EventDate = @deployStart
Go
exec deploy.DeploymentEvent_Insert @Event= "Deploy-Finished"
go
exec deploy.DeploymentEvent_Insert @Event= "PostDeploy-Started"
go
:r .\ProjectPostDeploy.sql
go
exec deploy.DeploymentEvent_Insert @Event= "PostDeploy-Completed"
