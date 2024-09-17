// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionImplTest);
    defineReflectiveTests(AnalysisSessionImpl_BlazeWorkspaceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnalysisSessionImpl_BlazeWorkspaceTest
    extends BlazeWorkspaceResolutionTest {
  void test_getErrors_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/blaze-bin/$relPath', '');

    var file = getFile('$workspaceRootPath/$relPath');
    var session = contextFor(file).currentSession;
    var result = await session.getErrors(file.path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getErrors_valid() async {
    var a = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'var x = 0',
    );

    var session = contextFor(a).currentSession;
    var result = await session.getErrorsValid(a);
    expect(result.path, a.path);
    expect(result.errors, hasLength(1));
    expect(result.uri.toString(), 'package:dart.my/a.dart');
  }

  void test_getParsedLibrary_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/blaze-bin/$relPath', '');

    var file = getFile('$workspaceRootPath/$relPath');
    var session = contextFor(file).currentSession;
    var result = session.getParsedLibrary(file.path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getResolvedLibrary_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/blaze-bin/$relPath', '');

    var file = getFile('$workspaceRootPath/$relPath');
    var session = contextFor(file).currentSession;
    var result = await session.getResolvedLibrary(file.path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getResolvedUnit_notFileOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/blaze-bin/$relPath', '');

    var file = getFile('$workspaceRootPath/$relPath');
    var session = contextFor(file).currentSession;
    var result = await session.getResolvedUnit(file.path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getResolvedUnit_valid() async {
    var file = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'class A {}',
    );

    var session = contextFor(file).currentSession;
    var result = await session.getResolvedUnit(file.path) as ResolvedUnitResult;
    expect(result.path, file.path);
    expect(result.errors, isEmpty);
    expect(result.uri.toString(), 'package:dart.my/a.dart');
  }

  void test_getUnitElement_invalidPath_notAbsolute() async {
    var file = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'class A {}',
    );

    var session = contextFor(file).currentSession;
    var result = await session.getUnitElement('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  void test_getUnitElement_notPathOfUri() async {
    var relPath = 'dart/my/lib/a.dart';
    newFile('$workspaceRootPath/blaze-bin/$relPath', '');

    var file = getFile('$workspaceRootPath/$relPath');
    var session = contextFor(file).currentSession;
    var result = await session.getUnitElement(file.path);
    expect(result, isA<NotPathOfUriResult>());
  }

  void test_getUnitElement_valid() async {
    var file = newFile(
      '$workspaceRootPath/dart/my/lib/a.dart',
      'class A {}',
    );

    var session = contextFor(file).currentSession;
    var result = await session.getUnitElementValid(file);
    expect(result.path, file.path);
    expect(result.element.classes, hasLength(1));
    expect(result.uri.toString(), 'package:dart.my/a.dart');
  }
}

@reflectiveTest
class AnalysisSessionImplTest extends PubPackageResolutionTest {
  test_applyPendingFileChanges_getFile() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var analysisContext = contextFor(a);

    int lineCount_in_a() {
      var result = analysisContext.currentSession.getFileValid(a);
      return result.lineInfo.lineCount;
    }

    expect(lineCount_in_a(), 1);

    newFile(a.path, '\n');
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The file must be re-read after `applyPendingFileChanges()`.
    expect(lineCount_in_a(), 2);
  }

  test_applyPendingFileChanges_getParsedLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var analysisContext = contextFor(a);

    int lineCount_in_a() {
      var analysisSession = analysisContext.currentSession;
      var result = analysisSession.getParsedLibraryValid(a);
      return result.units.first.lineInfo.lineCount;
    }

    expect(lineCount_in_a(), 1);

    newFile(a.path, '\n');
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The file must be re-read after `applyPendingFileChanges()`.
    expect(lineCount_in_a(), 2);
  }

  test_applyPendingFileChanges_getParsedUnit() async {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var analysisContext = contextFor(a);

    int lineCount_in_a() {
      var result = analysisContext.currentSession.getParsedUnitValid(a);
      return result.lineInfo.lineCount;
    }

    expect(lineCount_in_a(), 1);

    newFile(a.path, '\n');
    analysisContext.changeFile(a.path);
    await analysisContext.applyPendingFileChanges();

    // The file must be re-read after `applyPendingFileChanges()`.
    expect(lineCount_in_a(), 2);
  }

  test_getErrors() async {
    newFile(testFile.path, 'class C {');

    var session = contextFor(testFile).currentSession;
    var errorsResult = await session.getErrorsValid(testFile);
    expect(errorsResult.session, session);
    expect(errorsResult.path, testFile.path);
    expect(errorsResult.errors, isNotEmpty);
  }

  test_getErrors_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getErrors(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getErrors_invalidPath_notAbsolute() async {
    var session = contextFor(testFile).currentSession;
    var errorsResult = await session.getErrors('not_absolute.dart');
    expect(errorsResult, isA<InvalidPathResult>());
  }

  test_getFile_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getFile(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getFile_invalidPath_notAbsolute() async {
    var session = contextFor(testFile).currentSession;
    var errorsResult = session.getFile('not_absolute.dart');
    expect(errorsResult, isA<InvalidPathResult>());
  }

  test_getFile_library() async {
    var content = 'class A {}';
    var a = newFile('$testPackageLibPath/a.dart', content);

    var session = contextFor(testFile).currentSession;
    var file = session.getFileValid(a);
    expect(file.path, a.path);
    expect(file.uri.toString(), 'package:test/a.dart');
    expect(file.content, content);
    expect(file.isLibrary, isTrue);
    expect(file.isPart, isFalse);
  }

  test_getFile_part() async {
    var content = 'part of lib;';
    var a = newFile('$testPackageLibPath/a.dart', content);

    var session = contextFor(testFile).currentSession;
    var file = session.getFileValid(a);
    expect(file.path, a.path);
    expect(file.uri.toString(), 'package:test/a.dart');
    expect(file.content, content);
    expect(file.isLibrary, isFalse);
    expect(file.isPart, isTrue);
  }

  test_getLibraryByUri() async {
    newFile(testFile.path, r'''
class A {}
class B {}
''');

    var session = contextFor(testFile).currentSession;
    var result = await session.getLibraryByUriValid('package:test/test.dart');
    var library = result.element;
    expect(library.getClass('A'), isNotNull);
    expect(library.getClass('B'), isNotNull);
    expect(library.getClass('C'), isNull);
  }

  test_getLibraryByUri_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getLibraryByUriValid('package:test/test.dart'),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getLibraryByUri_notLibrary_part() async {
    newFile(testFile.path, r'''
part of 'a.dart';
''');

    var session = contextFor(testFile).currentSession;
    var result = await session.getLibraryByUri('package:test/test.dart');
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getLibraryByUri_unresolvedUri() async {
    var session = contextFor(testFile).currentSession;
    var result = await session.getLibraryByUri('package:foo/foo.dart');
    expect(result, isA<CannotResolveUriResult>());
  }

  test_getParsedLibrary() async {
    var test = newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
''');

    var session = contextFor(testFile).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(test);
    expect(parsedLibrary.session, session);

    expect(parsedLibrary.units, hasLength(1));
    {
      var parsedUnit = parsedLibrary.units[0];
      expect(parsedUnit.session, session);
      expect(parsedUnit.path, test.path);
      expect(parsedUnit.uri, Uri.parse('package:test/a.dart'));
      expect(parsedUnit.unit.declarations, hasLength(2));
    }
  }

  test_getParsedLibrary_getElementDeclaration_class() async {
    newFile(testFile.path, r'''
class A {}
class B {}
''');

    var session = contextFor(testFile).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var parsedLibrary = session.getParsedLibraryValid(testFile);

    var element = libraryResult.element.getClass('A')!;
    var declaration = parsedLibrary.getElementDeclaration(element)!;
    var node = declaration.node as ClassDeclaration;
    expect(node.name.lexeme, 'A');
    expect(node.offset, 0);
    expect(node.length, 10);
  }

  test_getParsedLibrary_getElementDeclaration_notThisLibrary() async {
    newFile(testFile.path, '');

    var session = contextFor(testFile).currentSession;
    var resolvedUnit =
        await session.getResolvedUnit(testFile.path) as ResolvedUnitResult;
    var typeProvider = resolvedUnit.typeProvider;
    var intClass = typeProvider.intType.element;

    var parsedLibrary = session.getParsedLibraryValid(testFile);

    expect(() {
      parsedLibrary.getElementDeclaration(intClass);
    }, throwsArgumentError);
  }

  test_getParsedLibrary_getElementDeclaration_synthetic() async {
    newFile(testFile.path, r'''
int foo = 0;
''');

    var session = contextFor(testFile).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(testFile);

    var unitResult = await session.getUnitElementValid(testFile);
    var fooElement = unitResult.element.topLevelVariables[0];
    expect(fooElement.name, 'foo');

    // We can get the variable element declaration.
    var fooDeclaration = parsedLibrary.getElementDeclaration(fooElement)!;
    var fooNode = fooDeclaration.node as VariableDeclaration;
    expect(fooNode.name.lexeme, 'foo');
    expect(fooNode.offset, 4);
    expect(fooNode.length, 7);

    // Synthetic elements don't have nodes.
    expect(parsedLibrary.getElementDeclaration(fooElement.getter!), isNull);
    expect(parsedLibrary.getElementDeclaration(fooElement.setter!), isNull);
  }

  test_getParsedLibrary_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getParsedLibrary(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getParsedLibrary_invalidPartUri() async {
    newFile(testFile.path, r'''
part 'a.dart';
part ':[invalid uri].dart';
part 'c.dart';
''');

    var session = contextFor(testFile).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(testFile);

    expect(parsedLibrary.units, hasLength(1));
    expect(
      parsedLibrary.units[0].path,
      convertPath('/home/test/lib/test.dart'),
    );
  }

  test_getParsedLibrary_invalidPath_notAbsolute() async {
    var session = contextFor(testFile).currentSession;
    var result = session.getParsedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getParsedLibrary_notLibrary() async {
    var test = newFile(testFile.path, 'part of "a.dart";');
    var session = contextFor(testFile).currentSession;
    expect(session.getParsedLibrary(test.path), isA<NotLibraryButPartResult>());
  }

  test_getParsedLibrary_parts() async {
    var aContent = r'''
part 'b.dart';
part 'c.dart';

class A {}
''';

    var bContent = r'''
part of 'a.dart';

class B1 {}
class B2 {}
''';

    var cContent = r'''
part of 'a.dart';

class C1 {}
class C2 {}
class C3 {}
''';

    var a = newFile('$testPackageLibPath/a.dart', aContent);
    var b = newFile('$testPackageLibPath/b.dart', bContent);
    var c = newFile('$testPackageLibPath/c.dart', cContent);

    var session = contextFor(testFile).currentSession;
    var parsedLibrary = session.getParsedLibraryValid(a);
    expect(parsedLibrary.units, hasLength(3));

    {
      var aUnit = parsedLibrary.units[0];
      expect(aUnit.path, a.path);
      expect(aUnit.uri, Uri.parse('package:test/a.dart'));
      expect(aUnit.unit.declarations, hasLength(1));
    }

    {
      var bUnit = parsedLibrary.units[1];
      expect(bUnit.path, b.path);
      expect(bUnit.uri, Uri.parse('package:test/b.dart'));
      expect(bUnit.unit.declarations, hasLength(2));
    }

    {
      var cUnit = parsedLibrary.units[2];
      expect(cUnit.path, c.path);
      expect(cUnit.uri, Uri.parse('package:test/c.dart'));
      expect(cUnit.unit.declarations, hasLength(3));
    }
  }

  test_getParsedLibraryByElement() async {
    var test = newFile(testFile.path, '');

    var session = contextFor(testFile).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var parsedLibrary = session.getParsedLibraryByElementValid(element);
    expect(parsedLibrary.session, session);
    expect(parsedLibrary.units, hasLength(1));

    {
      var unit = parsedLibrary.units[0];
      expect(unit.path, test.path);
      expect(unit.uri, Uri.parse('package:test/test.dart'));
      expect(unit.unit, isNotNull);
    }
  }

  test_getParsedLibraryByElement_differentSession() async {
    newFile(testFile.path, '');

    var session = contextFor(testFile).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var aaaFile = getFile('$workspaceRootPath/aaa/lib/a.dart');
    var aaaSession = contextFor(aaaFile).currentSession;

    var result = aaaSession.getParsedLibraryByElement(element);
    expect(result, isA<NotElementOfThisSessionResult>());
  }

  test_getParsedUnit() async {
    newFile(testFile.path, r'''
class A {}
class B {}
''');

    var session = contextFor(testFile).currentSession;
    var unitResult = session.getParsedUnitValid(testFile);
    expect(unitResult.session, session);
    expect(unitResult.path, testFile.path);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
  }

  test_getParsedUnit_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getParsedUnit(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getParsedUnit_invalidPath_notAbsolute() async {
    var session = contextFor(testFile).currentSession;
    var result = session.getParsedUnit('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getResolvedLibrary() async {
    var aContent = r'''
part 'b.dart';

class A /*a*/ {}
''';
    var a = newFile('$testPackageLibPath/a.dart', aContent);

    var bContent = r'''
part of 'a.dart';

class B /*b*/ {}
class B2 extends X {}
''';
    var b = newFile('$testPackageLibPath/b.dart', bContent);

    var session = contextFor(testFile).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(a);
    expect(resolvedLibrary.session, session);

    var typeProvider = resolvedLibrary.typeProvider;
    expect(typeProvider.intType.element.name, 'int');

    var libraryElement = resolvedLibrary.element;

    var aClass = libraryElement.getClass('A')!;

    var bClass = libraryElement.getClass('B')!;

    var aUnitResult = resolvedLibrary.units[0];
    expect(aUnitResult.path, a.path);
    expect(aUnitResult.uri, Uri.parse('package:test/a.dart'));
    expect(aUnitResult.content, aContent);
    expect(aUnitResult.unit, isNotNull);
    expect(aUnitResult.unit.directives, hasLength(1));
    expect(aUnitResult.unit.declarations, hasLength(1));
    expect(aUnitResult.errors, isEmpty);

    var bUnitResult = resolvedLibrary.units[1];
    expect(bUnitResult.path, b.path);
    expect(bUnitResult.uri, Uri.parse('package:test/b.dart'));
    expect(bUnitResult.content, bContent);
    expect(bUnitResult.unit, isNotNull);
    expect(bUnitResult.unit.directives, hasLength(1));
    expect(bUnitResult.unit.declarations, hasLength(2));
    expect(bUnitResult.errors, isNotEmpty);

    var aDeclaration = resolvedLibrary.getElementDeclaration(aClass)!;
    var aNode = aDeclaration.node as ClassDeclaration;
    expect(aNode.name.lexeme, 'A');
    expect(aNode.offset, 16);
    expect(aNode.length, 16);
    expect(aNode.declaredElement!.name, 'A');

    var bDeclaration = resolvedLibrary.getElementDeclaration(bClass)!;
    var bNode = bDeclaration.node as ClassDeclaration;
    expect(bNode.name.lexeme, 'B');
    expect(bNode.offset, 19);
    expect(bNode.length, 16);
    expect(bNode.declaredElement!.name, 'B');
  }

  test_getResolvedLibrary_getElementDeclaration_notThisLibrary() async {
    newFile(testFile.path, '');

    var session = contextFor(testFile).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(testFile);

    expect(() {
      var intClass = resolvedLibrary.typeProvider.intType.element;
      resolvedLibrary.getElementDeclaration(intClass);
    }, throwsArgumentError);
  }

  test_getResolvedLibrary_getElementDeclaration_synthetic() async {
    newFile(testFile.path, r'''
int foo = 0;
''');

    var session = contextFor(testFile).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(testFile);
    var unitElement = resolvedLibrary.element.definingCompilationUnit;

    var fooElement = unitElement.topLevelVariables[0];
    expect(fooElement.name, 'foo');

    // We can get the variable element declaration.
    var fooDeclaration = resolvedLibrary.getElementDeclaration(fooElement)!;
    var fooNode = fooDeclaration.node as VariableDeclaration;
    expect(fooNode.name.lexeme, 'foo');
    expect(fooNode.offset, 4);
    expect(fooNode.length, 7);
    expect(fooNode.declaredElement!.name, 'foo');

    // Synthetic elements don't have nodes.
    expect(resolvedLibrary.getElementDeclaration(fooElement.getter!), isNull);
    expect(resolvedLibrary.getElementDeclaration(fooElement.setter!), isNull);
  }

  test_getResolvedLibrary_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getResolvedLibrary(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getResolvedLibrary_invalidPartUri() async {
    newFile(testFile.path, r'''
part 'a.dart';
part ':[invalid uri].dart';
part 'c.dart';
''');

    var session = contextFor(testFile).currentSession;
    var resolvedLibrary = await session.getResolvedLibraryValid(testFile);

    expect(resolvedLibrary.units, hasLength(1));
    expect(
      resolvedLibrary.units[0].path,
      convertPath('/home/test/lib/test.dart'),
    );
  }

  test_getResolvedLibrary_invalidPath_notAbsolute() async {
    var session = contextFor(testFile).currentSession;
    var result = await session.getResolvedLibrary('not_absolute.dart');
    expect(result, isA<InvalidPathResult>());
  }

  test_getResolvedLibrary_notLibrary_part() async {
    var test = newFile(testFile.path, 'part of "a.dart";');

    var session = contextFor(testFile).currentSession;
    var result = await session.getResolvedLibrary(test.path);
    expect(result, isA<NotLibraryButPartResult>());
  }

  test_getResolvedLibraryByElement() async {
    var test = newFile(testFile.path, '');

    var session = contextFor(testFile).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var result = await session.getResolvedLibraryByElementValid(element);
    expect(result.session, session);
    expect(result.units, hasLength(1));
    expect(result.units[0].path, test.path);
    expect(result.units[0].uri, Uri.parse('package:test/test.dart'));
    expect(result.units[0].unit.declaredElement, isNotNull);
  }

  test_getResolvedLibraryByElement_differentSession() async {
    newFile(testFile.path, '');

    var session = contextFor(testFile).currentSession;
    var libraryResult = await session.getLibraryByUriValid(
      'package:test/test.dart',
    );
    var element = libraryResult.element;

    var aaaFile = getFile('$workspaceRootPath/aaa/lib/a.dart');
    var aaaSession = contextFor(aaaFile).currentSession;

    var result = await aaaSession.getResolvedLibraryByElement(element);
    expect(result, isA<NotElementOfThisSessionResult>());
  }

  test_getResolvedUnit() async {
    var test = newFile(testFile.path, r'''
class A {}
class B {}
''');

    var session = contextFor(testFile).currentSession;
    var unitResult =
        await session.getResolvedUnit(test.path) as ResolvedUnitResult;
    expect(unitResult.session, session);
    expect(unitResult.path, test.path);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
    expect(unitResult.typeProvider, isNotNull);
    expect(unitResult.libraryElement, isNotNull);
  }

  test_getResolvedUnit_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getResolvedUnit(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getUnitElement_inconsistent() async {
    var test = newFile(testFile.path, '');
    var session = contextFor(test).currentSession;
    driverFor(test).changeFile(test.path);
    expect(
      () => session.getUnitElement(test.path),
      throwsA(isA<InconsistentAnalysisException>()),
    );
  }

  test_getUnitElement_libraryUnit() async {
    newFile(testFile.path, r'''
class A {}
class B {}
''');

    await _assertFileUnitElementResultText(testFile, r'''
unitElementResult
  path: /home/test/lib/test.dart
  uri: package:test/test.dart
  element
    reference: root::package:test/test.dart::@fragment::package:test/test.dart
    library: root::package:test/test.dart
    classes: A, B
''');
  }

  test_getUnitElement_partOfUriKnown_inLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class A {}
class B {}
''');

    newFile(testFile.path, r'''
part 'a.dart';
''');

    await _assertFileUnitElementResultText(a, r'''
unitElementResult
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  element
    reference: root::package:test/test.dart::@fragment::package:test/a.dart
    library: root::package:test/test.dart
    classes: A, B
''');
  }

  test_getUnitElement_partOfUriKnown_notInLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class A {}
class B {}
''');

    await _assertFileUnitElementResultText(a, r'''
unitElementResult
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  element
    reference: root::package:test/a.dart::@fragment::package:test/a.dart
    library: root::package:test/a.dart
    classes: A, B
''');
  }

  test_getUnitElement_partOfUriName_inLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of my_lib;
class A {}
class B {}
''');

    newFile(testFile.path, r'''
library my_lib;
part 'a.dart';
''');

    await _assertFileUnitElementResultText(a, r'''
unitElementResult
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  element
    reference: root::package:test/test.dart::@fragment::package:test/a.dart
    library: root::package:test/test.dart
    classes: A, B
''');
  }

  test_getUnitElement_partOfUriName_notInLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of my_lib;
class A {}
class B {}
''');

    await _assertFileUnitElementResultText(a, r'''
unitElementResult
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  element
    reference: root::package:test/a.dart::@fragment::package:test/a.dart
    library: root::package:test/a.dart
    classes: A, B
''');
  }

  test_getUnitElement_partOfUriUnknown() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'foo:bar';
class A {}
class B {}
''');

    await _assertFileUnitElementResultText(a, r'''
unitElementResult
  path: /home/test/lib/a.dart
  uri: package:test/a.dart
  element
    reference: root::package:test/a.dart::@fragment::package:test/a.dart
    library: root::package:test/a.dart
    classes: A, B
''');
  }

  test_resourceProvider() async {
    var session = contextFor(testFile).currentSession;
    expect(session.resourceProvider, resourceProvider);
  }

  Future<void> _assertFileUnitElementResultText(
    File file,
    String expected,
  ) async {
    var session = contextFor(file).currentSession;
    var unitResult = await session.getUnitElementValid(file);
    _assertUnitElementResultText(unitResult, expected);
  }

  void _assertUnitElementResultText(
    UnitElementResult result,
    String expected,
  ) {
    var actual = _getElementUnitResultText(result);
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  String _getElementUnitResultText(UnitElementResult result) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');

    sink.writelnWithIndent('unitElementResult');
    sink.withIndent(() {
      // We could print it, but currently it is always the current.
      expect(result.session, contextFor(testFile).currentSession);

      var file = result.file;
      sink.writelnWithIndent('path: ${file.posixPath}');

      sink.writelnWithIndent('uri: ${result.uri}');

      sink.writelnWithIndent('element');
      sink.withIndent(() {
        var element = result.element as CompilationUnitElementImpl;
        sink.writelnWithIndent('reference: ${element.reference}');

        var library = element.library;
        sink.writelnWithIndent('library: ${library.reference}');

        var classListStr = element.classes.map((e) => e.name).join(', ');
        sink.writelnWithIndent('classes: $classListStr');
      });
    });

    return buffer.toString();
  }
}

extension on AnalysisSession {
  Future<ErrorsResult> getErrorsValid(File file) async {
    return await getErrors(file.path) as ErrorsResult;
  }

  FileResult getFileValid(File file) {
    return getFile(file.path) as FileResult;
  }

  Future<LibraryElementResult> getLibraryByUriValid(String uriStr) async {
    return await getLibraryByUri(uriStr) as LibraryElementResult;
  }

  ParsedLibraryResult getParsedLibraryByElementValid(LibraryElement element) {
    return getParsedLibraryByElement(element) as ParsedLibraryResult;
  }

  ParsedLibraryResult getParsedLibraryValid(File file) {
    return getParsedLibrary(file.path) as ParsedLibraryResult;
  }

  ParsedUnitResult getParsedUnitValid(File file) {
    return getParsedUnit(file.path) as ParsedUnitResult;
  }

  Future<ResolvedLibraryResult> getResolvedLibraryByElementValid(
      LibraryElement element) async {
    return await getResolvedLibraryByElement(element) as ResolvedLibraryResult;
  }

  Future<ResolvedLibraryResult> getResolvedLibraryValid(File file) async {
    return await getResolvedLibrary(file.path) as ResolvedLibraryResult;
  }

  Future<UnitElementResult> getUnitElementValid(File file) async {
    return await getUnitElement(file.path) as UnitElementResult;
  }
}
