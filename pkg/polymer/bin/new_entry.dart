/// 
/// Script to create boilerplate for a Polymer element.
/// Produces new .html entry point for a polymer app and updates the
/// pubspec.yaml to reflect it.
/// 
/// Run this script with pub run:
/// 
///     pub run polymer:new_entry <html_file>
/// 
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:source_span/source_span.dart';

void main(List<String> args) {
  var entryPoint = args[0];  
  var outputDir = path.dirname(entryPoint);
  var outputDirLocation = new Directory(outputDir);
  
  if (!outputDirLocation.existsSync()) {
    outputDirLocation.createSync(recursive: true);
  }
  
  outputDir = outputDirLocation.resolveSymbolicLinksSync();
  var pubspecDir = _findDirWithFile(outputDir, 'pubspec.yaml');
  
  if (pubspecDir == null) {
    print('Could not find pubspec.yaml when walking up from $outputDir');
    exitCode = 1;
    return;
  }

  var relativeEntryPoint = path.relative(
      path.join(outputDir, path.basename(entryPoint)), from: pubspecDir);
  
  try {
    if (_createBoilerPlate(relativeEntryPoint, pubspecDir) == false) {
      print('Added $entryPoint to ${path.join(pubspecDir, "pubspec.yaml")}');
    }
    print('Successfully created:');
    print('  ' + path.join(pubspecDir, entryPoint));
  } catch(e, t) {
    print('Exception: $e\n$t');
    print('Error creating files in $outputDir');
    exitCode = 1;
  }
 
  return;
}

String _findDirWithFile(String dir, String filename) {
  while (!new File(path.join(dir, filename)).existsSync()) {
    var parentDir = path.dirname(dir);
    // If we reached root and failed to find it, bail.
    if (parentDir == dir) return null;
    dir = parentDir;
  }
  return dir;
}

// Returns true if there was a monolithic polymer transformer in the pubspec,
// in which case the pubspec wasn't modified. Returns false otherwise.
bool _createBoilerPlate(String entryPoint, String pubspecDir) {
 
String html = '''
<!doctype html>
<html>
  <head>
    <script src="packages/web_components/platform.js"></script>
    <script src="packages/web_components/dart_support.js"></script>

    <!-- link rel="import" href="path_to_html_import.html" -->
  </head>
  <body>
    <!-- HTML for body here -->
    <script type="application/dart">export 'package:polymer/init.dart';</script>
  </body>
</html>
''';

  new File(path.join(pubspecDir, entryPoint)).writeAsStringSync(html);
  
  var pubspecPath = path.join(pubspecDir, 'pubspec.yaml');
  var pubspecText = new File(pubspecPath).readAsStringSync();
  var transformers = loadYaml(pubspecText)['transformers'];
  var entryPoints = [entryPoint];

  var insertionPoint;
  var textToInsert = '';

  if (transformers != null) {
    // If there are transformers in the pubspec, look for the polymer
    // transformers, get the entry points, and delete the old entry points.
    var transformersSourceSpan = transformers.span;
    SourceSpan sourceSpan;
    bool monolithicPolymerTransformer = false;
    
    transformers.forEach((e) {
      if (e is YamlMap && e['polymer'] != null) {
        entryPoints.addAll(e['polymer']['entry_points']);
        if (e['polymer'].keys.length > 1) {
          // TODO(dgrove): handle the case where there are additional sections
          // in the polymer transformer.
          throw new UnimplementedError('Cannot handle non-entry_point entries '
              'for polymer transformer');
        }
        sourceSpan = e.span;
      } else if (e == 'polymer') {
        if (path.split(entryPoint)[0] == 'web') {
          // In this case, there's no need to add the entry point.
          monolithicPolymerTransformer = true;
        } else {
          print('WARNING: Did not add entry_point $entryPoint to pubspec.yaml'
              ' because of already-existing transformer|polymer section');
          monolithicPolymerTransformer = true;
        }
      } 
    });
  
    if (monolithicPolymerTransformer) {
      return true;
    }
    if (sourceSpan == null) {
      // There were no polymer transformers.
      insertionPoint = transformersSourceSpan.start.offset;
      textToInsert = '- ';
    } else {
      insertionPoint = sourceSpan.start.offset;
      pubspecText = '${pubspecText.substring(0, insertionPoint)}'
          '${pubspecText.substring(sourceSpan.end.offset)}';
    } 
  } else {
    // There were no transformers at all.
    insertionPoint = pubspecText.length;
    textToInsert = 'transformers:\n- ';
  }
  
  // TODO(dgrove): Once dartbug.com/20409 is addressed, use that here.
  var entryPointsText = entryPoints.map((e) => '    - $e').join('\n');
  
  textToInsert =
'''${textToInsert}polymer:
    entry_points:
$entryPointsText''';

  
  if (insertionPoint == pubspecText.length) {
    pubspecText = '${pubspecText}${textToInsert}';
  } else {
    pubspecText = '${pubspecText.substring(0, insertionPoint)}'
        '${textToInsert}\n${pubspecText.substring(insertionPoint)}';
  }
 
  _writePubspec(pubspecPath, pubspecText);
  return false;
}

_writePubspec(String pubspecPath, String text) {
  new File(pubspecPath).writeAsStringSync(text);
}
