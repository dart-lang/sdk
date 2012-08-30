
BUILT_DIR=../../../out/ReleaseIA32
DART2JS=$BUILT_DIR/dart2js
DARTVM=$BUILT_DIR/dart

$DART2JS -ooutput/extract.dart.js -c extract.dart
node extractRunner.js

# Read database.json, 
# write database.filtered.json (with "best" entries) 
# and obsolete.json (with entries marked obsolete).
$DARTVM postProcess.dart

# Create database.html, examples.html, and obsolete.html.
$DARTVM prettyPrint.dart

# Copy up the final output to the main MDN directory so we can check it in.
cp output/database.filtered.json database.json
cp output/obsolete.json .
