using Microsoft.SqlServer.Dac;
using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Model;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using Assembly = System.Reflection.Assembly;



namespace sabinio.DeployObjectsInjector
{

    [ExportDeploymentPlanModifier("sabinio.DeployObjectsInjector", "1.0.0.0")]
    public class PlanModifier : DeploymentPlanModifier
    {
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {

            // Loop through all steps in the incoming deployment plan.
            // Bookmark the pre/post-deployment steps.
            // Remove anything that references the [deploy] schema.
            DeploymentStep beginPreDeploy  = null;
            DeploymentStep endPreDeploy    = null;
            DeploymentStep beginPostDeploy = null;
            DeploymentStep endPostDeploy   = null;
            DeploymentStep nextStep        = context.PlanHandle.Head;

            while (nextStep != null)
            {
                // Increment the step pointer, saving both the current and next steps
                DeploymentStep currentStep = nextStep;
                nextStep = currentStep.Next;

                // Look for steps that mark the pre/post deployment scripts
                // These steps will always be in the deployment plan

                if (currentStep is BeginPreDeploymentScriptStep)
                {
                    // This step marks the begining of the predeployment script.
                    // Save the step and move on.
                    beginPreDeploy = currentStep;
                    continue;
                }
                if (currentStep is EndPreDeploymentScriptStep )
                {
                    // This step marks the end of the predeployment script.
                    // Save the step and move on.
                    endPreDeploy = currentStep;
                    continue;
                }
                if (currentStep is BeginPostDeploymentScriptStep)
                {
                    // This is the step that marks the beginning of the post deployment script.  
                    // Save the step and move on.
                    beginPostDeploy = currentStep;
                    continue;
                }
                if (currentStep is EndPostDeploymentScriptStep)
                {
                    // This is the step that marks the end of the post deployment script.  
                    // We do not continue processing after this point.
                    endPostDeploy = currentStep;
                    break;
                }

                // Determine if this is a step that we need to inspect for [deploy] schema items
                DeploymentScriptDomStep domStep = currentStep as DeploymentScriptDomStep;
                if (domStep == null)
                {
                    // This step is not a step that will qualify,  
                    // so skip to the next step.  
                    continue;
                }

                TSqlScript script = domStep.Script as TSqlScript;
                if (script == null)
                {
                    // The script dom step does not have a script with batches - skip  
                    continue;
                }

                // If this step concerns an object in the [deploy] schema, remove the step.
                if (ElementChecker.IsDeployObject(domStep))
                {
                    Remove(context.PlanHandle, currentStep);
                }

            }

            // Modify the deployment plan.

            // Add a step to the start of the plan to mark the start time.
            DeploymentScriptStep setDeployStartVar = new DeploymentScriptStep(ScriptTools.AddCommentBlocks(":setvar deployStart getutcdate()"));
            AddAfter(context.PlanHandle, context.PlanHandle.Head, setDeployStartVar);

            // Get the model for the [deploy] schema objects from the Pipeline.Sql.Deploy.Db dacpac.
            // The "Pipeline.Sql.Deploy.Module" Powershell module should package our dacpac into a "db" folder adjacent to the module.
            string location = Assembly.GetExecutingAssembly().Location;
            TSqlModel sabinDeployModel = DacpacTools.CreateModelFromDacpacFile(@$"{location}\..\..\db\Pipeline.Sql.Deploy.Db.dacpac");

            // Get the model for the incoming deployment plan.
            TSqlModel deploymentPlanModel = context.Target;

            // Create dacpacs from the models in order to run a comparison
            DacPackage sabinDeployDacPac = DacpacTools.CreateInMemoryDacpacFromModel(sabinDeployModel);
            DacPackage targetDacPac = DacpacTools.CreateInMemoryDacpacFromModel(deploymentPlanModel);

            // Compare the dacpacs to create a tsql script to add/amend our objects. 
            string deployscript = DacpacTools.CreateDeployObjectsScript(sabinDeployDacPac, targetDacPac);
            // We don't want all the contents so strip out the unnecessary bits:
            string deployObjectsTSql = ScriptTools.TidyUpDeployScript(deployscript);

            // Add our steps.
            DeploymentScriptStep  injectSabinDeploy = new DeploymentScriptStep(deployObjectsTSql);
            DeploymentStep        injectPostDeploy  = new CreateSabinPostDeploy();
            if (beginPostDeploy != null)
            {
                AddBefore(context.PlanHandle, beginPostDeploy, injectSabinDeploy);
                AddAfter( context.PlanHandle, beginPostDeploy, injectPostDeploy);

            }

            DeploymentScriptStep injectPostDeployCompleted = new DeploymentScriptStep(
                    ScriptTools.AddCommentBlocks("exec deploy.DeploymentEvent_Insert @Event = 'PostDeploy-Completed'; ")
                    );
            if (endPostDeploy != null)
            {
                AddBefore(context.PlanHandle, endPostDeploy, injectPostDeployCompleted);
            }

            DeploymentScriptStep injectDeploymentComplete = new DeploymentScriptStep(
                    ScriptTools.AddCommentBlocks("exec deploy.DeploymentEvent_Insert @Event = 'Deployment-Completed'; ")
                    );
            AddAfter(context.PlanHandle, context.PlanHandle.Tail, injectDeploymentComplete);

        }
    }
}
