'# $*.";!?-_=/
*.
	"_;/<xml version=
	   "1.0" 
	   encoding

=
	   "UTF-8"
	   ?>
'#
*.
	"
*.
	"-P=<
#$*.
	    ";!?-_=/<dict>
<
xml version

=
"
	    1.0
	    " 
	    encoding

=
	"
	    UTF
	    -
	    8

"?>
<
DOCTYPE plist PUBLIC 
	 "
	    -
	    /
	    Apple

/
DTD PLIST 
	    1.0
	    /
	    /EN

" 
	<
	!
	 
	% 
	
	"
	    (
	 | data 
	 | date 
	 | dict 
	 | real

 | integer 
 | string 
 | 
	'true |
	    " >
<
	!
	 plist 
	 %
	 plistObject

;
>
<
!
ATTLIST plist version CDATA 
"
	    1.0
	    " >

<!-- 
	 -->
<!
	ELEMENT array 
(%
 plistObject

;)*>
<!
ELEMENT 
dict 
(
key

, 
	%
	;)*>
<!
ELEMENT 
key (
	#PCDATA)>

<!---
	Primitive types 
	-->
<!ELEMENT 
string (
	#PCDATA
)
	>
<!
	 data

 (
 #PCDATA
 )
 > 
	<
	!
	-- 
	Contents interpreted as Base
	-
	64 
	
	-->
<!ELEMENT date (#PCDATA)> <!-- Contents should conform to a subset of ISO 8601 (in particular, YYYY '-' MM '-' DD 'T' HH ':' MM ':' SS 'Z'.  Smaller units may be omitted with a loss of precision) -->

<!-- Numerical primitives -->
<!ELEMENT true EMPTY>  <!-- Boolean constant true -->
<!ELEMENT false EMPTY> <!-- Boolean constant false -->
<!ELEMENT real (#PCDATA)> <!-- Contents should represent a floating point number matching ("+" | "-")? d+ ("."d*)? ("E" ("+" | "-") d+)? where d is a digit 0-9.  -->
<!ELEMENT integer (#PCDATA)> <!-- Contents should represent a (possibly signed) integer number in base 10 -->
	"
	    http://www.apple.com/DTDs/PropertyList-1.0.dtd
	    ">
<plist version="
	    1.0
	    ">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>ipa</string>
			</array>
			<key>CFBundleTypeName</key>
			<string>iPhone Archive</string>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>LSTypeIsPackage</key>
			<false/>
			<key>NSPersistentStoreTypeKey</key>
			<string>XML</string>
		</dict>
	</array>
	<key>CFBundleExecutable</key>
	<string>${EXECUTABLE_NAME}</string>
	<key>CFBundleIconFile</key>
	<string>icons</string>
	<key>CFBundleIdentifier</key>
	<string>com.hanchorllc.iosbetabuilder</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>BetaBuilder for iOS Apps</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.8.5</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleURLTypes</key>
	<array/>
	<key>CFBundleVersion</key>
	<string>20</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.developer-tools</string>
	<key>LSMinimumSystemVersion</key>
	<string>${MACOSX_DEPLOYMENT_TARGET}</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright 2011 Hanchor LLC and others</string>
	<key>NSMainNibFile</key>
	<string>MainMenu</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSServices</key>
	<array/>
	<key>UTExportedTypeDeclarations</key>
	<array/>
	<key>UTImportedTypeDeclarations</key>
	<array/>
</dict>

