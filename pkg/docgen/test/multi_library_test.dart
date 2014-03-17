library single_library_test;

import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';

import '../lib/docgen.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;

import 'util.dart';

List<Uri> _writeLibFiles() {
  var codePath = getMultiLibraryCodePath();

  codePath = p.join(codePath, 'lib');

  return ['test_lib.dart', 'test_lib_bar.dart', 'test_lib_foo.dart']
      .map((name) => p.join(codePath, name))
      .map(p.toUri)
      .toList();
}

void main() {
  group('Generate docs for', () {
    test('multiple libraries.', () {
      var files = _writeLibFiles();
      return getMirrorSystem(files)
        .then((mirrorSystem) {
          var test_libraryUri = files[0];
          var library = new Library(mirrorSystem.libraries[test_libraryUri]);

          /// Testing fixReference
          // Testing Doc comment for class [B].
          var libraryMirror = mirrorSystem.libraries[test_libraryUri];
          var classDocComment = library.fixReference('B').children.first.text;
          expect(classDocComment, 'test_lib.B');

          // Test for linking to parameter [c]
          var importedLib = libraryMirror.libraryDependencies.firstWhere(
            (dep) => dep.isImport).targetLibrary;
          var aClassMirror =
              dart2js_util.classesOf(importedLib.declarations).first;
          expect(dart2js_util.qualifiedNameOf(aClassMirror),
                 'test_lib.foo.B');
          var exportedClass = Indexable.getDocgenObject(aClassMirror, library);
          expect(exportedClass is Class, isTrue);


          var method = exportedClass.methods['doThis'];
          expect(method is Method, isTrue);
          var methodParameterDocComment = method.fixReference(
              'c').children.first.text;
          expect(methodParameterDocComment, 'test_lib.B.doThis.c');


          expect(method.fixReference('A').children.first.text, 'test_lib.A');
          // Testing trying to refer to doThis function
          expect(method.fixReference('doThis').children.first.text,
              'test_lib.B.doThis');

          // Testing trying to refer to doThis function
          expect(method.fixReference('doElse').children.first.text,
              'test_lib.B.doElse');


          // Test a third library referencing another exported library in a
          // separate file.
          importedLib = libraryMirror.libraryDependencies.firstWhere(
            (dep) => dep.isImport &&
                     dart2js_util.qualifiedNameOf(dep.targetLibrary) ==
            'test_lib.bar').targetLibrary;
          aClassMirror = dart2js_util.classesOf(importedLib.declarations).first;
          expect(dart2js_util.qualifiedNameOf(aClassMirror),
                 'test_lib.bar.C');
          exportedClass = Indexable.getDocgenObject(aClassMirror, library);
          expect(exportedClass is Class, isTrue);
          expect(exportedClass.docName, 'test_lib.C');

          methodParameterDocComment = exportedClass.fixReference(
              'B').children.first.text;
          expect(methodParameterDocComment, 'test_lib.B');

          methodParameterDocComment = exportedClass.fixReference(
              'testFunc').children.first.text;
          expect(methodParameterDocComment, 'test_lib.testFunc');

        });
    });
  });
}
