// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';
import 'resolver_test_case.dart';
import 'test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnclosedScopeTest);
    defineReflectiveTests(ErrorResolverTest);
    defineReflectiveTests(LibraryImportScopeTest);
    defineReflectiveTests(LibraryScopeTest);
    defineReflectiveTests(PrefixedNamespaceTest);
    defineReflectiveTests(ScopeTest);
    defineReflectiveTests(StrictModeTest);
    defineReflectiveTests(TypePropagationTest);
  });
}

@reflectiveTest
class EnclosedScopeTest extends DriverResolutionTest {
  test_define_duplicate() async {
    Scope rootScope = _RootScope();
    EnclosedScope scope = EnclosedScope(rootScope);
    SimpleIdentifier identifier = AstTestFactory.identifier3('v');
    VariableElement element1 = ElementFactory.localVariableElement(identifier);
    VariableElement element2 = ElementFactory.localVariableElement(identifier);
    scope.define(element1);
    scope.define(element2);
    expect(scope.lookup(identifier, null), same(element1));
  }
}

@reflectiveTest
class ErrorResolverTest extends DriverResolutionTest {
  test_breakLabelOnSwitchMember() async {
    await assertErrorsInCode(r'''
class A {
  void m(int i) {
    switch (i) {
      l: case 0:
        break;
      case 1:
        break l;
    }
  }
}''', [
      error(CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, 105, 1),
    ]);
  }

  test_continueLabelOnSwitch() async {
    await assertErrorsInCode(r'''
class A {
  void m(int i) {
    l: switch (i) {
      case 0:
        continue l;
    }
  }
}''', [
      error(CompileTimeErrorCode.CONTINUE_LABEL_ON_SWITCH, 79, 1),
    ]);
  }

  test_enclosingElement_invalidLocalFunction() async {
    await assertErrorsInCode(r'''
class C {
  C() {
    int get x => 0;
  }
}''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 26, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 3),
      error(HintCode.UNUSED_ELEMENT, 30, 1),
      error(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 32, 2),
    ]);

    var constructor = findElement.unnamedConstructor('C');
    var x = findElement.localFunction('x');
    expect(x.enclosingElement, constructor);
  }
}

/// Tests for generic method and function resolution that do not use strong
/// mode.
@reflectiveTest
class GenericMethodResolverTest extends StaticTypeAnalyzer2TestShared {
  test_genericMethod_propagatedType_promotion() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340
    //
    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // strong mode example won't work, as we now compute a static type and
    // therefore discard the propagated type.
    //
    // So this test does not use strong mode.
    await assertNoErrorsInCode(r'''
abstract class Iter {
  List<S> map<S>(S f(x));
}
class C {}
C toSpan(dynamic element) {
  if (element is Iter) {
    var y = element.map(toSpan);
  }
  return null;
}''');
    expectIdentifierType('y = ', 'dynamic');
  }
}

@reflectiveTest
class LibraryImportScopeTest extends ResolverTestCase {
  void test_creation_empty() {
    LibraryImportScope(createDefaultTestLibrary());
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = TestAnalysisContext();
    String importedTypeName = "A";
    ClassElement importedType = ClassElementImpl(importedTypeName, -1);
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    Scope scope = LibraryImportScope(definingLibrary);
    expect(
        scope.lookup(
            AstTestFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
  }

  void test_extensions_imported() {
    var context = TestAnalysisContext();

    var extension = ElementFactory.extensionElement('test_extension');

    var importedUnit1 = ElementFactory.compilationUnit('/imported1.dart');
    importedUnit1.extensions = <ExtensionElement>[extension];

    var importedLibraryName = 'imported_lib';
    var importedLibrary = LibraryElementImpl(context, null, importedLibraryName,
        0, importedLibraryName.length, false);
    importedLibrary.definingCompilationUnit = importedUnit1;

    var importingLibraryName = 'importing_lib';
    var importingLibrary = LibraryElementImpl(context, null,
        importingLibraryName, 0, importingLibraryName.length, false);
    importingLibrary.definingCompilationUnit =
        ElementFactory.compilationUnit('/importing.dart');

    var importElement = ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    importingLibrary.imports = <ImportElement>[importElement];

    expect(
        LibraryImportScope(importingLibrary).extensions, contains(extension));
  }

  void test_prefixedAndNonPrefixed() {
    AnalysisContext context = TestAnalysisContext();
    String typeName = "C";
    String prefixName = "p";
    ClassElement prefixedType = ElementFactory.classElement2(typeName);
    ClassElement nonPrefixedType = ElementFactory.classElement2(typeName);
    LibraryElement prefixedLibrary =
        createTestLibrary(context, "import.prefixed");
    (prefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[prefixedType];
    ImportElementImpl prefixedImport = ElementFactory.importFor(
        prefixedLibrary, ElementFactory.prefix(prefixName));
    LibraryElement nonPrefixedLibrary =
        createTestLibrary(context, "import.nonPrefixed");
    (nonPrefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[nonPrefixedType];
    ImportElementImpl nonPrefixedImport =
        ElementFactory.importFor(nonPrefixedLibrary, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[
      prefixedImport,
      nonPrefixedImport
    ];
    Scope scope = LibraryImportScope(importingLibrary);
    Element prefixedElement = scope.lookup(
        AstTestFactory.identifier5(prefixName, typeName), importingLibrary);
    expect(prefixedElement, same(prefixedType));
    Element nonPrefixedElement =
        scope.lookup(AstTestFactory.identifier3(typeName), importingLibrary);
    expect(nonPrefixedElement, same(nonPrefixedType));
  }
}

@reflectiveTest
class LibraryScopeTest extends ResolverTestCase {
  void test_creation_empty() {
    LibraryScope(createDefaultTestLibrary());
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = TestAnalysisContext();
    String importedTypeName = "A";
    ClassElement importedType = ClassElementImpl(importedTypeName, -1);
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    Scope scope = LibraryScope(definingLibrary);
    expect(
        scope.lookup(
            AstTestFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
  }

  void test_extensions() {
    ExtensionElement extension =
        ElementFactory.extensionElement('test_extension');

    CompilationUnitElementImpl compilationUnit =
        ElementFactory.compilationUnit('/test.dart');
    compilationUnit.extensions = <ExtensionElement>[extension];

    String libraryName = 'lib';
    LibraryElementImpl library = LibraryElementImpl(
        null, null, libraryName, 0, libraryName.length, false);
    library.definingCompilationUnit = compilationUnit;

    expect(LibraryScope(library).extensions, contains(extension));
  }

  void test_extensions_imported() {
    var context = TestAnalysisContext();

    var importedUnit1 = ElementFactory.compilationUnit('/imported1.dart');
    var importedExtension = ElementFactory.extensionElement('test_extension');
    var unnamedImportedExtension = ElementFactory.extensionElement();
    importedUnit1.extensions = [importedExtension, unnamedImportedExtension];

    var importedLibraryName = 'imported_lib';
    var importedLibrary = LibraryElementImpl(context, null, importedLibraryName,
        0, importedLibraryName.length, false);
    importedLibrary.definingCompilationUnit = importedUnit1;

    var importingLibraryName = 'importing_lib';
    var importingLibrary = LibraryElementImpl(context, null,
        importingLibraryName, 0, importingLibraryName.length, false);

    var localExtension = ElementFactory.extensionElement('test_extension');

    var importingUnit = ElementFactory.compilationUnit('/importing.dart');
    importingUnit.extensions = [localExtension];
    importingLibrary.definingCompilationUnit = importingUnit;

    var importElement = ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    importingLibrary.imports = [importElement];

    var libraryExtensions = LibraryScope(importingLibrary).extensions;

    expect(libraryExtensions, contains(localExtension));
    expect(libraryExtensions, contains(importedExtension));
    expect(libraryExtensions, isNot(contains(unnamedImportedExtension)));
  }

  /// Ensure that if a library L1 defines an extension E, L2 exports L1, and L3
  /// imports L2, then E is included in the list.
  void test_extensions_imported_chain() {
    var context = TestAnalysisContext();

    var unit1 = ElementFactory.compilationUnit('/unit1.dart');
    var ext1 = ElementFactory.extensionElement('ext1');
    unit1.extensions = [ext1];

    var lib1Name = 'lib1';
    var lib1 =
        LibraryElementImpl(context, null, lib1Name, 0, lib1Name.length, false);
    lib1.definingCompilationUnit = unit1;

    var unit2 = ElementFactory.compilationUnit('/unit2.dart');

    var lib2Name = 'lib2';
    var lib2 =
        LibraryElementImpl(context, null, lib2Name, 0, lib2Name.length, false);
    lib2.definingCompilationUnit = unit2;

    var lib1Export = ExportElementImpl(0);
    lib1Export.exportedLibrary = lib1;
    lib2.exports = [lib1Export];

    var importingLibraryName = 'importing_lib';
    var importingLibrary = LibraryElementImpl(context, null,
        importingLibraryName, 0, importingLibraryName.length, false);

    var importingUnit = ElementFactory.compilationUnit('/importing.dart');
    importingLibrary.definingCompilationUnit = importingUnit;

    var lib2Import = ImportElementImpl(0);
    lib2Import.importedLibrary = lib2;
    importingLibrary.imports = [lib2Import];

    var libraryExtensions = LibraryScope(importingLibrary).extensions;

    expect(libraryExtensions, orderedEquals([ext1]));
  }

  /// Ensure that if there are two extensions with the same name that are
  /// imported from different libraries that they are both in the list of
  /// extensions.
  void test_extensions_imported_same_name() {
    var context = TestAnalysisContext();

    var sharedExtensionName = 'test_ext';

    var unit1 = ElementFactory.compilationUnit('/unit1.dart');
    var ext1 = ElementFactory.extensionElement(sharedExtensionName);
    unit1.extensions = [ext1];

    var lib1Name = 'lib1';
    var lib1 =
        LibraryElementImpl(context, null, lib1Name, 0, lib1Name.length, false);
    lib1.definingCompilationUnit = unit1;

    var unit2 = ElementFactory.compilationUnit('/unit2.dart');
    var ext2 = ElementFactory.extensionElement(sharedExtensionName);
    unit2.extensions = [ext2];

    var lib2Name = 'lib2';
    var lib2 =
        LibraryElementImpl(context, null, lib2Name, 0, lib2Name.length, false);
    lib2.definingCompilationUnit = unit2;

    var importingLibraryName = 'importing_lib';
    var importingLibrary = LibraryElementImpl(context, null,
        importingLibraryName, 0, importingLibraryName.length, false);

    var importingUnit = ElementFactory.compilationUnit('/importing.dart');
    importingLibrary.definingCompilationUnit = importingUnit;

    var importElement1 = ImportElementImpl(0);
    importElement1.importedLibrary = lib1;
    var importElement2 = ImportElementImpl(0);
    importElement2.importedLibrary = lib2;
    importingLibrary.imports = [importElement1, importElement2];

    var libraryExtensions = LibraryScope(importingLibrary).extensions;

    expect(libraryExtensions, contains(ext1));
    expect(libraryExtensions, contains(ext2));
  }

  /// Ensure that if there are two imports for the same library that the
  /// imported extension is only in the list one time.
  void test_extensions_imported_twice() {
    var context = TestAnalysisContext();

    var sharedExtensionName = 'test_ext';

    var unit1 = ElementFactory.compilationUnit('/unit1.dart');
    var ext1 = ElementFactory.extensionElement(sharedExtensionName);
    unit1.extensions = [ext1];

    var lib1Name = 'lib1';
    var lib1 =
        LibraryElementImpl(context, null, lib1Name, 0, lib1Name.length, false);
    lib1.definingCompilationUnit = unit1;

    var importingLibraryName = 'importing_lib';
    var importingLibrary = LibraryElementImpl(context, null,
        importingLibraryName, 0, importingLibraryName.length, false);

    var importingUnit = ElementFactory.compilationUnit('/importing.dart');
    importingLibrary.definingCompilationUnit = importingUnit;

    var importElement1 = ImportElementImpl(0);
    importElement1.importedLibrary = lib1;
    var importElement2 = ImportElementImpl(0);
    importElement2.importedLibrary = lib1;
    importingLibrary.imports = [importElement1, importElement2];

    var libraryExtensions = LibraryScope(importingLibrary).extensions;
    expect(libraryExtensions, orderedEquals([ext1]));
  }
}

@reflectiveTest
class PrefixedNamespaceTest extends DriverResolutionTest {
  void test_lookup_missing() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p.B'), isNull);
  }

  void test_lookup_missing_matchesPrefix() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p'), isNull);
  }

  void test_lookup_valid() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p.A'), same(element));
  }

  Map<String, Element> _toMap(List<Element> elements) {
    Map<String, Element> map = HashMap<String, Element>();
    for (Element element in elements) {
      map[element.name] = element;
    }
    return map;
  }
}

@reflectiveTest
class ScopeTest extends DriverResolutionTest {
  void test_define_duplicate() {
    Scope scope = _RootScope();
    SimpleIdentifier identifier = AstTestFactory.identifier3('v');
    VariableElement element1 = ElementFactory.localVariableElement(identifier);
    VariableElement element2 = ElementFactory.localVariableElement(identifier);
    scope.define(element1);
    scope.define(element2);
    expect(scope.localLookup('v'), same(element1));
  }

  void test_isPrivateName_nonPrivate() {
    expect(Scope.isPrivateName("Public"), isFalse);
  }

  void test_isPrivateName_private() {
    expect(Scope.isPrivateName("_Private"), isTrue);
  }
}

/// Instances of the class `StaticTypeVerifier` verify that all of the nodes in
/// an AST structure that should have a static type associated with them do have
/// a static type.
class StaticTypeVerifier extends GeneralizingAstVisitor<void> {
  /// A list containing all of the AST Expression nodes that were not resolved.
  final List<Expression> _unresolvedExpressions = <Expression>[];

  /// The TypeAnnotation nodes that were not resolved.
  final List<TypeAnnotation> _unresolvedTypes = <TypeAnnotation>[];

  /// Counter for the number of Expression nodes visited that are resolved.
  int _resolvedExpressionCount = 0;

  /// Counter for the number of TypeName nodes visited that are resolved.
  int _resolvedTypeCount = 0;

  /// Assert that all of the visited nodes have a static type associated with
  /// them.
  void assertResolved() {
    if (_unresolvedExpressions.isNotEmpty || _unresolvedTypes.isNotEmpty) {
      StringBuffer buffer = StringBuffer();
      int unresolvedTypeCount = _unresolvedTypes.length;
      if (unresolvedTypeCount > 0) {
        buffer.write("Failed to resolve ");
        buffer.write(unresolvedTypeCount);
        buffer.write(" of ");
        buffer.write(_resolvedTypeCount + unresolvedTypeCount);
        buffer.writeln(" type names:");
        for (TypeAnnotation identifier in _unresolvedTypes) {
          buffer.write("  ");
          buffer.write(identifier.toString());
          buffer.write(" (");
          buffer.write(_getFileName(identifier));
          buffer.write(" : ");
          buffer.write(identifier.offset);
          buffer.writeln(")");
        }
      }
      int unresolvedExpressionCount = _unresolvedExpressions.length;
      if (unresolvedExpressionCount > 0) {
        buffer.writeln("Failed to resolve ");
        buffer.write(unresolvedExpressionCount);
        buffer.write(" of ");
        buffer.write(_resolvedExpressionCount + unresolvedExpressionCount);
        buffer.writeln(" expressions:");
        for (Expression expression in _unresolvedExpressions) {
          buffer.write("  ");
          buffer.write(expression.toString());
          buffer.write(" (");
          buffer.write(_getFileName(expression));
          buffer.write(" : ");
          buffer.write(expression.offset);
          buffer.writeln(")");
        }
      }
      fail(buffer.toString());
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {}

  @override
  void visitCommentReference(CommentReference node) {}

  @override
  void visitContinueStatement(ContinueStatement node) {}

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitExpression(Expression node) {
    node.visitChildren(this);
    DartType staticType = node.staticType;
    if (staticType == null) {
      _unresolvedExpressions.add(node);
    } else {
      _resolvedExpressionCount++;
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {}

  @override
  void visitLabel(Label node) {}

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // In cases where we have a prefixed identifier where the prefix is dynamic,
    // we don't want to assert that the node will have a type.
    if (node.staticType == null && node.prefix.staticType.isDynamic) {
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // In cases where identifiers are being used for something other than an
    // expressions, then they can be ignored.
    AstNode parent = node.parent;
    if (parent is MethodInvocation && identical(node, parent.methodName)) {
      return;
    } else if (parent is RedirectingConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return;
    } else if (parent is SuperConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return;
    } else if (parent is ConstructorName && identical(node, parent.name)) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        identical(node, parent.fieldName)) {
      return;
    } else if (node.staticElement is PrefixElement) {
      // Prefixes don't have a type.
      return;
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitTypeAnnotation(TypeAnnotation node) {
    if (node.type == null) {
      _unresolvedTypes.add(node);
    } else {
      _resolvedTypeCount++;
    }
    super.visitTypeAnnotation(node);
  }

  @override
  void visitTypeName(TypeName node) {
    // Note: do not visit children from this node, the child SimpleIdentifier in
    // TypeName (i.e. "String") does not have a static type defined.
    // TODO(brianwilkerson) Not visiting the children means that we won't catch
    // type arguments that were not resolved.
    if (node.type == null) {
      _unresolvedTypes.add(node);
    } else {
      _resolvedTypeCount++;
    }
  }

  String _getFileName(AstNode node) {
    // TODO (jwren) there are two copies of this method, one here and one in
    // ResolutionVerifier, they should be resolved into a single method
    if (node != null) {
      AstNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = root;
        if (rootCU.declaredElement != null) {
          return rootCU.declaredElement.source.fullName;
        } else {
          return "<unknown file- CompilationUnit.getElement() returned null>";
        }
      } else {
        return "<unknown file- CompilationUnit.getRoot() is not a CompilationUnit>";
      }
    }
    return "<unknown file- ASTNode is null>";
  }
}

/// The class `StrictModeTest` contains tests to ensure that the correct errors
/// and warnings are reported when the analysis engine is run in strict mode.
@reflectiveTest
class StrictModeTest extends DriverResolutionTest {
  test_assert_is() async {
    await assertErrorsInCode(r'''
int f(num n) {
  assert (n is int);
  return n & 0x0F;
}''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 47, 1),
    ]);
  }

  test_conditional_and_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is int && n > 0) ? n & 0x0F : 0;
}''');
  }

  test_conditional_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is int) ? n & 0x0F : 0;
}''');
  }

  test_conditional_isNot() async {
    await assertErrorsInCode(r'''
int f(num n) {
  return (n is! int) ? 0 : n & 0x0F;
}''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 44, 1),
    ]);
  }

  test_conditional_or_is() async {
    await assertErrorsInCode(r'''
int f(num n) {
  return (n is! int || n < 0) ? 0 : n & 0x0F;
}''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 53, 1),
    ]);
  }

//  @failingTest
  test_for() async {
    await assertErrorsInCode(r'''
int f(List<int> list) {
  num sum = 0;
  for (num i = 0; i < list.length; i++) {
    sum += list[i];
  }
}''', [
      error(HintCode.MISSING_RETURN, 4, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 3),
    ]);
  }

  test_forEach() async {
    await assertErrorsInCode(r'''
int f(List<int> list) {
  num sum = 0;
  for (num n in list) {
    sum += n & 0x0F;
  }
}''', [
      error(HintCode.MISSING_RETURN, 4, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 3),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 76, 1),
    ]);
  }

  test_if_and_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is int && n > 0) {
    return n & 0x0F;
  }
  return 0;
}''');
  }

  test_if_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is int) {
    return n & 0x0F;
  }
  return 0;
}''');
  }

  test_if_isNot() async {
    await assertErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 72, 1),
    ]);
  }

  test_if_isNot_abrupt() async {
    await assertErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  }
  return n & 0x0F;
}''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 63, 1),
    ]);
  }

  test_if_or_is() async {
    await assertErrorsInCode(r'''
int f(num n) {
  if (n is! int || n < 0) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 81, 1),
    ]);
  }

  test_localVar() async {
    await assertErrorsInCode(r'''
int f() {
  num n = 1234;
  return n & 0x0F;
}''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 37, 1),
    ]);
  }
}

@reflectiveTest
class TypePropagationTest extends DriverResolutionTest {
  test_assignment_null() async {
    String code = r'''
main() {
  int v; // declare
  v = null;
  return v; // return
}''';
    await resolveTestCode(code);
    assertType(findElement.localVar('v').type, 'int');
    assertTypeNull(findNode.simple('v; // declare'));
    assertType(findNode.simple('v = null;'), 'int');
    assertType(findNode.simple('v; // return'), 'int');
  }

  test_functionExpression_asInvocationArgument_notSubtypeOfStaticType() async {
    await assertErrorsInCode(r'''
class A {
  m(void f(int i)) {}
}
x() {
  A a = new A();
  a.m(() => 0);
}''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 63, 7),
    ]);
    assertType(findNode.functionExpression('() => 0'), 'int Function()');
  }

  test_initializer_hasStaticType() async {
    await resolveTestCode(r'''
f() {
  int v = 0;
  return v;
}''');
    assertType(findElement.localVar('v').type, 'int');
    assertTypeNull(findNode.simple('v = 0;'));
    assertType(findNode.simple('v;'), 'int');
  }

  test_initializer_hasStaticType_parameterized() async {
    await resolveTestCode(r'''
f() {
  List<int> v = <int>[];
  return v;
}''');
    assertType(findElement.localVar('v').type, 'List<int>');
    assertTypeNull(findNode.simple('v ='));
    assertType(findNode.simple('v;'), 'List<int>');
  }

  test_initializer_null() async {
    await resolveTestCode(r'''
main() {
  int v = null;
  return v;
}''');
    assertType(findElement.localVar('v').type, 'int');
    assertTypeNull(findNode.simple('v ='));
    assertType(findNode.simple('v;'), 'int');
  }

  test_invocation_target_prefixed() async {
    newFile('/test/lib/a.dart', content: r'''
int max(int x, int y) => 0;
''');
    await resolveTestCode('''
import 'a.dart' as helper;
main() {
  helper.max(10, 10); // marker
}''');
    assertElement(
      findNode.simple('max(10, 10)'),
      findElement.importFind('package:test/a.dart').topFunction('max'),
    );
  }

  test_is_subclass() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  B m() => this;
}
A f(A p) {
  if (p is B) {
    return p.m();
  }
  return p;
}''');
    assertElement(
      findNode.methodInvocation('p.m()'),
      findElement.method('m', of: 'B'),
    );
  }

  test_mutatedOutsideScope() async {
    // https://code.google.com/p/dart/issues/detail?id=22732
    await assertNoErrorsInCode(r'''
class Base {
}

class Derived extends Base {
  get y => null;
}

class C {
  void f() {
    Base x = null;
    if (x is Derived) {
      print(x.y); // BAD
    }
    x = null;
  }
}

void g() {
  Base x = null;
  if (x is Derived) {
    print(x.y); // GOOD
  }
  x = null;
}''');
  }

  test_objectAccessInference_disabled_for_library_prefix() async {
    newFile('/test/lib/a.dart', content: '''
dynamic get hashCode => 42;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as helper;
main() {
  helper.hashCode;
}''');
    assertTypeDynamic(findNode.prefixed('helper.hashCode'));
  }

  test_objectAccessInference_disabled_for_local_getter() async {
    await assertNoErrorsInCode('''
dynamic get hashCode => null;
main() {
  hashCode; // marker
}''');
    assertTypeDynamic(findNode.simple('hashCode; // marker'));
  }

  test_objectMethodInference_disabled_for_library_prefix() async {
    newFile('/test/lib/a.dart', content: '''
dynamic toString = (int x) => x + 42;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as helper;
main() {
  helper.toString();
}''');
    assertTypeDynamic(
      findNode.functionExpressionInvocation('helper.toString()'),
    );
  }

  test_objectMethodInference_disabled_for_local_function() async {
    await resolveTestCode('''
main() {
  dynamic toString = () => null;
  toString(); // marker
}''');
    assertTypeDynamic(findElement.localVar('toString').type);
    assertTypeNull(findNode.simple('toString ='));
    assertTypeDynamic(findNode.simple('toString(); // marker'));
  }

  @failingTest
  test_propagatedReturnType_functionExpression() async {
    // TODO(scheglov) disabled because we don't resolve function expression
    await resolveTestCode(r'''
main() {
  var v = (() {return 42;})();
}''');
    assertTypeDynamic(findNode.simple('v = '));
  }
}

class _RootScope extends Scope {
  @override
  Element internalLookup(String name) => null;
}
