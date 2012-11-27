import '../../../pkg/unittest/lib/unittest.dart';
import '../lib/html_to_json.dart' as html_to_json;
import '../lib/json_to_html.dart' as json_to_html;
import 'dart:json';
import 'dart:io';

void main() {
  var scriptPath = new Path(new Options().script).directoryPath.toString();

  test('HTML Doc to JSON', () {
    var htmlPath = new Path('$scriptPath/test_data/html_to_json');
    var jsonPath = new Path('$scriptPath/test_output/html_to_json_test.json');

    var convertFuture = html_to_json.convert(htmlPath, jsonPath);

    convertFuture.then(expectAsync1((anyErrors) {
      var output = new File.fromPath(jsonPath);

      var goldenFile = new File(
          '$scriptPath/test_data/html_to_json/'
          'html_to_json_test_golden_output.json');

      expect(anyErrors, false, reason:'The conversion completed with errors.');
      expect(output.readAsStringSync(), goldenFile.readAsStringSync());
    }));
  });

  test('JSON to HTML Doc', () {
    var preHtmlPath = new Path('$scriptPath/test_data/json_to_html');
    var goldenHtmlPath = new Path('$scriptPath/test_data/html_to_json');
    var htmlPath = new Path('$scriptPath/test_output');
    var jsonPath = new Path('$scriptPath/test_output/html_to_json_test.json');

    var copyFuture = _copyFiles(preHtmlPath, htmlPath);

    copyFuture.then(expectAsync1((_) {
      var convertFuture = json_to_html.convert(htmlPath, jsonPath);

      convertFuture.then((anyErrors) {
        expect(anyErrors, false,
            reason:'The conversion completed with errors.');

        _compareFilesInDirectories(goldenHtmlPath, htmlPath);

      });
    }));
  });
}

void _compareFilesInDirectories(Path path1, Path path2) {
  final dir1 = new Directory.fromPath(path1);
  final dir2 = new Directory.fromPath(path2);
  final lister1 = dir1.list(recursive: false);
  final lister2 = dir2.list(recursive: false);

  // True once one of the listers is finished.
  var oneFinished = false;

  var list1 = <String, File>{};

  lister1.onFile = (String path) {
    if (path.endsWith('.dart')) {
      list1.putIfAbsent(new Path(path).filename, () => new File(path));
    }
  };

  lister1.onDone = (_) {
    lister2.onFile = (String path) {
      if (path.endsWith('.dart')) {
        expect(list1[new Path(path).filename].readAsStringSync(),
            new File(path).readAsStringSync());
      }
    };
  };
}

Future _copyFiles(Path fromDir, Path toDir) {
  // First copy the files into a new place to keep the old files.
  final completer = new Completer();
  final htmlDir = new Directory.fromPath(fromDir);
  final lister = htmlDir.list(recursive: false);

  lister.onFile = (String path) {
    final name = new Path.fromNative(path).filename;

    // Ignore private classes.
    if (name.startsWith('_')) return;

    // Ignore non-dart files.
    if (!name.endsWith('.dart')) return;

    File file = new File(path);
    File newFile = new File.fromPath(toDir.append(name));

    var outputStream = newFile.openOutputStream();
    outputStream.writeString(file.readAsStringSync());
  };

  lister.onDone = (_) {
    completer.complete(null);
  };
  return completer.future;
}