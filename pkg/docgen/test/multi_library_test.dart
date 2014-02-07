library single_library_test;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../lib/docgen.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;

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

Directory TEMP_DIRNAME;

List writeLibFiles() {
  TEMP_DIRNAME = Directory.systemTemp.createTempSync('single_library_');
  var fileName = path.join(TEMP_DIRNAME.path, 'temp.dart');
  var file = new File(fileName);
  file.writeAsStringSync(DART_LIBRARY_1);

  var fileName2 = path.join(TEMP_DIRNAME.path, 'temp2.dart');
  file = new File(fileName2);
  file.writeAsStringSync(DART_LIBRARY_2);

  var fileName3 = path.join(TEMP_DIRNAME.path, 'temp3.dart');
  file = new File(fileName3);
  file.writeAsStringSync(DART_LIBRARY_3);
  return [new Uri.file(fileName, windows: Platform.isWindows),
          new Uri.file(fileName2, windows: Platform.isWindows),
          new Uri.file(fileName3, windows: Platform.isWindows)];
}

main() {
  group('Generate docs for', () {
    test('multiple libraries.', () {
      var files = writeLibFiles();
      getMirrorSystem(files)
        .then(expectAsync1((mirrorSystem) {
          var testLibraryUri = files[0];
          var library = new Library(mirrorSystem.libraries[testLibraryUri]);

          /// Testing fixReference
          // Testing Doc comment for class [B].
          var libraryMirror = mirrorSystem.libraries[testLibraryUri];
          var classDocComment = library.fixReference('B').children.first.text;
          expect(classDocComment, 'testLib.B');

          // Test for linking to parameter [c]
          var importedLib = libraryMirror.libraryDependencies.firstWhere(
            (dep) => dep.isImport).targetLibrary;
          var aClassMirror =
              dart2js_util.classesOf(importedLib.declarations).first;
          expect(dart2js_util.qualifiedNameOf(aClassMirror),
                 'testLib2.foo.B');
          var exportedClass = Indexable.getDocgenObject(aClassMirror, library);
          expect(exportedClass is Class, isTrue);


          var method = exportedClass.methods['doThis'];
          expect(method is Method, isTrue);
          var methodParameterDocComment = method.fixReference(
              'c').children.first.text;
          expect(methodParameterDocComment, 'testLib.B.doThis.c');


          expect(method.fixReference('A').children.first.text, 'testLib.A');
          // Testing trying to refer to doThis function
          expect(method.fixReference('doThis').children.first.text,
              'testLib.B.doThis');

          // Testing trying to refer to doThis function
          expect(method.fixReference('doElse').children.first.text,
              'testLib.B.doElse');


          // Test a third library referencing another exported library in a
          // separate file.
          importedLib = libraryMirror.libraryDependencies.firstWhere(
            (dep) => dep.isImport &&
                     dart2js_util.qualifiedNameOf(dep.targetLibrary) ==
            'testLib.bar').targetLibrary;
          aClassMirror = dart2js_util.classesOf(importedLib.declarations).first;
          expect(dart2js_util.qualifiedNameOf(aClassMirror),
                 'testLib.bar.C');
          exportedClass = Indexable.getDocgenObject(aClassMirror, library);
          expect(exportedClass is Class, isTrue);
          expect(exportedClass.docName, 'testLib.C');

          methodParameterDocComment = exportedClass.fixReference(
              'B').children.first.text;
          expect(methodParameterDocComment, 'testLib.B');

          methodParameterDocComment = exportedClass.fixReference(
              'testFunc').children.first.text;
          expect(methodParameterDocComment, 'testLib.testFunc');

        })).whenComplete(() => TEMP_DIRNAME.deleteSync(recursive: true));
    });
  });
}
