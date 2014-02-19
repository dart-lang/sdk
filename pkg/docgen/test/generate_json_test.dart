import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

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

    d.dir('lib', [
        d.file('temp.dart', DART_LIBRARY_1),
        d.file('temp2.dart', DART_LIBRARY_2),
        d.file('temp3.dart', DART_LIBRARY_3),
    ]).create();

    schedule(() {
      return dg.docgen([d.defaultRoot], out: p.join(d.defaultRoot, 'docs'));
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

const String DART_LIBRARY_1 = '''
  library testLib;
  import 'temp2.dart';
  import 'temp3.dart';
  export 'temp2.dart';
  export 'temp3.dart';

  /**
   * Doc comment for class [A].
   *
   * Multiline Test
   */
  /*
   * Normal comment for class A.
   */
  class A {

    int _someNumber;

    A() {
      _someNumber = 12;
    }

    A.customConstructor();

    /**
     * Test for linking to parameter [A]
     */
    void doThis(int A) {
      print(A);
    }
  }
''';

const String DART_LIBRARY_2 = '''
  library testLib2.foo;
  import 'temp.dart';

  /**
   * Doc comment for class [B].
   *
   * Multiline Test
   */

  /*
   * Normal comment for class B.
   */
  class B extends A {

    B();
    B.fooBar();

    /**
     * Test for linking to super
     */
    int doElse(int b) {
      print(b);
    }

    /**
     * Test for linking to parameter [c]
     */
    void doThis(int c) {
      print(a);
    }
  }

  int testFunc(int a) {
  }
''';

const String DART_LIBRARY_3 = '''
  library testLib.bar;
  import 'temp.dart';

  /*
   * Normal comment for class C.
   */
  class C {
  }
''';
