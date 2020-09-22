<!--- Updates the database when a makerspace resource is changed with resourceDetails.cfm --->

<cfset app.id="MakerspaceBooking" />
<cfset app.permissionsRequired="view,reso" />
<cfinclude template="#app.includes#/appsPermissions.cfm" />

<!--- <cfdump var="#form#"> --->

<!--- Simple Server-side validation --->
<cfif isDefined('form.resourcename') AND len(form.resourcename) AND isDefined('form.typeid') AND isNumeric(form.typeid)>

	<!--- Get Type Info	--->
	<cfquery name="typeInfo" dbtype="ODBC" datasource="SecureSource">
		SELECT * FROM vsd.MakerspaceBookingResourceTypes WHERE TypeID = #form.typeid#
	</cfquery>

	<cfif typeInfo.RecordCount EQ 0>
		<span class="error">Type <cfoutput>#form.typeID#</cfoutput> does not exist.</span>
		<cfabort />
	</cfif>
	
	<!--- If there's an RID, update an existing resource --->
	<cfif isDefined('form.rid') AND isNumeric(form.rid)>
	
		<!--- Check that it really exists --->
		<cfquery name="ResourceInfo" dbtype="ODBC" datasource="SecureSource">
			SELECT * FROM vsd.MakerspaceBookingResources WHERE RID = #form.rid#
		</cfquery>

		<cfif ResourceInfo.RecordCount EQ 0>
			<span class="error">Resource <cfoutput>#form.rid#</cfoutput> does not exist.</span>
			<cfabort />
		</cfif>

		<!--- Update DB --->
		<cfquery name="updateResource" dbtype="ODBC" datasource="ReadWriteSource">
			UPDATE vsd.MakerspaceBookingResources SET
			ResourceName = '#form.ResourceName#',
			Description = '#form.Description#',
			Color = '#form.color#',
			TypeID = #form.typeID#,
			AllowBlocked = <cfif isDefined('form.AllowBlocked')>1<cfelse>0</cfif>,
			Concurrent = <cfif isDefined('form.Concurrent')>1<cfelse>0</cfif>,
			WeekdaymaxBookings = <cfif isNumeric(form.WeekdayMaxBookings)>#form.WeekdayMaxBookings#<cfelse>NULL</cfif>,
			WeekendmaxBookings = <cfif isNumeric(form.WeekendMaxBookings)>#form.WeekendMaxBookings#<cfelse>NULL</cfif>,
			FutureMaxBookings = <cfif isNumeric(form.FutureMaxBookings)>#form.FutureMaxBookings#<cfelse>NULL</cfif>,
			RequireCerts = <cfif isDefined('form.requireCerts')>1<cfelse>0</cfif>,
			ModifiedBy = '#session.identity#',
			Modified = GETDATE()
			WHERE RID=#form.rid#
		</cfquery>

	<!--- Else insert a new record --->
	<cfelse>

		<cfquery name="insertResource" dbtype="ODBC" datasource="ReadWriteSource">
			INSERT INTO vsd.MakerspaceBookingResources (ResourceName, Description, Color, MaxUsers, TypeID,
				AllowBlocked, Concurrent, WeekdayMaxBookings, WeekendMaxBookings, FutureMaxBookings, RequireCerts, ModifiedBy, Modified) VALUES(
			'#form.ResourceName#',
			'#form.Description#',
			'#form.color#',
			1,
			#form.typeID#,
			<cfif isDefined('form.AllowBlocked')>1<cfelse>0</cfif>,
			<cfif isDefined('form.Concurrent')>1<cfelse>0</cfif>,
			<cfif isNumeric(form.WeekdayMaxBookings)>#form.WeekdayMaxBookings#<cfelse>NULL</cfif>,
			<cfif isNumeric(form.WeekendMaxBookings)>#form.WeekendMaxBookings#<cfelse>NULL</cfif>,
			<cfif isNumeric(form.FutureMaxBookings)>#form.FutureMaxBookings#<cfelse>NULL</cfif>,
			<cfif isDefined('form.requireCerts')>1<cfelse>0</cfif>,
			'#session.identity#',
			GETDATE()							
			)
			SELECT SCOPE_IDENTITY() AS RID
		</cfquery>

		<cfset form.rid = insertResource.RID />

	</cfif>

	<cfset counter = 0 />
	<!--- Re-insert certifications for this resource --->
	<cfquery name="delInsertCerts" dbtype="ODBC" datasource="ReadWriteSource">
		DELETE FROM vsd.MakerspaceBookingResourcesCerts WHERE RID=#form.rid#
		<cfif isDefined('form.certs')>
			INSERT INTO vsd.MakerspaceBookingResourcesCerts (RID, MCID, ModifiedBy, Modified) VALUES

			<cfloop list="#form.certs#" index="certid"><cfif counter++ GT 0>,</cfif>
			(#form.rid#, #certid#, '#session.identity#', GETDATE())
			</cfloop>
		</cfif>
	</cfquery>

	<!--- Relocate to resources.cfm --->
	<cflocation addtoken="false" url="resources.cfm?branch=#TypeInfo.OfficeCode#" />

<cfelse>
	<span class="error">Something was wrong with your submission. Resourcename or typeid is not defined.</span>
</cfif>