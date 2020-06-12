<cfscript>
cfheader(name="Content-Type", value="application/json");
cfsetting(showDebugOutput="false", enableCFoutputOnly="true");
app.id="Makerspace";
include "#appsIncludes#/appsPermissions.cfm";
data = StructNew();
data.message = '';
data.error=false;

if (!isDefined('url.branch')) {
	data.error = true;
	data.message='No branch specified.';
	writeOutput(SerializeJSON(data));
	abort;
}


resources = new Query(datasource="SecureSource", dbtype="ODBC", sql="
	SELECT r.RID, ResourceName, Description, Color, ty.TypeID, TypeName FROM vsd.MakerspaceBookingResources r
	JOIN vsd.MakerspaceBookingResourceTypes ty ON r.TypeID=ty.TypeID
	WHERE OfficeCode='#url.branch#'
	--AND ty.TypeID=80 --Only gaming just to test
	ORDER BY TypeID, ResourceName
").execute().getResult();

resourcesArray = ArrayNew(1);
childrenArray = ArrayNew(1);

lastTypeID = "";
for (r in resources) {
	// start a new children array
	if (r.TypeID!=lastTypeID) {
		if (len(lastTypeID)) {
			type.children=childrenArray;
			ArrayAppend(resourcesArray, type);
			childrenArray = ArrayNew(1);
		}
		type = StructNew();
		type.id = r.TypeID;
		type.title = r.TypeName;
	}
	child = StructNew();
	child.id=r.RID;
	child.title=r.ResourceName;
	child.eventColor=r.Color;
	ArrayAppend(childrenArray, child);
	lastTypeID = r.typeID;
}
// Add the last item
if (len(lastTypeID) && isDefined('type')) {
	type.children=childrenArray;
	ArrayAppend(resourcesArray, type);
}


writeOutput(SerializeJSON(resourcesArray));
</cfscript>