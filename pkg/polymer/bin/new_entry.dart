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
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:source_span/source_span.dart';

void printUsage() {
  print('pub run polymer:new_entry entry_point_file.html');
}

void main(List<String> args) {
  var parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag('help', abbr: 'h');
  var entryPoint;

  try {
    var options = parser.parse(args);
    if (options['help']) {
      printUsage();
      return;
    }
    entryPoint = options.rest[0];
  } catch(e) {
    print('$e\n');
    printUsage();
    exitCode = 1;
    return;
  }

  // If the entrypoint file has no extension, add .html to it.
  if (path.extension(entryPoint) == '') {
    entryPoint = '${entryPoint}.html';
  }

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
    if (_createBoilerPlate(relativeEntryPoint, pubspecDir)) {
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

// Returns true if the pubspec file was modified. It might not be modified if
// there was a monolithic polymer transformer in the pubspec, or if the entry
// point for some reason already existed in the pubspec.
bool _createBoilerPlate(String entryPoint, String pubspecDir) {

String html = '''
<!doctype html>
<html>
  <head>
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
  var entryPoints;

  var insertionPoint;
  var textToInsert = '';

  if (transformers != null) {
    // If there are transformers in the pubspec, look for the polymer
    // transformers, get the entry points, and delete the old entry points.
    SourceSpan transformersSourceSpan = transformers.span;

    SourceSpan polymerTransformerSourceSpan;
    SourceSpan entryPointsSourceSpan;
    for (var e in transformers) {
      if (e == 'polymer') {
        // If they had an empty polymer transformer, just get rid of it (we will
        // replace it with our own map style one).
        var polymerRegex = new RegExp(r'\n\s*-\spolymer\s*');
        // Insert right after the newline.
        insertionPoint = pubspecText.indexOf(polymerRegex) + 1;
        pubspecText = pubspecText.replaceFirst(polymerRegex, '\n');
      } else if (e is YamlMap && e['polymer'] != null) {
        polymerTransformerSourceSpan = e['polymer'].span;

        var existing = e['polymer']['entry_points'];
        if (existing == null && e['polymer'].containsKey('entry_points')) {
          if (path.split(entryPoint)[0] != 'web') {
            print('WARNING: Did not add entry_point $entryPoint to pubspec.yaml'
              ' because of existing empty `entry_points` field in polymer'
              ' transformer. This defaults to treating all files under `web/`'
              ' as entry points, but you tried to add an entry point outside of'
              ' the `web/` folder. You will need to explicitly list all entry'
              ' points that you care about into your pubspec in order to'
              ' include any outside of `web/`.');
          }
          return false;
        }
        entryPoints = (existing == null ? [] :
            (existing is String ? [existing] : existing.toList()));

        if (entryPoints.contains(entryPoint)) return false;
        entryPoints.add(entryPoint);

        if (existing != null) {
          entryPointsSourceSpan = existing.span;
        }
      }
    }

    if (polymerTransformerSourceSpan == null) {
      if (insertionPoint == null) {
        insertionPoint = transformersSourceSpan.start.offset;
      }
      textToInsert = '- polymer:\n    entry_points:\n';
    } else if (entryPointsSourceSpan == null) {
      insertionPoint = polymerTransformerSourceSpan.start.offset;
      textToInsert = '    entry_points:\n';
    } else {
      insertionPoint = entryPointsSourceSpan.start.offset;
      pubspecText = '${pubspecText.substring(0, insertionPoint)}'
          '${pubspecText.substring(entryPointsSourceSpan.end.offset)}';
    }
  } else {
    // There were no transformers at all.
    insertionPoint = pubspecText.length;
    var optionalNewline = pubspecText.endsWith('\n') ? '' : '\n';
    textToInsert = '''
${optionalNewline}transformers:
- polymer:
    entry_points:
''';
    entryPoints = [entryPoint];
  }

  if (entryPoints == null) entryPoints = [entryPoint];
  // TODO(dgrove): Once dartbug.com/20409 is addressed, use that here.
  var entryPointsText = entryPoints.map((e) => '    - $e').join('\n');

  textToInsert += entryPointsText;
  if (insertionPoint == pubspecText.length) {
    pubspecText = '${pubspecText}${textToInsert}';
  } else {
    pubspecText = '${pubspecText.substring(0, insertionPoint)}'
        '${textToInsert}\n${pubspecText.substring(insertionPoint)}';
  }

  _writePubspec(pubspecPath, pubspecText);
  return true;
}

_writePubspec(String pubspecPath, String text) {
  new File(pubspecPath).writeAsStringSync(text);
}
