using System.Collections.Generic;
using Microsoft.SqlServer.Dac.Deployment;
using System.Reflection;
using System.Diagnostics.Metrics;

namespace sabinio.DeployObjectsInjector
{
    public class CreateSabinPostDeploy : DeploymentStep
    {
        public override IList<string> GenerateTSQL()
        {
            string createBeginPostDeploySQL = ScriptTools.AddCommentBlocks(@"
exec deploy.[Deployment_Insert] '$(DeployProperties)';

DECLARE @EventDate datetime = (SELECT CAST($(deployStart) as datetime));

exec deploy.DeploymentEvent_Insert @Event= 'Deploy-Started', @EventDate = @EventDate;
GO
exec deploy.DeploymentEvent_Insert @Event= 'Deploy-Finished'
GO
exec deploy.DeploymentEvent_Insert @Event= 'PostDeploy-Started'
GO
");

            var statementList = new List<string>();
            statementList.Add(createBeginPostDeploySQL);
            return statementList;
        }

    }


}