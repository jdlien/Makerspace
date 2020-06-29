<!--- This just checks the sequence number for a given branch. --->
<cfsetting showdebugoutput="false" />
<cfsetting enablecfoutputonly="true" />
<cfif isDefined('url.branch')>
	<cfset ThisLocation=url.branch />
<cfelse>
	<cfinclude template="#app.includes#/appsInit.cfm" />
	<cfparam name="ThisLocation" default="#RealStateBuilding#" />
</cfif>

<cfquery name="Update" dbtype="ODBC" datasource="SecureSource">
	SELECT Seq FROM vsd.MakerspaceUpdates WHERE OfficeCode='#ThisLocation#'
</cfquery>

<cfoutput>#Update.Seq#</cfoutput>