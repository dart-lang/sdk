import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

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
    print(d.defaultRoot);

    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen(['$codeDir/'], out: p.join(d.defaultRoot, 'docs'));
    });

    d.dir('docs', [
        d.matcherFile('index.json', _isJsonMap),
        d.matcherFile('index.txt', isNotNull),
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
}

final Matcher _isJsonMap = predicate((input) {
  try {
    return JSON.decode(input) is Map;
  } catch (e) {
    return false;
  }
}, 'Output is JSON encoded Map');
