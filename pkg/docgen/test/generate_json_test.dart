import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:unittest/matcher.dart';

import 'util.dart';
import '../lib/docgen.dart' as dg;

void main() {

  setUp(() {
     var tempDir;
     schedule(() {
       return Directory.systemTemp
           .createTemp('docgen_test-')
           .then((dir) {
         tempDir = dir;
         d.defaultRoot = tempDir.path;
       });
     });

     currentSchedule.onComplete.schedule(() {
       d.defaultRoot = null;
       return tempDir.delete(recursive: true);
     });
   });

  test('json output', () {
    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen([codeDir], out: p.join(d.defaultRoot, 'docs'));
    });

    d.dir('docs', [
        d.matcherFile('index.json', _isJsonMap),
        d.matcherFile('index.txt', _hasSortedLines),
        d.matcherFile('library_list.json', _isJsonMap),
        d.matcherFile('test_lib-bar.C.json', _isJsonMap),
        d.matcherFile('test_lib-bar.json', _isJsonMap),
        d.matcherFile('test_lib-foo.B.json', _isJsonMap),
        d.matcherFile('test_lib-foo.json', _isJsonMap),
        d.matcherFile('test_lib.A.json', _isJsonMap),
        d.matcherFile('test_lib.B.json', _isJsonMap),
        d.matcherFile('test_lib.C.json', _isJsonMap),
        d.matcherFile('test_lib.json', _isJsonMap),
    ]).validate();

  });

  test('typedef gen', () {
    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen([codeDir], out: p.join(d.defaultRoot, 'docs'));
    });

    schedule(() {
      var path = p.join(d.defaultRoot, 'docs', 'test_lib-bar.json');
      var dartCoreJson = new File(path).readAsStringSync();

      var testLibBar = JSON.decode(dartCoreJson) as Map<String, dynamic>;

      //
      // Validate function doc references
      //
      var generateFoo = testLibBar['functions']['methods']['generateFoo']
          as Map<String, dynamic>;

      expect(generateFoo['comment'], '<p><a>test_lib-bar.generateFoo.input</a> '
          'is of type <a>test_lib-bar.C</a> returns an <a>test_lib.A</a>.</p>');

      var classes = testLibBar['classes'] as Map<String, dynamic>;

      expect(classes, hasLength(3));

      expect(classes['class'], isList);
      expect(classes['error'], isList);

      var typeDefs = classes['typedef'] as Map<String, dynamic>;
      var comparator = typeDefs['AnATransformer'] as Map<String, dynamic>;

      var expectedPreview = '<p>Processes a [C] instance for testing.</p>';

      expect(comparator['preview'], expectedPreview);

      var expectedComment = expectedPreview + '\n'
          '<p>To eliminate import warnings for [A] and to test typedefs.</p>';

      expect(comparator['comment'], expectedComment);
    });
  });

  test('exclude non-lib code from package docs', () {
    schedule(() {
      var thisScript = Platform.script;
      var thisPath = p.fromUri(thisScript);
      expect(p.basename(thisPath), 'generate_json_test.dart');
      expect(p.dirname(thisPath), endsWith('test'));


      var codeDir = p.normalize(p.join(thisPath, '..', '..'));
      print(codeDir);
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen(['$codeDir/'], out: p.join(d.defaultRoot, 'docs'));
    });

    d.dir('docs', [
        d.dir('docgen', [
          d.matcherFile('docgen.json',  _isJsonMap)
        ]),
        d.matcherFile('index.json', _isJsonMap),
        d.matcherFile('index.txt', _hasSortedLines),
        d.matcherFile('library_list.json', _isJsonMap),
        d.nothing('test_lib.json'),
        d.nothing('test_lib-bar.json'),
        d.nothing('test_lib-foo.json')
    ]).validate();

  });
}

final Matcher _hasSortedLines = predicate((String input) {
  var lines = new LineSplitter().convert(input);

  var sortedLines = new List.from(lines)..sort();

  var orderedMatcher = orderedEquals(sortedLines);
  return orderedMatcher.matches(lines, {});
}, 'String has sorted lines');

final Matcher _isJsonMap = predicate((input) {
  try {
    return JSON.decode(input) is Map;
  } catch (e) {
    return false;
  }
}, 'Output is JSON encoded Map');
