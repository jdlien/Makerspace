<!--- YouKnowIAm identifies the currently authenticatd user on Staffweb --->
<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,block">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">
<cfparam name="form.RID" default="">
<!---<cfdump var="#form#">--->
<cfif isDefined('SubmitNew') AND len(trim(form.beginDate)) AND len(trim(form.endDate))>
	<!---Construct Start and End DateTimes from Multiple Fields--->
	<cfset StartTime = form.beginDate&" "&form.startTimeHour&":"&form.startTimeMinute>
	<cfset EndTime = form.endDate&" "&form.endTimeHour&":"&form.endTimeMinute>
	<cfif form.dow EQ 'continuous'><cfset continuous=1><cfelse><cfset continuous=0></cfif>
	
	<cfquery name="InsertBlockedTime" datasource="ReadWriteSource" dbtype="ODBC">
		INSERT INTO MakerspaceBlockedTimes (StartTime, EndTime, DayofWeek, Continuous, Description, ModifiedBy, Modified, OfficeCode)
		VALUES(
			'#StartTime#',
			'#EndTime#',
			<cfif isNumeric(trim(form.dow))>'#form.dow#'<cfelse>NULL</cfif>,
			'#continuous#',
			'#trim(form.description)#',
			'#YouKnowIAm#',
			GETDATE(),
			'#form.Branch#'
		)
		SELECT SCOPE_IDENTITY() AS BID
	</cfquery>
	
	<cfloop list="#form.RID#" index="ResourceID">
		<cfset TypeID=''>
		<cfif find('Type', ResourceID)>
			<cfset TypeID=Replace(ResourceID, 'Type', '', 'All')>
		</cfif>
		<cfquery name="InsertBlockedTimeResources" datasource="ReadWriteSource" dbtype="ODBC">
		INSERT INTO MakerspaceBlockedTimeResources (BID, RID, TypeID, ModifiedBy, Modified)
		VALUES(
			'#InsertBlockedTime.BID#',
			<cfif isNumeric(trim(ResourceID))>'#ResourceID#'<cfelse>NULL</cfif>,
			<cfif Len(TypeID)>'#TypeID#'<cfelse>NULL</cfif>,
			'#YouKnowIAm#',
			GETDATE()
		)
		</cfquery>
	</cfloop><!---list form.rid --->
</cfif><!---if form submitted to this page with required data--->
<cflocation addtoken="no" url="blockedtimes.cfm?branch=#form.branch#">