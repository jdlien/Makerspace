<cfsetting showdebugoutput="no" />
<!--- patronlookup.cfm - passed an id parameter which is an EPL card number.
	checks card validity and returns patron information via PatronInfo, which uses Symphony Web Services --->
<cfheader name="Content-Type" value="application/json" />
<cfobject component="PatronInfo" name="PatronInfo" />

<cfinclude template="#app.includes#/functions/queryToStruct.cfm" />

<cfif isDefined('form.id')><cfset url.id=form.id></cfif>
<!--- return an error if we didn't get a valid card number --->
<cfif NOT isDefined('url.id')>
	<cfset data.ERROR.MESSAGE="No card number specified">
	<cfoutput>#SerializeJSON(data)#</cfoutput>
	<cfabort />
</cfif>
<cfparam name="id" default="#url.id#" />
<cfset id=REReplace(id, '\s', '', 'All') />
<cfset data=PatronInfo.PatronInfo(id) />
<!--- Add certification info to this array --->
<cfset data.CERTIFICATIONS = ArrayNew(1) />

<cfquery name="PatronCertifications" dbtype="ODBC" datasource="SecureSource">
SELECT MC.MCID, MCCID, CertiName, CertiDesc, CustomerAllowed
 FROM vsd.MakerCerts MC LEFT OUTER JOIN
    (
     Select MCCID, LibraryCard, MCID, 'Yes' as CustomerAllowed
       from vsd.MakerCertsCustomers
      where UserKey = '#data.CUSTOMER.USERKEY#'
    ) MCC
  ON MCC.MCID = MC.MCID
where Shadowed != 'Yes'
Order by CertiName
</cfquery>

<cfquery name="MasterCourse" dbtype="ODBC" datasource="SecureSource">
	SELECT * FROM vsd.MakerCertsMainCourse
	WHERE UserKey = '#data.CUSTOMER.USERKEY#'
</cfquery>

<cfset data.Certifications = queryToStruct(Query=PatronCertifications, ForceArray=true) />
<cfif MasterCourse.RecordCount>
	<cfset data.MASTERCOURSE = true />
<cfelse>
	<cfset data.MASTERCOURSE = false />
</cfif>

<!--- Set special info on placeholder account --->
<cfif id IS "21221012345678">
	<cfset data.CUSTOMER.NAME="STAFF NOTES" />
	<cfset data.CUSTOMER.FIRST="STAFF" />
	<cfset data.CUSTOMER.LAST="NOTES" />
	<cfset data.CUSTOMER.FULLNAME="STAFF NOTES" />
	<!--- Remove this line after testing --->
	<!--- <cfset data.CUSTOMER.EMAIL="jlien@epl.ca" /> --->
</cfif>

<cfset data.CUSTOMER.CARDNUMBER = id />

<cfoutput>#SerializeJSON(data)#</cfoutput>
