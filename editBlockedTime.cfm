<cfsetting showdebugoutput="no">
<cfsetting enablecfoutputonly="yes">
<cfinclude template="/AppsRoot/Includes/INTYouKnowVariables.cfm">
<cfset app.id="MakerspaceBooking">
<cfset app.permissionsRequired="view,block">
<cfinclude template="/AppsRoot/Includes/PermissionsInclude.cfm">

<!--- Changes click-to-edit Start Time --->
<cfif isDefined('form.NewStartHour')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="original" dbtype="ODBC" datasource="SecureSource">
		SELECT StartTime FROM MakerspaceBlockedTimes
		WHERE BID=#form.id#
	</cfquery>
	<cfset newStartTime=DateFormat(original.StartTime, "YYYY-MMM-DD")&" "&form.NewStartHour&":"&TimeFormat(original.StartTime, "mm")>
	<cfquery name="UpdateStartDate" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes SET StartTime='#newStartTime#', ModifiedBy='#YouKnowIAm#', Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfoutput>#TimeFormat(newStartTime, "HH")#</cfoutput>
</cfif>

<cfif isDefined('form.NewStartMinute')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="original" dbtype="ODBC" datasource="SecureSource">
		SELECT StartTime FROM MakerspaceBlockedTimes
		WHERE BID=#form.id#
	</cfquery>
	<cfset newStartTime=DateFormat(original.StartTime, "YYYY-MMM-DD")&" "&TimeFormat(original.StartTime, "HH")&":"&form.newStartMinute>
	<cfquery name="UpdateStartDate" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes SET StartTime='#newStartTime#', ModifiedBy='#YouKnowIAm#', Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfoutput>#TimeFormat(newStartTime, "mm")#</cfoutput>
</cfif>

<!--- Changes click-to-edit End Time --->
<cfif isDefined('form.NewEndHour')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="original" dbtype="ODBC" datasource="SecureSource">
		SELECT EndTime FROM MakerspaceBlockedTimes
		WHERE BID=#form.id#
	</cfquery>
	<cfset newEndTime=DateFormat(original.EndTime, "YYYY-MMM-DD")&" "&form.NewEndHour&":"&TimeFormat(original.EndTime, "mm")>
	<cfquery name="UpdateEndDate" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes SET EndTime='#newEndTime#', ModifiedBy='#YouKnowIAm#', Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfoutput>#TimeFormat(newEndTime, "HH")#</cfoutput>
</cfif>

<cfif isDefined('form.NewEndMinute')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="original" dbtype="ODBC" datasource="SecureSource">
		SELECT EndTime FROM MakerspaceBlockedTimes
		WHERE BID=#form.id#
	</cfquery>
	<cfset newEndTime=DateFormat(original.EndTime, "YYYY-MMM-DD")&" "&TimeFormat(original.EndTime, "HH")&":"&form.newEndMinute>
	<cfquery name="UpdateEndDate" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes SET EndTime='#newEndTime#', ModifiedBy='#YouKnowIAm#', Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfoutput>#TimeFormat(newEndTime, "mm")#</cfoutput>
</cfif>


<!--- Changes click-to-edit Begin Date --->
<cfif isDefined('form.NewStartDate')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="originalStartTime" dbtype="ODBC" datasource="SecureSource">
		SELECT StartTime FROM MakerspaceBlockedTimes
		WHERE BID=#form.id#
	</cfquery>
	<cfset newStartTime=form.newStartDate&" "&TimeFormat(originalStartTime.StartTime, "HH:mm")>
	<cfquery name="UpdateStartDate" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes SET StartTime='#newStartTime#', ModifiedBy='#YouKnowIAm#', Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfoutput>#dateformat(newStartTime, "YYYY-MMM-DD")#</cfoutput>
</cfif>

<!--- Changes click-to-edit End Date --->
<cfif isDefined('form.NewEndDate')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="originalEndTime" dbtype="ODBC" datasource="SecureSource">
		SELECT EndTime FROM MakerspaceBlockedTimes
		WHERE BID=#form.id#
	</cfquery>
	<cfset newEndTime=form.newEndDate&" "&TimeFormat(originalEndTime.EndTime, "HH:mm")>
	<cfquery name="UpdateEndDate" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes SET EndTime='#newEndTime#', ModifiedBy='#YouKnowIAm#', Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfoutput>#dateformat(newEndTime, "YYYY-MMM-DD")#</cfoutput>
</cfif>


<!--- Changes click-to-edit Day of Week --->
<cfif isDefined('form.NewDoW')>
	<cfif form.NewDoW EQ 'continuous'><cfset continuous=1><cfelse><cfset continuous=0></cfif>
	<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateName" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes
		SET DayofWeek=<cfif isNumeric(form.newDoW)>'#form.newDoW#'<cfelse>NULL</cfif>,
			Continuous=#Continuous#,
			ModifiedBy='#YouKnowIAm#',
			Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfif form.NewDoW IS "daily" AND Continuous NEQ 1>
		<cfset DayOfWeekDesc="Every Day">
	<cfelseif Continuous EQ 1>
		<cfset DayOfWeekDesc="Continuous">
		<cfset DowValue="continuous">
	<cfelseif isNumeric(form.NewDoW)>
		<cfset DayOfWeekDesc=DayOfWeekAsString(form.NewDoW+1)>
	</cfif>	
	<cfoutput>#DayOfWeekDesc#</cfoutput>
</cfif>

<!--- Changes click-to-edit Resource. Now allowing multiple resources --->
<cftry>
<cfif isDefined("form.NewRID[]")>
	<cfset form.NewRID=form['NewRID[]']>
	<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<!--- Clear the old Resources from before --->
	<cfquery name="ClearRIDTypes" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes
		SET RID=NULL,
			TypeID=NULL,
			ModifiedBy='#YouKnowIAm#',
			Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfquery name="ClearBlockedTimeResources" dbtype="ODBC" datasource="ReadWriteSource">
		DELETE FROM MakerspaceBlockedTimeResources WHERE BID=#form.id#
	</cfquery>
	
	<!--- Now loop through and add all the new ones --->
	<cfif ListLen(form.NewRID)>
		<cfset ResourceDesc="">
		<cfset counter=0>
		<cfloop list="#form.NewRID#" index="ResourceID">
			<cfif counter><cfset ResourceDesc&=', '></cfif>
			<cfset ResourceID=Replace(ResourceID, 'z', '')>
			<cfset TypeID=''>
			<cfif find('Type', ResourceID)>
				<cfset TypeID=Replace(ResourceID, 'Type', '', 'All')>
				<cfquery name="ResourceType" dbtype="ODBC" datasource="SecureSource">
					SELECT TypeName FROM MakerspaceBookingResourceTypes Where TypeID=#TypeID#
				</cfquery>
				<cfset ResourceDesc&=ResourceType.TypeName>
			<cfelseif isNumeric(trim(ResourceID))>
				<cfquery name="Resource" dbtype="ODBC" datasource="SecureSource">
					SELECT ResourceName FROM MakerspaceBookingResources Where RID=#ResourceID#
				</cfquery>
				<cfset ResourceDesc&=Resource.ResourceName>
			</cfif>
			<!--- Only insert an entry if there's something to be inserted ---> 
			<cfif isNumeric(trim(ResourceID)) OR isDefined('TypeID')>
				<cfquery name="UpdateBlockedTimeResources" dbtype="ODBC" datasource="ReadWriteSource">
					INSERT INTO vsd.vsd.MakerspaceBlockedTimeResources (BID, RID, TypeID, ModifiedBy, Modified)
					VALUES (#form.id#,
						<cfif isNumeric(trim(ResourceID))>'#ResourceID#'<cfelse>NULL</cfif>,
						<cfif len(TypeID)>'#TypeID#'<cfelse>NULL</cfif>,
						'#YouKnowIAm#',
						GETDATE()
					)
				</cfquery>
			</cfif>
			<cfset counter++>
		</cfloop><!--- list form.NewRID --->		
	</cfif>
	<cfif ResourceDesc EQ ""><cfset ResourceDesc="All Resources"></cfif>
	<cfoutput>#ResourceDesc#</cfoutput>
</cfif>
<cfcatch></cfcatch>
</cftry>

<!--- Changes click-to-edit Description --->
<cfif isDefined('form.NewDesc')>
<cfset form.id = REReplace(form.id, "\D+(\d+)", "\1")>
	<cfquery name="UpdateDescription" dbtype="ODBC" datasource="ReadWriteSource">
		UPDATE vsd.vsd.MakerspaceBlockedTimes SET Description='#trim(form.NewDesc)#', ModifiedBy='#YouKnowIAm#', Modified=GETDATE()
		WHERE BID=#form.id#
	</cfquery>
	<cfoutput>#trim(form.NewDesc)#</cfoutput>
</cfif>