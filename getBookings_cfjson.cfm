<cfsetting showdebugoutput="no">
<cfsetting enablecfoutputonly="yes">
<cfif isDefined('form.rid') AND form.rid NEQ "">
	<cfquery name="ResourceInfo" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM MakerSpaceBookingResources
	WHERE RID='#form.rid#'
	</cfquery>
</cfif>
<cfquery name="Bookings" datasource="ReadWriteSource" dbtype="ODBC">
	SELECT * from MakerSpaceBookingTimes t
	JOIN MakerSpaceBookingResources r ON t.RID=r.RID
	WHERE 1=1
	<cfif isDefined('form.rid') AND form.rid NEQ "">AND RID='#form.rid#'</cfif>
	<cfif isDefined('url.start')>AND StartTime > '#url.start#'</cfif>
</cfquery>
<cfset BookingsArr=ArrayNew(1)>
<cfloop query="Bookings">
	<cfset bookingsArr[CurrentRow]=StructNew()>
	<cfset bookingsArr[CurrentRow].id=RID>
	<cfset bookingsArr[CurrentRow].title=ResourceName>
	<cfset bookingsArr[CurrentRow].start=StartTime>
	<cfset bookingsArr[CurrentRow].end=EndTime>
</cfloop>
<cfset eventSources.events=bookingsArr>
<cfif isDefined('form.rid') AND form.rid NEQ "">
	<cfset eventSources.color=ResourceInfo.Color>
</cfif>
<cfset eventSources.textColor='black'>
<cfoutput>#SerializeJSON(bookingsArr)#</cfoutput>