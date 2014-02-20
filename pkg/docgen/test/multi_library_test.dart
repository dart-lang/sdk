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

  return ['temp.dart', 'temp2.dart', 'temp3.dart']
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

        });
    });
  });
}
