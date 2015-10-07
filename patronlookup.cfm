<cfsetting showdebugoutput="no">
<!--- patronlookup.cfm - passed an id parameter which is an EPL card number.
	checks card validity and returns patron information via Symphony Web Services --->
<cfif isDefined('form.id')><cfset url.id=form.id></cfif>
<!--- return an error if we didn't get a valid card number --->
<cfif NOT isDefined('url.id')>
	<cfset data.error.message="No card number specified">
	<cfoutput>#SerializeJSON(data)#</cfoutput>
	<cfabort>
</cfif>
<cfparam name="id" default="#url.id#">
<!---Remove any whitespace from entered numbers--->
<cfset id=REReplace(id, '\s', '', 'All')>
<cfif len(id) LT 10>
	<cfif len(id) EQ 0>
		<cfset data.error.message="No card number entered">
	<cfelse>
		<cfset data.error.message="Card number is too short (#len(id)# entered)">
	</cfif>
	<cfoutput>#SerializeJSON(data)#</cfoutput>
	<cfabort>
</cfif>

<cfhttp url="http://web4.epl.ca:8080/symws/rest/security/loginUser?clientID=VSD&login=WEBSERVICE&password=REGONLINE">

<cftry>
	<cfset sessionXML = XMLParse(cfhttp.fileContent)>
	<cfif isDefined('sessionXML.LoginUserResponse')>
		<cfset sessionToken = sessionXML.LoginUserResponse.sessionToken.XmlText>
	<cfelse>
	There is a currently problem with Symphony Web Services.
	<!---<cfdump var="#sessionXML#">--->
	<cfabort>
	</cfif>

	<!---Basic Patron Info - name, birthday, Status, Address --->
	<cfhttp url="http://web4.epl.ca:8080/symws/rest/patron/lookupPatronInfo?clientID=VSD&sessionToken=#sessionToken#&userID=#id#&includePatronInfo=true&includePatronStatusInfo=true&includePatronAddressInfo=true">


	
	<cfset CustomerInfo = XMLParse(cfhttp.fileContent)>
	<cfif isDefined('url.debug')>
		<cfdump var="#CustomerInfo#">
	</cfif><!---debug--->
	<!--- If we are given an error by Symphony --->
	<cfif isDefined('CustomerInfo.Fault')>
	<cfset error.nouser="Error: "&CustomerInfo.Fault.string.xmlText>

	<!--- Otherwise proceed as if everything's peachy --->
	<cfelse>
		<!--- Set special info on placeholder account --->
		<cfif id IS "21221012345678">
			<cfset Customer.Name="PLACEHOLDER, EXEMPT">
			<cfset Customer.First="EXEMPT">
			<cfset Customer.Last="PLACEHOLDER">
			<cfset Customer.FullName="EXEMPT PLACEHOLDER">	
		<cfelse>
			<cfset Customer.Name=CustomerInfo.LookupPatronInfoResponse.patronInfo.displayName.XmlText>
			<cfset Customer.First=REReplace(Customer.Name, '.*, (.*)', '\1')>
			<cfset Customer.Last=REReplace(Customer.Name, '(.*), .*', '\1')>
			<cfset Customer.FullName=Customer.First&' '&Customer.Last>
		</cfif>
		<cfset Customer.Dept=CustomerInfo.LookupPatronInfoResponse.patronInfo.department.XmlText>
		<!--- I don't really need email, so I'm commenting it out for now as I don't want it accessible to the browser
		<cfset Customer.EMail=CustomerInfo.LookupPatronInfoResponse.patronAddressInfo.Address1Info[5].addressValue.XmlText> --->
		<cfset Customer.Status=CustomerInfo.LookupPatronInfoResponse.patronStatusInfo.statusType.XMLText>
		<!---Ensure Status is acceptable (OK or DELINQUENT)--->
		<cfif Customer.Status IS NOT 'OK' AND Customer.Status IS NOT 'DELINQUENT' AND Customer.Status IS NOT 'BLOCKED'>
			<cfset error.status='Status is '&Customer.Status>
		</cfif>
		<!---Ensure card is not expired --->
		<cfif isDefined('CustomerInfo.LookupPatronInfoResponse.patronStatusInfo.datePrivilegeExpires.XMLText')>
			<cfset Customer.Expiry=CustomerInfo.LookupPatronInfoResponse.patronStatusInfo.datePrivilegeExpires.XMLText>
		<!---<cfelse>
			 if we NEED an expiry, make one up <cfset Customer.Expiry='1914-01-01'>--->		
			<cfif DateCompare(Customer.Expiry, Now()) LT 1>
				<cfset error.expiry='This card expired '&Customer.Expiry>
			</cfif>
		</cfif><!---if expiry defined--->
		<!---Ensure card is not LOST --->
		<cfif Customer.Dept EQ "LOST">
			<cfset error.lost='This card has been flagged as lost'>
		</cfif>
		<cfset data.customer=customer>
	</cfif><!---no symphony error--->

	<!--- add our error to the structure if there are any --->
	<cfif isDefined('error')>
		<cfset error.message="<b>This card can't use this service at this time:</b>">
		<cfset data.error=error>
	</cfif>
	<!--- Output JSON data that our javascript will use --->
	<cfoutput>#SerializeJSON(data)#</cfoutput>

	<cfcatch>
			<cfset data.error.message="There was an error retreiving customer information.">
		<cfoutput>#SerializeJSON(data)#</cfoutput>
	</cfcatch>
</cftry>
