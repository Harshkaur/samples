CREATE PROCEDURE [dbo].[GetPatientListingSearch] 
@PatientType int,
@SystemUser uniqueIdentifier=null,
@Active int =1,
@CaregiverID uniqueIdentifier=null ,
@SearchString varchar(250)=null,
@SortColumn varchar(100) ='Name',
@SortOrder varchar(10) = 'asc',
@PageNumber INT =1,
@PageSize INT =10
AS

-- 1 means - Priority patients
-- 2 means - New patients
-- 3 means - Engaged
-- 4 means - All patients
-- 5 means - Escalated
-- 6 means - Complication
-- 7 means - Future Discharge

IF OBJECT_ID('tempdb..#Temp') IS NOT NULL
    DROP TABLE #Temp
IF OBJECT_ID('tempdb..#tempnotecount') IS NOT NULL
    DROP TABLE #tempnotecount
IF OBJECT_ID('tempdb..#tempAppointmentCount') IS NOT NULL
    DROP TABLE #tempAppointmentCount
IF OBJECT_ID('tempdb..#TempEngagment') IS NOT NULL
    DROP TABLE #TempEngagment
	IF OBJECT_ID('tempdb..#TempLastResult') IS NOT NULL
    DROP TABLE #TempLastResult

---------------------------------------
Create table #Temp
(
ID uniqueidentifier,
Fullname nvarchar(255),
Status int,
EF int,
LivingSituation nvarchar(255),
DischargeDate INT,
CareGiver nvarchar(255),
Weightinpounds decimal,
Responseweight decimal,
creatinine int,
potassium int,
Note int,
Appointment int,
--Engageged int
Engagement decimal(3,2),
diagnosis nvarchar(255),
AssignToName nvarchar(255),
RowNumber Int identity(1,1),
Escalated int,
Complication int
)


insert into #Temp
(

ID ,
Fullname ,
Status ,
EF,LivingSituation ,
DischargeDate ,
CareGiver ,
Weightinpounds ,
Responseweight,
creatinine ,
potassium,
Note,
Appointment,
--Engageged int
Engagement,
diagnosis,
AssignToName
)
select  DISTINCT   P.ID,PT.FullName,P.Status,P.EF,LS.name as LivingSituation,DATEDIFF(d,DateofProcedure,getdate()) as DischargeDate,
CG.Fullname CareGiver,
P.Weightinpounds,
P.Responseweight,
P.creatinine,
P.potassium,
0,
0,
0,
p.diagnosis,
su.fullname
	
from patient p
left join
LivingSituation LS on p.Livingsituation=LS.value 
left join
Note N on P.ID=N.PatientID
left join
Contact CG on P.Caregiver=CG.ID
join
Contact PT on P.Primarycontactid=PT.ID
left join
systemuser su on su.id=p.assignto
WHERE
((@active=-1 and 1=1)
or
(@active=1 and p.active=1)
or
(@active=0 and p.active=0)
)
--p.active=@active
and 
 (( @PatientType = 2 and P.CareGiver is null)
or (@PatientType=1 and P.Status=881810002)
or (@PatientType=7 and CONVERT(date,p.Dateofprocedure)>CONVERT(date,getdate()))
or ((@PatientType=3 or @PatientType=4 or @PatientType=5 or @PatientType=6)  and 1=1) 
)

and 
(
(@CaregiverID is null and 1=1)
or
(@CaregiverID is not null and p.CareGiver=@CaregiverID
)
)
and 
(
(@CaregiverID is null and 1=1)
or
(@CaregiverID is not null and p.CareGiver=@CaregiverID
)
)

and
(
(@SearchString is null and 1=1)
or
( @SearchString is not null and PT.email like '%'+@SearchString+'%' )
or
(@SearchString is not null and PT.Fullname like '%'+@SearchString+'%')
or
(@SearchString is not null and p.diagnosis like '%'+@SearchString+'%')
or
(@SearchString is not null and CG.Fullname like '%'+@SearchString+'%')
)

-----------------------------------------------------------------
create table #tempEscalatedCount (
patientID uniqueidentifier,
count int
)
insert into #tempEscalatedCount 
select pa.patientid,count(*) as c from patientalert pa 
join #Temp p on pa.patientid=p.id
where alertstatus<>83181001  group by patientid

update a set a.Escalated=b.count 
from #Temp a 
left outer join #tempEscalatedCount b on b.patientid=a.ID 

------------------------------------------------

create table #tempComplicationCount (
patientID uniqueidentifier,
count int
)
insert into #tempComplicationCount 
select p.id,count(1) as c
from questionresponse qr
join question q on q.id=qr.question 
join #Temp p on p.id=qr.patient
where 
--patient=@PatientID and 
q.Multiplicity=0 and q.section='9908765B-FBC8-E611-80F5-C4346BAC6B34' and q.parentquestion is null and qr.Questionresponse='True'
and q.questiontype=881810002 
group by p.id having count(qr.id)>2

update a set a.Complication=b.count 
from #Temp a 
left outer join #tempComplicationCount b on b.patientid=a.ID


------------------------------------------------


create table #tempNoteCount (
patientID uniqueidentifier,
count int
)
Insert into #tempNoteCount
select  N.patientid,count(N.id)
from 
Note N
left join
#Temp T
on N.patientID=T.ID
where N.status<>881810001
group by patientid

update a set a.note=b.count 
from #Temp a 
left outer join #tempNoteCount b on b.patientid=a.ID 
----------------------------------------------------
create table #tempAppointmentCount(
patientID uniqueidentifier,
count int
)

Insert into #tempAppointmentCount
select  A.patientid,count(A.id)
from 
appointment A
left join
#Temp T
on A.patientID=T.ID
where starttime>=getdate() and A.status<>88111001
group by patientid


update a set a.appointment=b.count 
from #Temp a 
left outer join #tempAppointmentCount b on b.patientid=a.ID 
------------------------------------------------------
Create table #TempEngagement
(
PatientID uniqueidentifier,
--Engageged int
Engagement decimal(3,2)
)

insert into #TempEngagement
select patientid,
--avg(datediff(Minute,rm.createdon,rm.receiveddatetime)) 
avg(
CASE 
     WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) < 10 THEN 1
     WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=10 and  datediff(Minute,rm.createdon,rm.receiveddatetime)< 60 THEN .9
     WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=60 and  datediff(Minute,rm.createdon,rm.receiveddatetime)< 120 THEN .8
	 WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=120 and datediff(Minute,rm.createdon,rm.receiveddatetime)< 180 THEN .7
	 WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=180 and datediff(Minute,rm.createdon,rm.receiveddatetime)< 240 THEN .6
	 WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=240 and datediff(Minute,rm.createdon,rm.receiveddatetime)< 300 THEN .5
     WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=300 and datediff(Minute,rm.createdon,rm.receiveddatetime)< 360 THEN .4
	 WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=360 and datediff(Minute,rm.createdon,rm.receiveddatetime)< 420 THEN .3
	 WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=420 and datediff(Minute,rm.createdon,rm.receiveddatetime)< 480 THEN .2
	 WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=480 and datediff(Minute,rm.createdon,rm.receiveddatetime)< 540 THEN .1
     WHEN datediff(Minute,rm.createdon,rm.receiveddatetime) >=540 THEN 0
END
)	

 from receivedmessages rm
left join Patient p on rm.patientid=p.id
where rm.patientid is not null
group by rm.patientid



update a set a.Engagement=b.Engagement 
from #Temp a 
left outer join #TempEngagement b on b.patientid=a.ID 

Declare @StartIndex int=1 , @EndIndex int =1
set @StartIndex = (((@PageNumber -1)*@PageSize)+1)
set @EndIndex= @PageNumber*@PageSize
-------------------------------------------------------------------------------
select ID ,
Fullname ,
[Status] ,
EF ,
LivingSituation ,
DischargeDate ,
CareGiver ,
Weightinpounds ,
Responseweight ,
creatinine ,
potassium ,
Note ,
Appointment ,
Engagement ,
diagnosis,
AssignToName,
Row_NUmber() OVER  (Order By  CASE WHEN @SortOrder = 'asc' THEN
      CASE @SortColumn 
         WHEN 'Name'   THEN FullName
        WHEN 'AssignToName' THEN AssignToName 
		WHEN 'CareGiver' THEN CareGiver 
	    END
    END,
    CASE WHEN @SortOrder = 'desc' THEN
      CASE @SortColumn 
        WHEN 'Name'   THEN FullName
        WHEN 'AssignToName' THEN AssignToName 
		WHEN 'CareGiver' THEN CareGiver 
	   END
    END DESC) AS RowNumber
Into #TempLastResult
from #Temp
where (@PatientType=3 and Engagement>=0 and Engagement is not null)
or(@PatientType=1 or @PatientType=2 or @PatientType=4 or @PatientType=7)
or (@PatientType=5 and Escalated>0 )
or (@PatientType=6 and Complication>0)

select 
ID ,
Fullname ,
[Status] ,
EF ,
LivingSituation ,
DischargeDate ,
CareGiver ,
Weightinpounds ,
Responseweight ,
creatinine ,
potassium ,
Note ,
Appointment ,
Engagement ,
diagnosis,
AssignToName
 from #TempLastResult
 where
 -- (@PatientType=3 and Engagement>=0 and Engagement is not null)
--or(@PatientType=1 or @PatientType=2 or @PatientType=4)
--and 
RowNumber between @StartIndex and @EndIndex
ORDER BY
CASE WHEN @SortOrder = 'asc' THEN
      CASE @SortColumn 
        WHEN 'Name'   THEN FullName
        WHEN 'AssignToName' THEN AssignToName 
		WHEN 'CareGiver' THEN CareGiver 
		
      END
    END
    CASE WHEN @SortOrder = 'desc' THEN
      CASE @SortColumn 
        WHEN 'Name'   THEN FullName
        WHEN 'AssignToName' THEN AssignToName 
		WHEN 'CareGiver' THEN CareGiver 
      END
    END DESC

	select Count(1) From #TempLastResult AS TotalRecords




GO


