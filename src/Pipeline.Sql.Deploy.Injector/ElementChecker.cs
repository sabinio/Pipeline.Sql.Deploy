using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Model;
using System.Text;

namespace sabinio.DeployObjectsInjector
{
    public class ElementChecker
    {
        public static bool IsDeployObject(
        DeploymentScriptDomStep domStep)
        {
            TSqlObject element = null;

            // figure out what type of step we've got, and retrieve  
            // either the source or target element.  
            if (domStep is CreateElementStep)
            {
                element = ((CreateElementStep)domStep).SourceElement;

            }
            else if (domStep is AlterElementStep)
            {
                element = ((AlterElementStep)domStep).SourceElement;
            }
            else if (domStep is DropElementStep)
            {
                element = ((DropElementStep)domStep).TargetElement;
            }

            // Check if the element belongs to the [deploy] schema.
            if (element != null)
            {
                string schemaName = GetSchema(element);

                if (schemaName == "[deploy]")
                {
                    return true;
                }
            }
            return false;
        }

        private static string GetElementName(TSqlObject element)
        {
            StringBuilder name = new StringBuilder();
            if (element.Name.HasExternalParts)
            {
                foreach (string part in element.Name.ExternalParts)
                {
                    if (name.Length > 0)
                    {
                        name.Append('.');
                    }
                    name.AppendFormat("[{0}]", part);
                }
            }

            foreach (string part in element.Name.Parts)
            {
                if (name.Length > 0)
                {
                    name.Append('.');
                }
                name.AppendFormat("[{0}]", part);
            }

            return name.ToString();
        }

        private static string GetSchema(TSqlObject element)
        {
            if (element.ObjectType ==  ModelSchema.Schema)
            {
                return GetElementName(element);
            }
            else 
            {
                var elementParent = element.GetParent(DacQueryScopes.UserDefined);
                if (elementParent != null)
                {
                    return GetSchema(elementParent);
                }
                else { 
                    return "foo"; 
                }
            }
        }
    }
}
