// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library native_extensions_test;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../lib/src/exports/mirrors_util.dart' as dart2js_util;
import '../lib/docgen.dart';

const String DART_LIBRARY = '''
  library sample_synchronous_extension;

  import 'dart-ext:sample_extension';

  // The simplest way to call native code: top-level functions.
  int systemRand() native "SystemRand";
  bool systemSrand(int seed) native "SystemSrand";

  void main() {
    systemRand();
    systemSrand(4);
  }
''';

main() {
  group('Generate docs for', () {
    test('file with native extensions.', () {
      var temporaryDir = Directory.systemTemp.createTempSync('native_ext_');
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

          // Testing trying to refer to m1 function
          var libraryDocComment =
              library.fixReference('systemRand').children.first.text;
          expect(libraryDocComment, 'sample_synchronous_extension.systemRand');

          libraryDocComment =
              library.fixReference('systemSrand').children.first.text;
          expect(libraryDocComment, 'sample_synchronous_extension.systemSrand');
        }).whenComplete(() => temporaryDir.deleteSync(recursive: true));
    });
  });
}
