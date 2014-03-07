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
      return dg.docgen(['$codeDir/'], out: p.join(d.defaultRoot, 'docs'));
    });

    d.dir('docs', [
        d.matcherFile('index.json', _isJsonMap),
        d.matcherFile('index.txt', _hasSortedLines),
        d.matcherFile('library_list.json', _isJsonMap),
        d.matcherFile('testLib-bar.C.json', _isJsonMap),
        d.matcherFile('testLib-bar.json', _isJsonMap),
        d.matcherFile('testLib.A.json', _isJsonMap),
        d.matcherFile('testLib.B.json', _isJsonMap),
        d.matcherFile('testLib.C.json', _isJsonMap),
        d.matcherFile('testLib.json', _isJsonMap),
        d.matcherFile('testLib2-foo.B.json', _isJsonMap),
        d.matcherFile('testLib2-foo.json', _isJsonMap)
    ]).validate();

  });

  test('typedef gen', () {
    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen(['$codeDir/'], out: p.join(d.defaultRoot, 'docs'));
    });

    schedule(() {
      var dartCoreJson = new File(p.join(d.defaultRoot, 'docs', 'testLib-bar.json'))
        .readAsStringSync();

      var dartCore = JSON.decode(dartCoreJson) as Map<String, dynamic>;

      var classes = dartCore['classes'] as Map<String, dynamic>;

      expect(classes, hasLength(3));

      expect(classes['class'], isList);
      expect(classes['error'], isList);

      var typeDefs = classes['typedef'] as Map<String, dynamic>;
      var comparator = typeDefs['AnATransformer'] as Map<String, dynamic>;

      var expectedPreview = '<p>A trivial use of <code>A</code> to eliminate '
          'import warnings.</p>';

      expect(comparator['preview'], expectedPreview);

      var expectedComment = expectedPreview +
          '\n<p>And to test typedef preview.</p>';

      expect(comparator['comment'], expectedComment);
    });
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
