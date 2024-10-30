using Microsoft.SqlServer.Dac;
using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Model;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;
using Assembly = System.Reflection.Assembly;


namespace sabinio.DeployObjectsInjector
{
    public class DacpacTools
    {
        public static TSqlModel CreateModelFromDacpacFile(string dacpacPath)
        {
            return TSqlModel.LoadFromDacpac(dacpacPath, new ModelLoadOptions());
        }

        public static DacPackage CreateInMemoryDacpacFromModel(TSqlModel InputModel)
        {
            var memoryStream = new MemoryStream();
            DacPackageExtensions.BuildPackage(memoryStream, InputModel, new PackageMetadata());
            memoryStream.Position = 0;
            return DacPackage.Load(memoryStream);
        }

        public static string CreateDeployObjectsScript(DacPackage dacpacToInject, DacPackage dacpacToAlter)
        {
            var options = new DacDeployOptions() { CreateNewDatabase = false, ScriptDatabaseOptions = false, ScriptDeployStateChecks = false, BlockOnPossibleDataLoss = false };
            return DacServices.GenerateDeployScript(dacpacToInject, dacpacToAlter, "dummydbname", options);
        }

    }
}
