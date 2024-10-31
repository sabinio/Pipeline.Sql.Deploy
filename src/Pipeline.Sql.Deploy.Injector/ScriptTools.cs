using System;
using System.Globalization;
using System.Text.RegularExpressions;

namespace sabinio.DeployObjectsInjector
{
    public class ScriptTools
    {

        private static string RemoveLeadingAndTrailingContent(string script, string leadInPattern, string leadOutPattern)
        {
            string leadincapturegroup    = @$"(?<removeleadin>[\s\S]*)";
            string usefulbitcapturegroup = @$"(?<usefulbit>[\s\S]*?)";
            string leadoutcapturegroup   = @$"(?<removeleadout>[\s\S]*)";
            string regex = $"{leadincapturegroup}{Regex.Escape(leadInPattern)}{usefulbitcapturegroup}{Regex.Escape(leadOutPattern)}{leadoutcapturegroup}";
            Match match = Regex.Match(script, regex);
            return match.Success ? match.Groups["usefulbit"].Value : script;

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
            script = RemoveLeadingAndTrailingContent(script, "USE [$(DatabaseName)];", "PRINT N'Update complete.';");
            return AddCommentBlocks(script);           
        }



    }
}
