
/*                                                
This is the standard predeploy script. 

Do not modify this script.

Put pre-deployment scripts in the ProjectPreDeploy.sql file

*/
Print 'Pre deploy script started'
create table #deploy (deployStart datetime)
insert into #deploy (deployStart) values (getutcdate())
go
:r ./ProjectPreDeploy.sql
go
Print 'Pre deploy script end'
