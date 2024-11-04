using Microsoft.SqlServer.Dac;
using Microsoft.SqlServer.Dac.Model;
using sabinio.DeployObjectsInjector;

namespace Pipeline.Sql.Deploy.Injector.Tests
{
    [TestFixture]
    public static class DacpacToolsTests
    {
        static string ArtifactsPath;
        static string? deployDacpacPath;
        static TSqlModel? deployTSqlModel;
        static DacPackage? deployDacpac;
        static SqlServerVersion targetVersion;

        [SetUp]
        public static void Setup() {
            ArtifactsPath = TestContext.Parameters.Get("artifactsPath", "unknown");
            deployDacpacPath = @$"{ArtifactsPath}\Pipeline.Sql.Deploy\db\Pipeline.Sql.Deploy.Db.dacpac";
            deployTSqlModel = DacpacTools.CreateModelFromDacpacFile(deployDacpacPath);
            deployDacpac = DacpacTools.CreateInMemoryDacpacFromModel(deployTSqlModel);
            targetVersion = deployTSqlModel.Version;
        }

        [Test]
        public static void CreateDeployObjectsScript_AddsDeployObjectsIfNotThere()
        {
            string NoDeployObjectsTSql = @"
CREATE SCHEMA [bob]
GO
CREATE TABLE [bob].[foo](
	[Id] [int] NULL
)
GO;
";
            TSqlModel NoDeployObjectsTSqlModel = new TSqlModel(targetVersion, new TSqlModelOptions());
            NoDeployObjectsTSqlModel.AddObjects(NoDeployObjectsTSql);
            DacPackage NoDeployObjectsDacpac = DacpacTools.CreateInMemoryDacpacFromModel(NoDeployObjectsTSqlModel);

            string deployScript = DacpacTools.CreateDeployObjectsScript(deployDacpac, NoDeployObjectsDacpac);
            TestContext.Out.WriteLine(deployScript);
            Assert.IsTrue(deployScript.Contains(@"CREATE SCHEMA [deploy]"));
            Assert.IsTrue(deployScript.Contains(@"CREATE TABLE [deploy].[DeploymentEvent]"));
            Assert.IsTrue(deployScript.Contains(@"CREATE TABLE [deploy].[Deployment]"));
            Assert.IsTrue(deployScript.Contains(@"CREATE PROCEDURE [deploy].[DeploymentEvent_Insert]"));
            Assert.IsTrue(deployScript.Contains(@"CREATE PROCEDURE [deploy].[Deployment_Insert]"));
        }



        [Test]
        public static void CreateDeployObjectsScript_AltersDeployObjectsIfTheyDontMatch()
        {
            TSqlModel ObjectsRequireAlterTSqlModel = new TSqlModel(targetVersion, new TSqlModelOptions());
            string ObjectsRequireAlterTSql = @"

CREATE SCHEMA [deploy];
GO 
CREATE TABLE [deploy].[Deployment](
	[DeploymentId] [int] IDENTITY(1,1) NOT NULL
)
GO

CREATE TABLE [deploy].[DeploymentEvent](
	[DeploymentId] [int] NOT NULL
) ON [PRIMARY]
GO

CREATE PROCEDURE [deploy].[Deployment_Insert]
	@foo nvarchar(max)
AS
    PRINT 'nope';
RETURN 0
GO

CREATE PROCEDURE [deploy].[DeploymentEvent_Insert]
    @bar int = NULL
AS
    PRINT 'nope';
RETURN 0
GO

";
            ObjectsRequireAlterTSqlModel.AddObjects(ObjectsRequireAlterTSql);
            DacPackage ObjectsRequireAlterDacpac = DacpacTools.CreateInMemoryDacpacFromModel(ObjectsRequireAlterTSqlModel);

            string deployScript = DacpacTools.CreateDeployObjectsScript(deployDacpac, ObjectsRequireAlterDacpac);
            TestContext.Out.WriteLine(deployScript);
            Assert.IsFalse(deployScript.Contains(@"CREATE SCHEMA [deploy]"));
            Assert.IsTrue(deployScript.Contains(@"ALTER TABLE [deploy].[DeploymentEvent]"));
            Assert.IsTrue(deployScript.Contains(@"ALTER TABLE [deploy].[Deployment]"));
            Assert.IsTrue(deployScript.Contains(@"ALTER PROCEDURE [deploy].[DeploymentEvent_Insert]"));
            Assert.IsTrue(deployScript.Contains(@"ALTER PROCEDURE [deploy].[Deployment_Insert]"));
        }

        [Test]
        public static void CreateDeployObjectsScript_DoesNotModifyFileGroups()
        {
            string NoDeployObjectsTSql = @"
CREATE TABLE [dbo].[foo]( [Id] [int] NULL )
GO;
";

            TSqlModel NoDeployObjectsTSqlModel = new TSqlModel(targetVersion, new TSqlModelOptions());
            NoDeployObjectsTSqlModel.AddObjects(NoDeployObjectsTSql);
            DacPackage NoDeployObjectsDacpac = DacpacTools.CreateInMemoryDacpacFromModel(NoDeployObjectsTSqlModel);

            string deployScript = DacpacTools.CreateDeployObjectsScript(deployDacpac, NoDeployObjectsDacpac);
            TestContext.Out.WriteLine(deployScript);
            Assert.IsFalse(deployScript.Contains(@"MODIFY FILEGROUP"));
        }

        [TearDown]
        public static void TearDown()
        {
            deployTSqlModel.Dispose();
            deployDacpac.Dispose();
        }
    }
}
