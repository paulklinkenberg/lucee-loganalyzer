component extends="org.lucee.cfml.test.LuceeTestCase" labels="log-viewer" {

	function beforeAll(){
		variables.root = getDirectoryFromPath(getCurrentTemplatePath());
		variables.root = listDeleteAt(root,listLen(root,"/\"), "/\") & "/";  // getDirectoryFromPath 
	};

	function run( testResults , testBox ) {
		describe( "Syntax check", function() {

			it(title="compile source CFML/CFC files in CFML", body=function(){
				
				admin action="updateMapping"
					type="server"
					password=request.SERVERADMINPASSWORD
					virtual="/tmpSource"
					physical=variables.root & "source/cfml/plugins/"
					archive=""
					primary="resource";

				expect( len( directoryList("/tmpSource") ) ).toBeGT( 0 );

				admin action="compileMapping"
					type="server"
					password=request.SERVERADMINPASSWORD
					virtual="/tmpSource"
					stoponerror="true";

			});

		});
	}
}
