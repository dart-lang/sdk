# Sample script showing how to use legpad.

# First compile "legpad.dart" to "legpad.dart.js" usung dart2js.
set -x
DART_DIR="../../.."
$DART_DIR/out/Release_ia32/dart2js --out=legpad.dart.js legpad.dart

# Now run legpad to generate an html page that can be used to compile
# example.dart
python legpad.py example.dart
