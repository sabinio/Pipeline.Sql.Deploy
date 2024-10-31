using Microsoft.SqlServer.TransactSql.ScriptDom;
using NUnit.Framework;
using sabinio.DeployObjectsInjector;
namespace Pipeline.Sql.Deploy.Injector.Tests
{
    [TestFixture]
    public class ScriptToolsTests
    {

        [TestCase(" ")]
        [TestCase(" GO ")]
        [TestCase("\r\n")]
        [TestCase(" \t ")]
        [TestCase(" GO \r\n GO")]
        public void AddCommentBlocks_IgnoresEmptyStatements(string value)
        {
            var result = ScriptTools.AddCommentBlocks(value);
            Assert.AreEqual(result, string.Empty);
        }


        [TestCase(" SELECT 'foo'; GO ")]
        public void AddCommentBlocks_AddsCommentBlocksToValidCommands(string value)
        {
            var actualresult = ScriptTools.AddCommentBlocks(value);
            var expectedresult = @"
/* Begin block added by sabinio.DeployObjectsInjector deployment contributor: */
  SELECT 'foo'; GO  
/* End block added by sabinio.DeployObjectsInjector deployment contributor. */
";
            Assert.AreEqual(expectedresult, actualresult);
        }


        [Test]
        public void TidyUpDeployScript_GetsTheImportantBit()
        {
            string script = @"
/*dull comment */ 
USE [$(DatabaseName)];
SELECT 'IMPORTANT BIT'
GO
PRINT N'Update complete.'; 
/*dull comment */
";
            var actualresult = ScriptTools.TidyUpDeployScript(script);
            var expectedresult = @"
/* Begin block added by sabinio.DeployObjectsInjector deployment contributor: */
 
SELECT 'IMPORTANT BIT'
GO
 
/* End block added by sabinio.DeployObjectsInjector deployment contributor. */
";
            Assert.AreEqual(expectedresult, actualresult);
        }

    }
}