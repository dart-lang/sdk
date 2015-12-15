// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summary_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/builder.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/summarize_elements.dart'
    as summarize_elements;
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(SummarizeElementsTest);
}

/**
 * Override of [SummaryTest] which creates summaries from the element model.
 */
@reflectiveTest
class SummarizeElementsTest extends ResolverTestCase with SummaryTest {
  @override
  bool get checkAstDerivedData => false;

  /**
   * Serialize the library containing the given class [element], then
   * deserialize it and return the summary of the class.
   */
  UnlinkedClass serializeClassElement(ClassElement element) {
    serializeLibraryElement(element.library);
    return findClass(element.name, failIfAbsent: true);
  }

  /**
   * Serialize the given [library] element, then deserialize it and store the
   * resulting summary in [lib].
   */
  void serializeLibraryElement(LibraryElement library) {
    BuilderContext builderContext = new BuilderContext();
    PrelinkedLibraryBuilder serializedLib = summarize_elements.serializeLibrary(
        builderContext, library, typeProvider);
    List<int> encodedLib = serializedLib.toBuffer();
    lib = new PrelinkedLibrary.fromBuffer(encodedLib);
  }

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Source source = addSource(text);
    LibraryElement library = resolve2(source);
    if (!allowErrors) {
      assertNoErrors(source);
    }
    serializeLibraryElement(library);
    expect(definingUnit.unlinked.imports.length, lib.importDependencies.length);
    for (PrelinkedUnit unit in lib.units) {
      expect(unit.unlinked.references.length, unit.references.length);
    }
  }

  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableGenericMethods = true;
    resetWithOptions(options);
  }

  test_class_no_superclass() {
    UnlinkedClass cls = serializeClassElement(typeProvider.objectType.element);
    expect(cls.supertype, isNull);
  }
}

/**
 * Base class containing most summary tests.  This allows summary tests to be
 * re-used to exercise all the different ways in which summaries can be
 * generated (e.g. direct from the AST, from the element model, from a
 * "relinking" process, etc.)
 */
abstract class SummaryTest {
  /**
   * The result of serializing and then deserializing the library under test.
   */
  PrelinkedLibrary lib;

  /**
   * `true` if the summary was created directly from the AST (and hence
   * contains information that is not obtainable from the element model alone).
   * TODO(paulberry): modify the element model so that it contains all the data
   * that summaries need, so that this flag is no longer needed.
   */
  bool get checkAstDerivedData;

  /**
   * Get access to the prelinked defining compilation unit.
   */
  PrelinkedUnit get definingUnit => lib.units[0];

  /**
   * Get access to the "unlinked" section of the summary.
   */
  UnlinkedLibrary get unlinked => lib.unlinked;

  /**
   * Convert [path] to a suitably formatted absolute path URI for the current
   * platform.
   */
  String absUri(String path) {
    return FileUtilities2.createFile(path).toURI().toString();
  }

  /**
   * Add the given source file so that it may be referenced by the file under
   * test.
   */
  addNamedSource(String filePath, String contents);

  /**
   * Verify that the [combinatorName] correctly represents the given [expected]
   * name.
   */
  void checkCombinatorName(
      UnlinkedCombinatorName combinatorName, String expected) {
    expect(combinatorName, new isInstanceOf<UnlinkedCombinatorName>());
    expect(combinatorName.name, expected);
  }

  /**
   * Verify that the [dependency]th element of the dependency table represents
   * a file reachable via the given [absoluteUri] and [relativeUri].
   */
  void checkDependency(int dependency, String absoluteUri, String relativeUri) {
    if (!checkAstDerivedData) {
      // The element model doesn't (yet) store enough information to recover
      // relative URIs, so we have to use the absolute URI.
      // TODO(paulberry): fix this.
      relativeUri = absoluteUri;
    }
    expect(dependency, new isInstanceOf<int>());
    expect(lib.dependencies[dependency].uri, relativeUri);
  }

  /**
   * Verify that the given [typeRef] represents the type `dynamic`.
   */
  void checkDynamicTypeRef(UnlinkedTypeRef typeRef) {
    checkTypeRef(typeRef, null, null, null);
  }

  /**
   * Verify that the dependency table contains an entry for a file reachable
   * via the given [absoluteUri] and [relativeUri].
   */
  void checkHasDependency(String absoluteUri, String relativeUri) {
    if (!checkAstDerivedData) {
      // The element model doesn't (yet) store enough information to recover
      // relative URIs, so we have to use the absolute URI.
      // TODO(paulberry): fix this.
      relativeUri = absoluteUri;
    }
    for (PrelinkedDependency dep in lib.dependencies) {
      if (dep.uri == relativeUri) {
        return;
      }
    }
    fail('Did not find dependency $absoluteUri');
  }

  /**
   * Verify that the dependency table *does not* contain any entries for a file
   * reachable via the given [absoluteUri] and [relativeUri].
   */
  void checkLacksDependency(String absoluteUri, String relativeUri) {
    if (!checkAstDerivedData) {
      // The element model doesn't (yet) store enough information to recover
      // relative URIs, so we have to use the absolute URI.
      // TODO(paulberry): fix this.
      relativeUri = absoluteUri;
    }
    for (PrelinkedDependency dep in lib.dependencies) {
      if (dep.uri == relativeUri) {
        fail('Unexpected dependency found: $relativeUri');
      }
    }
  }

  /**
   * Verify that the given [typeRef] represents a reference to a type parameter
   * having the given [deBruijnIndex].
   */
  void checkParamTypeRef(UnlinkedTypeRef typeRef, int deBruijnIndex) {
    expect(typeRef, new isInstanceOf<UnlinkedTypeRef>());
    expect(typeRef.reference, 0);
    expect(typeRef.typeArguments, isEmpty);
    expect(typeRef.paramReference, deBruijnIndex);
  }

  /**
   * Verify that the given [typeRef] represents a reference to a type declared
   * in a file reachable via [absoluteUri] and [relativeUri], having name
   * [expectedName].  If [expectedPrefix] is supplied, verify that the type is
   * reached via the given prefix.  If [allowTypeParameters] is true, allow the
   * type reference to supply type parameters.  [expectedKind] is the kind of
   * object referenced.  [sourceUnit] is the compilation unit within which the
   * [typeRef] appears; if not specified it is assumed to be the defining
   * compilation unit.  [expectedTargetUnit] is the index of the compilation
   * unit in which the target of the [typeRef] is expected to appear; if not
   * specified it is assumed to be the defining compilation unit.
   */
  void checkTypeRef(UnlinkedTypeRef typeRef, String absoluteUri,
      String relativeUri, String expectedName,
      {String expectedPrefix,
      bool allowTypeParameters: false,
      PrelinkedReferenceKind expectedKind: PrelinkedReferenceKind.classOrEnum,
      int expectedTargetUnit: 0,
      PrelinkedUnit sourceUnit}) {
    sourceUnit ??= definingUnit;
    expect(typeRef, new isInstanceOf<UnlinkedTypeRef>());
    expect(typeRef.paramReference, 0);
    int index = typeRef.reference;
    UnlinkedReference reference = sourceUnit.unlinked.references[index];
    PrelinkedReference referenceResolution = sourceUnit.references[index];
    if (index == 0) {
      // Index 0 is reserved for "dynamic".
      expect(reference.name, isEmpty);
      expect(reference.prefix, 0);
    }
    if (absoluteUri == null) {
      expect(referenceResolution.dependency, 0);
    } else {
      checkDependency(referenceResolution.dependency, absoluteUri, relativeUri);
    }
    if (!allowTypeParameters) {
      expect(typeRef.typeArguments, isEmpty);
    }
    if (expectedName == null) {
      expect(reference.name, isEmpty);
    } else {
      expect(reference.name, expectedName);
    }
    if (checkAstDerivedData) {
      if (expectedPrefix == null) {
        expect(reference.prefix, 0);
        expect(unlinked.prefixes[reference.prefix].name, isEmpty);
      } else {
        expect(reference.prefix, isNot(0));
        expect(unlinked.prefixes[reference.prefix].name, expectedPrefix);
      }
    }
    expect(referenceResolution.kind, expectedKind);
    expect(referenceResolution.unit, expectedTargetUnit);
  }

  /**
   * Verify that the given [typeRef] represents a reference to an unresolved
   * type.
   */
  void checkUnresolvedTypeRef(
      UnlinkedTypeRef typeRef, String expectedPrefix, String expectedName) {
    // When serializing from the element model, unresolved type refs lose their
    // name.
    checkTypeRef(typeRef, null, null, checkAstDerivedData ? expectedName : null,
        expectedPrefix: expectedPrefix,
        expectedKind: PrelinkedReferenceKind.unresolved);
  }

  fail_test_import_missing() {
    // TODO(paulberry): At the moment unresolved imports are not included in
    // the element model, so we can't pass this test.
    // Unresolved imports are included since this is necessary for proper
    // dependency tracking.
    serializeLibraryText('import "foo.dart";', allowErrors: true);
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    checkDependency(lib.importDependencies[0], absUri('/foo.dart'), 'foo.dart');
  }

  /**
   * Find the class with the given [className] in the summary, and return its
   * [UnlinkedClass] data structure.  If [unit] is not given, the class is
   * looked for in the defining compilation unit.
   */
  UnlinkedClass findClass(String className,
      {bool failIfAbsent: false, PrelinkedUnit unit}) {
    unit ??= definingUnit;
    UnlinkedClass result;
    for (UnlinkedClass cls in unit.unlinked.classes) {
      if (cls.name == className) {
        if (result != null) {
          fail('Duplicate class $className');
        }
        result = cls;
      }
    }
    if (result == null && failIfAbsent) {
      fail('Class $className not found in serialized output');
    }
    return result;
  }

  /**
   * Find the enum with the given [enumName] in the summary, and return its
   * [UnlinkedEnum] data structure.  If [unit] is not given, the enum is looked
   * for in the defining compilation unit.
   */
  UnlinkedEnum findEnum(String enumName,
      {bool failIfAbsent: false, PrelinkedUnit unit}) {
    unit ??= definingUnit;
    UnlinkedEnum result;
    for (UnlinkedEnum e in unit.unlinked.enums) {
      if (e.name == enumName) {
        if (result != null) {
          fail('Duplicate enum $enumName');
        }
        result = e;
      }
    }
    if (result == null && failIfAbsent) {
      fail('Enum $enumName not found in serialized output');
    }
    return result;
  }

  /**
   * Find the executable with the given [executableName] in the summary, and
   * return its [UnlinkedExecutable] data structure.  If [executables] is not
   * given, then the executable is searched for in the defining compilation
   * unit.
   */
  UnlinkedExecutable findExecutable(String executableName,
      {List<UnlinkedExecutable> executables, bool failIfAbsent: false}) {
    executables ??= definingUnit.unlinked.executables;
    UnlinkedExecutable result;
    for (UnlinkedExecutable executable in executables) {
      if (executable.name == executableName) {
        if (result != null) {
          fail('Duplicate executable $executableName');
        }
        result = executable;
      }
    }
    if (result == null && failIfAbsent) {
      fail('Executable $executableName not found in serialized output');
    }
    return result;
  }

  /**
   * Find the typedef with the given [typedefName] in the summary, and return
   * its [UnlinkedTypedef] data structure.  If [unit] is not given, the typedef
   * is looked for in the defining compilation unit.
   */
  UnlinkedTypedef findTypedef(String typedefName,
      {bool failIfAbsent: false, PrelinkedUnit unit}) {
    unit ??= definingUnit;
    UnlinkedTypedef result;
    for (UnlinkedTypedef type in unit.unlinked.typedefs) {
      if (type.name == typedefName) {
        if (result != null) {
          fail('Duplicate typedef $typedefName');
        }
        result = type;
      }
    }
    if (result == null && failIfAbsent) {
      fail('Typedef $typedefName not found in serialized output');
    }
    return result;
  }

  /**
   * Find the top level variable with the given [variableName] in the summary,
   * and return its [UnlinkedVariable] data structure.  If [variables] is not
   * specified, the variable is looked for in the defining compilation unit.
   */
  UnlinkedVariable findVariable(String variableName,
      {List<UnlinkedVariable> variables, bool failIfAbsent: false}) {
    variables ??= definingUnit.unlinked.variables;
    UnlinkedVariable result;
    for (UnlinkedVariable variable in variables) {
      if (variable.name == variableName) {
        if (result != null) {
          fail('Duplicate variable $variableName');
        }
        result = variable;
      }
    }
    if (result == null && failIfAbsent) {
      fail('Variable $variableName not found in serialized output');
    }
    return result;
  }

  /**
   * Serialize the given library [text] and return the summary of the class
   * with the given [className].
   */
  UnlinkedClass serializeClassText(String text, [String className = 'C']) {
    serializeLibraryText(text);
    return findClass(className, failIfAbsent: true);
  }

  /**
   * Serialize the given library [text] and return the summary of the enum with
   * the given [enumName].
   */
  UnlinkedEnum serializeEnumText(String text, [String enumName = 'E']) {
    serializeLibraryText(text);
    return findEnum(enumName, failIfAbsent: true);
  }

  /**
   * Serialize the given library [text] and return the summary of the
   * executable with the given [executableName].
   */
  UnlinkedExecutable serializeExecutableText(String text,
      [String executableName = 'f']) {
    serializeLibraryText(text);
    return findExecutable(executableName, failIfAbsent: true);
  }

  /**
   * Serialize the given library [text], then deserialize it and store its
   * summary in [lib].
   */
  void serializeLibraryText(String text, {bool allowErrors: false});

  /**
   * Serialize the given method [text] and return the summary of the executable
   * with the given [executableName].
   */
  UnlinkedExecutable serializeMethodText(String text,
      [String executableName = 'f']) {
    serializeLibraryText('class C { $text }');
    return findExecutable(executableName,
        executables: findClass('C', failIfAbsent: true).executables,
        failIfAbsent: true);
  }

  /**
   * Serialize the given library [text] and return the summary of the typedef
   * with the given [typedefName].
   */
  UnlinkedTypedef serializeTypedefText(String text,
      [String typedefName = 'F']) {
    serializeLibraryText(text);
    return findTypedef(typedefName, failIfAbsent: true);
  }

  /**
   * Serialize a type declaration using the given [text] as a type name, and
   * return a summary of the corresponding [UnlinkedTypeRef].  If the type
   * declaration needs to refer to types that are not available in core, those
   * types may be declared in [otherDeclarations].
   */
  UnlinkedTypeRef serializeTypeText(String text,
      {String otherDeclarations: '', bool allowErrors: false}) {
    return serializeVariableText('$otherDeclarations\n$text v;',
        allowErrors: allowErrors).type;
  }

  /**
   * Serialize the given library [text] and return the summary of the variable
   * with the given [variableName].
   */
  UnlinkedVariable serializeVariableText(String text,
      {String variableName: 'v', bool allowErrors: false}) {
    serializeLibraryText(text, allowErrors: allowErrors);
    return findVariable(variableName, failIfAbsent: true);
  }

  test_cascaded_export_hide_hide() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" hide C hide B, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib1.dart';
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(
        findVariable('a').type, absUri('/lib2.dart'), 'lib2.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_export_hide_show() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" hide C show A, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib1.dart';
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(
        findVariable('a').type, absUri('/lib2.dart'), 'lib2.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_export_show_hide() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" show A, B hide B, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib1.dart';
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(
        findVariable('a').type, absUri('/lib2.dart'), 'lib2.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_export_show_show() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" show A, B show A, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib1.dart';
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(
        findVariable('a').type, absUri('/lib2.dart'), 'lib2.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_hide_hide() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib.dart' hide C hide B, C;
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'lib.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_hide_show() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib.dart' hide C show A, C;
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'lib.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_show_hide() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib.dart' show A, B hide B, C;
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'lib.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_show_show() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText(
        '''
import 'lib.dart' show A, B show A, C;
A a;
B b;
C c;
    ''',
        allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'lib.dart', 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_class_abstract() {
    UnlinkedClass cls = serializeClassText('abstract class C {}');
    expect(cls.isAbstract, true);
  }

  test_class_alias_abstract() {
    UnlinkedClass cls = serializeClassText(
        'abstract class C = D with E; class D {} class E {}');
    expect(cls.isAbstract, true);
  }

  test_class_alias_concrete() {
    UnlinkedClass cls =
        serializeClassText('class C = D with E; class D {} class E {}');
    expect(cls.isAbstract, false);
  }

  test_class_alias_flag() {
    UnlinkedClass cls =
        serializeClassText('class C = D with E; class D {} class E {}');
    expect(cls.isMixinApplication, true);
  }

  test_class_alias_mixin_order() {
    UnlinkedClass cls = serializeClassText('''
class C = D with E, F;
class D {}
class E {}
class F {}
''');
    expect(cls.mixins, hasLength(2));
    checkTypeRef(cls.mixins[0], null, null, 'E');
    checkTypeRef(cls.mixins[1], null, null, 'F');
  }

  test_class_alias_no_implicit_constructors() {
    UnlinkedClass cls = serializeClassText('''
class C = D with E;
class D {
  D.foo();
  D.bar();
}
class E {}
''');
    expect(cls.executables, isEmpty);
  }

  test_class_alias_supertype() {
    UnlinkedClass cls =
        serializeClassText('class C = D with E; class D {} class E {}');
    checkTypeRef(cls.supertype, null, null, 'D');
  }

  test_class_concrete() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.isAbstract, false);
  }

  test_class_interface() {
    UnlinkedClass cls = serializeClassText('''
class C implements D {}
class D {}
''');
    expect(cls.interfaces, hasLength(1));
    checkTypeRef(cls.interfaces[0], null, null, 'D');
  }

  test_class_interface_order() {
    UnlinkedClass cls = serializeClassText('''
class C implements D, E {}
class D {}
class E {}
''');
    expect(cls.interfaces, hasLength(2));
    checkTypeRef(cls.interfaces[0], null, null, 'D');
    checkTypeRef(cls.interfaces[1], null, null, 'E');
  }

  test_class_mixin() {
    UnlinkedClass cls = serializeClassText('''
class C extends Object with D {}
class D {}
''');
    expect(cls.mixins, hasLength(1));
    checkTypeRef(cls.mixins[0], null, null, 'D');
  }

  test_class_mixin_order() {
    UnlinkedClass cls = serializeClassText('''
class C extends Object with D, E {}
class D {}
class E {}
''');
    expect(cls.mixins, hasLength(2));
    checkTypeRef(cls.mixins[0], null, null, 'D');
    checkTypeRef(cls.mixins[1], null, null, 'E');
  }

  test_class_name() {
    var classText = 'class C {}';
    UnlinkedClass cls = serializeClassText(classText);
    expect(cls.name, 'C');
  }

  test_class_no_flags() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.isAbstract, false);
    expect(cls.isMixinApplication, false);
  }

  test_class_no_interface() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.interfaces, isEmpty);
  }

  test_class_no_mixins() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.mixins, isEmpty);
  }

  test_class_no_type_param() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.typeParameters, isEmpty);
  }

  test_class_non_alias_flag() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.isMixinApplication, false);
  }

  test_class_superclass() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.supertype, isNull);
  }

  test_class_superclass_explicit() {
    UnlinkedClass cls = serializeClassText('class C extends D {} class D {}');
    expect(cls.supertype, isNotNull);
    checkTypeRef(cls.supertype, null, null, 'D');
  }

  test_class_type_param_bound() {
    UnlinkedClass cls = serializeClassText('class C<T extends List> {}');
    expect(cls.typeParameters, hasLength(1));
    expect(cls.typeParameters[0].name, 'T');
    expect(cls.typeParameters[0].bound, isNotNull);
    checkTypeRef(cls.typeParameters[0].bound, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true);
  }

  test_class_type_param_f_bound() {
    UnlinkedClass cls = serializeClassText('class C<T, U extends List<T>> {}');
    UnlinkedTypeRef typeArgument = cls.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 2);
  }

  test_class_type_param_f_bound_self_ref() {
    UnlinkedClass cls = serializeClassText('class C<T, U extends List<U>> {}');
    UnlinkedTypeRef typeArgument = cls.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 1);
  }

  test_class_type_param_no_bound() {
    UnlinkedClass cls = serializeClassText('class C<T> {}');
    expect(cls.typeParameters, hasLength(1));
    expect(cls.typeParameters[0].name, 'T');
    expect(cls.typeParameters[0].bound, isNull);
  }

  test_constructor() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(); }').executables);
    expect(executable.kind, UnlinkedExecutableKind.constructor);
    expect(executable.hasImplicitReturnType, isFalse);
  }

  test_constructor_anonymous() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(); }').executables);
    expect(executable.name, isEmpty);
  }

  test_constructor_const() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { const C(); }').executables);
    expect(executable.isConst, isTrue);
  }

  test_constructor_factory() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { factory C() => null; }').executables);
    expect(executable.isFactory, isTrue);
  }

  test_constructor_implicit() {
    // Implicit constructors are not serialized.
    UnlinkedExecutable executable = findExecutable(null,
        executables: serializeClassText('class C { C(); }').executables,
        failIfAbsent: false);
    expect(executable, isNull);
  }

  test_constructor_initializing_formal() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); final x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.isInitializingFormal, isTrue);
  }

  test_constructor_initializing_formal_explicit_type() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(int this.x); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    checkTypeRef(parameter.type, 'dart:core', 'dart:core', 'int');
  }

  test_constructor_initializing_formal_function_typed() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x()); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.isFunctionTyped, isTrue);
  }

  test_constructor_initializing_formal_function_typed_explicit_return_type() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(int this.x()); Function x; }')
                .executables);
    UnlinkedParam parameter = executable.parameters[0];
    checkTypeRef(parameter.type, 'dart:core', 'dart:core', 'int');
  }

  test_constructor_initializing_formal_function_typed_implicit_return_type() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x()); Function x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    // Since the parameter is function-typed it is considered to have an
    // explicit type, even though that explicit type itself has an implicit
    // return type.
    expect(parameter.hasImplicitType, isFalse);
    checkDynamicTypeRef(parameter.type);
  }

  test_constructor_initializing_formal_function_typed_no_prameters() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x()); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.parameters, isEmpty);
  }

  test_constructor_initializing_formal_function_typed_prameter() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x(a)); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.parameters, hasLength(1));
  }

  test_constructor_initializing_formal_function_typed_prameter_order() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x(a, b)); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.parameters, hasLength(2));
    expect(parameter.parameters[0].name, 'a');
    expect(parameter.parameters[1].name, 'b');
  }

  test_constructor_initializing_formal_implicit_type() {
    // Note: the implicit type of an initializing formal is the type of the
    // field.
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); int x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    checkTypeRef(parameter.type, 'dart:core', 'dart:core', 'int');
    expect(parameter.hasImplicitType, isTrue);
  }

  test_constructor_initializing_formal_name() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); final x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.name, 'x');
  }

  test_constructor_initializing_formal_named() {
    // TODO(paulberry): also test default value
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C({this.x}); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.named);
  }

  test_constructor_initializing_formal_non_function_typed() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); final x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.isFunctionTyped, isFalse);
  }

  test_constructor_initializing_formal_positional() {
    // TODO(paulberry): also test default value
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C([this.x]); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.positional);
  }

  test_constructor_initializing_formal_required() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); final x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.required);
  }

  test_constructor_named() {
    UnlinkedExecutable executable = findExecutable('foo',
        executables: serializeClassText('class C { C.foo(); }').executables);
    expect(executable.name, 'foo');
  }

  test_constructor_non_const() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(); }').executables);
    expect(executable.isConst, isFalse);
  }

  test_constructor_non_factory() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(); }').executables);
    expect(executable.isFactory, isFalse);
  }

  test_constructor_return_type() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(); }').executables);
    checkTypeRef(executable.returnType, null, null, 'C');
  }

  test_constructor_return_type_parameterized() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C<T, U> { C(); }').executables);
    checkTypeRef(executable.returnType, null, null, 'C',
        allowTypeParameters: true);
    expect(executable.returnType.typeArguments, hasLength(2));
    {
      UnlinkedTypeRef typeRef = executable.returnType.typeArguments[0];
      checkParamTypeRef(typeRef, 2);
    }
    {
      UnlinkedTypeRef typeRef = executable.returnType.typeArguments[1];
      checkParamTypeRef(typeRef, 1);
    }
  }

  test_dependencies_export_none() {
    // Exports are not listed as dependencies since no change to the exported
    // file can change the summary of the exporting file.
    addNamedSource('/a.dart', 'library a; export "b.dart";');
    addNamedSource('/b.dart', 'library b;');
    serializeLibraryText('export "a.dart";');
    checkLacksDependency(absUri('/a.dart'), 'a.dart');
    checkLacksDependency(absUri('/b.dart'), 'b.dart');
  }

  test_dependencies_import_to_export() {
    addNamedSource('/a.dart', 'library a; export "b.dart"; class A {}');
    addNamedSource('/b.dart', 'library b;');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'), 'a.dart');
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/b.dart'), 'b.dart');
  }

  test_dependencies_import_to_export_in_subdirs_absolute_export() {
    addNamedSource('/a/a.dart',
        'library a; export "${absUri('/a/b/b.dart')}"; class A {}');
    addNamedSource('/a/b/b.dart', 'library b;');
    serializeLibraryText('import "a/a.dart"; A a;');
    checkHasDependency(absUri('/a/a.dart'), 'a/a.dart');
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/a/b/b.dart'), '/a/b/b.dart');
  }

  test_dependencies_import_to_export_in_subdirs_absolute_import() {
    addNamedSource('/a/a.dart', 'library a; export "b/b.dart"; class A {}');
    addNamedSource('/a/b/b.dart', 'library b;');
    serializeLibraryText('import "${absUri('/a/a.dart')}"; A a;');
    checkHasDependency(absUri('/a/a.dart'), '/a/a.dart');
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/a/b/b.dart'), '/a/b/b.dart');
  }

  test_dependencies_import_to_export_in_subdirs_relative() {
    addNamedSource('/a/a.dart', 'library a; export "b/b.dart"; class A {}');
    addNamedSource('/a/b/b.dart', 'library b;');
    serializeLibraryText('import "a/a.dart"; A a;');
    checkHasDependency(absUri('/a/a.dart'), 'a/a.dart');
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/a/b/b.dart'), 'a/b/b.dart');
  }

  test_dependencies_import_to_export_loop() {
    addNamedSource('/a.dart', 'library a; export "b.dart"; class A {}');
    addNamedSource('/b.dart', 'library b; export "a.dart";');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'), 'a.dart');
    // Serialization should have been able to walk the transitive export
    // dependencies to b.dart without going into an infinite loop.
    checkHasDependency(absUri('/b.dart'), 'b.dart');
  }

  test_dependencies_import_to_export_transitive_closure() {
    addNamedSource('/a.dart', 'library a; export "b.dart"; class A {}');
    addNamedSource('/b.dart', 'library b; export "c.dart";');
    addNamedSource('/c.dart', 'library c;');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'), 'a.dart');
    // The main test library depends on c.dart, because names defined in
    // c.dart are exported by b.dart and then re-exported by a.dart.
    checkHasDependency(absUri('/c.dart'), 'c.dart');
  }

  test_dependencies_import_transitive_closure() {
    addNamedSource(
        '/a.dart', 'library a; import "b.dart"; class A extends B {}');
    addNamedSource('/b.dart', 'library b; class B {}');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'), 'a.dart');
    // The main test library doesn't depend on b.dart, because no change to
    // b.dart can possibly affect the serialized element model for it.
    checkLacksDependency(absUri('/b.dart'), 'b.dart');
  }

  test_elements_in_part() {
    addNamedSource(
        '/part1.dart',
        '''
part of my.lib;

class C {}
enum E { v }
var v;
f() {}
typedef F();
''');
    serializeLibraryText('library my.lib; part "part1.dart";');
    PrelinkedUnit unit = lib.units[1];
    expect(findClass('C', unit: unit), isNotNull);
    expect(findEnum('E', unit: unit), isNotNull);
    expect(findVariable('v', variables: unit.unlinked.variables), isNotNull);
    expect(
        findExecutable('f', executables: unit.unlinked.executables), isNotNull);
    expect(findTypedef('F', unit: unit), isNotNull);
  }

  test_enum() {
    UnlinkedEnum e = serializeEnumText('enum E { v1 }');
    expect(e.name, 'E');
    expect(e.values, hasLength(1));
    expect(e.values[0].name, 'v1');
  }

  test_enum_order() {
    UnlinkedEnum e = serializeEnumText('enum E { v1, v2 }');
    expect(e.values, hasLength(2));
    expect(e.values[0].name, 'v1');
    expect(e.values[1].name, 'v2');
  }

  test_executable_abstract() {
    UnlinkedExecutable executable =
        serializeClassText('abstract class C { f(); }').executables[0];
    expect(executable.isAbstract, isTrue);
  }

  test_executable_concrete() {
    UnlinkedExecutable executable =
        serializeClassText('abstract class C { f() {} }').executables[0];
    expect(executable.isAbstract, isFalse);
  }

  test_executable_function() {
    UnlinkedExecutable executable = serializeExecutableText('f() {}');
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.hasImplicitReturnType, isTrue);
    checkDynamicTypeRef(executable.returnType);
  }

  test_executable_function_explicit_return() {
    UnlinkedExecutable executable =
        serializeExecutableText('dynamic f() => null;');
    expect(executable.hasImplicitReturnType, isFalse);
    checkDynamicTypeRef(executable.returnType);
  }

  test_executable_getter() {
    UnlinkedExecutable executable = serializeExecutableText('int get f => 1;');
    expect(executable.kind, UnlinkedExecutableKind.getter);
    expect(executable.hasImplicitReturnType, isFalse);
    expect(findVariable('f'), isNull);
    expect(findExecutable('f='), isNull);
  }

  test_executable_getter_type() {
    UnlinkedExecutable executable = serializeExecutableText('int get f => 1;');
    checkTypeRef(executable.returnType, 'dart:core', 'dart:core', 'int');
    expect(executable.parameters, isEmpty);
  }

  test_executable_getter_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('get f => 1;');
    checkDynamicTypeRef(executable.returnType);
    expect(executable.hasImplicitReturnType, isTrue);
    expect(executable.parameters, isEmpty);
  }

  test_executable_member_function() {
    UnlinkedExecutable executable = findExecutable('f',
        executables: serializeClassText('class C { f() {} }').executables);
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.hasImplicitReturnType, isTrue);
  }

  test_executable_member_function_explicit_return() {
    UnlinkedExecutable executable = findExecutable('f',
        executables:
            serializeClassText('class C { dynamic f() => null; }').executables);
    expect(executable.hasImplicitReturnType, isFalse);
  }

  test_executable_member_getter() {
    UnlinkedClass cls = serializeClassText('class C { int get f => 1; }');
    UnlinkedExecutable executable =
        findExecutable('f', executables: cls.executables, failIfAbsent: true);
    expect(executable.kind, UnlinkedExecutableKind.getter);
    expect(executable.hasImplicitReturnType, isFalse);
    expect(findVariable('f', variables: cls.fields), isNull);
    expect(findExecutable('f=', executables: cls.executables), isNull);
  }

  test_executable_member_setter() {
    UnlinkedClass cls = serializeClassText('class C { void set f(value) {} }');
    UnlinkedExecutable executable =
        findExecutable('f=', executables: cls.executables, failIfAbsent: true);
    expect(executable.kind, UnlinkedExecutableKind.setter);
    // For setters, hasImplicitReturnType is always false.
    expect(executable.hasImplicitReturnType, isFalse);
    expect(findVariable('f', variables: cls.fields), isNull);
    expect(findExecutable('f', executables: cls.executables), isNull);
  }

  test_executable_member_setter_implicit_return() {
    UnlinkedClass cls = serializeClassText('class C { set f(value) {} }');
    UnlinkedExecutable executable =
        findExecutable('f=', executables: cls.executables, failIfAbsent: true);
    expect(executable.hasImplicitReturnType, isFalse);
    checkDynamicTypeRef(executable.returnType);
  }

  test_executable_name() {
    UnlinkedExecutable executable = serializeExecutableText('f() {}');
    expect(executable.name, 'f');
  }

  test_executable_no_flags() {
    UnlinkedExecutable executable = serializeExecutableText('f() {}');
    expect(executable.isAbstract, isFalse);
    expect(executable.isConst, isFalse);
    expect(executable.isFactory, isFalse);
    expect(executable.isStatic, isFalse);
  }

  test_executable_non_static() {
    UnlinkedExecutable executable =
        serializeClassText('class C { f() {} }').executables[0];
    expect(executable.isStatic, isFalse);
  }

  test_executable_non_static_top_level() {
    // Top level executables are considered non-static.
    UnlinkedExecutable executable = serializeExecutableText('f() {}');
    expect(executable.isStatic, isFalse);
  }

  test_executable_param_function_typed() {
    UnlinkedExecutable executable = serializeExecutableText('f(g()) {}');
    expect(executable.parameters[0].isFunctionTyped, isTrue);
    // Since the parameter is function-typed it is considered to have an
    // explicit type, even though that explicit type itself has an implicit
    // return type.
    expect(executable.parameters[0].hasImplicitType, isFalse);
  }

  test_executable_param_function_typed_explicit_return_type() {
    UnlinkedExecutable executable =
        serializeExecutableText('f(dynamic g()) {}');
    expect(executable.parameters[0].hasImplicitType, isFalse);
  }

  test_executable_param_function_typed_param() {
    UnlinkedExecutable executable = serializeExecutableText('f(g(x)) {}');
    expect(executable.parameters[0].parameters, hasLength(1));
  }

  test_executable_param_function_typed_param_none() {
    UnlinkedExecutable executable = serializeExecutableText('f(g()) {}');
    expect(executable.parameters[0].parameters, isEmpty);
  }

  test_executable_param_function_typed_param_order() {
    UnlinkedExecutable executable = serializeExecutableText('f(g(x, y)) {}');
    expect(executable.parameters[0].parameters, hasLength(2));
    expect(executable.parameters[0].parameters[0].name, 'x');
    expect(executable.parameters[0].parameters[1].name, 'y');
  }

  test_executable_param_function_typed_return_type() {
    UnlinkedExecutable executable = serializeExecutableText('f(int g()) {}');
    checkTypeRef(
        executable.parameters[0].type, 'dart:core', 'dart:core', 'int');
  }

  test_executable_param_function_typed_return_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('f(g()) {}');
    checkDynamicTypeRef(executable.parameters[0].type);
  }

  test_executable_param_function_typed_return_type_void() {
    UnlinkedExecutable executable = serializeExecutableText('f(void g()) {}');
    expect(executable.parameters[0].type, isNull);
  }

  test_executable_param_kind_named() {
    UnlinkedExecutable executable = serializeExecutableText('f({x}) {}');
    expect(executable.parameters[0].kind, UnlinkedParamKind.named);
  }

  test_executable_param_kind_positional() {
    UnlinkedExecutable executable = serializeExecutableText('f([x]) {}');
    expect(executable.parameters[0].kind, UnlinkedParamKind.positional);
  }

  test_executable_param_kind_required() {
    UnlinkedExecutable executable = serializeExecutableText('f(x) {}');
    expect(executable.parameters[0].kind, UnlinkedParamKind.required);
  }

  test_executable_param_name() {
    UnlinkedExecutable executable = serializeExecutableText('f(x) {}');
    expect(executable.parameters, hasLength(1));
    expect(executable.parameters[0].name, 'x');
  }

  test_executable_param_no_flags() {
    UnlinkedExecutable executable = serializeExecutableText('f(x) {}');
    expect(executable.parameters[0].isFunctionTyped, isFalse);
    expect(executable.parameters[0].isInitializingFormal, isFalse);
  }

  test_executable_param_non_function_typed() {
    UnlinkedExecutable executable = serializeExecutableText('f(g) {}');
    expect(executable.parameters[0].isFunctionTyped, isFalse);
  }

  test_executable_param_none() {
    UnlinkedExecutable executable = serializeExecutableText('f() {}');
    expect(executable.parameters, isEmpty);
  }

  test_executable_param_order() {
    UnlinkedExecutable executable = serializeExecutableText('f(x, y) {}');
    expect(executable.parameters, hasLength(2));
    expect(executable.parameters[0].name, 'x');
    expect(executable.parameters[1].name, 'y');
  }

  test_executable_param_type_explicit() {
    UnlinkedExecutable executable = serializeExecutableText('f(dynamic x) {}');
    checkDynamicTypeRef(executable.parameters[0].type);
    expect(executable.parameters[0].hasImplicitType, isFalse);
  }

  test_executable_param_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('f(x) {}');
    checkDynamicTypeRef(executable.parameters[0].type);
    expect(executable.parameters[0].hasImplicitType, isTrue);
  }

  test_executable_return_type() {
    UnlinkedExecutable executable = serializeExecutableText('int f() => 1;');
    checkTypeRef(executable.returnType, 'dart:core', 'dart:core', 'int');
    expect(executable.hasImplicitReturnType, isFalse);
  }

  test_executable_return_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('f() {}');
    checkDynamicTypeRef(executable.returnType);
    expect(executable.hasImplicitReturnType, isTrue);
  }

  test_executable_return_type_void() {
    UnlinkedExecutable executable = serializeExecutableText('void f() {}');
    expect(executable.returnType, isNull);
  }

  test_executable_setter() {
    UnlinkedExecutable executable =
        serializeExecutableText('void set f(value) {}', 'f=');
    expect(executable.kind, UnlinkedExecutableKind.setter);
    expect(executable.hasImplicitReturnType, isFalse);
    expect(findVariable('f'), isNull);
    expect(findExecutable('f'), isNull);
  }

  test_executable_setter_implicit_return() {
    UnlinkedExecutable executable =
        serializeExecutableText('set f(value) {}', 'f=');
    // For setters, hasImplicitReturnType is always false.
    expect(executable.hasImplicitReturnType, isFalse);
    checkDynamicTypeRef(executable.returnType);
  }

  test_executable_setter_type() {
    UnlinkedExecutable executable =
        serializeExecutableText('void set f(int value) {}', 'f=');
    expect(executable.returnType, isNull);
    expect(executable.parameters, hasLength(1));
    expect(executable.parameters[0].name, 'value');
    checkTypeRef(
        executable.parameters[0].type, 'dart:core', 'dart:core', 'int');
  }

  test_executable_static() {
    UnlinkedExecutable executable =
        serializeClassText('class C { static f() {} }').executables[0];
    expect(executable.isStatic, isTrue);
  }

  test_executable_type_param_f_bound() {
    // TODO(paulberry): also test top level executables.
    UnlinkedExecutable ex =
        serializeMethodText('void f<T, U extends List<T>>() {}');
    UnlinkedTypeRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 2);
  }

  test_executable_type_param_f_bound_self_ref() {
    // TODO(paulberry): also test top level executables.
    UnlinkedExecutable ex =
        serializeMethodText('void f<T, U extends List<U>>() {}');
    UnlinkedTypeRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 1);
  }

  test_executable_type_param_in_parameter() {
    // TODO(paulberry): also test top level executables.
    UnlinkedExecutable ex = serializeMethodText('void f<T>(T t) {}');
    checkParamTypeRef(ex.parameters[0].type, 1);
  }

  test_executable_type_param_in_return_type() {
    // TODO(paulberry): also test top level executables.
    UnlinkedExecutable ex = serializeMethodText('T f<T>() => null;');
    checkParamTypeRef(ex.returnType, 1);
  }

  test_export_hide_order() {
    serializeLibraryText('export "dart:async" hide Future, Stream;');
    expect(definingUnit.unlinked.exports, hasLength(1));
    expect(definingUnit.unlinked.exports[0].combinators, hasLength(1));
    expect(definingUnit.unlinked.exports[0].combinators[0].shows, isEmpty);
    expect(definingUnit.unlinked.exports[0].combinators[0].hides, hasLength(2));
    checkCombinatorName(
        definingUnit.unlinked.exports[0].combinators[0].hides[0], 'Future');
    checkCombinatorName(
        definingUnit.unlinked.exports[0].combinators[0].hides[1], 'Stream');
  }

  test_export_no_combinators() {
    serializeLibraryText('export "dart:async";');
    expect(definingUnit.unlinked.exports, hasLength(1));
    expect(definingUnit.unlinked.exports[0].combinators, isEmpty);
  }

  test_export_show_order() {
    serializeLibraryText('export "dart:async" show Future, Stream;');
    expect(definingUnit.unlinked.exports, hasLength(1));
    expect(definingUnit.unlinked.exports[0].combinators, hasLength(1));
    expect(definingUnit.unlinked.exports[0].combinators[0].shows, hasLength(2));
    expect(definingUnit.unlinked.exports[0].combinators[0].hides, isEmpty);
    checkCombinatorName(
        definingUnit.unlinked.exports[0].combinators[0].shows[0], 'Future');
    checkCombinatorName(
        definingUnit.unlinked.exports[0].combinators[0].shows[1], 'Stream');
  }

  test_export_uri() {
    addNamedSource('/a.dart', 'library my.lib;');
    String uriString = '"a.dart"';
    String libraryText = 'export $uriString;';
    serializeLibraryText(libraryText);
    expect(definingUnit.unlinked.exports, hasLength(1));
    expect(definingUnit.unlinked.exports[0].uri, 'a.dart');
  }

  test_field() {
    UnlinkedClass cls = serializeClassText('class C { int i; }');
    expect(findVariable('i', variables: cls.fields), isNotNull);
    expect(findExecutable('i', executables: cls.executables), isNull);
    expect(findExecutable('i=', executables: cls.executables), isNull);
  }

  test_field_final() {
    UnlinkedVariable variable =
        serializeClassText('class C { final int i = 0; }').fields[0];
    expect(variable.isFinal, isTrue);
  }

  test_field_non_final() {
    UnlinkedVariable variable =
        serializeClassText('class C { int i; }').fields[0];
    expect(variable.isFinal, isFalse);
  }

  test_generic_method_in_generic_class() {
    UnlinkedClass cls = serializeClassText(
        'class C<T, U> { void m<V, W>(T t, U u, V v, W w) {} }');
    List<UnlinkedParam> params = cls.executables[0].parameters;
    checkParamTypeRef(params[0].type, 4);
    checkParamTypeRef(params[1].type, 3);
    checkParamTypeRef(params[2].type, 2);
    checkParamTypeRef(params[3].type, 1);
  }

  test_import_deferred() {
    serializeLibraryText(
        'import "dart:async" deferred as a; main() { print(a.Future); }');
    expect(definingUnit.unlinked.imports[0].isDeferred, isTrue);
  }

  test_import_dependency() {
    serializeLibraryText('import "dart:async"; Future x;');
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    checkDependency(lib.importDependencies[0], 'dart:async', 'dart:async');
  }

  test_import_explicit() {
    serializeLibraryText('import "dart:core"; int i;');
    expect(definingUnit.unlinked.imports, hasLength(1));
    expect(definingUnit.unlinked.imports[0].isImplicit, isFalse);
  }

  test_import_hide_order() {
    serializeLibraryText(
        'import "dart:async" hide Future, Stream; Completer c;');
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    expect(definingUnit.unlinked.imports[0].combinators, hasLength(1));
    expect(definingUnit.unlinked.imports[0].combinators[0].shows, isEmpty);
    expect(definingUnit.unlinked.imports[0].combinators[0].hides, hasLength(2));
    checkCombinatorName(
        definingUnit.unlinked.imports[0].combinators[0].hides[0], 'Future');
    checkCombinatorName(
        definingUnit.unlinked.imports[0].combinators[0].hides[1], 'Stream');
  }

  test_import_implicit() {
    // The implicit import of dart:core is represented in the model.
    serializeLibraryText('');
    expect(definingUnit.unlinked.imports, hasLength(1));
    checkDependency(lib.importDependencies[0], 'dart:core', 'dart:core');
    expect(definingUnit.unlinked.imports[0].uri, isEmpty);
    expect(definingUnit.unlinked.imports[0].prefix, 0);
    expect(definingUnit.unlinked.imports[0].combinators, isEmpty);
    expect(definingUnit.unlinked.imports[0].isImplicit, isTrue);
  }

  test_import_no_combinators() {
    serializeLibraryText('import "dart:async"; Future x;');
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    expect(definingUnit.unlinked.imports[0].combinators, isEmpty);
  }

  test_import_no_flags() {
    serializeLibraryText('import "dart:async"; Future x;');
    expect(definingUnit.unlinked.imports[0].isImplicit, isFalse);
    expect(definingUnit.unlinked.imports[0].isDeferred, isFalse);
  }

  test_import_non_deferred() {
    serializeLibraryText(
        'import "dart:async" as a; main() { print(a.Future); }');
    expect(definingUnit.unlinked.imports[0].isDeferred, isFalse);
  }

  test_import_of_file_with_missing_part() {
    // Other references in foo.dart should be resolved even though foo.dart's
    // part declaration for bar.dart refers to a non-existent file.
    addNamedSource('/foo.dart', 'part "bar.dart"; class C {}');
    serializeLibraryText('import "foo.dart"; C x;');
    checkTypeRef(findVariable('x').type, absUri('/foo.dart'), 'foo.dart', 'C');
  }

  test_import_of_missing_export() {
    // Other references in foo.dart should be resolved even though foo.dart's
    // re-export of bar.dart refers to a non-existent file.
    addNamedSource('/foo.dart', 'export "bar.dart"; class C {}');
    serializeLibraryText('import "foo.dart"; C x;');
    checkTypeRef(findVariable('x').type, absUri('/foo.dart'), 'foo.dart', 'C');
  }

  test_import_offset() {
    String libraryText = '    import "dart:async"; Future x;';
    serializeLibraryText(libraryText);
    expect(
        definingUnit.unlinked.imports[0].offset, libraryText.indexOf('import'));
  }

  test_import_prefix_name() {
    String libraryText = 'import "dart:async" as a; a.Future x;';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    expect(definingUnit.unlinked.imports[0].prefix, isNot(0));
    expect(
        unlinked.prefixes[definingUnit.unlinked.imports[0].prefix].name, 'a');
  }

  test_import_prefix_none() {
    serializeLibraryText('import "dart:async"; Future x;');
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    expect(definingUnit.unlinked.imports[0].prefix, 0);
    expect(unlinked.prefixes[definingUnit.unlinked.imports[0].prefix].name,
        isEmpty);
  }

  test_import_prefix_reference() {
    UnlinkedVariable variable =
        serializeVariableText('import "dart:async" as a; a.Future v;');
    checkTypeRef(variable.type, 'dart:async', 'dart:async', 'Future',
        expectedPrefix: 'a');
  }

  test_import_reference() {
    UnlinkedVariable variable =
        serializeVariableText('import "dart:async"; Future v;');
    checkTypeRef(variable.type, 'dart:async', 'dart:async', 'Future');
  }

  test_import_reference_merged_no_prefix() {
    serializeLibraryText('''
import "dart:async" show Future;
import "dart:async" show Stream;

Future f;
Stream s;
''');
    checkTypeRef(findVariable('f').type, 'dart:async', 'dart:async', 'Future');
    checkTypeRef(findVariable('s').type, 'dart:async', 'dart:async', 'Stream');
  }

  test_import_reference_merged_prefixed() {
    serializeLibraryText('''
import "dart:async" as a show Future;
import "dart:async" as a show Stream;

a.Future f;
a.Stream s;
''');
    checkTypeRef(findVariable('f').type, 'dart:async', 'dart:async', 'Future',
        expectedPrefix: 'a');
    checkTypeRef(findVariable('s').type, 'dart:async', 'dart:async', 'Stream',
        expectedPrefix: 'a');
  }

  test_import_show_order() {
    String libraryText =
        'import "dart:async" show Future, Stream; Future x; Stream y;';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    expect(definingUnit.unlinked.imports[0].combinators, hasLength(1));
    expect(definingUnit.unlinked.imports[0].combinators[0].shows, hasLength(2));
    expect(definingUnit.unlinked.imports[0].combinators[0].hides, isEmpty);
    checkCombinatorName(
        definingUnit.unlinked.imports[0].combinators[0].shows[0], 'Future');
    checkCombinatorName(
        definingUnit.unlinked.imports[0].combinators[0].shows[1], 'Stream');
  }

  test_import_uri() {
    String uriString = '"dart:async"';
    String libraryText = 'import $uriString; Future x;';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(definingUnit.unlinked.imports, hasLength(2));
    expect(definingUnit.unlinked.imports[0].uri, 'dart:async');
  }

  test_library_named() {
    String text = 'library foo.bar;';
    serializeLibraryText(text);
    expect(definingUnit.unlinked.libraryName, 'foo.bar');
  }

  test_library_unnamed() {
    serializeLibraryText('');
    expect(definingUnit.unlinked.libraryName, isEmpty);
  }

  test_parts_defining_compilation_unit() {
    serializeLibraryText('');
    expect(lib.units, hasLength(1));
    expect(definingUnit.unlinked.parts, isEmpty);
  }

  test_parts_included() {
    addNamedSource('/part1.dart', 'part of my.lib;');
    String partString = '"part1.dart"';
    String libraryText = 'library my.lib; part $partString;';
    serializeLibraryText(libraryText);
    expect(lib.units, hasLength(2));
    expect(definingUnit.unlinked.parts, hasLength(1));
    expect(definingUnit.unlinked.parts[0].uri, 'part1.dart');
  }

  test_type_arguments_explicit() {
    UnlinkedTypeRef typeRef = serializeTypeText('List<int>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true);
    expect(typeRef.typeArguments, hasLength(1));
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'int');
  }

  test_type_arguments_explicit_dynamic() {
    UnlinkedTypeRef typeRef = serializeTypeText('List<dynamic>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_explicit_dynamic_typedef() {
    UnlinkedTypeRef typeRef =
        serializeTypeText('F<dynamic>', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, null, 'F',
        allowTypeParameters: true,
        expectedKind: PrelinkedReferenceKind.typedef);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_explicit_typedef() {
    UnlinkedTypeRef typeRef =
        serializeTypeText('F<int>', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, null, 'F',
        allowTypeParameters: true,
        expectedKind: PrelinkedReferenceKind.typedef);
    expect(typeRef.typeArguments, hasLength(1));
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'int');
  }

  test_type_arguments_implicit() {
    UnlinkedTypeRef typeRef = serializeTypeText('List');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_implicit_typedef() {
    UnlinkedTypeRef typeRef =
        serializeTypeText('F', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, null, 'F',
        allowTypeParameters: true,
        expectedKind: PrelinkedReferenceKind.typedef);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_order() {
    UnlinkedTypeRef typeRef = serializeTypeText('Map<int, Object>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'Map',
        allowTypeParameters: true);
    expect(typeRef.typeArguments, hasLength(2));
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'int');
    checkTypeRef(typeRef.typeArguments[1], 'dart:core', 'dart:core', 'Object');
  }

  test_type_dynamic() {
    checkDynamicTypeRef(serializeTypeText('dynamic'));
  }

  test_type_reference_from_part() {
    addNamedSource('/a.dart', 'part of foo; C v;');
    serializeLibraryText('library foo; part "a.dart"; class C {}');
    checkTypeRef(
        findVariable('v', variables: lib.units[1].unlinked.variables).type,
        null,
        null,
        'C',
        expectedKind: PrelinkedReferenceKind.classOrEnum,
        sourceUnit: lib.units[1]);
  }

  test_type_reference_to_class_argument() {
    UnlinkedClass cls = serializeClassText('class C<T, U> { T t; U u; }');
    {
      UnlinkedTypeRef typeRef =
          findVariable('t', variables: cls.fields, failIfAbsent: true).type;
      checkParamTypeRef(typeRef, 2);
    }
    {
      UnlinkedTypeRef typeRef =
          findVariable('u', variables: cls.fields, failIfAbsent: true).type;
      checkParamTypeRef(typeRef, 1);
    }
  }

  test_type_reference_to_import_of_export() {
    addNamedSource('/a.dart', 'library a; export "b.dart";');
    addNamedSource('/b.dart', 'library b; class C {}');
    checkTypeRef(serializeTypeText('C', otherDeclarations: 'import "a.dart";'),
        absUri('/b.dart'), 'b.dart', 'C');
  }

  test_type_reference_to_import_of_export_via_prefix() {
    addNamedSource('/a.dart', 'library a; export "b.dart";');
    addNamedSource('/b.dart', 'library b; class C {}');
    checkTypeRef(
        serializeTypeText('p.C', otherDeclarations: 'import "a.dart" as p;'),
        absUri('/b.dart'),
        'b.dart',
        'C',
        expectedPrefix: 'p');
  }

  test_type_reference_to_imported_part() {
    addNamedSource('/a.dart', 'library my.lib; part "b.dart";');
    addNamedSource('/b.dart', 'part of my.lib; class C {}');
    checkTypeRef(
        serializeTypeText('C',
            otherDeclarations: 'library my.lib; import "a.dart";'),
        absUri('/a.dart'),
        'a.dart',
        'C',
        expectedTargetUnit: 1);
  }

  test_type_reference_to_imported_part_with_prefix() {
    addNamedSource('/a.dart', 'library my.lib; part "b.dart";');
    addNamedSource('/b.dart', 'part of my.lib; class C {}');
    checkTypeRef(
        serializeTypeText('p.C',
            otherDeclarations: 'library my.lib; import "a.dart" as p;'),
        absUri('/a.dart'),
        'a.dart',
        'C',
        expectedPrefix: 'p',
        expectedTargetUnit: 1);
  }

  test_type_reference_to_internal_class() {
    checkTypeRef(serializeTypeText('C', otherDeclarations: 'class C {}'), null,
        null, 'C');
  }

  test_type_reference_to_internal_class_alias() {
    checkTypeRef(
        serializeTypeText('C',
            otherDeclarations: 'class C = D with E; class D {} class E {}'),
        null,
        null,
        'C');
  }

  test_type_reference_to_internal_enum() {
    checkTypeRef(serializeTypeText('E', otherDeclarations: 'enum E { value }'),
        null, null, 'E');
  }

  test_type_reference_to_local_part() {
    addNamedSource('/a.dart', 'part of my.lib; class C {}');
    checkTypeRef(
        serializeTypeText('C',
            otherDeclarations: 'library my.lib; part "a.dart";'),
        null,
        null,
        'C',
        expectedTargetUnit: 1);
  }

  test_type_reference_to_nonexistent_file_via_prefix() {
    UnlinkedTypeRef typeRef = serializeTypeText('p.C',
        otherDeclarations: 'import "foo.dart" as p;', allowErrors: true);
    checkUnresolvedTypeRef(typeRef, 'p', 'C');
  }

  test_type_reference_to_part() {
    addNamedSource('/a.dart', 'part of foo; class C {}');
    checkTypeRef(
        serializeTypeText('C',
            otherDeclarations: 'library foo; part "a.dart";'),
        null,
        null,
        'C',
        expectedKind: PrelinkedReferenceKind.classOrEnum,
        expectedTargetUnit: 1);
  }

  test_type_reference_to_typedef() {
    checkTypeRef(serializeTypeText('F', otherDeclarations: 'typedef void F();'),
        null, null, 'F',
        expectedKind: PrelinkedReferenceKind.typedef);
  }

  test_type_unit_counts_unreferenced_units() {
    addNamedSource('/a.dart', 'library a; part "b.dart"; part "c.dart";');
    addNamedSource('/b.dart', 'part of a;');
    addNamedSource('/c.dart', 'part of a; class C {}');
    UnlinkedTypeRef typeRef =
        serializeTypeText('C', otherDeclarations: 'import "a.dart";');
    // The referenced unit should be 2, since unit 0 is a.dart and unit 1 is
    // b.dart.  a.dart and b.dart are counted even though nothing is imported
    // from them.
    checkTypeRef(typeRef, absUri('/a.dart'), 'a.dart', 'C',
        expectedTargetUnit: 2);
  }

  test_type_unresolved() {
    UnlinkedTypeRef typeRef = serializeTypeText('Foo', allowErrors: true);
    checkUnresolvedTypeRef(typeRef, null, 'Foo');
  }

  test_typedef_name() {
    UnlinkedTypedef type = serializeTypedefText('typedef F();');
    expect(type.name, 'F');
  }

  test_typedef_param_none() {
    UnlinkedTypedef type = serializeTypedefText('typedef F();');
    expect(type.parameters, isEmpty);
  }

  test_typedef_param_order() {
    UnlinkedTypedef type = serializeTypedefText('typedef F(x, y);');
    expect(type.parameters, hasLength(2));
    expect(type.parameters[0].name, 'x');
    expect(type.parameters[1].name, 'y');
  }

  test_typedef_return_type_explicit() {
    UnlinkedTypedef type = serializeTypedefText('typedef int F();');
    checkTypeRef(type.returnType, 'dart:core', 'dart:core', 'int');
  }

  test_typedef_type_param_in_parameter() {
    UnlinkedTypedef type = serializeTypedefText('typedef F<T>(T t);');
    checkParamTypeRef(type.parameters[0].type, 1);
  }

  test_typedef_type_param_in_return_type() {
    UnlinkedTypedef type = serializeTypedefText('typedef T F<T>();');
    checkParamTypeRef(type.returnType, 1);
  }

  test_typedef_type_param_none() {
    UnlinkedTypedef type = serializeTypedefText('typedef F();');
    expect(type.typeParameters, isEmpty);
  }

  test_typedef_type_param_order() {
    UnlinkedTypedef type = serializeTypedefText('typedef F<T, U>();');
    expect(type.typeParameters, hasLength(2));
    expect(type.typeParameters[0].name, 'T');
    expect(type.typeParameters[1].name, 'U');
  }

  test_variable() {
    serializeVariableText('int i;', variableName: 'i');
    expect(findExecutable('i'), isNull);
    expect(findExecutable('i='), isNull);
  }

  test_variable_const() {
    UnlinkedVariable variable =
        serializeVariableText('const int i = 0;', variableName: 'i');
    expect(variable.isConst, isTrue);
  }

  test_variable_explicit_dynamic() {
    UnlinkedVariable variable = serializeVariableText('dynamic v;');
    checkDynamicTypeRef(variable.type);
    expect(variable.hasImplicitType, isFalse);
  }

  test_variable_final_top_level() {
    UnlinkedVariable variable =
        serializeVariableText('final int i = 0;', variableName: 'i');
    expect(variable.isFinal, isTrue);
  }

  test_variable_implicit_dynamic() {
    UnlinkedVariable variable = serializeVariableText('var v;');
    checkDynamicTypeRef(variable.type);
    expect(variable.hasImplicitType, isTrue);
  }

  test_variable_name() {
    UnlinkedVariable variable =
        serializeVariableText('int i;', variableName: 'i');
    expect(variable.name, 'i');
  }

  test_variable_no_flags() {
    UnlinkedVariable variable =
        serializeVariableText('int i;', variableName: 'i');
    expect(variable.isStatic, isFalse);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isFalse);
  }

  test_variable_non_const() {
    UnlinkedVariable variable =
        serializeVariableText('int i = 0;', variableName: 'i');
    expect(variable.isConst, isFalse);
  }

  test_variable_non_final() {
    UnlinkedVariable variable =
        serializeVariableText('int i;', variableName: 'i');
    expect(variable.isFinal, isFalse);
  }

  test_variable_non_static() {
    UnlinkedVariable variable =
        serializeClassText('class C { int i; }').fields[0];
    expect(variable.isStatic, isFalse);
  }

  test_variable_non_static_top_level() {
    // Top level variables are considered non-static.
    UnlinkedVariable variable =
        serializeVariableText('int i;', variableName: 'i');
    expect(variable.isStatic, isFalse);
  }

  test_variable_static() {
    UnlinkedVariable variable =
        serializeClassText('class C { static int i; }').fields[0];
    expect(variable.isStatic, isTrue);
  }

  test_variable_type() {
    UnlinkedVariable variable =
        serializeVariableText('int i;', variableName: 'i');
    checkTypeRef(variable.type, 'dart:core', 'dart:core', 'int');
  }
}
