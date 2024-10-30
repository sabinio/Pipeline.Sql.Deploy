using System.Globalization;
using System.Text.RegularExpressions;

namespace sabinio.DeployObjectsInjector
{
    public class ScriptTools
    {


        private static string RemoveLeadingContentBeforePattern(string script, string pattern) {
            string regex = $".*?{Regex.Escape(pattern)}";
            return Regex.Replace(script, regex, string.Empty, RegexOptions.Singleline);
        }

        private static string RemoveTrailingContentAfterPattern(string script, string pattern)
        {
            string regex = $"{Regex.Escape(pattern)}.*?";
            return Regex.Replace(script, regex, string.Empty, RegexOptions.Singleline);
        }

        private static string startComment = @"
/* Begin block added by sabinio.DeployObjectsInjector deployment contributor: */
";


        private static string endComment = @"
/* End block added by sabinio.DeployObjectsInjector deployment contributor. */
";

        public static string AddCommentBlocks(string script)
        {
            if( script.Replace("GO","").Trim().Length > 0 ) {
                return string.Format(CultureInfo.InvariantCulture, "{0} {1} {2}",
                startComment, script, endComment);
            }
            else  {
                return script.Replace("GO", "").Trim();
            }

        }
        public static string TidyUpDeployScript(string script) {
            script = RemoveLeadingContentBeforePattern(script, "USE [$(DatabaseName)];");
            script = RemoveTrailingContentAfterPattern(script, "PRINT N'Update complete.';");
            return AddCommentBlocks(script);           
        }



    }
}
