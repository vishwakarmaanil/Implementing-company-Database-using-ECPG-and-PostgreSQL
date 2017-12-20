/*

Project - 1 
Group Members:
1. Anil Vishwakarma
2. Siddhant Chaudhary

*/

#include <stdio.h>

EXEC SQL INCLUDE sqlca;

EXEC SQL WHENEVER SQLERROR sqlprint;

EXEC SQL BEGIN DECLARE SECTION;
char *ssn=NULL;
char *pno = NULL;
char *pname= NULL;
char *mgrName = NULL;
char *hours = NULL;
char *ename = NULL;
char *numberofemps = NULL;
char *numberofdependents=NULL;
char *totalhours = NULL;
char *ehours =NULL;
int hour_ind,totalHr_ind,dep_ind,ehours_ind;
char dname[20],fname[20],lname[20];
char minit[2];
double salary;
EXEC SQL END DECLARE SECTION;

void employeeandprojectinfo(char* ssn);

void updatedb(char* ssn,char* pno,char* hours);

int main(int argc, char* argv[])
{

	EXEC SQL CONNECT TO unix:postgresql://localhost /cs687 USER av0022 USING "f16687";

	EXEC SQL BEGIN DECLARE SECTION;
	char* ssn = argc > 1 ? argv[1] : NULL;
	char* pno = argc > 2 ? argv[2] : NULL;
	char* hours = argc > 3 ? argv[3] : NULL;
	EXEC SQL END DECLARE SECTION;

	employeeandprojectinfo(ssn);
	updatedb(ssn,pno,hours);
	employeeandprojectinfo(ssn);
	EXEC SQL COMMIT;
	EXEC SQL DISCONNECT;
	return 0;
}

void updatedb(char* ssn,char* pno,char* hours)
{
	
	EXEC SQL select hours INTO :ehours :ehours_ind
	FROM Works_On 
	Where Pno = :pno AND essn = :ssn;
	
	if (ehours)
	{
	

		if (strcmp(hours, "0") == 0)
		/*if input hours is 0 then delete row */		
		{
			
			EXEC SQL DELETE FROM Works_On 
			Where Pno = :pno AND essn = :ssn;
			printf("\n\tEmployee %s who was working on %s hours on project %s stopped working on this project\n\n", ename, ehours, pname);
		}
	else
	/* update hours*/
	
	{
	
		EXEC SQL UPDATE works_On 
		SET hours = :hours
		Where Pno = :pno AND essn = :ssn;

		printf("\n\tThe number of hours for employee %s on project %s is updated from %s to %s\n\n", ename, pname, ehours, hours);
	}
	}
	
	else
	{
		EXEC SQL INSERT INTO works_On 
		VALUES(:ssn,:pno,:hours);
		printf("\n\t Employee '%s' started to work on %s hours on project '%s'.\n\n", ename, hours, pname);
}


}

/* Retrieve and Print Employee informations and Project details*/
void employeeandprojectinfo(char* ssn)
{
	/*Employee Info*/
	EXEC SQL  
	select  emp.ename,dname,salary,depNo.numberofdependents  from
	(select ssn,fname || ' ' || minit || ' ' || lname As ename,dname,salary 
	INTO :ename,:dname, :salary,:numberofdependents :dep_ind
	from employee,department where Dnumber=Dno and Ssn=:ssn) as emp
	LEFT OUTER JOIN ( Select essn,count(*)numberofdependents from dependent group by essn) as depNo
	on depNo.essn=emp.ssn;

	printf("\n\t\t\tEmployee Information\t\t\t\n");
	printf("\t\t\t--------------------\t\t\t\n");
	printf("\tEmployee Name\t\t DepartmentName\t\t salary\t\t Number_of_dependents\n");
	
	if(SQLCODE==0)
	{	

	printf("\t%s\t\t%s\t\t%.2f\t\t%s\t\t\n\n",ename,dname,salary,numberofdependents);
	}


	/*Project Info*/

	EXEC SQL DECLARE C1 CURSOR FOR 
	Select EmpProjects.Pnumber, EmpProjects.Pname, EmpProjects.MgrName, EmpProjects.Hours, ProjGrp.numberofemps,ProjGrp.totalhours from
	(select Proj.Pnumber, Proj.Pname, MgrEmp.Fname || ' ' || MgrEmp.Minit || ' ' || MgrEmp.Lname As MgrName, Wrk.Hours  from Project As Proj 
	LEFT OUTER Join Department Dept ON Proj.Dnum = Dept.Dnumber
	LEFT OUTER Join Employee MgrEmp ON MgrEmp.ssn = Dept.Mgr_ssn
	LEFT OUTER JOIN Works_On Wrk ON Wrk.Pno = Proj.Pnumber where  wrk.essn=:ssn) AS EmpProjects
	LEFT OUTER JOIN (Select Wrk.Pno, Count(Essn) AS numberofemps,Sum(Wrk.Hours)totalhours From Works_On As Wrk Group by Wrk.Pno) AS ProjGrp
	ON EmpProjects.Pnumber = ProjGrp.Pno;

	EXEC SQL OPEN C1;
	printf("\n\t\t\tProject Information\t\t\t\n");
	printf("\t\t\t--------------------\t\t\t\n");
	printf(" Pno\t\t ProjectName\t \t\tEmployee Name\t \tHours\t Number_of_emps_in_project\tTotal_Hours_on_Project\n");
	
	EXEC SQL WHENEVER NOT FOUND DO BREAK;
	while (SQLCODE == 0)
	{
	EXEC SQL FETCH FROM C1 INTO :pno,:pname,:mgrName,:hours :hour_ind, :numberofemps,:totalhours :totalHr_ind;
	printf(" %s%s\t\t%s\t\t%s\t\t%s\t\t\t\t%s\n",pno,pname,mgrName,hours ,numberofemps,totalhours);

	}
EXEC SQL CLOSE C1;
}


