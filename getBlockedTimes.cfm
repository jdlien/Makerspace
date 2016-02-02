<cfsetting showdebugoutput="no">
<cfparam name="form.isStaff" default="true">
<cfparam name="form.hideOther" default="false">

<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
<cfelse>
	<cfinclude template="/AppsRoot/Includes/INTRealState.cfm">
	<cfset ThisLocation=RealStateBuilding/>
</cfif>

<!---
	Here we retrieve all blocked times as events. This can get complicated.
		-We only need to get times applicable to the current resource
			-This means that if a TypeID is set, and it applies to the given resource, we return the event
			-Most of the time, events will only apply to a certain day of the week.
--->
<cfif isDefined('url.rid') and url.rid NEQ ''><cfset form.rid=url.rid></cfif>
<cfif isDefined('form.rid') AND form.rid NEQ "">
	<cfquery name="ResourceInfo" datasource="SecureSource" dbtype="ODBC">
	SELECT * FROM MakerSpaceBookingResources
	WHERE RID='#form.rid#'
	</cfquery>
	<cfset resourceType=ResourceInfo.TypeID>
</cfif>
<!--- form.typeID is a list. Get the resources applicable to each typeid --->
<cfif isDefined('form.TypeID') AND len(form.TypeID) GT 0>
	<cfquery name="TypesResources" datasource="SecureSource" dbtype="ODBC">
		SELECT * FROM MakerspaceBookingResources
		WHERE
		<cfset i=0>
		<cfloop list="#form.TypeID#" index="TheType">
			<cfif i GT 0>OR </cfif>TypeID=#TheType#
			<cfset i++>
		</cfloop>
	</cfquery>
</cfif>
<cfparam name="form.id" default="">
<cfset form.id=REplace(form.id,' ', '', 'ALL')>

<!--- Retreive relevant blockedTimes - only show non-null RID/TypeID if relevant RID is passed --->
<cfquery name="BlockedTimes" datasource="SecureSource" dbtype="ODBC">
	SELECT t.BID, ISNULL(t.RID, btr.RID) AS RID, ISNULL(t.TypeID, btr.TypeID) AS TypeID, StartTime, EndTime,
	DayofWeek, Continuous, t.Description, t.OfficeCode, t.ModifiedBy,
	t.Modified, r.ResourceName, ty.TypeName
	FROM vsd.MakerspaceBlockedTimes t
	LEFT JOIN vsd.MakerspaceBlockedTimeResources btr on btr.BID=t.BID
	LEFT JOIN vsd.MakerspaceBookingResources r on t.RID=r.rid OR btr.RID=r.rid
	LEFT JOIN vsd.MakerspaceBookingResourceTypes ty on t.TypeID=ty.TypeID OR btr.TypeID=ty.TypeID
	WHERE t.OfficeCode='#ThisLocation#'
	<cfif isDefined('form.rid') AND form.rid NEQ "">
		AND ((t.RID='#form.rid#' OR btr.RID='#form.rid#')
		<cfif isDefined('resourceType') AND resourceType NEQ "">OR (t.TypeID='#ResourceType#' OR btr.TypeID='#ResourceType#')</cfif>)
		OR (t.RID IS NULL AND t.TypeID IS NULL AND btr.RID IS NULL AND btr.TypeID IS NULL AND t.OfficeCode='#ThisLocation#')
	</cfif>
	<cfif isDefined('form.TypeID') AND len(form.TypeID)>
		<!--- Retrieve blocked times applicable to TypesResources in this type, or the types themselves --->
		AND (
		<cfset i=0>
		<cfloop query="TypesResources">
			<cfif i GT 0>OR </cfif>btr.RID=#TypesResources.RID#
			<cfset i++>
		</cfloop>
		OR
		<cfset i=0>
		<cfloop list="#form.TypeID#" index="TheType">
			<cfif i GT 0>OR </cfif>btr.TypeID=#TheType#
			<cfset i++>
		</cfloop>
		OR (btr.TypeID IS NULL AND btr.RID IS NULL)
		)
	</cfif><!--- if TypeID is set --->
	<cfif isDefined('form.start')>AND t.EndTime > '#form.start#'</cfif>
	<cfif isDefined('form.end')>AND t.startTime < '#form.end#'</cfif>
</cfquery>
<!--- I wanted coldfusion to generate JSON from an structure, but it wasn't working very well --->
	[
<cfset counter=0>
<cfoutput query="BlockedTimes">
	<cfset tDesc=trim(Description) />
	<!--- Generate event for continuous blocked time (this is the simplest to do) --->
	<cfif Continuous IS 1>
		<cfif counter++ GT 0>,</cfif>
		{
		"title":"#tDesc#",
		"start":"#StartTime#",
		"end":"#EndTime#",
		"description":"<cfif len(ResourceName)>#ResourceName#<cfelseif len(TypeName)>#TypeName#</cfif> Unavailable: #tDesc#",
		"className":"blockedTime<cfif len(TypeName)> type#TypeID#<cfelseif len(ResourceName)> Res#RID#</cfif>",
		"color":"##000000"
		}
	<cfelse>
	<!--- Here I loop through each day in the blockedtimes's date range
	and generate an event for the time span if it's the correct day of the week --->
		<!--- I should only loop until the end date of the specified range--->
		<cfloop from="#StartTime#" to="#form.end#" index="i">
			<!--- Date of our iteration in the loop is a date this event falls on
			AND	this instance of a blocked time is within the displayed date range of our calendar--->
			<cfif (DayOfWeek(i)-1 IS DayofWeek OR DayofWeek IS "")
			AND (DateCompare(CreateDate(Year(i),Month(i),Day(i)), CreateDate(Year(endTime),Month(endTime),Day(endTime))) LTE 0)
			AND (DateCompare(CreateDate(Year(i),Month(i),Day(i)), CreateDate(Year(form.end),Month(form.end),Day(form.end))) LTE 0)
			AND (DateCompare(CreateDate(Year(i),Month(i),Day(i)), CreateDate(Year(form.start),Month(form.start),Day(form.start))) GTE 0)>
				<!--- don't add comma on first entry --->
				<cfif counter++ GT 0>,</cfif>
				{
					"title":"#tDesc#",
					"start":"#DateFormat(i, "YYYY-MM-DD")# #TimeFormat(StartTime, "HH:mm:00.0")#",
					"end":"#DateFormat(i, "YYYY-MM-DD")# #TimeFormat(EndTime, "HH:mm:00.0")#",
					"description":"<cfif len(ResourceName)>#ResourceName#<cfelseif len(TypeName)>#TypeName#</cfif> Unavailable: #tDesc#",
					"className":"blockedTime<cfif len(TypeName)> type#TypeID#<cfelseif len(ResourceName)> Res#RID#<cfelse> All</cfif>",
					"color":"##000000"
				}
			</cfif>
		</cfloop>
	</cfif><!---if Continuous--->
</cfoutput>
	]