../../../frog/minfrog --out=output/extract.dart.js --enable_type_checks --compile-only extract.dart
node extractRunner.js
../../../frog/minfrog postProcess.dart
../../../frog/minfrog prettyPrint.dart

# Copy up the final output to the main MDN directory so we can check it in.
cp output/database.filtered.json database.json
cp output/obsolete.json .
