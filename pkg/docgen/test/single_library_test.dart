library single_library_test;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../lib/docgen.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;

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

    int _someNumber;

    A() {
      _someNumber = 12;
    }

    /**
     * Test for linking to parameter [A]
     */
    void doThis(int A) {
      print(A);
    }
  }

  main() {
    A a = new A();
    a.doThis(5);
  }
''';

main() {
  group('Generate docs for', () {
    test('one simple file.', () {
      var temporaryDir = Directory.systemTemp.createTempSync('single_library_');
      var fileName = path.join(temporaryDir.path, 'temp.dart');
      var file = new File(fileName);
      file.writeAsStringSync(DART_LIBRARY);

      return getMirrorSystem([new Uri.file(fileName)])
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
          expect(classMethodTypes.every((e) => e is Map<String, Method>), isTrue);

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
          var method = Indexable.getDocgenObject(
              classMirror.declarations[dart2js_util.symbolOf('doThis')]);
          var methodParameterDocComment = method.fixReference(
              'A').children.first.text;
          expect(methodParameterDocComment, 'test.A.doThis.A');

          // Testing trying to refer to doThis function
          var methodDocComment = method.fixReference(
              'doThis').children.first.text;
          expect(methodDocComment, 'test.A.doThis');

          // Testing something with no reference
          var libraryDocComment = method.fixReference('foobar').text;
          expect(libraryDocComment, 'foobar');
        }).whenComplete(() => temporaryDir.deleteSync(recursive: true));
    });
  });
}
