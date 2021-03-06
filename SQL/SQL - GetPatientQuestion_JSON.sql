Create procedure [dbo].[GetPatientQuestions] 
@PatientID uniqueidentifier
as

declare @IsNewPatient bit
if exists(select * from patient where ID=@PatientID)
	set @IsNewPatient=0
else
	set @IsNewPatient=1

IF OBJECT_ID('tempdb..#TempCategory') IS NOT NULL
    DROP TABLE #Temp

IF OBJECT_ID('tempdb..#TempSections') IS NOT NULL
    DROP TABLE #Temp

Create table #TempCategory
(
tID uniqueidentifier,
TempID uniqueidentifier
)
insert into #TempCategory
select id,newid() as tempid from IntoqiCategory 

CREATE TABLE #TempSections
	(
		
		Displayorder int,
		Intoqicategory uniqueidentifier,
		Label nvarchar(300),
		Name nvarchar(300),
		SectionId uniqueidentifier,
		Showlabel bit,
		Visible bit,
		TempCategoryresponseid uniqueidentifier,
		TempSectionResponseID uniqueidentifier

	)
insert into  #TempSections
SELECT	Displayorder,Intoqicategory,Label,Name,SectionId,Showlabel ,Visible,null,NEWID() from section where  visible=1 order by displayorder 

update #TempSections set TempCategoryresponseid=tc.tempid from #TempSections ts join #TempCategory tc on ts.Intoqicategory=tc.tid

	SELECT 	Displayorder,Intoqicategory,Label,Name,SectionId   ,Showlabel ,	Visible,
	(
		SELECT s.SectionId as Section, q.Id As  [Questionid], qt.name as [Questiontype],q.QuestionLabel as [Name],  q.QuestionLabel as [QuestionLabel], 
		q.Parentquestion as [Parentquestion], q.Minnumber as [Minnumber] , q.Maxnumber as [Maxnumber], q.Ispriortestingrequired as [Ispriortestingrequired],
		q.Ispriorsurgeryrequired as [Ispriorsurgeryrequired],
		q.Ismedicationrequired as [Ismedicationrequired], trim(q.Globaloptionsetname) [Globaloptionsetname], q.Displayorder as [Displayorder], 
		(
			JSON_QUERY(dbo.fn_GetGlobalOptionSetsJSON (trim(q.Globaloptionsetname)))
		) as  [GlobalOptionSetValues],
		q.Combinewithnextquestion as [Combinewithnextquestion], q.Multiplicity as [Multiplicity],
		case @IsNewPatient when 0  then ISNULL(qr.id,NEWID()) else NewID() end as  Questionresponseid,	
		qr.Parentquestionresponse as [Parentquestionresponse], qr.Questionresponse as [Questionresponse],qr.Questionresponse as [OriginalQuestionResponse],
		qr.Patient as [Patient], 
		case @IsNewPatient when 0 then case when qr.Id is NULL Then 1	Else 0	End else 1 end as [IsNewQuestion],
		case @IsNewPatient when 0 then isnull(qr.Sectionresponse,s.TempSectionResponseID) else s.TempSectionResponseID end as [Sectionresponseid],
		case @IsNewPatient when 0 then isnull(sr.Categoryresponseid,s.TempCategoryresponseid) else s.TempCategoryresponseid end as  [Categoryresponseid],
		(
			SELECT s.SectionId as Section,q1.Id As  [Questionid], qt1.name as [Questiontype],q.QuestionLabel as [Name],  q1.QuestionLabel as [QuestionLabel], 
			q1.ParentQuestion as [Parentquestion], q1.Minnumber as [Minnumber] , q1.Maxnumber as [Maxnumber], q1.Ispriortestingrequired as [Ispriortestingrequired1],
			q1.Ispriorsurgeryrequired as [Ispriorsurgeryrequired],
			q1.Ismedicationrequired as [Ismedicationrequired], trim(q1.Globaloptionsetname) [Globaloptionsetname], q1.Displayorder as [Displayorder], 
			(
			JSON_QUERY(dbo.fn_GetGlobalOptionSetsJSON (trim(q1.Globaloptionsetname)))
			) as  [GlobalOptionSetValues],
			q1.Combinewithnextquestion as [Combinewithnextquestion], q1.Multiplicity as [Multiplicity],
			qr1.Parentquestionresponse as [Parentquestionresponse], qr1.Questionresponse as [Questionresponse],qr1.Questionresponse as [OriginalQuestionResponse],
			qr1.Patient as [Patient],
			case @IsNewPatient when 0 then case when qr1.Id is NULL Then 1 Else	0 End
			else 1 end as [IsNewQuestion],
			case @IsNewPatient when 0 then isnull(qr1.Sectionresponse,s.TempSectionResponseID ) else s.TempSectionResponseID end as [Sectionresponseid],
			case @IsNewPatient when 0 then ISNULL(qr1.Id,NEWID()) else NewID() end  as Questionresponseid,		
			case @IsNewPatient when 0 then isnull(sr1.Categoryresponseid,s.TempCategoryresponseid) else s.TempCategoryresponseid end  as [Categoryresponseid]
			From Question As q1
			Inner Join QuestionType As qt1 On q1.QuestionType = qt1.[Value] 
			Left Outer Join Questionresponse qr1 On q1.Id = qr1.Question 
			And (qr1.Patient = @PatientID)
			Left Outer Join Sectionresponse As sr1 On qr1.Sectionresponse = sr1.Id
			Where q1.multiplicity = 0 and q1.parentquestion=q.id
			Order By q1.Displayorder
			FOR JSON PATH ) as SubQuestions
			From Question As q
			Inner Join QuestionType As qt On q.QuestionType = qt.[Value] 
			Left Outer Join Questionresponse qr On q.Id = qr.Question 
			And (qr.Patient = @PatientID)
			Left Outer Join Sectionresponse As sr On qr.Sectionresponse = sr.Id
			Where (q.multiplicity =0) and q.parentQuestion is null and q.section=s.sectionid
			Order By q.Displayorder
			FOR JSON PATH )as Questions
			FROM   #TempSections s 	FOR JSON PATH 
			







