// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_await_test;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../lib/src/exports/mirrors_util.dart' as dart2js_util;
import '../lib/docgen.dart';

const String DART_LIBRARY = '''
  library test;
  /**
   * Doc comment for class [A].
   *
   * Multiline Test
   */
  /*
   * Normal comment for class A.
   */
  class A {
    m1() sync* {
      yield 0;
    }

    m2() async {
      await 0;
      await for (var e in m1()) {}
    }

    m3() async* {
      yield* m1();
    }
  }

  m1() sync* {
    yield 0;
  }

  m2() async {
    await 0;
    await for (var e in m1()) {}
  }

  m3() async* {
    yield* m1();
  }

  main() {
    m1();
    m2();
    m3();
    A a = new A();
    a.m1();
    a.m2();
    a.m3();
  }
''';

main() {
  group('Generate docs for', () {
    test('file with async/await.', () {
      var temporaryDir = Directory.systemTemp.createTempSync('single_library_');
      var fileName = path.join(temporaryDir.path, 'temp.dart');
      var file = new File(fileName);
      file.writeAsStringSync(DART_LIBRARY);

      return getMirrorSystem([new Uri.file(fileName)], false)
        .then((mirrorSystem) {
          var testLibraryUri = new Uri.file(path.absolute(fileName),
                                            windows: Platform.isWindows);
          var library = new Library(mirrorSystem.libraries[testLibraryUri]);
          expect(library is Library, isTrue);

          var classTypes = library.classes;
          var classes = [];
          classes.addAll(classTypes.values);
          classes.addAll(library.errors.values);
          expect(classes.every((e) => e is Class), isTrue);

          expect(library.typedefs.values.every((e) => e is Typedef), isTrue);

          var classMethodTypes = [];
          classes.forEach((e) {
            classMethodTypes.add(e.methods);
            classMethodTypes.add(e.inheritedMethods);
          });
          expect(classMethodTypes.every((e) => e is Map<String, Method>),
                 isTrue);

          var classMethods = [];
          classMethodTypes.forEach((e) {
            classMethods.addAll(e.values);
          });
          expect(classMethods.every((e) => e is Method), isTrue);

          var methodParameters = [];
          classMethods.forEach((e) {
            methodParameters.addAll(e.parameters.values);
          });
          expect(methodParameters.every((e) => e is Parameter), isTrue);

          var functionTypes = library.functions;
          expect(functionTypes is Map<String, Method>, isTrue);

          var functions = [];
          functions.addAll(functionTypes.values);
          expect(functions.every((e) => e is Method), isTrue);

          var functionParameters = [];
          functions.forEach((e) {
            functionParameters.addAll(e.parameters.values);
          });
          expect(functionParameters.every((e) => e is Parameter), isTrue);

          var variables = library.variables.values;
          expect(variables.every((e) => e is Variable), isTrue);

          /// Testing fixReference
          // Testing Doc comment for class [A].
          var libraryMirror = mirrorSystem.libraries[testLibraryUri];
          var classMirror =
              dart2js_util.classesOf(libraryMirror.declarations).first;
          var classDocComment = library.fixReference('A').children.first.text;
          expect(classDocComment, 'test.A');

          // Test for linking to parameter [A]
          var method = getDocgenObject(
              classMirror.declarations[dart2js_util.symbolOf('m1')]);

          // Testing trying to refer to m1 method
          var methodDocComment = method.fixReference(
              'm1').children.first.text;
          expect(methodDocComment, 'test.A.m1');

          // Testing something with no reference
          var libraryDocComment = method.fixReference('foobar').text;
          expect(libraryDocComment, 'foobar');

          // Testing trying to refer to m1 function
          libraryDocComment = library.fixReference('m1').children.first.text;
          expect(libraryDocComment, 'test.m1');
        }).whenComplete(() => temporaryDir.deleteSync(recursive: true));
    });
  });
}
