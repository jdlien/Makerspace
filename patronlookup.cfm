<cfsetting showdebugoutput="no" />
<!--- patronlookup.cfm - passed an id parameter which is an EPL card number.
	checks card validity and returns patron information via PatronInfo, which uses Symphony Web Services --->
<cfheader name="Content-Type" value="application/json" />
<cfobject component="PatronInfo" name="PatronInfo" />

<cfif isDefined('form.id')><cfset url.id=form.id></cfif>
<!--- return an error if we didn't get a valid card number --->
<cfif NOT isDefined('url.id')>
	<cfset data.error.message="No card number specified">
	<cfoutput>#SerializeJSON(data)#</cfoutput>
	<cfabort />
</cfif>
<cfparam name="id" default="#url.id#" />
<cfset id=REReplace(id, '\s', '', 'All') />
<cfset data=PatronInfo.PatronInfo(id) />
<!--- Set special info on placeholder account --->
<cfif id IS "21221012345678">
	<cfset data.Customer.Name="STAFF NOTES" />
	<cfset data.Customer.First="STAFF" />
	<cfset data.Customer.Last="NOTES" />
	<cfset data.Customer.FullName="STAFF NOTES" />
	<!--- Remove this line after testing --->
	<!--- <cfset data.Customer.Email="jlien@epl.ca" /> --->
</cfif>
<cfoutput>#SerializeJSON(data)#</cfoutput>
