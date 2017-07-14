// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summary_common;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/public_namespace_computer.dart'
    as public_namespace;
import 'package:path/path.dart' show posix;
import 'package:test/test.dart';

import '../context/mock_sdk.dart';

/**
 * Convert the given Posix style file [path] to the corresponding absolute URI.
 */
String absUri(String path) {
  String absolutePath = posix.absolute(path);
  return posix.toUri(absolutePath).toString();
}

/**
 * Convert a summary object (or a portion of one) into a canonical form that
 * can be easily compared using [expect].  If [orderByName] is true, and the
 * object is a [List], it is sorted by the `name` field of its elements.
 */
Object canonicalize(Object obj, {bool orderByName: false}) {
  if (obj is SummaryClass) {
    Map<String, Object> result = <String, Object>{};
    obj.toMap().forEach((String key, Object value) {
      bool orderByName = false;
      if (obj is UnlinkedPublicNamespace && key == 'names' ||
          obj is UnlinkedPublicName && key == 'members') {
        orderByName = true;
      }
      result[key] = canonicalize(value, orderByName: orderByName);
    });
    return result;
  } else if (obj is List) {
    List<Object> result = <Object>[];
    for (Object item in obj) {
      result.add(canonicalize(item));
    }
    if (orderByName) {
      result.sort((Object a, Object b) {
        if (a is Map && b is Map) {
          return Comparable.compare(a['name'], b['name']);
        } else {
          return 0;
        }
      });
    }
    return result;
  } else if (obj is String || obj is num || obj is bool) {
    return obj;
  } else {
    return obj.toString();
  }
}

UnlinkedPublicNamespace computePublicNamespaceFromText(
    String text, Source source) {
  CharacterReader reader = new CharSequenceReader(text);
  Scanner scanner =
      new Scanner(source, reader, AnalysisErrorListener.NULL_LISTENER);
  Parser parser = new Parser(source, AnalysisErrorListener.NULL_LISTENER);
  CompilationUnit unit = parser.parseCompilationUnit(scanner.tokenize());
  UnlinkedPublicNamespace namespace = new UnlinkedPublicNamespace.fromBuffer(
      public_namespace.computePublicNamespace(unit).toBuffer());
  return namespace;
}

/**
 * Type of a function that validates an [EntityRef].
 */
typedef void _EntityRefValidator(EntityRef entityRef);

/**
 * [SerializedMockSdk] is a singleton class representing the result of
 * serializing the mock SDK to summaries.  It is computed once and then shared
 * among test invocations so that we don't bog down the tests.
 *
 * Note: should an exception occur during computation of [instance], it will
 * silently be set to null to allow other tests to complete quickly.
 */
class SerializedMockSdk {
  static final SerializedMockSdk instance = _serializeMockSdk();

  final Map<String, UnlinkedUnit> uriToUnlinkedUnit;

  final Map<String, LinkedLibrary> uriToLinkedLibrary;
  SerializedMockSdk._(this.uriToUnlinkedUnit, this.uriToLinkedLibrary);

  static SerializedMockSdk _serializeMockSdk() {
    try {
      Map<String, UnlinkedUnit> uriToUnlinkedUnit = <String, UnlinkedUnit>{};
      Map<String, LinkedLibrary> uriToLinkedLibrary = <String, LinkedLibrary>{};
      PackageBundle bundle = new MockSdk().getLinkedBundle();
      for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
        String uri = bundle.unlinkedUnitUris[i];
        uriToUnlinkedUnit[uri] = bundle.unlinkedUnits[i];
      }
      for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
        String uri = bundle.linkedLibraryUris[i];
        uriToLinkedLibrary[uri] = bundle.linkedLibraries[i];
      }
      return new SerializedMockSdk._(uriToUnlinkedUnit, uriToLinkedLibrary);
    } catch (_) {
      return null;
    }
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
   * A test will set this to `true` if it contains `import`, `export`, or
   * `part` declarations that deliberately refer to non-existent files.
   */
  bool allowMissingFiles = false;

  /**
   * Get access to the linked defining compilation unit.
   */
  LinkedUnit get definingUnit => linked.units[0];

  /**
   * Whether the parts of the IDL marked `@informative` are expected to be
   * included in the generated summary; if `false`, these parts of the IDL won't
   * be checked.
   */
  bool get includeInformative => true;

  /**
   * Get access to the linked summary that results from serializing and
   * then deserializing the library under test.
   */
  LinkedLibrary get linked;

  /**
   * `true` if the linked portion of the summary only contains prelinked data.
   * This happens because we don't yet have a full linker; only a prelinker.
   */
  bool get skipFullyLinkedData;

  /**
   * `true` if non-const variable initializers are not serialized.
   */
  bool get skipNonConstInitializers;

  /**
   * `true` if the linked portion of the summary contains the result of strong
   * mode analysis.
   */
  bool get strongMode;

  /**
   * Get access to the unlinked compilation unit summaries that result from
   * serializing and deserializing the library under test.
   */
  List<UnlinkedUnit> get unlinkedUnits;

  /**
   * Add the given source file so that it may be referenced by the file under
   * test.
   */
  Source addNamedSource(String filePath, String contents);

  /**
   * TODO(scheglov) rename "Const" to "Expr" everywhere
   */
  void assertUnlinkedConst(UnlinkedExpr constExpr,
      {bool isValidConst: true,
      List<UnlinkedExprOperation> operators: const <UnlinkedExprOperation>[],
      List<UnlinkedExprAssignOperator> assignmentOperators:
          const <UnlinkedExprAssignOperator>[],
      List<int> ints: const <int>[],
      List<double> doubles: const <double>[],
      List<String> strings: const <String>[],
      List<_EntityRefValidator> referenceValidators:
          const <_EntityRefValidator>[]}) {
    expect(constExpr, isNotNull);
    expect(constExpr.isValidConst, isValidConst);
    expect(constExpr.operations, operators);
    expect(constExpr.ints, ints);
    expect(constExpr.doubles, doubles);
    expect(constExpr.strings, strings);
    expect(constExpr.assignmentOperators, assignmentOperators);
    expect(constExpr.references, hasLength(referenceValidators.length));
    for (int i = 0; i < referenceValidators.length; i++) {
      referenceValidators[i](constExpr.references[i]);
    }
  }

  /**
   * Check that [annotations] contains a single entry which is a reference to
   * a top level variable called `a` in the current library.
   */
  void checkAnnotationA(List<UnlinkedExpr> annotations) {
    expect(annotations, hasLength(1));
    assertUnlinkedConst(annotations[0], operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'a',
          expectedKind: ReferenceKind.topLevelPropertyAccessor)
    ]);
  }

  void checkConstCycle(String className,
      {String name: '', bool hasCycle: true}) {
    UnlinkedClass cls = findClass(className);
    int constCycleSlot =
        findExecutable(name, executables: cls.executables).constCycleSlot;
    expect(constCycleSlot, isNot(0));
    if (!skipFullyLinkedData) {
      expect(
          definingUnit.constCycles,
          hasCycle
              ? contains(constCycleSlot)
              : isNot(contains(constCycleSlot)));
    }
  }

  /**
   * Verify that the [dependency]th element of the dependency table represents
   * a file reachable via the given [absoluteUri].
   */
  void checkDependency(int dependency, String absoluteUri) {
    expect(dependency, new isInstanceOf<int>());
    expect(linked.dependencies[dependency].uri, absoluteUri);
  }

  /**
   * Verify that the given [dependency] lists the given
   * [relativeUris] as its parts.
   */
  void checkDependencyParts(
      LinkedDependency dependency, List<String> relativeUris) {
    expect(dependency.parts, relativeUris);
  }

  /**
   * Check that the given [documentationComment] matches the first
   * Javadoc-style comment found in [text].
   *
   * Note that the algorithm for finding the Javadoc-style comment in [text] is
   * a simple-minded text search; it is easily confused by corner cases such as
   * strings containing comments, nested comments, etc.
   */
  void checkDocumentationComment(
      UnlinkedDocumentationComment documentationComment, String text) {
    expect(documentationComment, isNotNull);
    int commentStart = text.indexOf('/*');
    expect(commentStart, isNot(-1));
    int commentEnd = text.indexOf('*/');
    expect(commentEnd, isNot(-1));
    commentEnd += 2;
    String expectedCommentText =
        text.substring(commentStart, commentEnd).replaceAll('\r\n', '\n');
    expect(documentationComment.text, expectedCommentText);
  }

  /**
   * Verify that the given [typeRef] represents the type `dynamic`.
   */
  void checkDynamicTypeRef(EntityRef typeRef) {
    checkTypeRef(typeRef, null, 'dynamic');
  }

  /**
   * Verify that the given [exportName] represents a reference to an entity
   * declared in a file reachable via [absoluteUri], having name [expectedName].
   * [expectedKind] is the kind of object referenced. [expectedTargetUnit] is
   * the index of the compilation unit in which the target of the [exportName]
   * is expected to appear; if not specified it is assumed to be the defining
   * compilation unit.
   */
  void checkExportName(LinkedExportName exportName, String absoluteUri,
      String expectedName, ReferenceKind expectedKind,
      {int expectedTargetUnit: 0}) {
    expect(exportName, new isInstanceOf<LinkedExportName>());
    // Exported names must come from other libraries.
    expect(exportName.dependency, isNot(0));
    checkDependency(exportName.dependency, absoluteUri);
    expect(exportName.name, expectedName);
    expect(exportName.kind, expectedKind);
    expect(exportName.unit, expectedTargetUnit);
  }

  /**
   * Verify that the dependency table contains an entry for a file reachable
   * via the given [relativeUri].  If [fullyLinked] is
   * `true`, then the dependency should be a fully-linked dependency; otherwise
   * it should be a prelinked dependency.
   *
   * The index of the [LinkedDependency] is returned.
   */
  int checkHasDependency(String relativeUri, {bool fullyLinked: false}) {
    List<String> found = <String>[];
    for (int i = 0; i < linked.dependencies.length; i++) {
      LinkedDependency dep = linked.dependencies[i];
      if (dep.uri == relativeUri) {
        if (fullyLinked) {
          expect(i, greaterThanOrEqualTo(linked.numPrelinkedDependencies));
        } else {
          expect(i, lessThan(linked.numPrelinkedDependencies));
        }
        return i;
      }
      found.add(dep.uri);
    }
    fail('Did not find dependency $relativeUri.  Found: $found');
    return null;
  }

  /**
   * Test an inferred type.  If [onlyInStrongMode] is `true` (the default) and
   * strong mode is disabled, verify that the given [slotId] exists and has no
   * associated type.  Otherwise, behave as in [checkLinkedTypeSlot].
   */
  void checkInferredTypeSlot(
      int slotId, String absoluteUri, String expectedName,
      {int numTypeArguments: 0,
      ReferenceKind expectedKind: ReferenceKind.classOrEnum,
      int expectedTargetUnit: 0,
      LinkedUnit linkedSourceUnit,
      UnlinkedUnit unlinkedSourceUnit,
      int numTypeParameters: 0,
      bool onlyInStrongMode: true}) {
    if (strongMode || !onlyInStrongMode) {
      checkLinkedTypeSlot(slotId, absoluteUri, expectedName,
          numTypeArguments: numTypeArguments,
          expectedKind: expectedKind,
          expectedTargetUnit: expectedTargetUnit,
          linkedSourceUnit: linkedSourceUnit,
          unlinkedSourceUnit: unlinkedSourceUnit,
          numTypeParameters: numTypeParameters);
    } else {
      // A slot id should have been assigned but it should not be associated
      // with any type.
      expect(slotId, isNot(0));
      expect(getTypeRefForSlot(slotId, linkedSourceUnit: linkedSourceUnit),
          isNull);
    }
  }

  /**
   * Verify that the dependency table *does not* contain any entries for a file
   * reachable via the given [relativeUri].
   */
  void checkLacksDependency(String relativeUri) {
    for (LinkedDependency dep in linked.dependencies) {
      if (dep.uri == relativeUri) {
        fail('Unexpected dependency found: $relativeUri');
      }
    }
  }

  /**
   * Verify that the given [typeRef] represents the type `dynamic`.
   */
  void checkLinkedDynamicTypeRef(EntityRef typeRef) {
    checkLinkedTypeRef(typeRef, null, 'dynamic');
  }

  /**
   * Verify that the given [typeRef] represents a reference to a type declared
   * in a file reachable via [absoluteUri], having name [expectedName].  Verify
   * that the number of type arguments is equal to [numTypeArguments].
   * [expectedKind] is the kind of object referenced.  [linkedSourceUnit] and
   * [unlinkedSourceUnit] refer to the compilation unit within which the
   * [typeRef] appears; if not specified they are assumed to refer to the
   * defining compilation unit. [expectedTargetUnit] is the index of the
   * compilation unit in which the target of the [typeRef] is expected to
   * appear; if not specified it is assumed to be the defining compilation unit.
   * [numTypeParameters] is the number of type parameters of the thing being
   * referred to.
   */
  void checkLinkedTypeRef(
      EntityRef typeRef, String absoluteUri, String expectedName,
      {int numTypeArguments: 0,
      ReferenceKind expectedKind: ReferenceKind.classOrEnum,
      int expectedTargetUnit: 0,
      LinkedUnit linkedSourceUnit,
      UnlinkedUnit unlinkedSourceUnit,
      int numTypeParameters: 0}) {
    linkedSourceUnit ??= definingUnit;
    expect(typeRef, isNotNull,
        reason: 'No entry in linkedSourceUnit.types matching slotId');
    expect(typeRef.paramReference, 0);
    int index = typeRef.reference;
    expect(typeRef.typeArguments, hasLength(numTypeArguments));
    checkReferenceIndex(index, absoluteUri, expectedName,
        expectedKind: expectedKind,
        expectedTargetUnit: expectedTargetUnit,
        linkedSourceUnit: linkedSourceUnit,
        unlinkedSourceUnit: unlinkedSourceUnit,
        numTypeParameters: numTypeParameters);
  }

  /**
   * Verify that the given [slotId] represents a reference to a type declared
   * in a file reachable via [absoluteUri], having name [expectedName].  Verify
   * that the number of type arguments is equal to [numTypeArguments].
   * [expectedKind] is the kind of object referenced.  [linkedSourceUnit] and
   * [unlinkedSourceUnit] refer to the compilation unit within which the
   * [typeRef] appears; if not specified they are assumed to refer to the
   * defining compilation unit. [expectedTargetUnit] is the index of the
   * compilation unit in which the target of the [typeRef] is expected to
   * appear; if not specified it is assumed to be the defining compilation unit.
   * [numTypeParameters] is the number of type parameters of the thing being
   * referred to.
   */
  void checkLinkedTypeSlot(int slotId, String absoluteUri, String expectedName,
      {int numTypeArguments: 0,
      ReferenceKind expectedKind: ReferenceKind.classOrEnum,
      int expectedTargetUnit: 0,
      LinkedUnit linkedSourceUnit,
      UnlinkedUnit unlinkedSourceUnit,
      int numTypeParameters: 0}) {
    // Slot ids should be nonzero, since zero means "no associated slot".
    expect(slotId, isNot(0));
    if (skipFullyLinkedData) {
      return;
    }
    linkedSourceUnit ??= definingUnit;
    checkLinkedTypeRef(
        getTypeRefForSlot(slotId, linkedSourceUnit: linkedSourceUnit),
        absoluteUri,
        expectedName,
        numTypeArguments: numTypeArguments,
        expectedKind: expectedKind,
        expectedTargetUnit: expectedTargetUnit,
        linkedSourceUnit: linkedSourceUnit,
        unlinkedSourceUnit: unlinkedSourceUnit,
        numTypeParameters: numTypeParameters);
  }

  /**
   * Verify that the given [typeRef] represents a reference to a type parameter
   * having the given [deBruijnIndex].
   */
  void checkParamTypeRef(EntityRef typeRef, int deBruijnIndex) {
    expect(typeRef, new isInstanceOf<EntityRef>());
    expect(typeRef.reference, 0);
    expect(typeRef.typeArguments, isEmpty);
    expect(typeRef.paramReference, deBruijnIndex);
  }

  /**
   * Verify that [prefixReference] is a valid reference to a prefix having the
   * given [name].
   */
  void checkPrefix(int prefixReference, String name) {
    expect(prefixReference, isNot(0));
    expect(unlinkedUnits[0].references[prefixReference].prefixReference, 0);
    expect(unlinkedUnits[0].references[prefixReference].name, name);
    expect(definingUnit.references[prefixReference].dependency, 0);
    expect(definingUnit.references[prefixReference].kind, ReferenceKind.prefix);
    expect(definingUnit.references[prefixReference].unit, 0);
  }

  /**
   * Check the data structures that are reachable from an index in the
   * references table.  If the reference in question is an explicit
   * reference, return the [UnlinkedReference] that is used to make the
   * explicit reference.  If the type reference in question is an implicit
   * reference, return `null`.
   */
  UnlinkedReference checkReferenceIndex(
      int referenceIndex, String absoluteUri, String expectedName,
      {ReferenceKind expectedKind: ReferenceKind.classOrEnum,
      int expectedTargetUnit: 0,
      LinkedUnit linkedSourceUnit,
      UnlinkedUnit unlinkedSourceUnit,
      int numTypeParameters: 0,
      int localIndex: 0,
      bool unresolvedHasName: false}) {
    linkedSourceUnit ??= definingUnit;
    unlinkedSourceUnit ??= unlinkedUnits[0];
    LinkedReference referenceResolution =
        linkedSourceUnit.references[referenceIndex];
    String name;
    UnlinkedReference reference;
    if (referenceIndex < unlinkedSourceUnit.references.length) {
      // This is an explicit reference, so its name and prefix should be in
      // [UnlinkedUnit.references].
      expect(referenceResolution.name, isEmpty);
      reference = unlinkedSourceUnit.references[referenceIndex];
      name = reference.name;
      if (reference.prefixReference != 0) {
        // Prefixes should appear in the references table before any reference
        // that uses them.
        expect(reference.prefixReference, lessThan(referenceIndex));
      }
    } else {
      // This is an implicit reference, so its name should be in
      // [LinkedUnit.references].
      name = referenceResolution.name;
    }
    // Index 0 is reserved.
    expect(referenceIndex, isNot(0));
    if (absoluteUri == null) {
      expect(referenceResolution.dependency, 0);
    } else {
      checkDependency(referenceResolution.dependency, absoluteUri);
    }
    if (expectedName == null) {
      expect(name, isEmpty);
    } else {
      expect(name, expectedName);
    }
    expect(referenceResolution.kind, expectedKind);
    expect(referenceResolution.unit, expectedTargetUnit);
    expect(referenceResolution.numTypeParameters, numTypeParameters);
    expect(referenceResolution.localIndex, localIndex);
    return reference;
  }

  /**
   * Verify that the given [typeRef] represents a reference to a type declared
   * in a file reachable via [absoluteUri], having name [expectedName].
   * If [expectedPrefix] is supplied, verify that the type is reached via the
   * given prefix.  Verify that the number of type arguments is equal to
   * [numTypeArguments].  [expectedKind] is the kind of object referenced.
   * [linkedSourceUnit] and [unlinkedSourceUnit] refer to the compilation unit
   * within which the [typeRef] appears; if not specified they are assumed to
   * refer to the defining compilation unit. [expectedTargetUnit] is the index
   * of the compilation unit in which the target of the [typeRef] is expected
   * to appear; if not specified it is assumed to be the defining compilation
   * unit.  [numTypeParameters] is the number of type parameters of the thing
   * being referred to.
   */
  void checkTypeRef(EntityRef typeRef, String absoluteUri, String expectedName,
      {String expectedPrefix,
      List<_PrefixExpectation> prefixExpectations,
      int numTypeArguments: 0,
      ReferenceKind expectedKind: ReferenceKind.classOrEnum,
      int expectedTargetUnit: 0,
      LinkedUnit linkedSourceUnit,
      UnlinkedUnit unlinkedSourceUnit,
      int numTypeParameters: 0,
      bool unresolvedHasName: false}) {
    linkedSourceUnit ??= definingUnit;
    expect(typeRef, new isInstanceOf<EntityRef>());
    expect(typeRef.paramReference, 0);
    int index = typeRef.reference;
    expect(typeRef.typeArguments, hasLength(numTypeArguments));
    UnlinkedReference reference = checkReferenceIndex(
        index, absoluteUri, expectedName,
        expectedKind: expectedKind,
        expectedTargetUnit: expectedTargetUnit,
        linkedSourceUnit: linkedSourceUnit,
        unlinkedSourceUnit: unlinkedSourceUnit,
        numTypeParameters: numTypeParameters,
        unresolvedHasName: unresolvedHasName);
    expect(reference, isNotNull,
        reason: 'Unlinked type refs must refer to an explicit reference');
    if (expectedPrefix != null) {
      checkPrefix(reference.prefixReference, expectedPrefix);
    } else if (prefixExpectations != null) {
      for (_PrefixExpectation expectation in prefixExpectations) {
        expect(reference.prefixReference, isNot(0));
        reference = checkReferenceIndex(reference.prefixReference,
            expectation.absoluteUri, expectation.name,
            expectedKind: expectation.kind,
            expectedTargetUnit: expectedTargetUnit,
            linkedSourceUnit: linkedSourceUnit,
            unlinkedSourceUnit: unlinkedSourceUnit,
            numTypeParameters: expectation.numTypeParameters);
      }
      expect(reference.prefixReference, 0);
    } else {
      expect(reference.prefixReference, 0);
    }
  }

  /**
   * Verify that the given [typeRef] represents a reference to an unresolved
   * type.
   */
  void checkUnresolvedTypeRef(
      EntityRef typeRef, String expectedPrefix, String expectedName,
      {LinkedUnit linkedSourceUnit, UnlinkedUnit unlinkedSourceUnit}) {
    // When serializing from the element model, unresolved type refs lose their
    // name.
    checkTypeRef(typeRef, null, expectedName,
        expectedPrefix: expectedPrefix,
        expectedKind: ReferenceKind.unresolved,
        linkedSourceUnit: linkedSourceUnit,
        unlinkedSourceUnit: unlinkedSourceUnit);
  }

  /**
   * Verify that the given [typeRef] represents the type `void`.
   */
  void checkVoidTypeRef(EntityRef typeRef) {
    checkTypeRef(typeRef, null, 'void');
  }

  fail_invalid_prefix_dynamic() {
//    if (checkAstDerivedData) {
//      // TODO(paulberry): get this to work properly.
//      return;
//    }
    var t = serializeTypeText('dynamic.T', allowErrors: true);
    checkUnresolvedTypeRef(t, 'dynamic', 'T');
  }

  fail_invalid_prefix_type_parameter() {
//    if (checkAstDerivedData) {
//      // TODO(paulberry): get this to work properly.
//      return;
//    }
    checkUnresolvedTypeRef(
        serializeClassText('class C<T> { T.U x; }', allowErrors: true)
            .fields[0]
            .type,
        'T',
        'U');
  }

  fail_invalid_prefix_void() {
//    if (checkAstDerivedData) {
//      // TODO(paulberry): get this to work properly.
//      return;
//    }
    checkUnresolvedTypeRef(
        serializeTypeText('void.T', allowErrors: true), 'void', 'T');
  }

  /**
   * Find the class with the given [className] in the summary, and return its
   * [UnlinkedClass] data structure.  If [unit] is not given, the class is
   * looked for in the defining compilation unit.
   */
  UnlinkedClass findClass(String className,
      {bool failIfAbsent: false, UnlinkedUnit unit}) {
    unit ??= unlinkedUnits[0];
    UnlinkedClass result;
    for (UnlinkedClass cls in unit.classes) {
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
      {bool failIfAbsent: false, UnlinkedUnit unit}) {
    unit ??= unlinkedUnits[0];
    UnlinkedEnum result;
    for (UnlinkedEnum e in unit.enums) {
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
    executables ??= unlinkedUnits[0].executables;
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
   * Find the parameter with the given [name] in [parameters].
   */
  UnlinkedParam findParameter(List<UnlinkedParam> parameters, String name) {
    UnlinkedParam result;
    for (UnlinkedParam parameter in parameters) {
      if (parameter.name == name) {
        if (result != null) {
          fail('Duplicate parameter $name');
        }
        result = parameter;
      }
    }
    if (result == null) {
      fail('Parameter $name not found');
    }
    return result;
  }

  /**
   * Find the typedef with the given [typedefName] in the summary, and return
   * its [UnlinkedTypedef] data structure.  If [unit] is not given, the typedef
   * is looked for in the defining compilation unit.
   */
  UnlinkedTypedef findTypedef(String typedefName,
      {bool failIfAbsent: false, UnlinkedUnit unit}) {
    unit ??= unlinkedUnits[0];
    UnlinkedTypedef result;
    for (UnlinkedTypedef type in unit.typedefs) {
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
    variables ??= unlinkedUnits[0].variables;
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
   * Find the entry in [linkedSourceUnit.types] matching [slotId].
   */
  EntityRef getTypeRefForSlot(int slotId, {LinkedUnit linkedSourceUnit}) {
    linkedSourceUnit ??= definingUnit;
    for (EntityRef typeRef in linkedSourceUnit.types) {
      if (typeRef.slot == slotId) {
        return typeRef;
      }
    }
    return null;
  }

  /**
   * Serialize the given library [text] and return the summary of the class
   * with the given [className].
   */
  UnlinkedClass serializeClassText(String text,
      {String className: 'C', bool allowErrors: false}) {
    serializeLibraryText(text, allowErrors: allowErrors);
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
      {String executableName: 'f', bool allowErrors: false}) {
    serializeLibraryText(text, allowErrors: allowErrors);
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
   * return a summary of the corresponding [EntityRef].  If the type
   * declaration needs to refer to types that are not available in core, those
   * types may be declared in [otherDeclarations].
   */
  EntityRef serializeTypeText(String text,
      {String otherDeclarations: '', bool allowErrors: false}) {
    return serializeVariableText('$otherDeclarations\n$text v;',
            allowErrors: allowErrors)
        .type;
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

  test_apiSignature() {
    List<int> signature1;
    List<int> signature2;
    List<int> signature3;
    {
      serializeLibraryText('class A {}');
      signature1 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText('class A { }');
      signature2 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText('class B {}');
      signature3 = unlinkedUnits[0].apiSignature;
    }
    expect(signature2, signature1);
    expect(signature3, isNot(signature1));
  }

  test_apiSignature_excludeBody_constructor() {
    List<int> signature1;
    List<int> signature2;
    List<int> signature3;
    {
      serializeLibraryText(r'''
class A {
  A() {
  }
}
''');
      signature1 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText(r'''
class A {
  A() {
    int v1;
    f() {
      double v2;
    }
  }
}
''');
      signature2 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText(r'''
class A {
  A(int p) {
  }
}
''');
    }
    expect(signature2, signature1);
    expect(signature3, isNot(signature1));
  }

  test_apiSignature_excludeBody_method() {
    List<int> signature1;
    List<int> signature2;
    List<int> signature3;
    {
      serializeLibraryText(r'''
class A {
  m() {
  }
}
''');
      signature1 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText(r'''
class A {
  m() {
    int v1;
    f() {
      double v2;
    }
  }
}
''');
      signature2 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText(r'''
class A {
  m(p) {
  }
}
''');
    }
    expect(signature2, signature1);
    expect(signature3, isNot(signature1));
  }

  test_apiSignature_excludeBody_topLevelFunction() {
    List<int> signature1;
    List<int> signature2;
    List<int> signature3;
    {
      serializeLibraryText('main() {}');
      signature1 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText(r'''
main() {
  int v1 = 1;
  f() {
    int v2 = 2;
  }
}
''');
      signature2 = unlinkedUnits[0].apiSignature;
    }
    {
      serializeLibraryText('main(p) {}');
      signature3 = unlinkedUnits[0].apiSignature;
    }
    expect(signature2, signature1);
    expect(signature3, isNot(signature1));
  }

  test_bottom_reference_shared() {
    if (skipFullyLinkedData) {
      return;
    }
    // The synthetic executables for both `x` and `y` have type `() => `Bottom`.
    // Verify that they both use the same reference to `Bottom`.
    serializeLibraryText('int x = null; int y = null;');
    EntityRef xInitializerReturnType =
        getTypeRefForSlot(findVariable('x').initializer.inferredReturnTypeSlot);
    EntityRef yInitializerReturnType =
        getTypeRefForSlot(findVariable('y').initializer.inferredReturnTypeSlot);
    expect(xInitializerReturnType.reference, yInitializerReturnType.reference);
  }

  test_cascaded_export_hide_hide() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" hide C hide B, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib1.dart';
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib2.dart'), 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_export_hide_show() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" hide C show A, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib1.dart';
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib2.dart'), 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_export_show_hide() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" show A, B hide B, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib1.dart';
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib2.dart'), 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_export_show_show() {
    addNamedSource('/lib1.dart', 'export "lib2.dart" show A, B show A, C;');
    addNamedSource('/lib2.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib1.dart';
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib2.dart'), 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_hide_hide() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib.dart' hide C hide B, C;
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_hide_show() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib.dart' hide C show A, C;
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_show_hide() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib.dart' show A, B hide B, C;
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'A');
    checkUnresolvedTypeRef(findVariable('b').type, null, 'B');
    checkUnresolvedTypeRef(findVariable('c').type, null, 'C');
  }

  test_cascaded_import_show_show() {
    addNamedSource('/lib.dart', 'class A {} class B {} class C {}');
    serializeLibraryText('''
import 'lib.dart' show A, B show A, C;
A a;
B b;
C c;
    ''', allowErrors: true);
    checkTypeRef(findVariable('a').type, absUri('/lib.dart'), 'A');
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
        serializeClassText('class C = _D with _E; class _D {} class _E {}');
    expect(cls.isAbstract, false);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.classOrEnum);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'C');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
  }

  test_class_alias_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}''';
    UnlinkedClass cls = serializeClassText(text);
    expect(cls.documentationComment, isNotNull);
    checkDocumentationComment(cls.documentationComment, text);
  }

  test_class_alias_flag() {
    UnlinkedClass cls =
        serializeClassText('class C = D with E; class D {} class E {}');
    expect(cls.isMixinApplication, true);
  }

  test_class_alias_generic() {
    serializeClassText('class C<A, B> = _D with _E; class _D {} class _E {}');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 2);
  }

  test_class_alias_mixin_order() {
    UnlinkedClass cls = serializeClassText('''
class C = D with E, F;
class D {}
class E {}
class F {}
''');
    expect(cls.mixins, hasLength(2));
    checkTypeRef(cls.mixins[0], null, 'E');
    checkTypeRef(cls.mixins[1], null, 'F');
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

  test_class_alias_private() {
    serializeClassText('class _C = _D with _E; class _D {} class _E {}',
        className: '_C');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_class_alias_reference_generic() {
    EntityRef typeRef = serializeTypeText('C',
        otherDeclarations: 'class C<D, E> = F with G; class F {} class G {}');
    checkTypeRef(typeRef, null, 'C', numTypeParameters: 2);
  }

  test_class_alias_reference_generic_imported() {
    addNamedSource(
        '/lib.dart', 'class C<D, E> = F with G; class F {} class G {}');
    EntityRef typeRef =
        serializeTypeText('C', otherDeclarations: 'import "lib.dart";');
    checkTypeRef(typeRef, absUri('/lib.dart'), 'C', numTypeParameters: 2);
  }

  test_class_alias_supertype() {
    UnlinkedClass cls =
        serializeClassText('class C = D with E; class D {} class E {}');
    checkTypeRef(cls.supertype, null, 'D');
    expect(cls.hasNoSupertype, isFalse);
  }

  test_class_codeRange() {
    if (!includeInformative) return;
    UnlinkedClass cls = serializeClassText(' class C {}');
    _assertCodeRange(cls.codeRange, 1, 10);
  }

  test_class_concrete() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.isAbstract, false);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.classOrEnum);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'C');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
  }

  test_class_constMembers() {
    UnlinkedClass cls = serializeClassText('''
class C {
  int fieldInstance = 0;
  final int fieldInstanceFinal = 0;
  static int fieldStatic = 0;
  static final int fieldStaticFinal = 0;
  static const int fieldStaticConst = 0;
  static const int _fieldStaticConstPrivate = 0;
  static void methodStaticPublic() {}
  static void _methodStaticPrivate() {}
  void methodInstancePublic() {}
  C operator+(C c) => null;
}
''');
    expect(cls.isAbstract, false);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    UnlinkedPublicName className = unlinkedUnits[0].publicNamespace.names[0];
    expect(className.kind, ReferenceKind.classOrEnum);
    expect(className.name, 'C');
    expect(className.numTypeParameters, 0);
    // executables
    Map<String, UnlinkedPublicName> executablesMap =
        <String, UnlinkedPublicName>{};
    className.members.forEach((e) => executablesMap[e.name] = e);
    expect(executablesMap, hasLength(4));
    Map<String, ReferenceKind> expectedExecutableKinds =
        <String, ReferenceKind>{
      'fieldStaticConst': ReferenceKind.propertyAccessor,
      'fieldStaticFinal': ReferenceKind.propertyAccessor,
      'fieldStatic': ReferenceKind.propertyAccessor,
      'methodStaticPublic': ReferenceKind.method,
    };
    expectedExecutableKinds.forEach((String name, ReferenceKind expectedKind) {
      UnlinkedPublicName executable = executablesMap[name];
      expect(executable.kind, expectedKind);
      expect(executable.members, isEmpty);
    });
  }

  test_class_constMembers_constructors() {
    UnlinkedClass cls = serializeClassText('''
class C {
  const C();
  const C.constructorNamedPublicConst();
  C.constructorNamedPublic();
  C._constructorNamedPrivate();
}
''');
    expect(cls.isAbstract, false);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    UnlinkedPublicName className = unlinkedUnits[0].publicNamespace.names[0];
    expect(className.kind, ReferenceKind.classOrEnum);
    expect(className.name, 'C');
    expect(className.numTypeParameters, 0);
    // executables
    Map<String, UnlinkedPublicName> executablesMap =
        <String, UnlinkedPublicName>{};
    className.members.forEach((e) => executablesMap[e.name] = e);
    expect(executablesMap, hasLength(2));
    {
      UnlinkedPublicName executable =
          executablesMap['constructorNamedPublicConst'];
      expect(executable.kind, ReferenceKind.constructor);
      expect(executable.members, isEmpty);
    }
    {
      UnlinkedPublicName executable = executablesMap['constructorNamedPublic'];
      expect(executable.kind, ReferenceKind.constructor);
      expect(executable.members, isEmpty);
    }
  }

  test_class_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C {}''';
    UnlinkedClass cls = serializeClassText(text);
    expect(cls.documentationComment, isNotNull);
    checkDocumentationComment(cls.documentationComment, text);
  }

  test_class_documented_tripleSlash() {
    if (!includeInformative) return;
    String text = '''
/// aaa
/// bbbb
/// cc
class C {}''';
    UnlinkedClass cls = serializeClassText(text);
    UnlinkedDocumentationComment comment = cls.documentationComment;
    expect(comment, isNotNull);
    expect(comment.text, '/// aaa\n/// bbbb\n/// cc');
  }

  test_class_documented_with_references() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs referring to [D] and [E]
 */
class C {}

class D {}
class E {}''';
    UnlinkedClass cls = serializeClassText(text);
    expect(cls.documentationComment, isNotNull);
    checkDocumentationComment(cls.documentationComment, text);
  }

  test_class_documented_with_with_windows_line_endings() {
    if (!includeInformative) return;
    String text = '/**\r\n * Docs\r\n */\r\nclass C {}';
    UnlinkedClass cls = serializeClassText(text);
    expect(cls.documentationComment, isNotNull);
    checkDocumentationComment(cls.documentationComment, text);
  }

  test_class_interface() {
    UnlinkedClass cls = serializeClassText('''
class C implements D {}
class D {}
''');
    expect(cls.interfaces, hasLength(1));
    checkTypeRef(cls.interfaces[0], null, 'D');
  }

  test_class_interface_order() {
    UnlinkedClass cls = serializeClassText('''
class C implements D, E {}
class D {}
class E {}
''');
    expect(cls.interfaces, hasLength(2));
    checkTypeRef(cls.interfaces[0], null, 'D');
    checkTypeRef(cls.interfaces[1], null, 'E');
  }

  test_class_mixin() {
    UnlinkedClass cls = serializeClassText('''
class C extends Object with D {}
class D {}
''');
    expect(cls.mixins, hasLength(1));
    checkTypeRef(cls.mixins[0], null, 'D');
  }

  test_class_mixin_order() {
    UnlinkedClass cls = serializeClassText('''
class C extends Object with D, E {}
class D {}
class E {}
''');
    expect(cls.mixins, hasLength(2));
    checkTypeRef(cls.mixins[0], null, 'D');
    checkTypeRef(cls.mixins[1], null, 'E');
  }

  test_class_name() {
    var classText = 'class C {}';
    UnlinkedClass cls = serializeClassText(classText);
    expect(cls.name, 'C');
    if (includeInformative) {
      expect(cls.nameOffset, classText.indexOf('C'));
    }
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

  test_class_private() {
    serializeClassText('class _C {}', className: '_C');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_class_reference_generic() {
    EntityRef typeRef =
        serializeTypeText('C', otherDeclarations: 'class C<D, E> {}');
    checkTypeRef(typeRef, null, 'C', numTypeParameters: 2);
  }

  test_class_reference_generic_imported() {
    addNamedSource('/lib.dart', 'class C<D, E> {}');
    EntityRef typeRef =
        serializeTypeText('C', otherDeclarations: 'import "lib.dart";');
    checkTypeRef(typeRef, absUri('/lib.dart'), 'C', numTypeParameters: 2);
  }

  test_class_superclass() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.supertype, isNull);
    expect(cls.hasNoSupertype, isFalse);
  }

  test_class_superclass_explicit() {
    UnlinkedClass cls = serializeClassText('class C extends D {} class D {}');
    expect(cls.supertype, isNotNull);
    checkTypeRef(cls.supertype, null, 'D');
    expect(cls.hasNoSupertype, isFalse);
  }

  test_class_type_param_bound() {
    UnlinkedClass cls = serializeClassText('class C<T extends List> {}');
    expect(cls.typeParameters, hasLength(1));
    {
      UnlinkedTypeParam typeParameter = cls.typeParameters[0];
      expect(typeParameter.name, 'T');
      expect(typeParameter.bound, isNotNull);
      checkTypeRef(typeParameter.bound, 'dart:core', 'List',
          numTypeParameters: 1);
    }
  }

  test_class_type_param_f_bound() {
    UnlinkedClass cls = serializeClassText('class C<T, U extends List<T>> {}');
    EntityRef typeArgument = cls.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 2);
  }

  test_class_type_param_f_bound_self_ref() {
    UnlinkedClass cls = serializeClassText('class C<T, U extends List<U>> {}');
    EntityRef typeArgument = cls.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 1);
  }

  test_class_type_param_no_bound() {
    String text = 'class C<T> {}';
    UnlinkedClass cls = serializeClassText(text);
    expect(cls.typeParameters, hasLength(1));
    expect(cls.typeParameters[0].name, 'T');
    if (includeInformative) {
      expect(cls.typeParameters[0].nameOffset, text.indexOf('T'));
    }
    expect(cls.typeParameters[0].bound, isNull);
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 1);
  }

  test_closure_executable_with_bottom_return_type() {
    UnlinkedVariable variable = serializeVariableText('var v = (() => null);');
    UnlinkedExecutable closure;
    {
      UnlinkedExecutable executable = variable.initializer;
      expect(executable.localFunctions, hasLength(1));
      expect(executable.localFunctions[0].returnType, isNull);
      closure = executable.localFunctions[0];
    }
    if (strongMode) {
      // Strong mode infers a type for the closure of `() => dynamic`, so the
      // inferred return type slot should be empty.
      expect(getTypeRefForSlot(closure.inferredReturnTypeSlot), isNull);
    } else {
      // Spec mode infers a type for the closure of `() => Bottom`.
      checkInferredTypeSlot(closure.inferredReturnTypeSlot, null, '*bottom*',
          onlyInStrongMode: false);
    }
  }

  test_closure_executable_with_imported_return_type() {
    addNamedSource('/a.dart', 'class C { D d; } class D {}');
    // The closure has type `() => D`; `D` is defined in a library that is
    // imported.
    UnlinkedExecutable executable = serializeVariableText(r'''
import "a.dart";
var v = (() {
  print((() => new C().d)());
});
''').initializer.localFunctions[0];
    expect(executable.localFunctions, hasLength(1));
    expect(executable.localFunctions[0].returnType, isNull);
    checkInferredTypeSlot(executable.localFunctions[0].inferredReturnTypeSlot,
        absUri('/a.dart'), 'D',
        onlyInStrongMode: false);
    checkHasDependency(absUri('/a.dart'), fullyLinked: false);
  }

  test_closure_executable_with_return_type_from_closure() {
    if (skipFullyLinkedData) {
      return;
    }
    // The closure has type `() => () => int`, where the `() => int` part refers
    // to the nested closure.
    UnlinkedExecutable executable = serializeExecutableText('''
f() {
  print(() {}); // force the closure below to have index 1
  print(() => () => 0);
}
''');
    expect(executable.localFunctions, hasLength(2));
    EntityRef closureType =
        getTypeRefForSlot(executable.localFunctions[1].inferredReturnTypeSlot);
    checkLinkedTypeRef(closureType, null, '',
        expectedKind: ReferenceKind.function);
    int outerClosureIndex =
        definingUnit.references[closureType.reference].containingReference;
    checkReferenceIndex(outerClosureIndex, null, '',
        expectedKind: ReferenceKind.function, localIndex: 1);
    int topLevelFunctionIndex =
        definingUnit.references[outerClosureIndex].containingReference;
    checkReferenceIndex(topLevelFunctionIndex, null, 'f',
        expectedKind: ReferenceKind.topLevelFunction);
    expect(
        definingUnit.references[topLevelFunctionIndex].containingReference, 0);
  }

  test_closure_executable_with_unimported_return_type() {
    addNamedSource('/a.dart', 'import "b.dart"; class C { D d; }');
    addNamedSource('/b.dart', 'class D {}');
    // The closure has type `() => D`; `D` is defined in a library that is not
    // imported.
    UnlinkedExecutable executable = serializeVariableText(r'''
import "a.dart";
var v = (() {
  print((() => new C().d)());
});
''').initializer.localFunctions[0];
    expect(executable.localFunctions, hasLength(1));
    expect(executable.localFunctions[0].returnType, isNull);
    checkInferredTypeSlot(executable.localFunctions[0].inferredReturnTypeSlot,
        absUri('/b.dart'), 'D',
        onlyInStrongMode: false);
    if (!skipFullyLinkedData) {
      checkHasDependency('b.dart', fullyLinked: true);
    }
  }

  test_constExpr_binary_add() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 + 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.add
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_and() {
    UnlinkedVariable variable =
        serializeVariableText('const v = true && false;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushTrue,
      UnlinkedExprOperation.pushFalse,
      UnlinkedExprOperation.and
    ]);
  }

  test_constExpr_binary_bitAnd() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 & 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.bitAnd
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_bitOr() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 | 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.bitOr
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_bitShiftLeft() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 << 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.bitShiftLeft
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_bitShiftRight() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 >> 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.bitShiftRight
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_bitXor() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 ^ 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.bitXor
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_divide() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 / 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.divide
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_equal() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 == 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.equal
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_equal_not() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 != 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.notEqual
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_floorDivide() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 ~/ 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.floorDivide
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_greater() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 > 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.greater
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_greaterEqual() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 >= 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.greaterEqual
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_less() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 < 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.less
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_lessEqual() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 <= 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.lessEqual
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_modulo() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 % 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.modulo
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_multiply() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 * 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.multiply
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_or() {
    UnlinkedVariable variable =
        serializeVariableText('const v = false || true;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushFalse,
      UnlinkedExprOperation.pushTrue,
      UnlinkedExprOperation.or
    ]);
  }

  test_constExpr_binary_qq() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 ?? 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.ifNull
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_binary_subtract() {
    UnlinkedVariable variable = serializeVariableText('const v = 1 - 2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.subtract
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_classMember_shadows_typeParam() {
    // Although it is an error for a class member to have the same name as a
    // type parameter, the spec makes it clear that the class member scope is
    // nested inside the type parameter scope.  So go ahead and verify that
    // the class member shadows the type parameter.
    String text = '''
class C<T> {
  static const T = null;
  final x;
  const C() : x = T;
}
''';
    UnlinkedClass cls = serializeClassText(text, allowErrors: true);
    assertUnlinkedConst(cls.executables[0].constantInitializers[0].expression,
        operators: [
          UnlinkedExprOperation.pushReference
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'T',
                  expectedKind: ReferenceKind.propertyAccessor,
                  prefixExpectations: [
                    new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                        numTypeParameters: 1)
                  ])
        ]);
  }

  test_constExpr_conditional() {
    UnlinkedVariable variable =
        serializeVariableText('const v = true ? 1 : 2;', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushTrue,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.conditional
    ], ints: [
      1,
      2
    ]);
  }

  test_constExpr_constructorParam_shadows_classMember() {
    UnlinkedClass cls = serializeClassText('''
class C {
  static const a = null;
  final b;
  const C(a) : b = a;
}
''');
    assertUnlinkedConst(cls.executables[0].constantInitializers[0].expression,
        operators: [UnlinkedExprOperation.pushParameter], strings: ['a']);
  }

  test_constExpr_constructorParam_shadows_typeParam() {
    UnlinkedClass cls = serializeClassText('''
class C<T> {
  final x;
  const C(T) : x = T;
}
''');
    assertUnlinkedConst(cls.executables[0].constantInitializers[0].expression,
        operators: [UnlinkedExprOperation.pushParameter], strings: ['T']);
  }

  test_constExpr_functionExpression() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
import 'dart:async';
const v = (f) async => await f;
''');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.await
        ],
        strings: [
          'f'
        ],
        ints: []);
  }

  test_constExpr_functionExpression_asArgument() {
    // Even though function expressions are not allowed in constant
    // declarations, they might occur due to erroneous code, so make sure they
    // function correctly.
    UnlinkedVariable variable = serializeVariableText('''
const v = foo(5, () => 42);
foo(a, b) {}
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.pushLocalFunctionReference,
          UnlinkedExprOperation.invokeMethodRef
        ],
        ints: [
          5,
          0,
          0,
          0,
          2,
          0
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.topLevelFunction)
        ]);
  }

  test_constExpr_functionExpression_asArgument_multiple() {
    // Even though function expressions are not allowed in constant
    // declarations, they might occur due to erroneous code, so make sure they
    // function correctly.
    UnlinkedVariable variable = serializeVariableText('''
const v = foo(5, () => 42, () => 43);
foo(a, b, c) {}
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.pushLocalFunctionReference,
          UnlinkedExprOperation.pushLocalFunctionReference,
          UnlinkedExprOperation.invokeMethodRef
        ],
        ints: [
          5,
          0,
          0,
          0,
          1,
          0,
          3,
          0
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.topLevelFunction)
        ]);
  }

  test_constExpr_functionExpression_inConstructorInitializers() {
    // Even though function expressions are not allowed in constant
    // declarations, they might occur due to erroneous code, so make sure they
    // function correctly.
    UnlinkedExecutable executable = serializeClassText('''
class C {
  final x, y;
  const C() : x = (() => 42), y = (() => 43);
}
''').executables[0];
    expect(executable.localFunctions, hasLength(2));
    assertUnlinkedConst(executable.constantInitializers[0].expression,
        isValidConst: false,
        operators: [UnlinkedExprOperation.pushLocalFunctionReference],
        ints: [0, 0]);
    assertUnlinkedConst(executable.constantInitializers[1].expression,
        isValidConst: false,
        operators: [UnlinkedExprOperation.pushLocalFunctionReference],
        ints: [0, 1]);
  }

  test_constExpr_invokeConstructor_generic_named() {
    UnlinkedVariable variable = serializeVariableText('''
class C<K, V> {
  const C.named();
}
const v = const C<int, String>.named();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) {
        checkTypeRef(r, null, 'named',
            expectedKind: ReferenceKind.constructor,
            prefixExpectations: [
              new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                  numTypeParameters: 2)
            ],
            numTypeArguments: 2);
        checkTypeRef(r.typeArguments[0], 'dart:core', 'int');
        checkTypeRef(r.typeArguments[1], 'dart:core', 'String');
      }
    ]);
  }

  test_constExpr_invokeConstructor_generic_named_imported() {
    addNamedSource('/a.dart', '''
class C<K, V> {
  const C.named();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = const C<int, String>.named();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) {
        checkTypeRef(r, null, 'named',
            expectedKind: ReferenceKind.constructor,
            prefixExpectations: [
              new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                  absoluteUri: absUri('/a.dart'), numTypeParameters: 2)
            ],
            numTypeArguments: 2);
        checkTypeRef(r.typeArguments[0], 'dart:core', 'int');
        checkTypeRef(r.typeArguments[1], 'dart:core', 'String');
      }
    ]);
  }

  test_constExpr_invokeConstructor_generic_named_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C<K, V> {
  const C.named();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = const p.C<int, String>.named();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) {
        checkTypeRef(r, null, 'named',
            expectedKind: ReferenceKind.constructor,
            prefixExpectations: [
              new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                  absoluteUri: absUri('/a.dart'), numTypeParameters: 2),
              new _PrefixExpectation(ReferenceKind.prefix, 'p')
            ],
            numTypeArguments: 2);
        checkTypeRef(r.typeArguments[0], 'dart:core', 'int');
        checkTypeRef(r.typeArguments[1], 'dart:core', 'String');
      }
    ]);
  }

  test_constExpr_invokeConstructor_generic_unnamed() {
    UnlinkedVariable variable = serializeVariableText('''
class C<K, V> {
  const C();
}
const v = const C<int, String>();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) {
        checkTypeRef(r, null, 'C',
            expectedKind: ReferenceKind.classOrEnum,
            numTypeParameters: 2,
            numTypeArguments: 2);
        checkTypeRef(r.typeArguments[0], 'dart:core', 'int');
        checkTypeRef(r.typeArguments[1], 'dart:core', 'String');
      }
    ]);
  }

  test_constExpr_invokeConstructor_generic_unnamed_imported() {
    addNamedSource('/a.dart', '''
class C<K, V> {
  const C();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = const C<int, String>();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) {
        checkTypeRef(r, absUri('/a.dart'), 'C',
            expectedKind: ReferenceKind.classOrEnum,
            numTypeParameters: 2,
            numTypeArguments: 2);
        checkTypeRef(r.typeArguments[0], 'dart:core', 'int');
        checkTypeRef(r.typeArguments[1], 'dart:core', 'String');
      }
    ]);
  }

  test_constExpr_invokeConstructor_generic_unnamed_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C<K, V> {
  const C();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = const p.C<int, String>();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) {
        checkTypeRef(r, absUri('/a.dart'), 'C',
            expectedKind: ReferenceKind.classOrEnum,
            numTypeParameters: 2,
            numTypeArguments: 2,
            prefixExpectations: [
              new _PrefixExpectation(ReferenceKind.prefix, 'p')
            ]);
        checkTypeRef(r.typeArguments[0], 'dart:core', 'int');
        checkTypeRef(r.typeArguments[1], 'dart:core', 'String');
      }
    ]);
  }

  test_constExpr_invokeConstructor_named() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  const C.named();
}
const v = const C.named();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.constructor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_invokeConstructor_named_imported() {
    addNamedSource('/a.dart', '''
class C {
  const C.named();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = const C.named();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.constructor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart'))
              ])
    ]);
  }

  test_constExpr_invokeConstructor_named_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C {
  const C.named();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = const p.C.named();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.constructor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_invokeConstructor_unnamed() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  const C(a, b, c, d, {e, f, g});
}
const v = const C(11, 22, 3.3, '444', e: 55, g: '777', f: 66);
''');
    // Stack: 11 22 3.3 '444' 55 '777' 66 ^head
    // Ints: ^pointer 3 4
    // Doubles: ^pointer
    // Strings: ^pointer 'e' 'g' 'f' ''
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushDouble,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      11,
      22,
      55,
      66,
      3,
      4,
    ], doubles: [
      3.3
    ], strings: [
      '444',
      '777',
      'e',
      'g',
      'f'
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'C', expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_constExpr_invokeConstructor_unnamed_imported() {
    addNamedSource('/a.dart', '''
class C {
  const C();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = const C();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'C',
          expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_constExpr_invokeConstructor_unnamed_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C {
  const C();
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = const p.C();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'C',
              expectedKind: ReferenceKind.classOrEnum,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_invokeConstructor_unresolved_named() {
    UnlinkedVariable variable = serializeVariableText('''
class C {}
const v = const C.foo();
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_invokeConstructor_unresolved_named2() {
    UnlinkedVariable variable = serializeVariableText('''
const v = const C.foo();
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.unresolved, 'C')
              ])
    ]);
  }

  test_constExpr_invokeConstructor_unresolved_named_prefixed() {
    addNamedSource('/a.dart', '''
class C {
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = const p.C.foo();
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_invokeConstructor_unresolved_named_prefixed2() {
    addNamedSource('/a.dart', '');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = const p.C.foo();
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.unresolved, 'C'),
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_invokeConstructor_unresolved_unnamed() {
    UnlinkedVariable variable = serializeVariableText('''
const v = const Foo();
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'Foo', expectedKind: ReferenceKind.unresolved)
    ]);
  }

  test_constExpr_invokeMethodRef_identical() {
    UnlinkedVariable variable =
        serializeVariableText('const v = identical(42, null);');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushNull,
      UnlinkedExprOperation.invokeMethodRef
    ], ints: [
      42,
      0,
      2,
      0
    ], referenceValidators: [
      (EntityRef r) {
        checkTypeRef(r, 'dart:core', 'identical',
            expectedKind: ReferenceKind.topLevelFunction);
      }
    ]);
  }

  test_constExpr_length_classConstField() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  static const int length = 0;
}
const int v = C.length;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'length',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_length_classConstField_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C {
  static const int length = 0;
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const int v = p.C.length;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'length',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_length_identifierTarget() {
    UnlinkedVariable variable = serializeVariableText('''
const String a = 'aaa';
const int v = a.length;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'length',
              expectedKind: ReferenceKind.unresolved,
              unresolvedHasName: true,
              prefixExpectations: [
                new _PrefixExpectation(
                    ReferenceKind.topLevelPropertyAccessor, 'a')
              ])
    ]);
  }

  test_constExpr_length_identifierTarget_classConstField() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  static const String F = '';
}
const int v = C.F.length;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'length',
              expectedKind: ReferenceKind.unresolved,
              unresolvedHasName: true,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.propertyAccessor, 'F'),
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C'),
              ])
    ]);
  }

  test_constExpr_length_identifierTarget_imported() {
    addNamedSource('/a.dart', '''
const String a = 'aaa';
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const int v = a.length;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'length',
              expectedKind: ReferenceKind.unresolved,
              unresolvedHasName: true,
              prefixExpectations: [
                new _PrefixExpectation(
                    ReferenceKind.topLevelPropertyAccessor, 'a',
                    absoluteUri: absUri('/a.dart'))
              ])
    ]);
  }

  test_constExpr_length_identifierTarget_imported_withPrefix() {
    addNamedSource('/a.dart', '''
const String a = 'aaa';
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const int v = p.a.length;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'length',
              expectedKind: ReferenceKind.unresolved,
              unresolvedHasName: true,
              prefixExpectations: [
                new _PrefixExpectation(
                    ReferenceKind.topLevelPropertyAccessor, 'a',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_length_parenthesizedBinaryTarget() {
    UnlinkedVariable variable =
        serializeVariableText('const v = ("abc" + "edf").length;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.add,
      UnlinkedExprOperation.extractProperty
    ], strings: [
      'abc',
      'edf',
      'length'
    ]);
  }

  test_constExpr_length_parenthesizedStringTarget() {
    UnlinkedVariable variable =
        serializeVariableText('const v = ("abc").length;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.extractProperty
    ], strings: [
      'abc',
      'length'
    ]);
  }

  test_constExpr_length_stringLiteralTarget() {
    UnlinkedVariable variable =
        serializeVariableText('const v = "abc".length;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.extractProperty
    ], strings: [
      'abc',
      'length'
    ]);
  }

  test_constExpr_makeSymbol() {
    UnlinkedVariable variable = serializeVariableText('const v = #a.bb.ccc;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.makeSymbol], strings: ['a.bb.ccc']);
  }

  test_constExpr_makeTypedList() {
    UnlinkedVariable variable =
        serializeVariableText('const v = const <int>[11, 22, 33];');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.makeTypedList
    ], ints: [
      11,
      22,
      33,
      3
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, 'dart:core', 'int',
          expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_constExpr_makeTypedList_dynamic() {
    UnlinkedVariable variable =
        serializeVariableText('const v = const <dynamic>[11, 22, 33];');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.makeTypedList
    ], ints: [
      11,
      22,
      33,
      3
    ], referenceValidators: [
      (EntityRef r) => checkDynamicTypeRef(r)
    ]);
  }

  test_constExpr_makeTypedMap() {
    UnlinkedVariable variable = serializeVariableText(
        'const v = const <int, String>{11: "aaa", 22: "bbb", 33: "ccc"};');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.makeTypedMap
    ], ints: [
      11,
      22,
      33,
      3
    ], strings: [
      'aaa',
      'bbb',
      'ccc'
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, 'dart:core', 'int',
          expectedKind: ReferenceKind.classOrEnum),
      (EntityRef r) => checkTypeRef(r, 'dart:core', 'String',
          expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_constExpr_makeTypedMap_dynamic() {
    UnlinkedVariable variable = serializeVariableText(
        'const v = const <dynamic, dynamic>{11: "aaa", 22: "bbb", 33: "ccc"};');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.makeTypedMap
    ], ints: [
      11,
      22,
      33,
      3
    ], strings: [
      'aaa',
      'bbb',
      'ccc'
    ], referenceValidators: [
      (EntityRef r) => checkDynamicTypeRef(r),
      (EntityRef r) => checkDynamicTypeRef(r)
    ]);
  }

  test_constExpr_makeUntypedList() {
    UnlinkedVariable variable =
        serializeVariableText('const v = const [11, 22, 33];');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.makeUntypedList
    ], ints: [
      11,
      22,
      33,
      3
    ]);
  }

  test_constExpr_makeUntypedMap() {
    UnlinkedVariable variable = serializeVariableText(
        'const v = const {11: "aaa", 22: "bbb", 33: "ccc"};');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.makeUntypedMap
    ], ints: [
      11,
      22,
      33,
      3
    ], strings: [
      'aaa',
      'bbb',
      'ccc'
    ]);
  }

  test_constExpr_parenthesized() {
    UnlinkedVariable variable = serializeVariableText('const v = (1 + 2) * 3;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.add,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.multiply,
    ], ints: [
      1,
      2,
      3
    ]);
  }

  test_constExpr_prefix_complement() {
    UnlinkedVariable variable = serializeVariableText('const v = ~2;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.complement
    ], ints: [
      2
    ]);
  }

  test_constExpr_prefix_negate() {
    UnlinkedVariable variable = serializeVariableText('const v = -(2);');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.negate
    ], ints: [
      2
    ]);
  }

  test_constExpr_prefix_not() {
    UnlinkedVariable variable = serializeVariableText('const v = !true;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushTrue, UnlinkedExprOperation.not]);
  }

  test_constExpr_pushDouble() {
    UnlinkedVariable variable = serializeVariableText('const v = 123.4567;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushDouble], doubles: [123.4567]);
  }

  test_constExpr_pushFalse() {
    UnlinkedVariable variable = serializeVariableText('const v = false;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushFalse]);
  }

  test_constExpr_pushInt() {
    UnlinkedVariable variable = serializeVariableText('const v = 1;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [1]);
  }

  test_constExpr_pushInt_max() {
    UnlinkedVariable variable = serializeVariableText('const v = 0xFFFFFFFF;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
    ], ints: [
      0xFFFFFFFF
    ]);
  }

  test_constExpr_pushInt_negative() {
    UnlinkedVariable variable = serializeVariableText('const v = -5;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.negate
    ], ints: [
      5
    ]);
  }

  test_constExpr_pushLongInt() {
    UnlinkedVariable variable =
        serializeVariableText('const v = 0xA123456789ABCDEF012345678;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushLongInt],
        ints: [4, 0xA, 0x12345678, 0x9ABCDEF0, 0x12345678]);
  }

  test_constExpr_pushLongInt_min2() {
    UnlinkedVariable variable = serializeVariableText('const v = 0x100000000;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushLongInt
    ], ints: [
      2,
      1,
      0,
    ]);
  }

  test_constExpr_pushLongInt_min3() {
    UnlinkedVariable variable =
        serializeVariableText('const v = 0x10000000000000000;');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushLongInt
    ], ints: [
      3,
      1,
      0,
      0,
    ]);
  }

  test_constExpr_pushNull() {
    UnlinkedVariable variable = serializeVariableText('const v = null;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushNull]);
  }

  test_constExpr_pushReference_class() {
    UnlinkedVariable variable = serializeVariableText('''
class C {}
const v = C;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'C', expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_constExpr_pushReference_enum() {
    UnlinkedVariable variable = serializeVariableText('''
enum C {V1, V2, V3}
const v = C;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'C', expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_constExpr_pushReference_enumValue() {
    UnlinkedVariable variable = serializeVariableText('''
enum C {V1, V2, V3}
const v = C.V1;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'V1',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_enumValue_viaImport() {
    addNamedSource('/a.dart', '''
enum C {V1, V2, V3}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = C.V1;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'V1',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart'))
              ])
    ]);
  }

  test_constExpr_pushReference_enumValues() {
    UnlinkedVariable variable = serializeVariableText('''
enum C {V1, V2, V3}
const v = C.values;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'values',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_enumValues_viaImport() {
    addNamedSource('/a.dart', '''
enum C {V1, V2, V3}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = C.values;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'values',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart'))
              ])
    ]);
  }

  test_constExpr_pushReference_field() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  static const int F = 1;
}
const v = C.F;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'F',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_field_imported() {
    addNamedSource('/a.dart', '''
class C {
  static const int F = 1;
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = C.F;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'F',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart'))
              ])
    ]);
  }

  test_constExpr_pushReference_field_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C {
  static const int F = 1;
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = p.C.F;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'F',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p'),
              ])
    ]);
  }

  test_constExpr_pushReference_field_simpleIdentifier() {
    UnlinkedVariable variable = serializeClassText('''
class C {
  static const a = b;
  static const b = null;
}
''').fields[0];
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'b',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_staticGetter() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  static int get x => null;
}
const v = C.x;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'x',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_staticGetter_imported() {
    addNamedSource('/a.dart', '''
class C {
  static int get x => null;
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = C.x;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'x',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart'))
              ])
    ]);
  }

  test_constExpr_pushReference_staticGetter_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C {
  static int get x => null;
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = p.C.x;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'x',
              expectedKind: ReferenceKind.propertyAccessor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_pushReference_staticMethod() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  static m() {}
}
const v = C.m;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'm',
              expectedKind: ReferenceKind.method,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_staticMethod_imported() {
    addNamedSource('/a.dart', '''
class C {
  static m() {}
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = C.m;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'm',
              expectedKind: ReferenceKind.method,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart'))
              ])
    ]);
  }

  test_constExpr_pushReference_staticMethod_imported_withPrefix() {
    addNamedSource('/a.dart', '''
class C {
  static m() {}
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = p.C.m;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'm',
              expectedKind: ReferenceKind.method,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_pushReference_staticMethod_simpleIdentifier() {
    UnlinkedVariable variable = serializeClassText('''
class C {
  static const a = m;
  static m() {}
}
''').fields[0];
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'm',
              expectedKind: ReferenceKind.method,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_topLevelFunction() {
    UnlinkedVariable variable = serializeVariableText('''
f() {}
const v = f;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'f',
          expectedKind: ReferenceKind.topLevelFunction)
    ]);
  }

  test_constExpr_pushReference_topLevelFunction_imported() {
    addNamedSource('/a.dart', '''
f() {}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = f;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'f',
          expectedKind: ReferenceKind.topLevelFunction)
    ]);
  }

  test_constExpr_pushReference_topLevelFunction_imported_withPrefix() {
    addNamedSource('/a.dart', '''
f() {}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = p.f;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'f',
              expectedKind: ReferenceKind.topLevelFunction,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.prefix, 'p')
              ])
    ]);
  }

  test_constExpr_pushReference_topLevelGetter() {
    UnlinkedVariable variable = serializeVariableText('''
int get x => null;
const v = x;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'x',
          expectedKind: ReferenceKind.topLevelPropertyAccessor)
    ]);
  }

  test_constExpr_pushReference_topLevelGetter_imported() {
    addNamedSource('/a.dart', 'int get x => null;');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = x;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'x',
          expectedKind: ReferenceKind.topLevelPropertyAccessor)
    ]);
  }

  test_constExpr_pushReference_topLevelGetter_imported_withPrefix() {
    addNamedSource('/a.dart', 'int get x => null;');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = p.x;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'x',
          expectedKind: ReferenceKind.topLevelPropertyAccessor,
          expectedPrefix: 'p')
    ]);
  }

  test_constExpr_pushReference_topLevelVariable() {
    UnlinkedVariable variable = serializeVariableText('''
const int a = 1;
const v = a;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'a',
          expectedKind: ReferenceKind.topLevelPropertyAccessor)
    ]);
  }

  test_constExpr_pushReference_topLevelVariable_imported() {
    addNamedSource('/a.dart', 'const int a = 1;');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
const v = a;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'a',
          expectedKind: ReferenceKind.topLevelPropertyAccessor)
    ]);
  }

  test_constExpr_pushReference_topLevelVariable_imported_withPrefix() {
    addNamedSource('/a.dart', 'const int a = 1;');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = p.a;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) {
        return checkTypeRef(r, absUri('/a.dart'), 'a',
            expectedKind: ReferenceKind.topLevelPropertyAccessor,
            expectedPrefix: 'p');
      }
    ]);
  }

  test_constExpr_pushReference_typeParameter() {
    String text = '''
class C<T> {
  static const a = T;
}
''';
    UnlinkedVariable variable =
        serializeClassText(text, allowErrors: true).fields[0];
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) {
        return checkParamTypeRef(r, 1);
      }
    ]);
  }

  test_constExpr_pushReference_unresolved_prefix0() {
    UnlinkedVariable variable = serializeVariableText('''
const v = foo;
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'foo', expectedKind: ReferenceKind.unresolved)
    ]);
  }

  test_constExpr_pushReference_unresolved_prefix1() {
    UnlinkedVariable variable = serializeVariableText('''
class C {}
const v = C.foo;
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
              ])
    ]);
  }

  test_constExpr_pushReference_unresolved_prefix2() {
    addNamedSource('/a.dart', '''
class C {}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
const v = p.C.foo;
''', allowErrors: true);
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                    absoluteUri: absUri('/a.dart')),
                new _PrefixExpectation(ReferenceKind.prefix, 'p'),
              ])
    ]);
  }

  test_constExpr_pushString_adjacent() {
    UnlinkedVariable variable =
        serializeVariableText('const v = "aaa" "b" "ccc";');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushString], strings: ['aaabccc']);
  }

  test_constExpr_pushString_adjacent_interpolation() {
    UnlinkedVariable variable =
        serializeVariableText(r'const v = "aaa" "bb ${42} bbb" "cccc";');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.concatenate,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.concatenate,
    ], ints: [
      42,
      3,
      3,
    ], strings: [
      'aaa',
      'bb ',
      ' bbb',
      'cccc'
    ]);
  }

  test_constExpr_pushString_interpolation() {
    UnlinkedVariable variable =
        serializeVariableText(r'const v = "aaa ${42} bbb";');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.concatenate
    ], ints: [
      42,
      3
    ], strings: [
      'aaa ',
      ' bbb'
    ]);
  }

  test_constExpr_pushString_simple() {
    UnlinkedVariable variable = serializeVariableText('const v = "abc";');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushString], strings: ['abc']);
  }

  test_constExpr_pushTrue() {
    UnlinkedVariable variable = serializeVariableText('const v = true;');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushTrue]);
  }

  test_constructor() {
    String text = 'class C { C(); }';
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(text).executables);
    expect(executable.kind, UnlinkedExecutableKind.constructor);
    expect(executable.returnType, isNull);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.isGenerator, isFalse);
    if (includeInformative) {
      expect(executable.nameOffset, text.indexOf('C();'));
      expect(executable.periodOffset, 0);
      expect(executable.nameEnd, 0);
    }
    expect(executable.isRedirectedConstructor, isFalse);
    expect(executable.redirectedConstructor, isNull);
    expect(executable.redirectedConstructorName, isEmpty);

    if (includeInformative) {
      expect(executable.visibleOffset, 0);
      expect(executable.visibleLength, 0);
    }
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
    expect(executable.isExternal, isFalse);
  }

  test_constructor_const_external() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { external const C(); }').executables);
    expect(executable.isConst, isTrue);
    expect(executable.isExternal, isTrue);
  }

  test_constructor_documented() {
    if (!includeInformative) return;
    String text = '''
class C {
  /**
   * Docs
   */
  C();
}''';
    UnlinkedExecutable executable = serializeClassText(text).executables[0];
    expect(executable.documentationComment, isNotNull);
    checkDocumentationComment(executable.documentationComment, text);
  }

  test_constructor_external() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { external C(); }').executables);
    expect(executable.isExternal, isTrue);
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

  test_constructor_initializers_assertInvocation() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  const C(int x) : assert(x >= 42);
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(
        initializer.kind, UnlinkedConstructorInitializerKind.assertInvocation);
    expect(initializer.name, '');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(1));
    assertUnlinkedConst(initializer.arguments[0], operators: [
      UnlinkedExprOperation.pushParameter,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.greaterEqual
    ], ints: [
      42
    ], strings: [
      'x'
    ]);
  }

  test_constructor_initializers_assertInvocation_message() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  const C(int x) : assert(x >= 42, 'foo');
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(
        initializer.kind, UnlinkedConstructorInitializerKind.assertInvocation);
    expect(initializer.name, '');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(2));
    assertUnlinkedConst(initializer.arguments[0], operators: [
      UnlinkedExprOperation.pushParameter,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.greaterEqual
    ], ints: [
      42
    ], strings: [
      'x',
    ]);
    assertUnlinkedConst(initializer.arguments[1], operators: [
      UnlinkedExprOperation.pushString,
    ], strings: [
      'foo'
    ]);
  }

  test_constructor_initializers_field() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  final x;
  const C() : x = 42;
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(initializer.kind, UnlinkedConstructorInitializerKind.field);
    expect(initializer.name, 'x');
    assertUnlinkedConst(initializer.expression,
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
    expect(initializer.arguments, isEmpty);
  }

  test_constructor_initializers_field_withParameter() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  final x;
  const C(int p) : x = p;
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(initializer.kind, UnlinkedConstructorInitializerKind.field);
    expect(initializer.name, 'x');
    assertUnlinkedConst(initializer.expression,
        operators: [UnlinkedExprOperation.pushParameter], strings: ['p']);
    expect(initializer.arguments, isEmpty);
  }

  test_constructor_initializers_notConst() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  final x;
  C() : x = 42;
}
''').executables);
    expect(executable.constantInitializers, isEmpty);
  }

  test_constructor_initializers_superInvocation_named() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.aaa(42);
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(
        initializer.kind, UnlinkedConstructorInitializerKind.superInvocation);
    expect(initializer.name, 'aaa');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(1));
    assertUnlinkedConst(initializer.arguments[0],
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
  }

  test_constructor_initializers_superInvocation_namedExpression() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class A {
  const A(a, {int b, int c});
}
class C extends A {
  const C() : super(1, b: 2, c: 3);
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(
        initializer.kind, UnlinkedConstructorInitializerKind.superInvocation);
    expect(initializer.name, '');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(3));
    assertUnlinkedConst(initializer.arguments[0],
        operators: [UnlinkedExprOperation.pushInt], ints: [1]);
    assertUnlinkedConst(initializer.arguments[1],
        operators: [UnlinkedExprOperation.pushInt], ints: [2]);
    assertUnlinkedConst(initializer.arguments[2],
        operators: [UnlinkedExprOperation.pushInt], ints: [3]);
    expect(initializer.argumentNames, ['b', 'c']);
  }

  test_constructor_initializers_superInvocation_unnamed() {
    UnlinkedExecutable executable =
        findExecutable('ccc', executables: serializeClassText(r'''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(
        initializer.kind, UnlinkedConstructorInitializerKind.superInvocation);
    expect(initializer.name, '');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(1));
    assertUnlinkedConst(initializer.arguments[0],
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
  }

  test_constructor_initializers_thisInvocation_named() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  const C() : this.named(1, 'bbb');
  const C.named(int a, String b);
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(initializer.kind, UnlinkedConstructorInitializerKind.thisInvocation);
    expect(initializer.name, 'named');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(2));
    assertUnlinkedConst(initializer.arguments[0],
        operators: [UnlinkedExprOperation.pushInt], ints: [1]);
    assertUnlinkedConst(initializer.arguments[1],
        operators: [UnlinkedExprOperation.pushString], strings: ['bbb']);
  }

  test_constructor_initializers_thisInvocation_namedExpression() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  const C() : this.named(1, b: 2, c: 3);
  const C.named(a, {int b, int c});
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(initializer.kind, UnlinkedConstructorInitializerKind.thisInvocation);
    expect(initializer.name, 'named');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(3));
    assertUnlinkedConst(initializer.arguments[0],
        operators: [UnlinkedExprOperation.pushInt], ints: [1]);
    assertUnlinkedConst(initializer.arguments[1],
        operators: [UnlinkedExprOperation.pushInt], ints: [2]);
    assertUnlinkedConst(initializer.arguments[2],
        operators: [UnlinkedExprOperation.pushInt], ints: [3]);
    expect(initializer.argumentNames, ['b', 'c']);
  }

  test_constructor_initializers_thisInvocation_unnamed() {
    UnlinkedExecutable executable =
        findExecutable('named', executables: serializeClassText(r'''
class C {
  const C.named() : this(1, 'bbb');
  const C(int a, String b);
}
''').executables);
    expect(executable.constantInitializers, hasLength(1));
    UnlinkedConstructorInitializer initializer =
        executable.constantInitializers[0];
    expect(initializer.kind, UnlinkedConstructorInitializerKind.thisInvocation);
    expect(initializer.name, '');
    expect(initializer.expression, isNull);
    expect(initializer.arguments, hasLength(2));
    assertUnlinkedConst(initializer.arguments[0],
        operators: [UnlinkedExprOperation.pushInt], ints: [1]);
    assertUnlinkedConst(initializer.arguments[1],
        operators: [UnlinkedExprOperation.pushString], strings: ['bbb']);
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
    checkTypeRef(parameter.type, 'dart:core', 'int');
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
    checkTypeRef(parameter.type, 'dart:core', 'int');
  }

  test_constructor_initializing_formal_function_typed_implicit_return_type() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x()); Function x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.isFunctionTyped, isTrue);
    expect(parameter.type, isNull);
  }

  test_constructor_initializing_formal_function_typed_no_parameters() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x()); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.parameters, isEmpty);
  }

  test_constructor_initializing_formal_function_typed_parameter() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x(a)); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.parameters, hasLength(1));
  }

  test_constructor_initializing_formal_function_typed_parameter_order() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(this.x(a, b)); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.parameters, hasLength(2));
    expect(parameter.parameters[0].name, 'a');
    expect(parameter.parameters[1].name, 'b');
  }

  test_constructor_initializing_formal_function_typed_withDefault() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  C([this.x() = foo]);
  final x;
}
int foo() => 0;
''').executables);
    UnlinkedParam param = executable.parameters[0];
    expect(param.isFunctionTyped, isTrue);
    expect(param.kind, UnlinkedParamKind.positional);
    expect(param.defaultValueCode, 'foo');
    assertUnlinkedConst(param.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
          expectedKind: ReferenceKind.topLevelFunction)
    ]);
  }

  test_constructor_initializing_formal_implicit_type() {
    // Note: the implicit type of an initializing formal is the type of the
    // field.
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); int x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.type, isNull);
  }

  test_constructor_initializing_formal_name() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); final x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.name, 'x');
  }

  test_constructor_initializing_formal_named() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C({this.x}); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.named);
    expect(parameter.initializer, isNull);
    expect(parameter.defaultValueCode, isEmpty);
  }

  test_constructor_initializing_formal_named_withDefault() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C({this.x: 42}); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.named);
    expect(parameter.initializer, isNotNull);
    expect(parameter.defaultValueCode, '42');
    if (includeInformative) {
      _assertCodeRange(parameter.codeRange, 13, 10);
    }
    assertUnlinkedConst(parameter.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
  }

  test_constructor_initializing_formal_non_function_typed() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); final x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.isFunctionTyped, isFalse);
  }

  test_constructor_initializing_formal_positional() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C([this.x]); final x; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.positional);
    expect(parameter.initializer, isNull);
    expect(parameter.defaultValueCode, isEmpty);
  }

  test_constructor_initializing_formal_positional_withDefault() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C([this.x = 42]); final x; }')
                .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.positional);
    expect(parameter.initializer, isNotNull);
    expect(parameter.defaultValueCode, '42');
    if (includeInformative) {
      _assertCodeRange(parameter.codeRange, 13, 11);
    }
    assertUnlinkedConst(parameter.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
  }

  test_constructor_initializing_formal_required() {
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); final x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.kind, UnlinkedParamKind.required);
  }

  test_constructor_initializing_formal_typedef() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText(
                'typedef F<T>(T x); class C<X> { C(this.f); F<X> f; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.isFunctionTyped, isFalse);
    expect(parameter.parameters, isEmpty);
  }

  test_constructor_initializing_formal_withDefault() {
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(r'''
class C {
  C([this.x = 42]);
  final int x;
}''').executables);
    UnlinkedParam param = executable.parameters[0];
    expect(param.kind, UnlinkedParamKind.positional);
    expect(param.defaultValueCode, '42');
    assertUnlinkedConst(param.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
  }

  test_constructor_named() {
    String text = 'class C { C.foo(); }';
    UnlinkedExecutable executable = findExecutable('foo',
        executables: serializeClassText(text).executables);
    expect(executable.name, 'foo');
    if (includeInformative) {
      expect(executable.nameOffset, text.indexOf('foo'));
      expect(executable.periodOffset, text.indexOf('.foo'));
      expect(executable.nameEnd, text.indexOf('()'));
      _assertCodeRange(executable.codeRange, 10, 8);
    }
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

  test_constructor_param_inferred_type_explicit() {
    UnlinkedExecutable ctor =
        serializeClassText('class C { C(int v); }').executables[0];
    expect(ctor.kind, UnlinkedExecutableKind.constructor);
    expect(ctor.parameters[0].inferredTypeSlot, 0);
  }

  test_constructor_param_inferred_type_implicit() {
    UnlinkedExecutable ctor =
        serializeClassText('class C { C(v); }').executables[0];
    expect(ctor.kind, UnlinkedExecutableKind.constructor);
    expect(ctor.parameters[0].inferredTypeSlot, 0);
  }

  test_constructor_redirected_factory_named() {
    String text = '''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named() : super._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'named',
        expectedKind: ReferenceKind.constructor,
        prefixExpectations: [
          new _PrefixExpectation(ReferenceKind.classOrEnum, 'D')
        ]);
  }

  test_constructor_redirected_factory_named_generic() {
    String text = '''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'named',
        expectedKind: ReferenceKind.constructor,
        prefixExpectations: [
          new _PrefixExpectation(ReferenceKind.classOrEnum, 'D',
              numTypeParameters: 2)
        ],
        numTypeArguments: 2);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[0], 1);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[1], 2);
  }

  test_constructor_redirected_factory_named_imported() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    String text = '''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'named',
        expectedKind: ReferenceKind.constructor,
        prefixExpectations: [
          new _PrefixExpectation(
            ReferenceKind.classOrEnum,
            'D',
            absoluteUri: absUri('/foo.dart'),
          )
        ]);
  }

  test_constructor_redirected_factory_named_imported_generic() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    String text = '''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'named',
        expectedKind: ReferenceKind.constructor,
        prefixExpectations: [
          new _PrefixExpectation(
            ReferenceKind.classOrEnum,
            'D',
            numTypeParameters: 2,
            absoluteUri: absUri('/foo.dart'),
          )
        ],
        numTypeArguments: 2);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[0], 1);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[1], 2);
  }

  test_constructor_redirected_factory_named_prefixed() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    String text = '''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D.named;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'named',
        expectedKind: ReferenceKind.constructor,
        prefixExpectations: [
          new _PrefixExpectation(
            ReferenceKind.classOrEnum,
            'D',
            absoluteUri: absUri('/foo.dart'),
          ),
          new _PrefixExpectation(ReferenceKind.prefix, 'foo')
        ]);
  }

  test_constructor_redirected_factory_named_prefixed_generic() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    String text = '''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>.named;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'named',
        expectedKind: ReferenceKind.constructor,
        prefixExpectations: [
          new _PrefixExpectation(
            ReferenceKind.classOrEnum,
            'D',
            numTypeParameters: 2,
            absoluteUri: absUri('/foo.dart'),
          ),
          new _PrefixExpectation(ReferenceKind.prefix, 'foo')
        ],
        numTypeArguments: 2);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[0], 1);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[1], 2);
  }

  test_constructor_redirected_factory_unnamed() {
    String text = '''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D() : super._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'D');
  }

  test_constructor_redirected_factory_unnamed_generic() {
    String text = '''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D() : super._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, null, 'D',
        numTypeParameters: 2, numTypeArguments: 2);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[0], 1);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[1], 2);
  }

  test_constructor_redirected_factory_unnamed_imported() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    String text = '''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, absUri('/foo.dart'), 'D');
  }

  test_constructor_redirected_factory_unnamed_imported_generic() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    String text = '''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, absUri('/foo.dart'), 'D',
        numTypeParameters: 2, numTypeArguments: 2);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[0], 1);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[1], 2);
  }

  test_constructor_redirected_factory_unnamed_prefixed() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    String text = '''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, absUri('/foo.dart'), 'D',
        expectedPrefix: 'foo');
  }

  test_constructor_redirected_factory_unnamed_prefixed_generic() {
    addNamedSource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    String text = '''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>;
  C._();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isTrue);
    expect(executable.redirectedConstructorName, isEmpty);
    checkTypeRef(executable.redirectedConstructor, absUri('/foo.dart'), 'D',
        numTypeParameters: 2, expectedPrefix: 'foo', numTypeArguments: 2);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[0], 1);
    checkParamTypeRef(executable.redirectedConstructor.typeArguments[1], 2);
  }

  test_constructor_redirected_thisInvocation_named() {
    String text = '''
class C {
  C() : this.named();
  C.named();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isFalse);
    expect(executable.redirectedConstructorName, 'named');
    expect(executable.redirectedConstructor, isNull);
  }

  test_constructor_redirected_thisInvocation_unnamed() {
    String text = '''
class C {
  C.named() : this();
  C();
}
''';
    UnlinkedExecutable executable =
        serializeClassText(text, className: 'C').executables[0];
    expect(executable.isRedirectedConstructor, isTrue);
    expect(executable.isFactory, isFalse);
    expect(executable.redirectedConstructorName, isEmpty);
    expect(executable.redirectedConstructor, isNull);
  }

  test_constructor_return_type() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C { C(); }').executables);
    expect(executable.returnType, isNull);
  }

  test_constructor_return_type_parameterized() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C<T, U> { C(); }').executables);
    expect(executable.returnType, isNull);
  }

  test_constructor_withCycles_const() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = const D();
}
class D {
  final x;
  const D() : x = const C();
}
class E {
  final x;
  const E() : x = null;
}
''');
    checkConstCycle('C');
    checkConstCycle('D');
    checkConstCycle('E', hasCycle: false);
  }

  test_constructor_withCycles_nonConst() {
    serializeLibraryText('''
class C {
  final x;
  C() : x = new D();
}
class D {
  final x;
  D() : x = new C();
}
''');
    expect(findClass('C').executables[0].constCycleSlot, 0);
    expect(findClass('D').executables[0].constCycleSlot, 0);
  }

  test_constructorCycle_redirectToImplicitConstructor() {
    serializeLibraryText('''
class C {
  const factory C() = D;
}
class D extends C {}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_redirectToNonConstConstructor() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    serializeLibraryText('''
class C {
  const factory C() = D;
}
class D extends C {
  D();
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_redirectToSymbolConstructor() {
    // The symbol constructor has some special case behaviors in analyzer.
    // Make sure those special case behaviors don't cause problems.
    serializeLibraryText('''
class C {
  const factory C(String name) = Symbol;
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToClass() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = C;
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToEnum() {
    serializeLibraryText('''
enum E { v }
class C {
  final x;
  const C() : x = E;
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToEnumValue() {
    serializeLibraryText('''
enum E { v }
class C {
  final x;
  const C() : x = E.v;
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToEnumValues() {
    serializeLibraryText('''
enum E { v }
class C {
  final x;
  const C() : x = E.values;
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToGenericParameter() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    serializeLibraryText('''
class C<T> {
  final x;
  const C() : x = T;
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToGenericParameter_asSupertype() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    serializeLibraryText('''
class C<T> extends T {
  const C();
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToStaticMethod_inOtherClass() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = D.f;
}
class D {
  static void f() {}
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToStaticMethod_inSameClass() {
    serializeLibraryText('''
class C {
  final x;
  static void f() {}
  const C() : x = f;
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToTopLevelFunction() {
    serializeLibraryText('''
void f() {}
class C {
  final x;
  const C() : x = f;
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToTypedef() {
    serializeLibraryText('''
typedef F();
class C {
  final x;
  const C() : x = F;
}
''');
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToUndefinedName() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    serializeLibraryText('''
class C {
  final x;
  const C() : x = foo;
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToUndefinedName_viaPrefix() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    addNamedSource('/a.dart', '');
    serializeLibraryText('''
import 'a.dart' as a;
class C {
  final x;
  const C() : x = a.foo;
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_referenceToUndefinedName_viaPrefix_nonExistentFile() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    allowMissingFiles = true;
    serializeLibraryText('''
import 'a.dart' as a;
class C {
  final x;
  const C() : x = a.foo;
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_trivial() {
    serializeLibraryText('''
class C {
  const C() : this();
}
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_constructorCycle_viaFactoryRedirect() {
    serializeLibraryText('''
class C {
  const C();
  const factory C.named() = D;
}
class D extends C {
  final x;
  const D() : x = y;
}
const y = const C.named();
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
    checkConstCycle('C', name: 'named');
    checkConstCycle('D');
  }

  test_constructorCycle_viaFinalField() {
    serializeLibraryText('''
class C {
  final x = const C();
  const C();
}
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_constructorCycle_viaLength() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    serializeLibraryText('''
class C {
  final x;
  const C() : x = y.length;
}
const y = const C();
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_constructorCycle_viaNamedConstructor() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = const D.named();
}
class D {
  final x;
  const D.named() : x = const C();
}
''');
    checkConstCycle('C');
    checkConstCycle('D', name: 'named');
  }

  test_constructorCycle_viaOrdinaryRedirect() {
    serializeLibraryText('''
class C {
  final x;
  const C() : this.named();
  const C.named() : x = const C();
}
''');
    checkConstCycle('C');
    checkConstCycle('C', name: 'named');
  }

  test_constructorCycle_viaOrdinaryRedirect_suppressSupertype() {
    // Since C redirects to C.named, it doesn't implicitly refer to B's unnamed
    // constructor.  Therefore there is no cycle.
    serializeLibraryText('''
class B {
  final x;
  const B() : x = const C();
  const B.named() : x = null;
}
class C extends B {
  const C() : this.named();
  const C.named() : super.named();
}
''');
    checkConstCycle('B', hasCycle: false);
    checkConstCycle('B', name: 'named', hasCycle: false);
    checkConstCycle('C', hasCycle: false);
    checkConstCycle('C', name: 'named', hasCycle: false);
  }

  test_constructorCycle_viaRedirectArgument() {
    serializeLibraryText('''
class C {
  final x;
  const C() : this.named(y);
  const C.named(this.x);
}
const y = const C();
''', allowErrors: true);
    checkConstCycle('C');
    checkConstCycle('C', name: 'named', hasCycle: false);
  }

  test_constructorCycle_viaStaticField_inOtherClass() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = D.y;
}
class D {
  static const y = const C();
}
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_constructorCycle_viaStaticField_inSameClass() {
    serializeLibraryText('''
class C {
  final x;
  static const y = const C();
  const C() : x = y;
}
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_constructorCycle_viaSuperArgument() {
    serializeLibraryText('''
class B {
  final x;
  const B(this.x);
}
class C extends B {
  const C() : super(y);
}
const y = const C();
''', allowErrors: true);
    checkConstCycle('B', hasCycle: false);
    checkConstCycle('C');
  }

  test_constructorCycle_viaSupertype() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = const D();
}
class D extends C {
  const D();
}
''');
    checkConstCycle('C');
    checkConstCycle('D');
  }

  test_constructorCycle_viaSupertype_Enum() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    serializeLibraryText('''
enum E { v }
class C extends E {
  const C();
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
  }

  test_constructorCycle_viaSupertype_explicit() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = const D();
  const C.named() : x = const D.named();
}
class D extends C {
  const D() : super();
  const D.named() : super.named();
}
''');
    checkConstCycle('C');
    checkConstCycle('C', name: 'named');
    checkConstCycle('D');
    checkConstCycle('D', name: 'named');
  }

  test_constructorCycle_viaSupertype_explicit_undefined() {
    // It's not valid Dart but we need to make sure it doesn't crash
    // summary generation.
    serializeLibraryText('''
class C {
  final x;
  const C() : x = const D();
}
class D extends C {
  const D() : super.named();
}
''', allowErrors: true);
    checkConstCycle('C', hasCycle: false);
    checkConstCycle('D', hasCycle: false);
  }

  test_constructorCycle_viaSupertype_withDefaultTypeArgument() {
    serializeLibraryText('''
class C<T> {
  final x;
  const C() : x = const D();
}
class D extends C {
  const D();
}
''');
    checkConstCycle('C');
    checkConstCycle('D');
  }

  test_constructorCycle_viaSupertype_withTypeArgument() {
    serializeLibraryText('''
class C<T> {
  final x;
  const C() : x = const D();
}
class D extends C<int> {
  const D();
}
''');
    checkConstCycle('C');
    checkConstCycle('D');
  }

  test_constructorCycle_viaTopLevelVariable() {
    serializeLibraryText('''
class C {
  final x;
  const C() : x = y;
}
const y = const C();
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_constructorCycle_viaTopLevelVariable_imported() {
    addNamedSource('/a.dart', '''
import 'test.dart';
const y = const C();
    ''');
    serializeLibraryText('''
import 'a.dart';
class C {
  final x;
  const C() : x = y;
}
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_constructorCycle_viaTopLevelVariable_importedViaPrefix() {
    addNamedSource('/a.dart', '''
import 'test.dart';
const y = const C();
    ''');
    serializeLibraryText('''
import 'a.dart' as a;
class C {
  final x;
  const C() : x = a.y;
}
''', allowErrors: true);
    checkConstCycle('C');
  }

  test_dependencies_export_to_export_unused() {
    addNamedSource('/a.dart', 'export "b.dart";');
    addNamedSource('/b.dart', '');
    serializeLibraryText('export "a.dart";');
    // The main test library depends on b.dart, even though it doesn't
    // re-export any names defined in b.dart, because a change to b.dart might
    // cause it to start exporting a name that the main test library *does*
    // use.
    checkHasDependency(absUri('/b.dart'));
  }

  test_dependencies_export_unused() {
    addNamedSource('/a.dart', '');
    serializeLibraryText('export "a.dart";');
    // The main test library depends on a.dart, even though it doesn't
    // re-export any names defined in a.dart, because a change to a.dart might
    // cause it to start exporting a name that the main test library *will*
    // re-export.
    checkHasDependency(absUri('/a.dart'));
  }

  test_dependencies_import_to_export() {
    addNamedSource('/a.dart', 'library a; export "b.dart"; class A {}');
    addNamedSource('/b.dart', 'library b;');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'));
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/b.dart'));
  }

  test_dependencies_import_to_export_in_subdirs_absolute_export() {
    addNamedSource('/a/a.dart',
        'library a; export "${absUri('/a/b/b.dart')}"; class A {}');
    addNamedSource('/a/b/b.dart', 'library b;');
    serializeLibraryText('import "a/a.dart"; A a;');
    checkHasDependency(absUri('/a/a.dart'));
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/a/b/b.dart'));
  }

  test_dependencies_import_to_export_in_subdirs_absolute_import() {
    addNamedSource('/a/a.dart', 'library a; export "b/b.dart"; class A {}');
    addNamedSource('/a/b/b.dart', 'library b;');
    serializeLibraryText('import "${absUri('/a/a.dart')}"; A a;');
    checkHasDependency(absUri('/a/a.dart'));
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/a/b/b.dart'));
  }

  test_dependencies_import_to_export_in_subdirs_relative() {
    addNamedSource('/a/a.dart', 'library a; export "b/b.dart"; class A {}');
    addNamedSource('/a/b/b.dart', 'library b;');
    serializeLibraryText('import "a/a.dart"; A a;');
    checkHasDependency(absUri('/a/a.dart'));
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/a/b/b.dart'));
  }

  test_dependencies_import_to_export_loop() {
    addNamedSource('/a.dart', 'library a; export "b.dart"; class A {}');
    addNamedSource('/b.dart', 'library b; export "a.dart";');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'));
    // Serialization should have been able to walk the transitive export
    // dependencies to b.dart without going into an infinite loop.
    checkHasDependency(absUri('/b.dart'));
  }

  test_dependencies_import_to_export_transitive_closure() {
    addNamedSource('/a.dart', 'library a; export "b.dart"; class A {}');
    addNamedSource('/b.dart', 'library b; export "c.dart";');
    addNamedSource('/c.dart', 'library c;');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'));
    // The main test library depends on c.dart, because names defined in
    // c.dart are exported by b.dart and then re-exported by a.dart.
    checkHasDependency(absUri('/c.dart'));
  }

  test_dependencies_import_to_export_unused() {
    addNamedSource('/a.dart', 'export "b.dart";');
    addNamedSource('/b.dart', '');
    serializeLibraryText('import "a.dart";', allowErrors: true);
    // The main test library depends on b.dart, even though it doesn't use any
    // names defined in b.dart, because a change to b.dart might cause it to
    // start exporting a name that the main test library *does* use.
    checkHasDependency(absUri('/b.dart'));
  }

  test_dependencies_import_transitive_closure() {
    addNamedSource(
        '/a.dart', 'library a; import "b.dart"; class A extends B {}');
    addNamedSource('/b.dart', 'library b; class B {}');
    serializeLibraryText('import "a.dart"; A a;');
    checkHasDependency(absUri('/a.dart'));
    // The main test library doesn't depend on b.dart, because no change to
    // b.dart can possibly affect the serialized element model for it.
    checkLacksDependency(absUri('/b.dart'));
  }

  test_dependencies_import_unused() {
    addNamedSource('/a.dart', '');
    serializeLibraryText('import "a.dart";', allowErrors: true);
    // The main test library depends on a.dart, even though it doesn't use any
    // names defined in a.dart, because a change to a.dart might cause it to
    // start exporting a name that the main test library *does* use.
    checkHasDependency(absUri('/a.dart'));
  }

  test_dependencies_parts() {
    addNamedSource(
        '/a.dart', 'library a; part "b.dart"; part "c.dart"; class A {}');
    addNamedSource('/b.dart', 'part of a;');
    addNamedSource('/c.dart', 'part of a;');
    serializeLibraryText('import "a.dart"; A a;');
    int dep = checkHasDependency(absUri('/a.dart'));
    checkDependencyParts(
        linked.dependencies[dep], [absUri('/b.dart'), absUri('/c.dart')]);
  }

  test_dependencies_parts_relative_to_importing_library() {
    addNamedSource('/a/b.dart', 'export "c/d.dart";');
    addNamedSource('/a/c/d.dart',
        'library d; part "e/f.dart"; part "g/h.dart"; class D {}');
    addNamedSource('/a/c/e/f.dart', 'part of d;');
    addNamedSource('/a/c/g/h.dart', 'part of d;');
    serializeLibraryText('import "a/b.dart"; D d;');
    int dep = checkHasDependency(absUri('/a/c/d.dart'));
    checkDependencyParts(linked.dependencies[dep],
        [absUri('/a/c/e/f.dart'), absUri('/a/c/g/h.dart')]);
  }

  test_elements_in_part() {
    addNamedSource('/part1.dart', '''
part of my.lib;

class C {}
enum E { v }
var v;
f() {}
typedef F();
''');
    serializeLibraryText('library my.lib; part "part1.dart";');
    UnlinkedUnit unit = unlinkedUnits[1];
    expect(findClass('C', unit: unit), isNotNull);
    expect(findEnum('E', unit: unit), isNotNull);
    expect(findVariable('v', variables: unit.variables), isNotNull);
    expect(findExecutable('f', executables: unit.executables), isNotNull);
    expect(findTypedef('F', unit: unit), isNotNull);
  }

  test_enum() {
    String text = 'enum E { v1 }';
    UnlinkedEnum e = serializeEnumText(text);
    expect(e.name, 'E');
    if (includeInformative) {
      expect(e.nameOffset, text.indexOf('E'));
    }
    expect(e.values, hasLength(1));
    expect(e.values[0].name, 'v1');
    if (includeInformative) {
      expect(e.values[0].nameOffset, text.indexOf('v1'));
      _assertCodeRange(e.codeRange, 0, 13);
    }
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.classOrEnum);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'E');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
    expect(unlinkedUnits[0].publicNamespace.names[0].members, hasLength(2));
    expect(unlinkedUnits[0].publicNamespace.names[0].members[0].kind,
        ReferenceKind.propertyAccessor);
    expect(unlinkedUnits[0].publicNamespace.names[0].members[0].name, 'values');
    expect(
        unlinkedUnits[0].publicNamespace.names[0].members[0].numTypeParameters,
        0);
    expect(unlinkedUnits[0].publicNamespace.names[0].members[1].kind,
        ReferenceKind.propertyAccessor);
    expect(unlinkedUnits[0].publicNamespace.names[0].members[1].name, 'v1');
    expect(
        unlinkedUnits[0].publicNamespace.names[0].members[1].numTypeParameters,
        0);
  }

  test_enum_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }''';
    UnlinkedEnum enm = serializeEnumText(text);
    expect(enm.documentationComment, isNotNull);
    checkDocumentationComment(enm.documentationComment, text);
  }

  test_enum_order() {
    UnlinkedEnum e = serializeEnumText('enum E { v1, v2 }');
    expect(e.values, hasLength(2));
    expect(e.values[0].name, 'v1');
    expect(e.values[1].name, 'v2');
  }

  test_enum_private() {
    serializeEnumText('enum _E { v1 }', '_E');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_enum_value_documented() {
    if (!includeInformative) return;
    String text = '''
enum E {
  /**
   * Docs
   */
  v
}''';
    UnlinkedEnumValue value = serializeEnumText(text).values[0];
    expect(value.documentationComment, isNotNull);
    checkDocumentationComment(value.documentationComment, text);
  }

  test_enum_value_private() {
    serializeEnumText('enum E { _v }', 'E');
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].members, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].members[0].name, 'values');
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
    String text = '  f() {}';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.returnType, isNull);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.isGenerator, isFalse);
    if (includeInformative) {
      expect(executable.nameOffset, text.indexOf('f'));
      expect(executable.visibleOffset, 0);
      expect(executable.visibleLength, 0);
    }
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.topLevelFunction);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'f');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
  }

  test_executable_function_async() {
    UnlinkedExecutable executable = serializeExecutableText(r'''
import 'dart:async';
Future f() async {}
''');
    expect(executable.isAsynchronous, isTrue);
    expect(executable.isGenerator, isFalse);
  }

  test_executable_function_asyncStar() {
    UnlinkedExecutable executable = serializeExecutableText(r'''
import 'dart:async';
Stream f() async* {}
''');
    expect(executable.isAsynchronous, isTrue);
    expect(executable.isGenerator, isTrue);
  }

  test_executable_function_explicit_return() {
    UnlinkedExecutable executable =
        serializeExecutableText('dynamic f() => null;');
    checkDynamicTypeRef(executable.returnType);
  }

  test_executable_function_external() {
    UnlinkedExecutable executable = serializeExecutableText('external f();');
    expect(executable.isExternal, isTrue);
  }

  test_executable_function_private() {
    serializeExecutableText('_f() {}', executableName: '_f');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_executable_getter() {
    String text = 'int get f => 1;';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.kind, UnlinkedExecutableKind.getter);
    expect(executable.returnType, isNotNull);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.isGenerator, isFalse);
    if (includeInformative) {
      expect(executable.nameOffset, text.indexOf('f'));
    }
    expect(findVariable('f'), isNull);
    expect(findExecutable('f='), isNull);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.topLevelPropertyAccessor);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'f');
  }

  test_executable_getter_external() {
    UnlinkedExecutable executable =
        serializeExecutableText('external int get f;');
    expect(executable.isExternal, isTrue);
  }

  test_executable_getter_private() {
    serializeExecutableText('int get _f => 1;', executableName: '_f');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_executable_getter_type() {
    UnlinkedExecutable executable = serializeExecutableText('int get f => 1;');
    checkTypeRef(executable.returnType, 'dart:core', 'int');
    expect(executable.parameters, isEmpty);
  }

  test_executable_getter_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('get f => 1;');
    expect(executable.returnType, isNull);
    expect(executable.parameters, isEmpty);
  }

  test_executable_localFunctions() {
    String code = r'''
f() {
  f1() {}
  {
    f2() {}
  }
}
''';
    UnlinkedExecutable executable = serializeExecutableText(code);
    List<UnlinkedExecutable> functions = executable.localFunctions;
    expect(functions, isEmpty);
  }

  test_executable_member_function() {
    UnlinkedExecutable executable = findExecutable('f',
        executables: serializeClassText('class C { f() {} }').executables);
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.returnType, isNull);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.isGenerator, isFalse);
    if (includeInformative) {
      expect(executable.visibleOffset, 0);
      expect(executable.visibleLength, 0);
      _assertCodeRange(executable.codeRange, 10, 6);
    }
  }

  test_executable_member_function_async() {
    UnlinkedExecutable executable =
        findExecutable('f', executables: serializeClassText(r'''
import 'dart:async';
class C {
  Future f() async {}
}
''').executables);
    expect(executable.isAsynchronous, isTrue);
    expect(executable.isGenerator, isFalse);
  }

  test_executable_member_function_asyncStar() {
    UnlinkedExecutable executable =
        findExecutable('f', executables: serializeClassText(r'''
import 'dart:async';
class C {
  Stream f() async* {}
}
''').executables);
    expect(executable.isAsynchronous, isTrue);
    expect(executable.isGenerator, isTrue);
  }

  test_executable_member_function_explicit_return() {
    UnlinkedExecutable executable = findExecutable('f',
        executables:
            serializeClassText('class C { dynamic f() => null; }').executables);
    expect(executable.returnType, isNotNull);
  }

  test_executable_member_function_external() {
    UnlinkedExecutable executable = findExecutable('f',
        executables:
            serializeClassText('class C { external f(); }').executables);
    expect(executable.isExternal, isTrue);
  }

  test_executable_member_getter() {
    UnlinkedClass cls = serializeClassText('class C { int get f => 1; }');
    UnlinkedExecutable executable =
        findExecutable('f', executables: cls.executables, failIfAbsent: true);
    expect(executable.kind, UnlinkedExecutableKind.getter);
    expect(executable.returnType, isNotNull);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.isGenerator, isFalse);
    expect(executable.isStatic, isFalse);
    if (includeInformative) {
      _assertCodeRange(executable.codeRange, 10, 15);
    }
    expect(findVariable('f', variables: cls.fields), isNull);
    expect(findExecutable('f=', executables: cls.executables), isNull);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'C');
    expect(unlinkedUnits[0].publicNamespace.names[0].members, isEmpty);
  }

  test_executable_member_getter_external() {
    UnlinkedClass cls = serializeClassText('class C { external int get f; }');
    UnlinkedExecutable executable =
        findExecutable('f', executables: cls.executables, failIfAbsent: true);
    expect(executable.isExternal, isTrue);
  }

  test_executable_member_getter_static() {
    UnlinkedClass cls =
        serializeClassText('class C { static int get f => 1; }');
    UnlinkedExecutable executable =
        findExecutable('f', executables: cls.executables, failIfAbsent: true);
    expect(executable.isStatic, isTrue);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'C');
    expect(unlinkedUnits[0].publicNamespace.names[0].members, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].members[0].name, 'f');
    expect(unlinkedUnits[0].publicNamespace.names[0].members[0].kind,
        ReferenceKind.propertyAccessor);
    expect(
        unlinkedUnits[0].publicNamespace.names[0].members[0].numTypeParameters,
        0);
    expect(
        unlinkedUnits[0].publicNamespace.names[0].members[0].members, isEmpty);
  }

  test_executable_member_setter() {
    UnlinkedClass cls = serializeClassText('class C { void set f(value) {} }');
    UnlinkedExecutable executable =
        findExecutable('f=', executables: cls.executables, failIfAbsent: true);
    expect(executable.kind, UnlinkedExecutableKind.setter);
    expect(executable.returnType, isNotNull);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.isGenerator, isFalse);
    if (includeInformative) {
      _assertCodeRange(executable.codeRange, 10, 20);
    }
    expect(findVariable('f', variables: cls.fields), isNull);
    expect(findExecutable('f', executables: cls.executables), isNull);
  }

  test_executable_member_setter_external() {
    UnlinkedClass cls =
        serializeClassText('class C { external void set f(value); }');
    UnlinkedExecutable executable =
        findExecutable('f=', executables: cls.executables, failIfAbsent: true);
    expect(executable.isExternal, isTrue);
  }

  test_executable_member_setter_implicit_return() {
    UnlinkedClass cls = serializeClassText('class C { set f(value) {} }');
    UnlinkedExecutable executable =
        findExecutable('f=', executables: cls.executables, failIfAbsent: true);
    expect(executable.returnType, isNull);
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

  test_executable_operator() {
    UnlinkedExecutable executable =
        serializeClassText('class C { C operator+(C c) => null; }')
            .executables[0];
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.name, '+');
    expect(executable.returnType, isNotNull);
    expect(executable.isAbstract, false);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isConst, false);
    expect(executable.isFactory, false);
    expect(executable.isGenerator, isFalse);
    expect(executable.isStatic, false);
    expect(executable.parameters, hasLength(1));
    checkTypeRef(executable.returnType, null, 'C');
    expect(executable.typeParameters, isEmpty);
    expect(executable.isExternal, false);
  }

  test_executable_operator_abstract() {
    UnlinkedExecutable executable =
        serializeClassText('class C { C operator+(C c); }', allowErrors: true)
            .executables[0];
    expect(executable.isAbstract, true);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, false);
    expect(executable.isGenerator, isFalse);
  }

  test_executable_operator_equal() {
    UnlinkedExecutable executable = serializeClassText(
            'class C { bool operator==(Object other) => false; }')
        .executables[0];
    expect(executable.name, '==');
  }

  test_executable_operator_external() {
    UnlinkedExecutable executable =
        serializeClassText('class C { external C operator+(C c); }')
            .executables[0];
    expect(executable.isAbstract, false);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, true);
    expect(executable.isGenerator, isFalse);
  }

  test_executable_operator_greater_equal() {
    UnlinkedExecutable executable =
        serializeClassText('class C { bool operator>=(C other) => false; }')
            .executables[0];
    expect(executable.name, '>=');
  }

  test_executable_operator_index() {
    UnlinkedExecutable executable =
        serializeClassText('class C { bool operator[](int i) => null; }')
            .executables[0];
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.name, '[]');
    expect(executable.returnType, isNotNull);
    expect(executable.isAbstract, false);
    expect(executable.isConst, false);
    expect(executable.isFactory, false);
    expect(executable.isStatic, false);
    expect(executable.parameters, hasLength(1));
    checkTypeRef(executable.returnType, 'dart:core', 'bool');
    expect(executable.typeParameters, isEmpty);
  }

  test_executable_operator_index_set() {
    UnlinkedExecutable executable = serializeClassText(
            'class C { void operator[]=(int i, bool v) => null; }')
        .executables[0];
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.name, '[]=');
    expect(executable.returnType, isNotNull);
    expect(executable.isAbstract, false);
    expect(executable.isConst, false);
    expect(executable.isFactory, false);
    expect(executable.isStatic, false);
    expect(executable.parameters, hasLength(2));
    checkVoidTypeRef(executable.returnType);
    expect(executable.typeParameters, isEmpty);
  }

  test_executable_operator_less_equal() {
    UnlinkedExecutable executable =
        serializeClassText('class C { bool operator<=(C other) => false; }')
            .executables[0];
    expect(executable.name, '<=');
  }

  test_executable_param_codeRange() {
    if (!includeInformative) return;
    UnlinkedExecutable executable = serializeExecutableText('f(int x) {}');
    UnlinkedParam parameter = executable.parameters[0];
    _assertCodeRange(parameter.codeRange, 2, 5);
  }

  test_executable_param_function_typed() {
    UnlinkedExecutable executable = serializeExecutableText('f(g()) {}');
    expect(executable.parameters[0].isFunctionTyped, isTrue);
    expect(executable.parameters[0].type, isNull);
  }

  test_executable_param_function_typed_explicit_return_type() {
    UnlinkedExecutable executable =
        serializeExecutableText('f(dynamic g()) {}');
    expect(executable.parameters[0].type, isNotNull);
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
    checkTypeRef(executable.parameters[0].type, 'dart:core', 'int');
  }

  test_executable_param_function_typed_return_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('f(g()) {}');
    expect(executable.parameters[0].isFunctionTyped, isTrue);
    expect(executable.parameters[0].type, isNull);
  }

  test_executable_param_function_typed_return_type_void() {
    UnlinkedExecutable executable = serializeExecutableText('f(void g()) {}');
    checkVoidTypeRef(executable.parameters[0].type);
  }

  test_executable_param_function_typed_withDefault() {
    UnlinkedExecutable executable = serializeExecutableText(r'''
f([int p(int a2, String b2) = foo]) {}
int foo(int a, String b) => 0;
''');
    UnlinkedParam param = executable.parameters[0];
    expect(param.kind, UnlinkedParamKind.positional);
    expect(param.initializer, isNotNull);
    expect(param.defaultValueCode, 'foo');
    assertUnlinkedConst(param.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'foo',
          expectedKind: ReferenceKind.topLevelFunction)
    ]);
  }

  test_executable_param_isFinal() {
    String text = 'f(x, final y) {}';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.parameters, hasLength(2));
    expect(executable.parameters[0].name, 'x');
    expect(executable.parameters[0].isFinal, isFalse);
    expect(executable.parameters[1].name, 'y');
    expect(executable.parameters[1].isFinal, isTrue);
  }

  test_executable_param_kind_named() {
    UnlinkedExecutable executable = serializeExecutableText('f({x}) {}');
    UnlinkedParam param = executable.parameters[0];
    expect(param.kind, UnlinkedParamKind.named);
    expect(param.initializer, isNull);
    expect(param.defaultValueCode, isEmpty);
  }

  test_executable_param_kind_named_withDefault() {
    UnlinkedExecutable executable = serializeExecutableText('f({x: 42}) {}');
    UnlinkedParam param = executable.parameters[0];
    expect(param.kind, UnlinkedParamKind.named);
    expect(param.initializer, isNotNull);
    expect(param.defaultValueCode, '42');
    if (includeInformative) {
      _assertCodeRange(param.codeRange, 3, 5);
    }
    assertUnlinkedConst(param.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
  }

  test_executable_param_kind_positional() {
    UnlinkedExecutable executable = serializeExecutableText('f([x]) {}');
    UnlinkedParam param = executable.parameters[0];
    expect(param.kind, UnlinkedParamKind.positional);
    expect(param.initializer, isNull);
    expect(param.defaultValueCode, isEmpty);
  }

  test_executable_param_kind_positional_withDefault() {
    UnlinkedExecutable executable = serializeExecutableText('f([x = 42]) {}');
    UnlinkedParam param = executable.parameters[0];
    expect(param.kind, UnlinkedParamKind.positional);
    expect(param.initializer, isNotNull);
    expect(param.defaultValueCode, '42');
    if (includeInformative) {
      _assertCodeRange(param.codeRange, 3, 6);
    }
    assertUnlinkedConst(param.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [42]);
  }

  test_executable_param_kind_required() {
    UnlinkedExecutable executable = serializeExecutableText('f(x) {}');
    UnlinkedParam param = executable.parameters[0];
    expect(param.kind, UnlinkedParamKind.required);
    expect(param.initializer, isNull);
    expect(param.defaultValueCode, isEmpty);
  }

  test_executable_param_name() {
    String text = 'f(x) {}';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.parameters, hasLength(1));
    expect(executable.parameters[0].name, 'x');
    if (includeInformative) {
      expect(executable.parameters[0].nameOffset, text.indexOf('x'));
    }
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

  test_executable_param_of_constructor_no_covariance() {
    UnlinkedExecutable executable =
        serializeClassText('class C { C(x); }').executables[0];
    expect(executable.parameters[0].inheritsCovariantSlot, 0);
  }

  test_executable_param_of_method_covariance() {
    UnlinkedExecutable executable =
        serializeClassText('class C { m(x) {} }').executables[0];
    expect(executable.parameters[0].inheritsCovariantSlot, isNot(0));
  }

  test_executable_param_of_param_no_covariance() {
    UnlinkedExecutable executable =
        serializeClassText('class C { m(f(x)) {} }').executables[0];
    expect(executable.parameters[0].parameters[0].inheritsCovariantSlot, 0);
  }

  test_executable_param_of_setter_covariance() {
    UnlinkedExecutable executable =
        serializeClassText('class C { void set s(x) {} }').executables[0];
    expect(executable.parameters[0].inheritsCovariantSlot, isNot(0));
  }

  test_executable_param_of_static_method_no_covariance() {
    UnlinkedExecutable executable =
        serializeClassText('class C { static m(x) {} }').executables[0];
    expect(executable.parameters[0].inheritsCovariantSlot, 0);
  }

  test_executable_param_of_top_level_function_no_covariance() {
    UnlinkedExecutable executable = serializeExecutableText('f(x) {}');
    expect(executable.parameters[0].inheritsCovariantSlot, 0);
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
  }

  test_executable_param_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('f(x) {}');
    expect(executable.parameters[0].type, isNull);
  }

  test_executable_param_type_typedef() {
    UnlinkedExecutable executable = serializeExecutableText(r'''
typedef MyFunction(int p);
f(MyFunction myFunction) {}
''');
    expect(executable.parameters[0].isFunctionTyped, isFalse);
    checkTypeRef(executable.parameters[0].type, null, 'MyFunction',
        expectedKind: ReferenceKind.typedef);
  }

  test_executable_return_type() {
    UnlinkedExecutable executable = serializeExecutableText('int f() => 1;');
    checkTypeRef(executable.returnType, 'dart:core', 'int');
  }

  test_executable_return_type_implicit() {
    UnlinkedExecutable executable = serializeExecutableText('f() {}');
    expect(executable.returnType, isNull);
  }

  test_executable_return_type_void() {
    UnlinkedExecutable executable = serializeExecutableText('void f() {}');
    checkVoidTypeRef(executable.returnType);
  }

  test_executable_setter() {
    String text = 'void set f(value) {}';
    UnlinkedExecutable executable =
        serializeExecutableText(text, executableName: 'f=');
    expect(executable.kind, UnlinkedExecutableKind.setter);
    expect(executable.returnType, isNotNull);
    expect(executable.isAsynchronous, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.isGenerator, isFalse);
    if (includeInformative) {
      expect(executable.nameOffset, text.indexOf('f'));
    }
    expect(findVariable('f'), isNull);
    expect(findExecutable('f'), isNull);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.topLevelPropertyAccessor);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'f=');
  }

  test_executable_setter_external() {
    UnlinkedExecutable executable = serializeExecutableText(
        'external void set f(value);',
        executableName: 'f=');
    expect(executable.isExternal, isTrue);
  }

  test_executable_setter_implicit_return() {
    UnlinkedExecutable executable =
        serializeExecutableText('set f(value) {}', executableName: 'f=');
    expect(executable.returnType, isNull);
  }

  test_executable_setter_private() {
    serializeExecutableText('void set _f(value) {}', executableName: '_f=');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_executable_setter_type() {
    UnlinkedExecutable executable = serializeExecutableText(
        'void set f(int value) {}',
        executableName: 'f=');
    checkVoidTypeRef(executable.returnType);
    expect(executable.parameters, hasLength(1));
    expect(executable.parameters[0].name, 'value');
    checkTypeRef(executable.parameters[0].type, 'dart:core', 'int');
  }

  test_executable_static() {
    UnlinkedExecutable executable =
        serializeClassText('class C { static f() {} }').executables[0];
    expect(executable.isStatic, isTrue);
  }

  test_executable_type_param_f_bound_function() {
    UnlinkedExecutable ex =
        serializeExecutableText('void f<T, U extends List<T>>() {}');
    EntityRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 2);
  }

  test_executable_type_param_f_bound_method() {
    UnlinkedExecutable ex =
        serializeMethodText('void f<T, U extends List<T>>() {}');
    EntityRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 2);
  }

  test_executable_type_param_f_bound_self_ref_function() {
    UnlinkedExecutable ex =
        serializeExecutableText('void f<T, U extends List<U>>() {}');
    EntityRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 1);
  }

  test_executable_type_param_f_bound_self_ref_method() {
    UnlinkedExecutable ex =
        serializeMethodText('void f<T, U extends List<U>>() {}');
    EntityRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 1);
  }

  test_executable_type_param_in_parameter_function() {
    UnlinkedExecutable ex = serializeExecutableText('void f<T>(T t) {}');
    checkParamTypeRef(ex.parameters[0].type, 1);
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 1);
  }

  test_executable_type_param_in_parameter_method() {
    UnlinkedExecutable ex = serializeMethodText('void f<T>(T t) {}');
    checkParamTypeRef(ex.parameters[0].type, 1);
  }

  test_executable_type_param_in_return_type_function() {
    UnlinkedExecutable ex = serializeExecutableText('T f<T>() => null;');
    checkParamTypeRef(ex.returnType, 1);
  }

  test_executable_type_param_in_return_type_method() {
    UnlinkedExecutable ex = serializeMethodText('T f<T>() => null;');
    checkParamTypeRef(ex.returnType, 1);
  }

  test_export_class() {
    addNamedSource('/a.dart', 'class C {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'C',
        ReferenceKind.classOrEnum);
  }

  test_export_class_alias() {
    addNamedSource(
        '/a.dart', 'class C extends _D with _E {} class _D {} class _E {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'C',
        ReferenceKind.classOrEnum);
  }

  test_export_configurations() {
    addNamedSource('/foo.dart', 'class A {}');
    addNamedSource('/foo_io.dart', 'class A {}');
    addNamedSource('/foo_html.dart', 'class A {}');
    String libraryText = r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.flavor == 'html') 'foo_html.dart';

class B extends A {}
''';
    serializeLibraryText(libraryText);
    UnlinkedExportPublic exp = unlinkedUnits[0].publicNamespace.exports[0];
    expect(exp.configurations, hasLength(2));
    {
      UnlinkedConfiguration configuration = exp.configurations[0];
      expect(configuration.name, 'dart.library.io');
      expect(configuration.value, 'true');
      expect(configuration.uri, 'foo_io.dart');
    }
    {
      UnlinkedConfiguration configuration = exp.configurations[1];
      expect(configuration.name, 'dart.flavor');
      expect(configuration.value, 'html');
      expect(configuration.uri, 'foo_html.dart');
    }
  }

  test_export_dependency() {
    serializeLibraryText('export "dart:async";');
    expect(unlinkedUnits[0].exports, hasLength(1));
    checkDependency(linked.exportDependencies[0], 'dart:async');
  }

  test_export_enum() {
    addNamedSource('/a.dart', 'enum E { v }');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'E',
        ReferenceKind.classOrEnum);
  }

  test_export_from_part() {
    addNamedSource('/a.dart', 'library foo; part "b.dart";');
    addNamedSource('/b.dart', 'part of foo; f() {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'f',
        ReferenceKind.topLevelFunction,
        expectedTargetUnit: 1);
  }

  test_export_function() {
    addNamedSource('/a.dart', 'f() {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'f',
        ReferenceKind.topLevelFunction);
  }

  test_export_getter() {
    addNamedSource('/a.dart', 'get f => null');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'f',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_export_hide() {
    addNamedSource('/a.dart', 'f() {} g() {}');
    serializeLibraryText('export "a.dart" hide g;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'f',
        ReferenceKind.topLevelFunction);
  }

  test_export_hide_order() {
    serializeLibraryText('export "dart:async" hide Future, Stream;');
    expect(unlinkedUnits[0].publicNamespace.exports, hasLength(1));
    expect(
        unlinkedUnits[0].publicNamespace.exports[0].combinators, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].shows,
        isEmpty);
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].hides,
        hasLength(2));
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].hides[0],
        'Future');
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].hides[1],
        'Stream');
    if (includeInformative) {
      expect(
          unlinkedUnits[0].publicNamespace.exports[0].combinators[0].offset, 0);
      expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].end, 0);
    }
    expect(linked.exportNames, isNotEmpty);
  }

  test_export_missing() {
    // Unresolved exports are included since this is necessary for proper
    // dependency tracking.
    allowMissingFiles = true;
    serializeLibraryText('export "foo.dart";', allowErrors: true);
    expect(unlinkedUnits[0].imports, hasLength(1));
    checkDependency(linked.exportDependencies[0], absUri('/foo.dart'));
  }

  test_export_names_excludes_names_from_library() {
    addNamedSource('/a.dart', 'part of my.lib; int y; int _y;');
    serializeLibraryText('library my.lib; part "a.dart"; int x; int _x;');
    expect(linked.exportNames, isEmpty);
  }

  test_export_no_combinators() {
    serializeLibraryText('export "dart:async";');
    expect(unlinkedUnits[0].publicNamespace.exports, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators, isEmpty);
  }

  test_export_not_shadowed_by_prefix() {
    addNamedSource('/a.dart', 'f() {}');
    serializeLibraryText('export "a.dart"; import "dart:core" as f; f.int _x;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'f',
        ReferenceKind.topLevelFunction);
  }

  test_export_offset() {
    String libraryText = '    export "dart:async";';
    serializeLibraryText(libraryText);
    expect(unlinkedUnits[0].exports[0].uriOffset,
        libraryText.indexOf('"dart:async"'));
    expect(unlinkedUnits[0].exports[0].uriEnd, libraryText.indexOf(';'));
    expect(unlinkedUnits[0].exports[0].offset, libraryText.indexOf('export'));
  }

  test_export_private() {
    // Private names should not be exported.
    addNamedSource('/a.dart', '_f() {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, isEmpty);
  }

  test_export_setter() {
    addNamedSource('/a.dart', 'void set f(value) {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'f=',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_export_shadowed() {
    // f() is not shown in exportNames because it is already defined at top
    // level in the library.
    addNamedSource('/a.dart', 'f() {}');
    serializeLibraryText('export "a.dart"; f() {}');
    expect(linked.exportNames, isEmpty);
  }

  test_export_shadowed_variable() {
    // Neither `v` nor `v=` is shown in exportNames because both are defined at
    // top level in the library by the declaration `var v;`.
    addNamedSource('/a.dart', 'var v;');
    serializeLibraryText('export "a.dart"; var v;');
    expect(linked.exportNames, isEmpty);
  }

  test_export_shadowed_variable_const() {
    // `v=` is shown in exportNames because the top level declaration
    // `const v = 0;` only shadows `v`, not `v=`.
    addNamedSource('/a.dart', 'var v;');
    serializeLibraryText('export "a.dart"; const v = 0;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'v=',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_export_shadowed_variable_final() {
    // `v=` is shown in exportNames because the top level declaration
    // `final v = 0;` only shadows `v`, not `v=`.
    addNamedSource('/a.dart', 'var v;');
    serializeLibraryText('export "a.dart"; final v = 0;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'v=',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_export_show() {
    addNamedSource('/a.dart', 'f() {} g() {}');
    serializeLibraryText('export "a.dart" show f;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'f',
        ReferenceKind.topLevelFunction);
  }

  test_export_show_order() {
    String libraryText = 'export "dart:async" show Future, Stream;';
    serializeLibraryText(libraryText);
    expect(unlinkedUnits[0].publicNamespace.exports, hasLength(1));
    expect(
        unlinkedUnits[0].publicNamespace.exports[0].combinators, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].shows,
        hasLength(2));
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].hides,
        isEmpty);
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].shows[0],
        'Future');
    expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].shows[1],
        'Stream');
    if (includeInformative) {
      expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].offset,
          libraryText.indexOf('show'));
      expect(unlinkedUnits[0].publicNamespace.exports[0].combinators[0].end,
          libraryText.indexOf(';'));
    }
  }

  test_export_typedef() {
    addNamedSource('/a.dart', 'typedef F();');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(
        linked.exportNames[0], absUri('/a.dart'), 'F', ReferenceKind.typedef);
  }

  test_export_typedef_genericFunction() {
    addNamedSource('/a.dart', 'typedef F<S> = S Function<T>(T x);');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'F',
        ReferenceKind.genericFunctionTypedef);
  }

  test_export_uri() {
    addNamedSource('/a.dart', 'library my.lib;');
    String uriString = '"a.dart"';
    String libraryText = 'export $uriString;';
    serializeLibraryText(libraryText);
    var unlinkedExports = unlinkedUnits[0].publicNamespace.exports;
    expect(unlinkedExports, hasLength(1));
    expect(unlinkedExports[0].uri, 'a.dart');
    expect(unlinkedExports[0].configurations, isEmpty);
  }

  test_export_uri_invalid() {
    String uriString = '[invalid uri]';
    String libraryText = 'export "$uriString";';
    serializeLibraryText(libraryText);
    expect(unlinkedUnits[0].publicNamespace.exports, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.exports[0].uri, uriString);
  }

  test_export_uri_nullStringValue() {
    String libraryText = r'''
export "${'a'}.dart";
''';
    serializeLibraryText(libraryText);
    var unlinkedExports = unlinkedUnits[0].publicNamespace.exports;
    expect(unlinkedExports, hasLength(1));
    expect(unlinkedExports[0].uri, '');
    expect(unlinkedExports[0].configurations, isEmpty);
  }

  test_export_variable() {
    addNamedSource('/a.dart', 'var v;');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(2));
    LinkedExportName getter =
        linked.exportNames.firstWhere((e) => e.name == 'v');
    expect(getter, isNotNull);
    checkExportName(
        getter, absUri('/a.dart'), 'v', ReferenceKind.topLevelPropertyAccessor);
    LinkedExportName setter =
        linked.exportNames.firstWhere((e) => e.name == 'v=');
    expect(setter, isNotNull);
    checkExportName(setter, absUri('/a.dart'), 'v=',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_expr_assignOperator_assign() {
    _assertAssignmentOperator(
        '(a = 1 + 2) + 3', UnlinkedExprAssignOperator.assign);
  }

  test_expr_assignOperator_bitAnd() {
    _assertAssignmentOperator(
        '(a &= 1 + 2) + 3', UnlinkedExprAssignOperator.bitAnd);
  }

  test_expr_assignOperator_bitOr() {
    _assertAssignmentOperator(
        '(a |= 1 + 2) + 3', UnlinkedExprAssignOperator.bitOr);
  }

  test_expr_assignOperator_bitXor() {
    _assertAssignmentOperator(
        '(a ^= 1 + 2) + 3', UnlinkedExprAssignOperator.bitXor);
  }

  test_expr_assignOperator_divide() {
    _assertAssignmentOperator(
        '(a /= 1 + 2) + 3', UnlinkedExprAssignOperator.divide);
  }

  test_expr_assignOperator_floorDivide() {
    _assertAssignmentOperator(
        '(a ~/= 1 + 2) + 3', UnlinkedExprAssignOperator.floorDivide);
  }

  test_expr_assignOperator_ifNull() {
    _assertAssignmentOperator(
        '(a ??= 1 + 2) + 3', UnlinkedExprAssignOperator.ifNull);
  }

  test_expr_assignOperator_minus() {
    _assertAssignmentOperator(
        '(a -= 1 + 2) + 3', UnlinkedExprAssignOperator.minus);
  }

  test_expr_assignOperator_modulo() {
    _assertAssignmentOperator(
        '(a %= 1 + 2) + 3', UnlinkedExprAssignOperator.modulo);
  }

  test_expr_assignOperator_multiply() {
    _assertAssignmentOperator(
        '(a *= 1 + 2) + 3', UnlinkedExprAssignOperator.multiply);
  }

  test_expr_assignOperator_plus() {
    _assertAssignmentOperator(
        '(a += 1 + 2) + 3', UnlinkedExprAssignOperator.plus);
  }

  test_expr_assignOperator_shiftLeft() {
    _assertAssignmentOperator(
        '(a <<= 1 + 2) + 3', UnlinkedExprAssignOperator.shiftLeft);
  }

  test_expr_assignOperator_shiftRight() {
    _assertAssignmentOperator(
        '(a >>= 1 + 2) + 3', UnlinkedExprAssignOperator.shiftRight);
  }

  test_expr_assignToIndex_ofFieldSequence() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class A {
  B b;
}
class B {
  C c;
}
class C {
  List<int> f = <int>[0, 1, 2];
}
A a = new A();
final v = (a.b.c.f[1] = 5);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.pushReference,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToIndex,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          5,
          1
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'f',
                  expectedKind: ReferenceKind.unresolved,
                  prefixExpectations: [
                    new _PrefixExpectation(ReferenceKind.unresolved, 'c'),
                    new _PrefixExpectation(ReferenceKind.unresolved, 'b'),
                    new _PrefixExpectation(
                        ReferenceKind.topLevelPropertyAccessor, 'a')
                  ])
        ]);
  }

  test_expr_assignToIndex_ofIndexExpression() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class A {
 List<B> b;
}
class B {
  List<C> c;
}
class C {
  List<int> f = <int>[0, 1, 2];
}
A a = new A();
final v = (a.b[1].c[2].f[3] = 5);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          // 5
          UnlinkedExprOperation.pushInt,
          // a.b[1]
          UnlinkedExprOperation.pushReference,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.extractIndex,
          // c[2]
          UnlinkedExprOperation.extractProperty,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.extractIndex,
          // f[3] = 5
          UnlinkedExprOperation.extractProperty,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToIndex,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          5,
          1,
          2,
          3,
        ],
        strings: [
          'c',
          'f'
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'b',
                  expectedKind: ReferenceKind.unresolved,
                  prefixExpectations: [
                    new _PrefixExpectation(
                        ReferenceKind.topLevelPropertyAccessor, 'a')
                  ])
        ]);
  }

  test_expr_assignToIndex_ofTopLevelVariable() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
List<int> a = <int>[0, 1, 2];
final v = (a[1] = 5);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.pushReference,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToIndex,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          5,
          1,
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'a',
              expectedKind: ReferenceKind.topLevelPropertyAccessor)
        ]);
  }

  test_expr_assignToProperty_ofInstanceCreation() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C {
  int f;
}
final v = (new C().f = 5);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.invokeConstructor,
          UnlinkedExprOperation.assignToProperty,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          5,
          0,
          0,
        ],
        strings: [
          'f'
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'C',
              expectedKind: ReferenceKind.classOrEnum)
        ]);
  }

  test_expr_assignToRef_classStaticField() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C {
  static int f;
}
final v = (C.f = 1);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToRef,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          1,
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'f',
                  expectedKind: ReferenceKind.unresolved,
                  prefixExpectations: [
                    new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
                  ])
        ]);
  }

  test_expr_assignToRef_fieldSequence() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class A {
  B b;
}
class B {
  C c;
}
class C {
  int f;
}
A a = new A();
final v = (a.b.c.f = 1);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToRef,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          1,
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'f',
                  expectedKind: ReferenceKind.unresolved,
                  prefixExpectations: [
                    new _PrefixExpectation(ReferenceKind.unresolved, 'c'),
                    new _PrefixExpectation(ReferenceKind.unresolved, 'b'),
                    new _PrefixExpectation(
                        ReferenceKind.topLevelPropertyAccessor, 'a')
                  ])
        ]);
  }

  test_expr_assignToRef_postfixDecrement() {
    _assertRefPrefixPostfixIncrementDecrement(
        'a-- + 2', UnlinkedExprAssignOperator.postfixDecrement);
  }

  test_expr_assignToRef_postfixIncrement() {
    _assertRefPrefixPostfixIncrementDecrement(
        'a++ + 2', UnlinkedExprAssignOperator.postfixIncrement);
  }

  test_expr_assignToRef_prefixDecrement() {
    _assertRefPrefixPostfixIncrementDecrement(
        '--a + 2', UnlinkedExprAssignOperator.prefixDecrement);
  }

  test_expr_assignToRef_prefixIncrement() {
    _assertRefPrefixPostfixIncrementDecrement(
        '++a + 2', UnlinkedExprAssignOperator.prefixIncrement);
  }

  test_expr_assignToRef_topLevelVariable() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
int a = 0;
final v = (a = 1);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToRef,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          1,
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'a',
              expectedKind: ReferenceKind.topLevelPropertyAccessor)
        ]);
  }

  test_expr_assignToRef_topLevelVariable_imported() {
    if (skipNonConstInitializers) {
      return;
    }
    addNamedSource('/a.dart', '''
int a = 0;
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart';
final v = (a = 1);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToRef,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          1,
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'a',
              expectedKind: ReferenceKind.topLevelPropertyAccessor)
        ]);
  }

  test_expr_assignToRef_topLevelVariable_imported_withPrefix() {
    if (skipNonConstInitializers) {
      return;
    }
    addNamedSource('/a.dart', '''
int a = 0;
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
final v = (p.a = 1);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.assignToRef,
        ],
        assignmentOperators: [
          (UnlinkedExprAssignOperator.assign)
        ],
        ints: [
          1,
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) {
            return checkTypeRef(r, absUri('/a.dart'), 'a',
                expectedKind: ReferenceKind.topLevelPropertyAccessor,
                expectedPrefix: 'p');
          }
        ]);
  }

  test_expr_cascadeSection_assignToIndex() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C {
  List<int> items;
}
final C c = new C();
final v = c.items..[1] = 2;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushReference,
        ],
        assignmentOperators: [],
        ints: [],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'items',
                  expectedKind: ReferenceKind.unresolved,
                  prefixExpectations: [
                    new _PrefixExpectation(
                        ReferenceKind.topLevelPropertyAccessor, 'c'),
                  ])
        ]);
  }

  test_expr_cascadeSection_assignToProperty() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C {
  int f1 = 0;
  int f2 = 0;
}
final v = new C()..f1 = 1..f2 += 2;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeConstructor,
        ],
        assignmentOperators: [],
        ints: [
          0,
          0
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'C',
              expectedKind: ReferenceKind.classOrEnum)
        ]);
  }

  test_expr_cascadeSection_embedded() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class A {
  int fa1;
  B b;
  int fa2;
}
class B {
  int fb;
}
final v = new A()
  ..fa1 = 1
  ..b = (new B()..fb = 2)
  ..fa2 = 3;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeConstructor,
        ],
        assignmentOperators: [],
        ints: [
          0,
          0,
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'A',
              expectedKind: ReferenceKind.classOrEnum),
        ]);
  }

  test_expr_cascadeSection_invokeMethod() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class A {
  int m(int _) => 0;
}
final A a = new A();
final v = a..m(5).abs()..m(6);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushReference,
        ],
        ints: [],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'a',
              expectedKind: ReferenceKind.topLevelPropertyAccessor),
        ]);
  }

  test_expr_extractIndex_ofClassField() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C {
  List<int> get items => null;
}
final v = new C().items[5];
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeConstructor,
          UnlinkedExprOperation.extractProperty,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.extractIndex,
        ],
        ints: [
          0,
          0,
          5
        ],
        strings: [
          'items'
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'C',
              expectedKind: ReferenceKind.classOrEnum)
        ]);
  }

  test_expr_extractProperty_ofInvokeConstructor() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C {
  int f = 0;
}
final v = new C().f;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeConstructor,
          UnlinkedExprOperation.extractProperty,
        ],
        ints: [
          0,
          0
        ],
        strings: [
          'f'
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'C',
              expectedKind: ReferenceKind.classOrEnum)
        ]);
  }

  test_expr_functionExpression_asArgument() {
    UnlinkedVariable variable = serializeVariableText('''
final v = foo(5, () => 42);
foo(a, b) {}
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeMethodRef
        ],
        ints: [
          0,
          0,
          0
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.topLevelFunction)
        ]);
  }

  test_expr_functionExpression_asArgument_multiple() {
    UnlinkedVariable variable = serializeVariableText('''
final v = foo(5, () => 42, () => 43);
foo(a, b, c) {}
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeMethodRef
        ],
        ints: [
          0,
          0,
          0
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'foo',
              expectedKind: ReferenceKind.topLevelFunction)
        ]);
  }

  test_expr_functionExpression_withBlockBody() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = () { return 42; };
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [UnlinkedExprOperation.pushLocalFunctionReference],
        ints: [0, 0]);
  }

  test_expr_functionExpression_withExpressionBody() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = () => 42;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [UnlinkedExprOperation.pushLocalFunctionReference],
        ints: [0, 0]);
  }

  test_expr_functionExpressionInvocation_withBlockBody() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = ((a, b) {return 42;})(1, 2);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false, operators: [UnlinkedExprOperation.pushNull]);
  }

  test_expr_functionExpressionInvocation_withExpressionBody() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = ((a, b) => 42)(1, 2);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false, operators: [UnlinkedExprOperation.pushNull]);
  }

  test_expr_inClosure() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('var v = () => 1;');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [1]);
  }

  test_expr_inClosure_noTypeInferenceNeeded() {
    // We don't serialize closure body expressions for closures that don't need
    // to participate in type inference.
    UnlinkedVariable variable = serializeVariableText('Object v = () => 1;');
    expect(variable.initializer.localFunctions[0].bodyExpr, isNull);
  }

  test_expr_inClosure_refersToOuterParam() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable =
        serializeVariableText('var v = (x) => (y) => x;');
    assertUnlinkedConst(
        variable.initializer.localFunctions[0].localFunctions[0].bodyExpr,
        operators: [UnlinkedExprOperation.pushParameter],
        strings: ['x']);
  }

  test_expr_inClosure_refersToParam() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('var v = (x) => x;');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        operators: [UnlinkedExprOperation.pushParameter], strings: ['x']);
  }

  test_expr_inClosure_refersToParam_methodCall() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('var v = (x) => x.f();');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.invokeMethod
        ],
        strings: [
          'x',
          'f'
        ],
        ints: [
          0,
          0,
          0
        ]);
  }

  test_expr_inClosure_refersToParam_methodCall_prefixed() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable =
        serializeVariableText('var v = (x) => x.y.f();');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.extractProperty,
          UnlinkedExprOperation.invokeMethod
        ],
        strings: [
          'x',
          'y',
          'f'
        ],
        ints: [
          0,
          0,
          0
        ]);
  }

  test_expr_inClosure_refersToParam_outOfScope() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable =
        serializeVariableText('var x; var v = (b) => (b ? (x) => x : x);');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.pushLocalFunctionReference,
          UnlinkedExprOperation.pushReference,
          UnlinkedExprOperation.conditional,
        ],
        strings: [
          'b'
        ],
        ints: [
          0,
          0
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'x',
              expectedKind: ReferenceKind.topLevelPropertyAccessor)
        ]);
  }

  test_expr_inClosure_refersToParam_prefixedIdentifier() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('var v = (x) => x.y;');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        operators: [
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.extractProperty
        ],
        strings: [
          'x',
          'y'
        ]);
  }

  test_expr_inClosure_refersToParam_prefixedIdentifier_assign() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable =
        serializeVariableText('var v = (x) => x.y = null;');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushNull,
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.assignToProperty
        ],
        strings: [
          'x',
          'y'
        ],
        assignmentOperators: [
          UnlinkedExprAssignOperator.assign
        ]);
  }

  test_expr_inClosure_refersToParam_prefixedPrefixedIdentifier() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('var v = (x) => x.y.z;');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        operators: [
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.extractProperty,
          UnlinkedExprOperation.extractProperty
        ],
        strings: [
          'x',
          'y',
          'z'
        ]);
  }

  test_expr_inClosure_refersToParam_prefixedPrefixedIdentifier_assign() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable =
        serializeVariableText('var v = (x) => x.y.z = null;');
    assertUnlinkedConst(variable.initializer.localFunctions[0].bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushNull,
          UnlinkedExprOperation.pushParameter,
          UnlinkedExprOperation.extractProperty,
          UnlinkedExprOperation.assignToProperty
        ],
        strings: [
          'x',
          'y',
          'z'
        ],
        assignmentOperators: [
          UnlinkedExprAssignOperator.assign
        ]);
  }

  test_expr_invalid_typeParameter_asPrefix() {
    if (skipNonConstInitializers) {
      return;
    }
    var c = serializeClassText('''
class C<T> {
  final f = T.k;
}
''');
    assertUnlinkedConst(c.fields[0].initializer.bodyExpr,
        isValidConst: false, operators: []);
  }

  test_expr_invokeMethod_instance() {
    UnlinkedVariable variable = serializeVariableText('''
class C {
  int m(a, {b, c}) => 42;
}
final v = new C().m(1, b: 2, c: 3);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeConstructor,
          UnlinkedExprOperation.invokeMethod,
        ],
        ints: [
          0,
          0,
          0,
          0,
          0
        ],
        strings: [
          'm'
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'C',
              expectedKind: ReferenceKind.classOrEnum)
        ]);
  }

  test_expr_invokeMethod_withTypeParameters() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C {
  f<T, U>() => null;
}
final v = new C().f<int, String>();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeConstructor,
          UnlinkedExprOperation.invokeMethod
        ],
        ints: [
          0,
          0,
          0,
          0,
          2
        ],
        strings: [
          'f'
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'C'),
          (EntityRef r) => checkTypeRef(r, 'dart:core', 'int'),
          (EntityRef r) => checkTypeRef(r, 'dart:core', 'String')
        ]);
  }

  test_expr_invokeMethodRef_instance() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class A {
  B b;
}
class B {
  C c;
}
class C {
  int m(int a, int b) => a + b;
}
A a = new A();
final v = a.b.c.m(10, 20);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeMethodRef,
        ],
        ints: [
          0,
          0,
          0
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'm',
                  expectedKind: ReferenceKind.unresolved,
                  prefixExpectations: [
                    new _PrefixExpectation(ReferenceKind.unresolved, 'c'),
                    new _PrefixExpectation(ReferenceKind.unresolved, 'b'),
                    new _PrefixExpectation(
                        ReferenceKind.topLevelPropertyAccessor, 'a')
                  ])
        ]);
  }

  test_expr_invokeMethodRef_static_importedWithPrefix() {
    if (skipNonConstInitializers) {
      return;
    }
    addNamedSource('/a.dart', '''
class C {
  static int m() => 42;
}
''');
    UnlinkedVariable variable = serializeVariableText('''
import 'a.dart' as p;
final v = p.C.m();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeMethodRef,
        ],
        ints: [
          0,
          0,
          0
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'm',
                  expectedKind: ReferenceKind.method,
                  prefixExpectations: [
                    new _PrefixExpectation(ReferenceKind.classOrEnum, 'C',
                        absoluteUri: absUri('/a.dart')),
                    new _PrefixExpectation(ReferenceKind.prefix, 'p')
                  ])
        ]);
  }

  test_expr_invokeMethodRef_with_reference_arg() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
f(x) => null;
final u = null;
final v = f(u);
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeMethodRef
        ],
        ints: [
          0,
          0,
          0
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'f',
              expectedKind: ReferenceKind.topLevelFunction)
        ]);
  }

  test_expr_invokeMethodRef_withTypeParameters() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
f<T, U>() => null;
final v = f<int, String>();
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.invokeMethodRef
        ],
        ints: [
          0,
          0,
          2
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'f',
              expectedKind: ReferenceKind.topLevelFunction,
              numTypeParameters: 2),
          (EntityRef r) => checkTypeRef(r, 'dart:core', 'int'),
          (EntityRef r) => checkTypeRef(r, 'dart:core', 'String')
        ]);
  }

  test_expr_makeTypedList() {
    UnlinkedVariable variable =
        serializeVariableText('var v = <int>[11, 22, 33];');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.makeTypedList
    ], ints: [
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, 'dart:core', 'int',
          expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_expr_makeTypedMap() {
    UnlinkedVariable variable = serializeVariableText(
        'var v = <int, String>{11: "aaa", 22: "bbb", 33: "ccc"};');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.makeTypedMap
    ], ints: [
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, 'dart:core', 'int',
          expectedKind: ReferenceKind.classOrEnum),
      (EntityRef r) => checkTypeRef(r, 'dart:core', 'String',
          expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_expr_makeUntypedList() {
    UnlinkedVariable variable = serializeVariableText('var v = [11, 22, 33];');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.makeUntypedList
    ], ints: [
      11,
      22,
      33,
      3
    ]);
  }

  test_expr_makeUntypedMap() {
    UnlinkedVariable variable =
        serializeVariableText('var v = {11: "aaa", 22: "bbb", 33: "ccc"};');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.pushInt,
      UnlinkedExprOperation.pushString,
      UnlinkedExprOperation.makeUntypedMap
    ], ints: [
      11,
      22,
      33,
      3
    ], strings: [
      'aaa',
      'bbb',
      'ccc'
    ]);
  }

  test_expr_super() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = super;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushSuper,
    ]);
  }

  test_expr_this() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = this;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr, operators: [
      UnlinkedExprOperation.pushThis,
    ]);
  }

  test_expr_throwException() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = throw 1 + 2;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.add,
          UnlinkedExprOperation.throwException,
        ],
        ints: [
          1,
          2
        ]);
  }

  test_expr_typeCast() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = 42 as num;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.typeCast,
        ],
        ints: [
          42
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, 'dart:core', 'num',
              expectedKind: ReferenceKind.classOrEnum)
        ]);
  }

  test_expr_typeCheck() {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = 42 is num;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.typeCheck,
        ],
        ints: [
          42
        ],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, 'dart:core', 'num',
              expectedKind: ReferenceKind.classOrEnum)
        ]);
  }

  test_field() {
    UnlinkedClass cls = serializeClassText('class C { int i; }');
    UnlinkedVariable variable = findVariable('i', variables: cls.fields);
    expect(variable, isNotNull);
    expect(variable.isConst, isFalse);
    expect(variable.isStatic, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.initializer, isNull);
    expect(variable.inheritsCovariantSlot, isNot(0));
    expect(findExecutable('i', executables: cls.executables), isNull);
    expect(findExecutable('i=', executables: cls.executables), isNull);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'C');
    expect(unlinkedUnits[0].publicNamespace.names[0].members, isEmpty);
  }

  test_field_const() {
    UnlinkedVariable variable =
        serializeClassText('class C { static const int i = 0; }').fields[0];
    expect(variable.isConst, isTrue);
    expect(variable.inheritsCovariantSlot, 0);
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [0]);
  }

  test_field_documented() {
    if (!includeInformative) return;
    String text = '''
class C {
  /**
   * Docs
   */
  var v;
}''';
    UnlinkedVariable variable = serializeClassText(text).fields[0];
    expect(variable.documentationComment, isNotNull);
    checkDocumentationComment(variable.documentationComment, text);
  }

  test_field_final() {
    UnlinkedVariable variable =
        serializeClassText('class C { final int i = 0; }').fields[0];
    expect(variable.isFinal, isTrue);
    expect(variable.inheritsCovariantSlot, 0);
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.pushInt], ints: [0]);
  }

  test_field_final_notConstExpr() {
    UnlinkedVariable variable = serializeClassText(r'''
class C {
  final int f = 1 + m();
  static int m() => 42;
}''').fields[0];
    expect(variable.isFinal, isTrue);
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.invokeMethodRef,
          UnlinkedExprOperation.add,
        ],
        ints: [
          1,
          0,
          0,
          0
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'm',
                  expectedKind: ReferenceKind.method,
                  prefixExpectations: [
                    new _PrefixExpectation(ReferenceKind.classOrEnum, 'C')
                  ])
        ]);
  }

  test_field_final_typeParameter() {
    UnlinkedVariable variable = serializeClassText(r'''
class C<T> {
  final f = <T>[];
}''').fields[0];
    expect(variable.isFinal, isTrue);
    assertUnlinkedConst(variable.initializer.bodyExpr,
        operators: [UnlinkedExprOperation.makeTypedList],
        ints: [0],
        referenceValidators: [(EntityRef r) => checkParamTypeRef(r, 1)]);
  }

  test_field_formal_param_inferred_type_explicit() {
    UnlinkedClass cls = serializeClassText(
        'class C extends D { var v; C(int this.v); }'
        ' abstract class D { num get v; }',
        className: 'C');
    checkInferredTypeSlot(cls.fields[0].inferredTypeSlot, 'dart:core', 'num');
    expect(cls.executables[0].kind, UnlinkedExecutableKind.constructor);
    expect(cls.executables[0].parameters[0].inferredTypeSlot, 0);
  }

  test_field_formal_param_inferred_type_implicit() {
    // Both the field `v` and the constructor argument `this.v` will have their
    // type inferred by strong mode.  But only the field should have its
    // inferred type stored in the summary, since the standard rules for field
    // formal parameters will take care of the rest (they implicitly inherit
    // the type of the associated field).
    UnlinkedClass cls = serializeClassText(
        'class C extends D { var v; C(this.v); }'
        ' abstract class D { int get v; }',
        className: 'C');
    checkInferredTypeSlot(cls.fields[0].inferredTypeSlot, 'dart:core', 'int');
    expect(cls.executables[0].kind, UnlinkedExecutableKind.constructor);
    expect(cls.executables[0].parameters[0].inferredTypeSlot, 0);
  }

  test_field_inferred_type_nonstatic_explicit_initialized() {
    UnlinkedVariable v = serializeClassText('class C { num v = 0; }').fields[0];
    expect(v.inferredTypeSlot, 0);
  }

  test_field_inferred_type_nonstatic_explicit_uninitialized() {
    UnlinkedVariable v = serializeClassText(
            'class C extends D { num v; } abstract class D { int get v; }',
            className: 'C',
            allowErrors: true)
        .fields[0];
    expect(v.inferredTypeSlot, 0);
  }

  test_field_inferred_type_nonstatic_implicit_initialized() {
    UnlinkedVariable v = serializeClassText('class C { var v = 0; }').fields[0];
    checkInferredTypeSlot(v.inferredTypeSlot, 'dart:core', 'int');
  }

  test_field_inferred_type_nonstatic_implicit_uninitialized() {
    UnlinkedVariable v = serializeClassText(
            'class C extends D { var v; } abstract class D { int get v; }',
            className: 'C')
        .fields[0];
    checkInferredTypeSlot(v.inferredTypeSlot, 'dart:core', 'int');
  }

  test_field_inferred_type_static_explicit_initialized() {
    UnlinkedVariable v =
        serializeClassText('class C { static int v = 0; }').fields[0];
    expect(v.inferredTypeSlot, 0);
  }

  test_field_inferred_type_static_implicit_initialized() {
    UnlinkedVariable v =
        serializeClassText('class C { static var v = 0; }').fields[0];
    checkInferredTypeSlot(v.inferredTypeSlot, 'dart:core', 'int');
  }

  test_field_inferred_type_static_implicit_uninitialized() {
    UnlinkedVariable v =
        serializeClassText('class C { static var v; }').fields[0];
    expect(v.inferredTypeSlot, 0);
  }

  test_field_static() {
    UnlinkedVariable variable =
        serializeClassText('class C { static int i; }').fields[0];
    expect(variable.isStatic, isTrue);
    expect(variable.initializer, isNull);
    expect(variable.inheritsCovariantSlot, 0);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'C');
    expect(unlinkedUnits[0].publicNamespace.names[0].members, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].members[0].name, 'i');
    expect(unlinkedUnits[0].publicNamespace.names[0].members[0].kind,
        ReferenceKind.propertyAccessor);
    expect(
        unlinkedUnits[0].publicNamespace.names[0].members[0].numTypeParameters,
        0);
    expect(
        unlinkedUnits[0].publicNamespace.names[0].members[0].members, isEmpty);
  }

  test_field_static_final() {
    UnlinkedVariable variable =
        serializeClassText('class C { static final int i = 0; }').fields[0];
    expect(variable.isStatic, isTrue);
    expect(variable.isFinal, isTrue);
    expect(variable.initializer.bodyExpr, isNull);
    expect(variable.inheritsCovariantSlot, 0);
  }

  test_field_static_final_untyped() {
    UnlinkedVariable variable =
        serializeClassText('class C { static final x = 0; }').fields[0];
    expect(variable.initializer.bodyExpr, isNotNull);
    expect(variable.inheritsCovariantSlot, 0);
  }

  test_field_untyped() {
    UnlinkedVariable variable =
        serializeClassText('class C { var x = 0; }').fields[0];
    expect(variable.initializer.bodyExpr, isNotNull);
    expect(variable.inheritsCovariantSlot, isNot(0));
  }

  test_fully_linked_references_follow_other_references() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    serializeLibraryText('final x = 0; String y;');
    checkLinkedTypeSlot(
        unlinkedUnits[0].variables[0].inferredTypeSlot, 'dart:core', 'int');
    checkTypeRef(unlinkedUnits[0].variables[1].type, 'dart:core', 'String');
    // Even though the definition of y follows the definition of x, the linked
    // type reference for x should use a higher numbered reference than the
    // unlinked type reference for y.
    EntityRef propagatedType =
        getTypeRefForSlot(unlinkedUnits[0].variables[0].inferredTypeSlot);
    expect(unlinkedUnits[0].variables[1].type.reference,
        lessThan(propagatedType.reference));
  }

  test_function_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
f() {}''';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.documentationComment, isNotNull);
    checkDocumentationComment(executable.documentationComment, text);
  }

  test_function_inferred_type_implicit_param() {
    UnlinkedExecutable f = serializeExecutableText('void f(value) {}');
    expect(f.parameters[0].inferredTypeSlot, 0);
  }

  test_function_inferred_type_implicit_return() {
    UnlinkedExecutable f = serializeExecutableText('f() => null;');
    expect(f.inferredReturnTypeSlot, 0);
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

  test_getter_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
get f => null;''';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.documentationComment, isNotNull);
    checkDocumentationComment(executable.documentationComment, text);
  }

  test_getter_inferred_type_nonstatic_explicit_return() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { num get f => null; }'
            ' abstract class D { int get f; }',
            className: 'C',
            allowErrors: true)
        .executables[0];
    expect(f.inferredReturnTypeSlot, 0);
  }

  test_getter_inferred_type_nonstatic_implicit_return() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { get f => null; } abstract class D { int get f; }',
            className: 'C')
        .executables[0];
    checkInferredTypeSlot(f.inferredReturnTypeSlot, 'dart:core', 'int');
  }

  test_getter_inferred_type_static_implicit_return() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { static get f => null; }'
            ' class D { static int get f => null; }',
            className: 'C')
        .executables[0];
    expect(f.inferredReturnTypeSlot, 0);
  }

  test_implicit_dependencies_follow_other_dependencies() {
    if (skipFullyLinkedData) {
      return;
    }
    addNamedSource('/a.dart', 'import "b.dart"; class C {} D f() => null;');
    addNamedSource('/b.dart', 'class D {}');
    serializeLibraryText('import "a.dart"; final x = f(); C y;');
    // The dependency on b.dart is implicit, so it should be placed at the end
    // of the dependency list, after a.dart, even though the code that refers
    // to b.dart comes before the code that refers to a.dart.
    int aDep = checkHasDependency('a.dart', fullyLinked: false);
    int bDep = checkHasDependency('b.dart', fullyLinked: true);
    expect(aDep, lessThan(bDep));
  }

  test_import_configurations() {
    addNamedSource('/foo.dart', 'bar() {}');
    addNamedSource('/foo_io.dart', 'bar() {}');
    addNamedSource('/foo_html.dart', 'bar() {}');
    String libraryText = r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.flavor == 'html') 'foo_html.dart';
''';
    serializeLibraryText(libraryText);
    UnlinkedImport imp = unlinkedUnits[0].imports[0];
    expect(imp.configurations, hasLength(2));
    {
      UnlinkedConfiguration configuration = imp.configurations[0];
      expect(configuration.name, 'dart.library.io');
      expect(configuration.value, 'true');
      expect(configuration.uri, 'foo_io.dart');
    }
    {
      UnlinkedConfiguration configuration = imp.configurations[1];
      expect(configuration.name, 'dart.flavor');
      expect(configuration.value, 'html');
      expect(configuration.uri, 'foo_html.dart');
    }
  }

  test_import_deferred() {
    serializeLibraryText(
        'import "dart:async" deferred as a; main() { print(a.Future); }');
    expect(unlinkedUnits[0].imports[0].isDeferred, isTrue);
  }

  test_import_dependency() {
    serializeLibraryText('import "dart:async"; Future x;');
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    checkDependency(linked.importDependencies[0], 'dart:async');
  }

  test_import_explicit() {
    serializeLibraryText('import "dart:core"; int i;');
    expect(unlinkedUnits[0].imports, hasLength(1));
    expect(unlinkedUnits[0].imports[0].isImplicit, isFalse);
  }

  test_import_hide_order() {
    serializeLibraryText(
        'import "dart:async" hide Future, Stream; Completer c;');
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].combinators, hasLength(1));
    expect(unlinkedUnits[0].imports[0].combinators[0].shows, isEmpty);
    expect(unlinkedUnits[0].imports[0].combinators[0].hides, hasLength(2));
    expect(unlinkedUnits[0].imports[0].combinators[0].hides[0], 'Future');
    expect(unlinkedUnits[0].imports[0].combinators[0].hides[1], 'Stream');
    if (includeInformative) {
      expect(unlinkedUnits[0].imports[0].combinators[0].offset, 0);
      expect(unlinkedUnits[0].imports[0].combinators[0].end, 0);
    }
  }

  test_import_implicit() {
    // The implicit import of dart:core is represented in the model.
    serializeLibraryText('');
    expect(unlinkedUnits[0].imports, hasLength(1));
    checkDependency(linked.importDependencies[0], 'dart:core');
    expect(unlinkedUnits[0].imports[0].uri, isEmpty);
    if (includeInformative) {
      expect(unlinkedUnits[0].imports[0].uriOffset, 0);
      expect(unlinkedUnits[0].imports[0].uriEnd, 0);
    }
    expect(unlinkedUnits[0].imports[0].prefixReference, 0);
    expect(unlinkedUnits[0].imports[0].combinators, isEmpty);
    expect(unlinkedUnits[0].imports[0].isImplicit, isTrue);
  }

  test_import_missing() {
    // Unresolved imports are included since this is necessary for proper
    // dependency tracking.
    allowMissingFiles = true;
    serializeLibraryText('import "foo.dart";', allowErrors: true);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    checkDependency(linked.importDependencies[0], absUri('/foo.dart'));
  }

  test_import_no_combinators() {
    serializeLibraryText('import "dart:async"; Future x;');
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].combinators, isEmpty);
  }

  test_import_no_flags() {
    serializeLibraryText('import "dart:async"; Future x;');
    expect(unlinkedUnits[0].imports[0].isImplicit, isFalse);
    expect(unlinkedUnits[0].imports[0].isDeferred, isFalse);
  }

  test_import_non_deferred() {
    serializeLibraryText(
        'import "dart:async" as a; main() { print(a.Future); }');
    expect(unlinkedUnits[0].imports[0].isDeferred, isFalse);
  }

  test_import_of_file_with_missing_part() {
    // Other references in foo.dart should be resolved even though foo.dart's
    // part declaration for bar.dart refers to a non-existent file.
    allowMissingFiles = true;
    addNamedSource('/foo.dart', 'part "bar.dart"; class C {}');
    serializeLibraryText('import "foo.dart"; C x;');
    checkTypeRef(findVariable('x').type, absUri('/foo.dart'), 'C');
  }

  test_import_of_missing_export() {
    // Other references in foo.dart should be resolved even though foo.dart's
    // re-export of bar.dart refers to a non-existent file.
    allowMissingFiles = true;
    addNamedSource('/foo.dart', 'export "bar.dart"; class C {}');
    serializeLibraryText('import "foo.dart"; C x;');
    checkTypeRef(findVariable('x').type, absUri('/foo.dart'), 'C');
  }

  test_import_offset() {
    String libraryText = '    import "dart:async"; Future x;';
    serializeLibraryText(libraryText);
    expect(unlinkedUnits[0].imports[0].offset, libraryText.indexOf('import'));
    expect(unlinkedUnits[0].imports[0].uriOffset,
        libraryText.indexOf('"dart:async"'));
    expect(unlinkedUnits[0].imports[0].uriEnd, libraryText.indexOf('; Future'));
  }

  test_import_prefix_name() {
    String libraryText = 'import "dart:async" as a; a.Future x;';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    checkPrefix(unlinkedUnits[0].imports[0].prefixReference, 'a');
    expect(unlinkedUnits[0].imports[0].prefixOffset, libraryText.indexOf('a;'));
  }

  test_import_prefix_none() {
    serializeLibraryText('import "dart:async"; Future x;');
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].prefixReference, 0);
  }

  test_import_prefix_not_in_public_namespace() {
    serializeLibraryText('import "dart:async" as a; a.Future v;');
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(2));
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'v');
    expect(unlinkedUnits[0].publicNamespace.names[1].name, 'v=');
  }

  test_import_prefix_reference() {
    UnlinkedVariable variable =
        serializeVariableText('import "dart:async" as a; a.Future v;');
    checkTypeRef(variable.type, 'dart:async', 'Future',
        expectedPrefix: 'a', numTypeParameters: 1);
  }

  test_import_prefixes_take_precedence_over_imported_names() {
    addNamedSource('/a.dart', 'class b {} class A');
    addNamedSource('/b.dart', 'class Cls {}');
    addNamedSource('/c.dart', 'class Cls {}');
    addNamedSource('/d.dart', 'class c {} class D');
    serializeLibraryText('''
import 'a.dart';
import 'b.dart' as b;
import 'c.dart' as c;
import 'd.dart';
A aCls;
b.Cls bCls;
c.Cls cCls;
D dCls;
''');
    checkTypeRef(findVariable('aCls').type, absUri('/a.dart'), 'A');
    checkTypeRef(findVariable('bCls').type, absUri('/b.dart'), 'Cls',
        expectedPrefix: 'b');
    checkTypeRef(findVariable('cCls').type, absUri('/c.dart'), 'Cls',
        expectedPrefix: 'c');
    checkTypeRef(findVariable('dCls').type, absUri('/d.dart'), 'D');
  }

  test_import_reference() {
    UnlinkedVariable variable =
        serializeVariableText('import "dart:async"; Future v;');
    checkTypeRef(variable.type, 'dart:async', 'Future', numTypeParameters: 1);
  }

  test_import_reference_merged_no_prefix() {
    serializeLibraryText('''
import "dart:async" show Future;
import "dart:async" show Stream;

Future f;
Stream s;
''');
    {
      EntityRef typeRef = findVariable('f').type;
      checkTypeRef(typeRef, 'dart:async', 'Future', numTypeParameters: 1);
    }
    {
      EntityRef typeRef = findVariable('s').type;
      checkTypeRef(typeRef, 'dart:async', 'Stream',
          expectedTargetUnit: 1, numTypeParameters: 1);
    }
  }

  test_import_reference_merged_prefixed() {
    serializeLibraryText('''
import "dart:async" as a show Future;
import "dart:async" as a show Stream;

a.Future f;
a.Stream s;
''');
    {
      EntityRef typeRef = findVariable('f').type;
      checkTypeRef(typeRef, 'dart:async', 'Future',
          expectedPrefix: 'a', numTypeParameters: 1);
    }
    {
      EntityRef typeRef = findVariable('s').type;
      checkTypeRef(typeRef, 'dart:async', 'Stream',
          expectedTargetUnit: 1, expectedPrefix: 'a', numTypeParameters: 1);
    }
  }

  test_import_reference_merged_prefixed_separate_libraries() {
    addNamedSource('/a.dart', 'class A {}');
    addNamedSource('/b.dart', 'class B {}');
    serializeLibraryText('''
import 'a.dart' as p;
import 'b.dart' as p;

p.A a;
p.B b;
''');
    checkTypeRef(findVariable('a').type, absUri('/a.dart'), 'A',
        expectedPrefix: 'p');
    checkTypeRef(findVariable('b').type, absUri('/b.dart'), 'B',
        expectedPrefix: 'p');
  }

  test_import_self() {
    serializeLibraryText('''
import 'test.dart' as p;
class C {}
class D extends p.C {} // Prevent "unused import" warning
''');
    expect(unlinkedUnits[0].imports[0].uri, 'test.dart');
    checkDependency(linked.importDependencies[0], absUri('/test.dart'));
    checkTypeRef(
        unlinkedUnits[0].classes[1].supertype, absUri('/test.dart'), 'C',
        expectedPrefix: 'p');
  }

  test_import_show_order() {
    String libraryText =
        'import "dart:async" show Future, Stream; Future x; Stream y;';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].combinators, hasLength(1));
    expect(unlinkedUnits[0].imports[0].combinators[0].shows, hasLength(2));
    expect(unlinkedUnits[0].imports[0].combinators[0].hides, isEmpty);
    expect(unlinkedUnits[0].imports[0].combinators[0].shows[0], 'Future');
    expect(unlinkedUnits[0].imports[0].combinators[0].shows[1], 'Stream');
    expect(unlinkedUnits[0].imports[0].combinators[0].offset,
        libraryText.indexOf('show'));
    expect(unlinkedUnits[0].imports[0].combinators[0].end,
        libraryText.indexOf('; Future'));
  }

  test_import_uri() {
    String uriString = '"dart:async"';
    String libraryText = 'import $uriString; Future x;';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].uri, 'dart:async');
  }

  test_import_uri_invalid() {
    String uriString = '[invalid uri]';
    String libraryText = 'import "$uriString";';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].uri, uriString);
  }

  test_import_uri_nullStringValue() {
    String libraryText = r'''
import "${'a'}.dart";
''';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].uri, '');
  }

  test_inferred_function_type_parameter_type_with_unrelated_type_param() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    // The type that is inferred for C.f's parameter g is "() -> void".
    // Since the associated element for that function type is B.f's parameter g,
    // and B has a type parameter, the inferred type will record a type
    // parameter.
    UnlinkedClass c = serializeClassText('''
abstract class B<T> {
  void f(void g());
}
class C<T> extends B<T> {
  void f(g) {}
}
''');
    expect(c.executables, hasLength(1));
    UnlinkedExecutable f = c.executables[0];
    expect(f.parameters, hasLength(1));
    UnlinkedParam g = f.parameters[0];
    expect(g.name, 'g');
    EntityRef typeRef = getTypeRefForSlot(g.inferredTypeSlot);
    checkLinkedTypeRef(typeRef, null, 'f',
        expectedKind: ReferenceKind.method, numTypeArguments: 1);
    checkParamTypeRef(typeRef.typeArguments[0], 1);
  }

  test_inferred_type_keeps_leading_dynamic() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedClass cls =
        serializeClassText('class C { final x = <dynamic, int>{}; }');
    EntityRef type = getTypeRefForSlot(cls.fields[0].inferredTypeSlot);
    // Check that x has inferred type `Map<dynamic, int>`.
    checkLinkedTypeRef(type, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkLinkedTypeRef(type.typeArguments[0], null, 'dynamic');
    checkLinkedTypeRef(type.typeArguments[1], 'dart:core', 'int');
  }

  test_inferred_type_reference_shared_prefixed() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    // Variable `y` has an inferred type of `p.C`.  Verify that the reference
    // used by the explicit type of `x` is re-used for the inferred type.
    addNamedSource('/a.dart', 'class C {}');
    serializeLibraryText('import "a.dart" as p; p.C x; var y = new p.C();');
    EntityRef xType = findVariable('x').type;
    EntityRef yType = getTypeRefForSlot(findVariable('y').inferredTypeSlot);
    expect(yType.reference, xType.reference);
  }

  test_inferred_type_refers_to_bound_type_param() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedClass cls = serializeClassText(
        'class C<T> extends D<int, T> { var v; }'
        ' abstract class D<U, V> { Map<V, U> get v; }',
        className: 'C');
    EntityRef type = getTypeRefForSlot(cls.fields[0].inferredTypeSlot);
    // Check that v has inferred type Map<T, int>.
    checkLinkedTypeRef(type, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkParamTypeRef(type.typeArguments[0], 1);
    checkLinkedTypeRef(type.typeArguments[1], 'dart:core', 'int');
  }

  test_inferred_type_refers_to_function_typed_param_of_typedef() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedVariable v = serializeVariableText('''
typedef void F(int g(String s));
h(F f) => null;
var v = h((y) {});
''');
    expect(v.initializer.localFunctions, hasLength(1));
    UnlinkedExecutable closure = v.initializer.localFunctions[0];
    expect(closure.parameters, hasLength(1));
    UnlinkedParam y = closure.parameters[0];
    expect(y.name, 'y');
    EntityRef typeRef = getTypeRefForSlot(y.inferredTypeSlot);
    checkLinkedTypeRef(typeRef, null, 'F', expectedKind: ReferenceKind.typedef);
    expect(typeRef.implicitFunctionTypeIndices, [0]);
  }

  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedClass cls = serializeClassText(
        'class C<T, U> extends D<U, int> { void f(int x, g) {} }'
        ' abstract class D<V, W> { void f(int x, W g(V s)); }',
        className: 'C');
    EntityRef type =
        getTypeRefForSlot(cls.executables[0].parameters[1].inferredTypeSlot);
    // Check that parameter g's inferred type is the type implied by D.f's 1st
    // (zero-based) parameter.
    expect(type.implicitFunctionTypeIndices, [1]);
    expect(type.paramReference, 0);
    expect(type.typeArguments, hasLength(2));
    checkParamTypeRef(type.typeArguments[0], 1);
    checkTypeRef(type.typeArguments[1], 'dart:core', 'int');
    expect(type.reference,
        greaterThanOrEqualTo(unlinkedUnits[0].references.length));
    LinkedReference linkedReference =
        linked.units[0].references[type.reference];
    expect(linkedReference.dependency, 0);
    expect(linkedReference.kind, ReferenceKind.method);
    expect(linkedReference.name, 'f');
    expect(linkedReference.numTypeParameters, 0);
    expect(linkedReference.unit, 0);
    expect(linkedReference.containingReference, isNot(0));
    expect(linkedReference.containingReference, lessThan(type.reference));
    checkReferenceIndex(linkedReference.containingReference, null, 'D',
        numTypeParameters: 2);
  }

  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    addNamedSource('/a.dart', 'import "b.dart"; abstract class D extends E {}');
    addNamedSource(
        '/b.dart', 'abstract class E { void f(int x, int g(String s)); }');
    UnlinkedClass cls = serializeClassText(
        'import "a.dart"; class C extends D { void f(int x, g) {} }');
    EntityRef type =
        getTypeRefForSlot(cls.executables[0].parameters[1].inferredTypeSlot);
    // Check that parameter g's inferred type is the type implied by D.f's 1st
    // (zero-based) parameter.
    expect(type.implicitFunctionTypeIndices, [1]);
    expect(type.paramReference, 0);
    expect(type.typeArguments, isEmpty);
    expect(type.reference,
        greaterThanOrEqualTo(unlinkedUnits[0].references.length));
    LinkedReference linkedReference =
        linked.units[0].references[type.reference];
    expect(linkedReference.dependency, 0);
    expect(linkedReference.kind, ReferenceKind.method);
    expect(linkedReference.name, 'f');
    expect(linkedReference.numTypeParameters, 0);
    expect(linkedReference.unit, 0);
    expect(linkedReference.containingReference, isNot(0));
    expect(linkedReference.containingReference, lessThan(type.reference));
    checkReferenceIndex(
        linkedReference.containingReference, absUri('/b.dart'), 'E');
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedClass cls = serializeClassText(
        'class C extends D { void f(int x, g) {} }'
        ' abstract class D { void f(int x, int g(String s)); }',
        className: 'C');
    EntityRef type =
        getTypeRefForSlot(cls.executables[0].parameters[1].inferredTypeSlot);
    // Check that parameter g's inferred type is the type implied by D.f's 1st
    // (zero-based) parameter.
    expect(type.implicitFunctionTypeIndices, [1]);
    expect(type.paramReference, 0);
    expect(type.typeArguments, isEmpty);
    expect(type.reference,
        greaterThanOrEqualTo(unlinkedUnits[0].references.length));
    LinkedReference linkedReference =
        linked.units[0].references[type.reference];
    expect(linkedReference.dependency, 0);
    expect(linkedReference.kind, ReferenceKind.method);
    expect(linkedReference.name, 'f');
    expect(linkedReference.numTypeParameters, 0);
    expect(linkedReference.unit, 0);
    expect(linkedReference.containingReference, isNot(0));
    expect(linkedReference.containingReference, lessThan(type.reference));
    checkReferenceIndex(linkedReference.containingReference, null, 'D');
  }

  test_inferred_type_refers_to_nested_function_typed_param() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedVariable v = serializeVariableText('''
f(void g(int x, void h())) => null;
var v = f((x, y) {});
''');
    expect(v.initializer.localFunctions, hasLength(1));
    UnlinkedExecutable closure = v.initializer.localFunctions[0];
    expect(closure.parameters, hasLength(2));
    UnlinkedParam y = closure.parameters[1];
    expect(y.name, 'y');
    EntityRef typeRef = getTypeRefForSlot(y.inferredTypeSlot);
    checkLinkedTypeRef(typeRef, null, 'f',
        expectedKind: ReferenceKind.topLevelFunction);
    expect(typeRef.implicitFunctionTypeIndices, [0, 1]);
  }

  test_inferred_type_refers_to_nested_function_typed_param_named() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedVariable v = serializeVariableText('''
f({void g(int x, void h())}) => null;
var v = f(g: (x, y) {});
''');
    expect(v.initializer.localFunctions, hasLength(1));
    UnlinkedExecutable closure = v.initializer.localFunctions[0];
    expect(closure.parameters, hasLength(2));
    UnlinkedParam y = closure.parameters[1];
    expect(y.name, 'y');
    EntityRef typeRef = getTypeRefForSlot(y.inferredTypeSlot);
    checkLinkedTypeRef(typeRef, null, 'f',
        expectedKind: ReferenceKind.topLevelFunction);
    expect(typeRef.implicitFunctionTypeIndices, [0, 1]);
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedClass cls = serializeClassText(
        'class C extends D { void set f(g) {} }'
        ' abstract class D { void set f(int g(String s)); }',
        className: 'C');
    EntityRef type =
        getTypeRefForSlot(cls.executables[0].parameters[0].inferredTypeSlot);
    // Check that parameter g's inferred type is the type implied by D.f's 1st
    // (zero-based) parameter.
    expect(type.implicitFunctionTypeIndices, [0]);
    expect(type.paramReference, 0);
    expect(type.typeArguments, isEmpty);
    expect(type.reference,
        greaterThanOrEqualTo(unlinkedUnits[0].references.length));
    LinkedReference linkedReference =
        linked.units[0].references[type.reference];
    expect(linkedReference.dependency, 0);
    expect(linkedReference.kind, ReferenceKind.propertyAccessor);
    expect(linkedReference.name, 'f=');
    expect(linkedReference.numTypeParameters, 0);
    expect(linkedReference.unit, 0);
    expect(linkedReference.containingReference, isNot(0));
    expect(linkedReference.containingReference, lessThan(type.reference));
    checkReferenceIndex(linkedReference.containingReference, null, 'D');
  }

  test_inferred_type_skips_trailing_dynamic() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedClass cls =
        serializeClassText('class C { final x = <int, dynamic>{}; }');
    EntityRef type = getTypeRefForSlot(cls.fields[0].inferredTypeSlot);
    // Check that x has inferred type `Map<int, dynamic>`.
    checkLinkedTypeRef(type, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkLinkedTypeRef(type.typeArguments[0], 'dart:core', 'int');
    checkLinkedDynamicTypeRef(type.typeArguments[1]);
  }

  test_inferred_type_skips_unnecessary_dynamic() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedClass cls = serializeClassText('class C { final x = []; }');
    EntityRef type = getTypeRefForSlot(cls.fields[0].inferredTypeSlot);
    // Check that x has inferred type `List<dynamic>`.
    checkLinkedTypeRef(type, 'dart:core', 'List',
        numTypeParameters: 1, numTypeArguments: 1);
  }

  test_initializer_executable_with_bottom_return_type() {
    // The synthetic executable for `v` has type `() => Bottom`.
    UnlinkedVariable variable = serializeVariableText('int v = null;');
    expect(variable.initializer.returnType, isNull);
    checkInferredTypeSlot(
        variable.initializer.inferredReturnTypeSlot, null, '*bottom*',
        onlyInStrongMode: false);
  }

  test_initializer_executable_with_imported_return_type() {
    addNamedSource('/a.dart', 'class C { D d; } class D {}');
    // The synthetic executable for `v` has type `() => D`; `D` is defined in
    // a library that is imported.  Note: `v` is mis-typed as `int` to prevent
    // type propagation, which would complicate the test.
    UnlinkedVariable variable = serializeVariableText(
        'import "a.dart"; int v = new C().d;',
        allowErrors: true);
    expect(variable.initializer.returnType, isNull);
    checkInferredTypeSlot(
        variable.initializer.inferredReturnTypeSlot, absUri('/a.dart'), 'D',
        onlyInStrongMode: false);
    checkHasDependency(absUri('/a.dart'), fullyLinked: false);
  }

  test_initializer_executable_with_return_type_from_closure() {
    if (skipFullyLinkedData) {
      return;
    }
    // The synthetic executable for `v` has type `() => () => int`, where the
    // `() => int` part refers to the closure declared inside the initializer
    // for v.  Note: `v` is mis-typed as `int` to prevent type propagation,
    // which would complicate the test.
    UnlinkedVariable variable =
        serializeVariableText('int v = () => 0;', allowErrors: true);
    EntityRef closureType =
        getTypeRefForSlot(variable.initializer.inferredReturnTypeSlot);
    checkLinkedTypeRef(closureType, null, '',
        expectedKind: ReferenceKind.function);
    int initializerIndex =
        definingUnit.references[closureType.reference].containingReference;
    checkReferenceIndex(initializerIndex, null, '',
        expectedKind: ReferenceKind.function);
    int variableIndex =
        definingUnit.references[initializerIndex].containingReference;
    checkReferenceIndex(variableIndex, null, 'v',
        expectedKind: ReferenceKind.topLevelPropertyAccessor);
    expect(definingUnit.references[variableIndex].containingReference, 0);
  }

  test_initializer_executable_with_return_type_from_closure_field() {
    if (skipFullyLinkedData) {
      return;
    }
    // The synthetic executable for `v` has type `() => () => int`, where the
    // `() => int` part refers to the closure declared inside the initializer
    // for v.  Note: `v` is mis-typed as `int` to prevent type propagation,
    // which would complicate the test.
    UnlinkedClass cls = serializeClassText('''
class C {
  int v = () => 0;
}
''', allowErrors: true);
    UnlinkedVariable variable = cls.fields[0];
    EntityRef closureType =
        getTypeRefForSlot(variable.initializer.inferredReturnTypeSlot);
    checkLinkedTypeRef(closureType, null, '',
        expectedKind: ReferenceKind.function);
    int initializerIndex =
        definingUnit.references[closureType.reference].containingReference;
    checkReferenceIndex(initializerIndex, null, '',
        expectedKind: ReferenceKind.function);
    int variableIndex =
        definingUnit.references[initializerIndex].containingReference;
    checkReferenceIndex(variableIndex, null, 'v',
        expectedKind: ReferenceKind.propertyAccessor);
    int classIndex = definingUnit.references[variableIndex].containingReference;
    checkReferenceIndex(classIndex, null, 'C');
    expect(definingUnit.references[classIndex].containingReference, 0);
  }

  test_initializer_executable_with_unimported_return_type() {
    addNamedSource('/a.dart', 'import "b.dart"; class C { D d; }');
    addNamedSource('/b.dart', 'class D {}');
    // The synthetic executable for `v` has type `() => D`; `D` is defined in
    // a library that is not imported.  Note: `v` is mis-typed as `int` to
    // prevent type propagation, which would complicate the test.
    UnlinkedVariable variable = serializeVariableText(
        'import "a.dart"; int v = new C().d;',
        allowErrors: true);
    expect(variable.initializer.returnType, isNull);
    checkInferredTypeSlot(
        variable.initializer.inferredReturnTypeSlot, absUri('/b.dart'), 'D',
        onlyInStrongMode: false);
    if (!skipFullyLinkedData) {
      checkHasDependency('b.dart', fullyLinked: true);
    }
  }

  test_library_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
library foo;''';
    serializeLibraryText(text);
    expect(unlinkedUnits[0].libraryDocumentationComment, isNotNull);
    checkDocumentationComment(
        unlinkedUnits[0].libraryDocumentationComment, text);
  }

  test_library_name_with_spaces() {
    String text = 'library foo . bar ;';
    serializeLibraryText(text);
    expect(unlinkedUnits[0].libraryName, 'foo.bar');
    expect(unlinkedUnits[0].libraryNameOffset, text.indexOf('foo . bar'));
    expect(unlinkedUnits[0].libraryNameLength, 'foo . bar'.length);
  }

  test_library_named() {
    String text = 'library foo.bar;';
    serializeLibraryText(text);
    expect(unlinkedUnits[0].libraryName, 'foo.bar');
    expect(unlinkedUnits[0].libraryNameOffset, text.indexOf('foo.bar'));
    expect(unlinkedUnits[0].libraryNameLength, 'foo.bar'.length);
  }

  test_library_unnamed() {
    serializeLibraryText('');
    expect(unlinkedUnits[0].libraryName, isEmpty);
    expect(unlinkedUnits[0].libraryNameOffset, 0);
    expect(unlinkedUnits[0].libraryNameLength, 0);
  }

  test_library_with_missing_part() {
    // References to other parts should still be resolved.
    allowMissingFiles = true;
    addNamedSource('/bar.dart', 'part of my.lib; class C {}');
    serializeLibraryText(
        'library my.lib; part "foo.dart"; part "bar.dart"; C c;',
        allowErrors: true);
    checkTypeRef(findVariable('c').type, null, 'C', expectedTargetUnit: 2);
  }

  test_lineStarts() {
    String text = '''
int foo;
class Test {}

int bar;'''
        .replaceAll('\r\n', '\n');
    serializeLibraryText(text);
    expect(unlinkedUnits[0].lineStarts, [0, 9, 23, 24]);
  }

  test_linked_reference_reuse() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    // When the reference for a linked type is the same as an explicitly
    // referenced type, the explicit reference should be re-used.
    addNamedSource('/a.dart', 'class C {}');
    addNamedSource('/b.dart', 'import "a.dart"; C f() => null;');
    serializeLibraryText(
        'import "a.dart"; import "b.dart"; C c1; final c2 = f();');
    int explicitReference = findVariable('c1').type.reference;
    expect(getTypeRefForSlot(findVariable('c2').inferredTypeSlot).reference,
        explicitReference);
  }

  test_linked_type_dependency_reuse() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    // When the dependency for a linked type is the same as an explicit
    // dependency, the explicit dependency should be re-used.
    addNamedSource('/a.dart', 'class C {} class D {}');
    addNamedSource('/b.dart', 'import "a.dart"; D f() => null;');
    serializeLibraryText(
        'import "a.dart"; import "b.dart"; C c; final d = f();');
    int cReference = findVariable('c').type.reference;
    int explicitDependency = linked.units[0].references[cReference].dependency;
    int dReference =
        getTypeRefForSlot(findVariable('d').inferredTypeSlot).reference;
    expect(
        linked.units[0].references[dReference].dependency, explicitDependency);
  }

  test_local_names_take_precedence_over_imported_names() {
    addNamedSource('/a.dart', 'class C {} class D {}');
    serializeLibraryText('''
import 'a.dart';
class C {}
C c;
D d;''');
    checkTypeRef(findVariable('c').type, null, 'C');
    checkTypeRef(findVariable('d').type, absUri('/a.dart'), 'D');
  }

  test_localNameShadowsImportPrefix() {
    serializeLibraryText('import "dart:async" as a; class a {}; a x;');
    checkTypeRef(findVariable('x').type, null, 'a');
  }

  test_metadata_classDeclaration() {
    checkAnnotationA(
        serializeClassText('const a = null; @a class C {}').annotations);
  }

  test_metadata_classTypeAlias() {
    checkAnnotationA(serializeClassText(
            'const a = null; @a class C = D with E; class D {} class E {}',
            className: 'C')
        .annotations);
  }

  test_metadata_constructor_call_named() {
    UnlinkedClass cls = serializeClassText(
        'class A { const A.named(); } @A.named() class C {}');
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.constructor,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'A')
              ])
    ]);
  }

  test_metadata_constructor_call_named_prefixed() {
    addNamedSource('/foo.dart', 'class A { const A.named(); }');
    UnlinkedClass cls = serializeClassText(
        'import "foo.dart" as foo; @foo.A.named() class C {}');
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.constructor,
              prefixExpectations: [
                new _PrefixExpectation(
                  ReferenceKind.classOrEnum,
                  'A',
                  absoluteUri: absUri('/foo.dart'),
                ),
                new _PrefixExpectation(ReferenceKind.prefix, 'foo')
              ])
    ]);
  }

  test_metadata_constructor_call_named_prefixed_unresolved_class() {
    addNamedSource('/foo.dart', '');
    UnlinkedClass cls = serializeClassText(
        'import "foo.dart" as foo; @foo.A.named() class C {}',
        allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.unresolved, 'A'),
                new _PrefixExpectation(ReferenceKind.prefix, 'foo')
              ])
    ]);
  }

  test_metadata_constructor_call_named_prefixed_unresolved_constructor() {
    addNamedSource('/foo.dart', 'class A {}');
    UnlinkedClass cls = serializeClassText(
        'import "foo.dart" as foo; @foo.A.named() class C {}',
        allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(
                  ReferenceKind.classOrEnum,
                  'A',
                  absoluteUri: absUri('/foo.dart'),
                ),
                new _PrefixExpectation(ReferenceKind.prefix, 'foo')
              ])
    ]);
  }

  test_metadata_constructor_call_named_unresolved_class() {
    UnlinkedClass cls =
        serializeClassText('@A.named() class C {}', allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.unresolved, 'A')
              ])
    ]);
  }

  test_metadata_constructor_call_named_unresolved_constructor() {
    UnlinkedClass cls = serializeClassText('class A {} @A.named() class C {}',
        allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'named',
              expectedKind: ReferenceKind.unresolved,
              prefixExpectations: [
                new _PrefixExpectation(ReferenceKind.classOrEnum, 'A')
              ])
    ]);
  }

  test_metadata_constructor_call_unnamed() {
    UnlinkedClass cls =
        serializeClassText('class A { const A(); } @A() class C {}');
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'A', expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_metadata_constructor_call_unnamed_prefixed() {
    addNamedSource('/foo.dart', 'class A { const A(); }');
    UnlinkedClass cls =
        serializeClassText('import "foo.dart" as foo; @foo.A() class C {}');
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/foo.dart'), 'A',
          expectedKind: ReferenceKind.classOrEnum, expectedPrefix: 'foo')
    ]);
  }

  test_metadata_constructor_call_unnamed_prefixed_unresolved() {
    addNamedSource('/foo.dart', '');
    UnlinkedClass cls = serializeClassText(
        'import "foo.dart" as foo; @foo.A() class C {}',
        allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'A',
          expectedKind: ReferenceKind.unresolved, expectedPrefix: 'foo')
    ]);
  }

  test_metadata_constructor_call_unnamed_unresolved() {
    UnlinkedClass cls =
        serializeClassText('@A() class C {}', allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      0
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'A', expectedKind: ReferenceKind.unresolved)
    ]);
  }

  test_metadata_constructor_call_with_args() {
    UnlinkedClass cls =
        serializeClassText('class A { const A(x); } @A(null) class C {}');
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.pushNull,
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      1
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'A', expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_metadata_constructorDeclaration_named() {
    checkAnnotationA(
        serializeClassText('const a = null; class C { @a C.named(); }')
            .executables[0]
            .annotations);
  }

  test_metadata_constructorDeclaration_unnamed() {
    checkAnnotationA(serializeClassText('const a = null; class C { @a C(); }')
        .executables[0]
        .annotations);
  }

  test_metadata_enumDeclaration() {
    checkAnnotationA(
        serializeEnumText('const a = null; @a enum E { v }').annotations);
  }

  test_metadata_exportDirective() {
    addNamedSource('/foo.dart', '');
    serializeLibraryText('@a export "foo.dart"; const a = null;');
    checkAnnotationA(unlinkedUnits[0].exports[0].annotations);
  }

  test_metadata_fieldDeclaration() {
    checkAnnotationA(serializeClassText('const a = null; class C { @a int x; }')
        .fields[0]
        .annotations);
  }

  test_metadata_fieldFormalParameter() {
    checkAnnotationA(
        serializeClassText('const a = null; class C { var x; C(@a this.x); }')
            .executables[0]
            .parameters[0]
            .annotations);
  }

  test_metadata_fieldFormalParameter_withDefault() {
    checkAnnotationA(serializeClassText(
            'const a = null; class C { var x; C([@a this.x = null]); }')
        .executables[0]
        .parameters[0]
        .annotations);
  }

  test_metadata_functionDeclaration_function() {
    checkAnnotationA(
        serializeExecutableText('const a = null; @a f() {}').annotations);
  }

  test_metadata_functionDeclaration_getter() {
    checkAnnotationA(
        serializeExecutableText('const a = null; @a get f => null;')
            .annotations);
  }

  test_metadata_functionDeclaration_setter() {
    checkAnnotationA(serializeExecutableText(
            'const a = null; @a set f(value) {}',
            executableName: 'f=')
        .annotations);
  }

  test_metadata_functionTypeAlias() {
    checkAnnotationA(
        serializeTypedefText('const a = null; @a typedef F();').annotations);
  }

  test_metadata_functionTypedFormalParameter() {
    checkAnnotationA(serializeExecutableText('const a = null; f(@a g()) {}')
        .parameters[0]
        .annotations);
  }

  test_metadata_functionTypedFormalParameter_withDefault() {
    checkAnnotationA(
        serializeExecutableText('const a = null; f([@a g() = null]) {}')
            .parameters[0]
            .annotations);
  }

  test_metadata_importDirective() {
    addNamedSource('/foo.dart', 'const b = null;');
    serializeLibraryText('@a import "foo.dart"; const a = b;');
    checkAnnotationA(unlinkedUnits[0].imports[0].annotations);
  }

  test_metadata_invalid_assignable() {
    // Verify that the following does not cause an exception to be thrown.
    serializeLibraryText('@a(-b=""c');
    expect(unlinkedUnits, hasLength(1));
    List<UnlinkedVariable> variables = unlinkedUnits[0].variables;
    expect(variables, hasLength(1));
    List<UnlinkedExpr> annotations = variables[0].annotations;
    expect(annotations, hasLength(1));
    expect(annotations[0].isValidConst, isFalse);
  }

  test_metadata_invalid_instanceCreation_argument_super() {
    List<UnlinkedExpr> annotations = serializeClassText('''
class A {
  const A(_);
}

@A(super)
class C {}
''').annotations;
    expect(annotations, hasLength(1));
    assertUnlinkedConst(annotations[0], operators: [
      UnlinkedExprOperation.pushSuper,
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      1
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'A', expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_metadata_invalid_instanceCreation_argument_this() {
    List<UnlinkedExpr> annotations = serializeClassText('''
class A {
  const A(_);
}

@A(this)
class C {}
''').annotations;
    expect(annotations, hasLength(1));
    assertUnlinkedConst(annotations[0], operators: [
      UnlinkedExprOperation.pushThis,
      UnlinkedExprOperation.invokeConstructor,
    ], ints: [
      0,
      1
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'A', expectedKind: ReferenceKind.classOrEnum)
    ]);
  }

  test_metadata_libraryDirective() {
    serializeLibraryText('@a library L; const a = null;');
    checkAnnotationA(unlinkedUnits[0].libraryAnnotations);
  }

  test_metadata_methodDeclaration_getter() {
    checkAnnotationA(
        serializeClassText('const a = null; class C { @a get m => null; }')
            .executables[0]
            .annotations);
  }

  test_metadata_methodDeclaration_method() {
    checkAnnotationA(serializeClassText('const a = null; class C { @a m() {} }')
        .executables[0]
        .annotations);
  }

  test_metadata_methodDeclaration_setter() {
    checkAnnotationA(
        serializeClassText('const a = null; class C { @a set m(value) {} }')
            .executables[0]
            .annotations);
  }

  test_metadata_multiple_annotations() {
    UnlinkedClass cls =
        serializeClassText('const a = null, b = null; @a @b class C {}');
    List<UnlinkedExpr> annotations = cls.annotations;
    expect(annotations, hasLength(2));
    assertUnlinkedConst(annotations[0], operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'a',
          expectedKind: ReferenceKind.topLevelPropertyAccessor)
    ]);
    assertUnlinkedConst(annotations[1], operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'b',
          expectedKind: ReferenceKind.topLevelPropertyAccessor)
    ]);
  }

  test_metadata_partDirective() {
    addNamedSource('/foo.dart', 'part of L;');
    serializeLibraryText('library L; @a part "foo.dart"; const a = null;');
    checkAnnotationA(unlinkedUnits[0].parts[0].annotations);
  }

  test_metadata_prefixed_variable() {
    addNamedSource('/a.dart', 'const b = null;');
    UnlinkedClass cls =
        serializeClassText('import "a.dart" as a; @a.b class C {}');
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, absUri('/a.dart'), 'b',
          expectedKind: ReferenceKind.topLevelPropertyAccessor,
          expectedPrefix: 'a')
    ]);
  }

  test_metadata_prefixed_variable_unresolved() {
    addNamedSource('/a.dart', '');
    UnlinkedClass cls = serializeClassText(
        'import "a.dart" as a; @a.b class C {}',
        allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) => checkTypeRef(r, null, 'b',
          expectedKind: ReferenceKind.unresolved, expectedPrefix: 'a')
    ]);
  }

  test_metadata_simpleFormalParameter() {
    checkAnnotationA(serializeExecutableText('const a = null; f(@a x) {}')
        .parameters[0]
        .annotations);
  }

  test_metadata_simpleFormalParameter_withDefault() {
    checkAnnotationA(
        serializeExecutableText('const a = null; f([@a x = null]) {}')
            .parameters[0]
            .annotations);
  }

  test_metadata_topLevelVariableDeclaration() {
    checkAnnotationA(
        serializeVariableText('const a = null; @a int v;').annotations);
  }

  test_metadata_typeParameter_ofClass() {
    checkAnnotationA(serializeClassText('const a = null; class C<@a T> {}')
        .typeParameters[0]
        .annotations);
  }

  test_metadata_typeParameter_ofClassTypeAlias() {
    checkAnnotationA(serializeClassText(
            'const a = null; class C<@a T> = D with E; class D {} class E {}',
            className: 'C')
        .typeParameters[0]
        .annotations);
  }

  test_metadata_typeParameter_ofFunction() {
    checkAnnotationA(serializeExecutableText('const a = null; f<@a T>() {}')
        .typeParameters[0]
        .annotations);
  }

  test_metadata_typeParameter_ofTypedef() {
    checkAnnotationA(serializeTypedefText('const a = null; typedef F<@a T>();')
        .typeParameters[0]
        .annotations);
  }

  test_metadata_variable_unresolved() {
    UnlinkedClass cls = serializeClassText('@a class C {}', allowErrors: true);
    expect(cls.annotations, hasLength(1));
    assertUnlinkedConst(cls.annotations[0], operators: [
      UnlinkedExprOperation.pushReference
    ], referenceValidators: [
      (EntityRef r) =>
          checkTypeRef(r, null, 'a', expectedKind: ReferenceKind.unresolved)
    ]);
  }

  test_method_documented() {
    if (!includeInformative) return;
    String text = '''
class C {
  /**
   * Docs
   */
  f() {}
}''';
    UnlinkedExecutable executable = serializeClassText(text).executables[0];
    expect(executable.documentationComment, isNotNull);
    checkDocumentationComment(executable.documentationComment, text);
  }

  test_method_inferred_type_nonstatic_explicit_param() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { void f(num value) {} }'
            ' abstract class D { void f(int value); }',
            className: 'C')
        .executables[0];
    expect(f.parameters[0].inferredTypeSlot, 0);
  }

  test_method_inferred_type_nonstatic_explicit_return() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { num f() => null; } abstract class D { int f(); }',
            className: 'C',
            allowErrors: true)
        .executables[0];
    expect(f.inferredReturnTypeSlot, 0);
  }

  test_method_inferred_type_nonstatic_implicit_param() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { void f(value) {} }'
            ' abstract class D { void f(int value); }',
            className: 'C')
        .executables[0];
    checkInferredTypeSlot(f.parameters[0].inferredTypeSlot, 'dart:core', 'int');
  }

  test_method_inferred_type_nonstatic_implicit_return() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { f() => null; } abstract class D { int f(); }',
            className: 'C')
        .executables[0];
    checkInferredTypeSlot(f.inferredReturnTypeSlot, 'dart:core', 'int');
  }

  test_method_inferred_type_static_implicit_param() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { static void f(value) {} }'
            ' class D { static void f(int value) {} }',
            className: 'C')
        .executables[0];
    expect(f.parameters[0].inferredTypeSlot, 0);
  }

  test_method_inferred_type_static_implicit_return() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { static f() => null; }'
            ' class D { static int f() => null; }',
            className: 'C')
        .executables[0];
    expect(f.inferredReturnTypeSlot, 0);
  }

  test_nested_generic_functions() {
    UnlinkedExecutable executable = serializeVariableText('''
var v = (() {
  void f<T, U>() {
    void g<V, W>() {
      void h<X, Y>(T t, U u, V v W w, X x, Y y) {
      }
    }
  }
});
''').initializer.localFunctions[0].localFunctions[0];
    expect(executable.typeParameters, hasLength(2));
    expect(executable.localFunctions[0].typeParameters, hasLength(2));
    expect(executable.localFunctions[0].localFunctions[0].typeParameters,
        hasLength(2));
    List<UnlinkedParam> parameters =
        executable.localFunctions[0].localFunctions[0].parameters;
    checkParamTypeRef(findParameter(parameters, 't').type, 6);
    checkParamTypeRef(findParameter(parameters, 'u').type, 5);
    checkParamTypeRef(findParameter(parameters, 'v').type, 4);
    checkParamTypeRef(findParameter(parameters, 'w').type, 3);
    checkParamTypeRef(findParameter(parameters, 'x').type, 2);
    checkParamTypeRef(findParameter(parameters, 'y').type, 1);
  }

  test_parameter_visibleRange_abstractMethod() {
    UnlinkedExecutable m = findExecutable('m',
        executables:
            serializeClassText('abstract class C { m(p); }').executables,
        failIfAbsent: true);
    _assertParameterZeroVisibleRange(m.parameters[0]);
  }

  test_parameter_visibleRange_function_blockBody() {
    String text = r'''
var v = (() {
  f(x) { // 1
    f2(y) { // 2
    } // 3
  } // 4
});
''';
    var closure = serializeVariableText(text).initializer.localFunctions[0];
    UnlinkedExecutable f = closure.localFunctions[0];
    UnlinkedExecutable f2 = f.localFunctions[0];
    _assertParameterVisible(text, f.parameters[0], '{ // 1', '} // 4');
    _assertParameterVisible(text, f2.parameters[0], '{ // 2', '} // 3');
  }

  test_parameter_visibleRange_function_emptyBody() {
    UnlinkedExecutable f = serializeExecutableText('external f(x);');
    _assertParameterZeroVisibleRange(f.parameters[0]);
  }

  test_parameter_visibleRange_function_expressionBody() {
    String text = r'''
f(x) => 42;
''';
    UnlinkedExecutable f = serializeExecutableText(text);
    _assertParameterVisible(text, f.parameters[0], '=>', ';');
  }

  test_parameter_visibleRange_inFunctionTypedParameter() {
    String text = 'f(g(p)) {}';
    UnlinkedExecutable f = serializeExecutableText(text);
    UnlinkedParam g = f.parameters[0];
    UnlinkedParam p = g.parameters[0];
    expect(g.name, 'g');
    expect(p.name, 'p');
    _assertParameterVisible(text, g, '{', '}');
    _assertParameterZeroVisibleRange(p);
  }

  test_parameter_visibleRange_invalid_fieldFormalParameter() {
    UnlinkedExecutable m =
        findExecutable('m', executables: serializeClassText(r'''
class C {
  int foo;
  void m(this.foo) {}
}
''').executables);
    _assertParameterZeroVisibleRange(m.parameters[0]);
  }

  test_parameter_visibleRange_typedef() {
    UnlinkedTypedef type = serializeTypedefText('typedef F(x);');
    _assertParameterZeroVisibleRange(type.parameters[0]);
  }

  test_part_declaration() {
    addNamedSource('/a.dart', 'part of my.lib;');
    String text = 'library my.lib; part "a.dart"; // <-part';
    serializeLibraryText(text);
    expect(unlinkedUnits[0].publicNamespace.parts, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.parts[0], 'a.dart');
    expect(unlinkedUnits[0].parts, hasLength(1));
    expect(unlinkedUnits[0].parts[0].uriOffset, text.indexOf('"a.dart"'));
    expect(unlinkedUnits[0].parts[0].uriEnd, text.indexOf('; // <-part'));
  }

  test_part_declaration_invalidUri_nullStringValue() {
    addNamedSource('/a.dart', 'part of my.lib;');
    String text = r'''
library my.lib;
part "${'a'}.dart"; // <-part
''';
    serializeLibraryText(text);
    expect(unlinkedUnits[0].publicNamespace.parts, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.parts[0], '');
    expect(unlinkedUnits[0].parts, hasLength(1));
    expect(unlinkedUnits[0].parts[0].uriOffset, text.indexOf(r'"${'));
    expect(unlinkedUnits[0].parts[0].uriEnd, text.indexOf('; // <-part'));
  }

  test_part_isPartOf() {
    addNamedSource('/a.dart', 'part of foo; class C {}');
    serializeLibraryText('library foo; part "a.dart";');
    expect(unlinkedUnits[0].isPartOf, isFalse);
    expect(unlinkedUnits[1].isPartOf, isTrue);
  }

  test_part_uri_invalid() {
    String uriString = '[invalid uri]';
    String libraryText = 'part "$uriString";';
    serializeLibraryText(libraryText);
    expect(unlinkedUnits[0].publicNamespace.parts, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.parts[0], uriString);
  }

  test_parts_defining_compilation_unit() {
    serializeLibraryText('');
    expect(linked.units, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.parts, isEmpty);
  }

  test_parts_included() {
    addNamedSource('/part1.dart', 'part of my.lib;');
    String partString = '"part1.dart"';
    String libraryText = 'library my.lib; part $partString;';
    serializeLibraryText(libraryText);
    expect(linked.units, hasLength(2));
    expect(unlinkedUnits[0].publicNamespace.parts, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.parts[0], 'part1.dart');
  }

  test_public_namespace_of_part() {
    addNamedSource('/a.dart', 'part of foo; class C {}');
    serializeLibraryText('library foo; part "a.dart";');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
    expect(unlinkedUnits[1].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[1].publicNamespace.names[0].name, 'C');
  }

  test_reference_zero() {
    // Element zero of the references table should be populated in a standard
    // way.
    serializeLibraryText('');
    UnlinkedReference unlinkedReference0 = unlinkedUnits[0].references[0];
    expect(unlinkedReference0.name, '');
    expect(unlinkedReference0.prefixReference, 0);
    LinkedReference linkedReference0 = linked.units[0].references[0];
    expect(linkedReference0.containingReference, 0);
    expect(linkedReference0.dependency, 0);
    expect(linkedReference0.kind, ReferenceKind.unresolved);
    expect(linkedReference0.localIndex, 0);
    expect(linkedReference0.name, '');
    expect(linkedReference0.numTypeParameters, 0);
    expect(linkedReference0.unit, 0);
  }

  test_setter_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set f(value) {}''';
    UnlinkedExecutable executable =
        serializeExecutableText(text, executableName: 'f=');
    expect(executable.documentationComment, isNotNull);
    checkDocumentationComment(executable.documentationComment, text);
  }

  test_setter_inferred_type_nonstatic_explicit_param() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { void set f(num value) {} }'
            ' abstract class D { void set f(int value); }',
            className: 'C')
        .executables[0];
    expect(f.parameters[0].inferredTypeSlot, 0);
  }

  test_setter_inferred_type_nonstatic_explicit_return() {
    UnlinkedExecutable f =
        serializeClassText('class C { void set f(int value) {} }')
            .executables[0];
    expect(f.inferredReturnTypeSlot, 0);
  }

  test_setter_inferred_type_nonstatic_implicit_param() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { void set f(value) {} }'
            ' abstract class D { void set f(int value); }',
            className: 'C')
        .executables[0];
    checkInferredTypeSlot(f.parameters[0].inferredTypeSlot, 'dart:core', 'int');
  }

  test_setter_inferred_type_nonstatic_implicit_return() {
    UnlinkedExecutable f =
        serializeClassText('class C { set f(int value) {} }').executables[0];
    checkInferredTypeSlot(f.inferredReturnTypeSlot, null, 'void');
  }

  test_setter_inferred_type_static_implicit_param() {
    UnlinkedExecutable f = serializeClassText(
            'class C extends D { static void set f(value) {} }'
            ' class D { static void set f(int value) {} }',
            className: 'C')
        .executables[0];
    expect(f.parameters[0].inferredTypeSlot, 0);
  }

  test_setter_inferred_type_static_implicit_return() {
    UnlinkedExecutable f =
        serializeClassText('class C { static set f(int value) {} }')
            .executables[0];
    expect(f.inferredReturnTypeSlot, 0);
  }

  test_setter_inferred_type_top_level_implicit_param() {
    UnlinkedExecutable f =
        serializeExecutableText('void set f(value) {}', executableName: 'f=');
    expect(f.parameters[0].inferredTypeSlot, 0);
  }

  test_setter_inferred_type_top_level_implicit_return() {
    UnlinkedExecutable f =
        serializeExecutableText('set f(int value) {}', executableName: 'f=');
    expect(f.inferredReturnTypeSlot, 0);
  }

  test_slot_reuse() {
    // Different compilation units have independent notions of slot id, so slot
    // ids should be reused.
    addNamedSource('/a.dart', 'part of foo; final v = 0;');
    serializeLibraryText('library foo; part "a.dart"; final w = 0;');
    expect(unlinkedUnits[1].variables[0].inferredTypeSlot,
        unlinkedUnits[0].variables[0].inferredTypeSlot);
  }

  test_syntheticFunctionType_genericClosure() {
    if (skipFullyLinkedData) {
      return;
    }
    if (!strongMode) {
      // The test below uses generic comment syntax because proper generic
      // method syntax doesn't support generic closures.  So it can only run in
      // strong mode.
      // TODO(paulberry): once proper generic method syntax supports generic
      // closures, rewrite the test below without using generic comment syntax,
      // and remove this hack.  See dartbug.com/25819
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
final v = f() ? /*<T>*/(T t) => 0 : /*<T>*/(T t) => 1;
bool f() => true;
''');
    EntityRef inferredType = getTypeRefForSlot(variable.inferredTypeSlot);
    checkLinkedTypeRef(inferredType.syntheticReturnType, 'dart:core', 'int');
    expect(inferredType.syntheticParams, hasLength(1));
    checkLinkedTypeRef(inferredType.syntheticParams[0].type, null, '*bottom*');
  }

  test_syntheticFunctionType_inGenericClass() {
    if (skipFullyLinkedData) {
      return;
    }
    UnlinkedVariable variable = serializeClassText('''
class C<T, U> {
  var v = f() ? (T t, U u) => 0 : (T t, U u) => 1;
}
bool f() => false;
''').fields[0];
    EntityRef inferredType =
        getTypeRefForSlot(variable.initializer.inferredReturnTypeSlot);
    checkLinkedTypeRef(inferredType.syntheticReturnType, 'dart:core', 'int');
    checkParamTypeRef(inferredType.syntheticParams[0].type, 2);
    checkParamTypeRef(inferredType.syntheticParams[1].type, 1);
  }

  test_type_arguments_explicit() {
    EntityRef typeRef = serializeTypeText('List<int>');
    checkTypeRef(typeRef, 'dart:core', 'List',
        numTypeParameters: 1, numTypeArguments: 1);
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'int');
  }

  test_type_arguments_explicit_dynamic() {
    EntityRef typeRef = serializeTypeText('List<dynamic>');
    checkTypeRef(typeRef, 'dart:core', 'List',
        numTypeParameters: 1, numTypeArguments: 1);
    checkDynamicTypeRef(typeRef.typeArguments[0]);
  }

  test_type_arguments_explicit_dynamic_dynamic() {
    EntityRef typeRef = serializeTypeText('Map<dynamic, dynamic>');
    checkTypeRef(typeRef, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkDynamicTypeRef(typeRef.typeArguments[0]);
    checkDynamicTypeRef(typeRef.typeArguments[1]);
  }

  test_type_arguments_explicit_dynamic_int() {
    EntityRef typeRef = serializeTypeText('Map<dynamic, int>');
    checkTypeRef(typeRef, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkDynamicTypeRef(typeRef.typeArguments[0]);
    checkTypeRef(typeRef.typeArguments[1], 'dart:core', 'int');
  }

  test_type_arguments_explicit_dynamic_typedef() {
    EntityRef typeRef =
        serializeTypeText('F<dynamic>', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, 'F',
        expectedKind: ReferenceKind.typedef,
        numTypeParameters: 1,
        numTypeArguments: 1);
    checkDynamicTypeRef(typeRef.typeArguments[0]);
  }

  test_type_arguments_explicit_String_dynamic() {
    EntityRef typeRef = serializeTypeText('Map<String, dynamic>');
    checkTypeRef(typeRef, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'String');
    checkDynamicTypeRef(typeRef.typeArguments[1]);
  }

  test_type_arguments_explicit_String_int() {
    EntityRef typeRef = serializeTypeText('Map<String, int>');
    checkTypeRef(typeRef, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'String');
    checkTypeRef(typeRef.typeArguments[1], 'dart:core', 'int');
  }

  test_type_arguments_explicit_typedef() {
    EntityRef typeRef =
        serializeTypeText('F<int>', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, 'F',
        expectedKind: ReferenceKind.typedef,
        numTypeParameters: 1,
        numTypeArguments: 1);
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'int');
  }

  test_type_arguments_implicit() {
    EntityRef typeRef = serializeTypeText('List');
    checkTypeRef(typeRef, 'dart:core', 'List', numTypeParameters: 1);
  }

  test_type_arguments_implicit_typedef() {
    EntityRef typeRef =
        serializeTypeText('F', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, 'F',
        expectedKind: ReferenceKind.typedef, numTypeParameters: 1);
  }

  test_type_arguments_implicit_typedef_withBound() {
    EntityRef typeRef = serializeTypeText('F',
        otherDeclarations: 'typedef T F<T extends num>();');
    checkTypeRef(typeRef, null, 'F',
        expectedKind: ReferenceKind.typedef, numTypeParameters: 1);
  }

  test_type_arguments_order() {
    EntityRef typeRef = serializeTypeText('Map<int, Object>');
    checkTypeRef(typeRef, 'dart:core', 'Map',
        numTypeParameters: 2, numTypeArguments: 2);
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'int');
    checkTypeRef(typeRef.typeArguments[1], 'dart:core', 'Object');
  }

  test_type_dynamic() {
    checkDynamicTypeRef(serializeTypeText('dynamic'));
  }

  test_type_invalid_typeParameter_asPrefix() {
    UnlinkedClass c = serializeClassText('''
class C<T> {
  m(T.K p) {}
}
''');
    UnlinkedExecutable m = c.executables[0];
    expect(m.name, 'm');
    checkTypeRef(m.parameters[0].type, null, 'dynamic');
  }

  test_type_param_codeRange() {
    if (!includeInformative) return;
    UnlinkedClass cls =
        serializeClassText('class A {} class C<T extends A> {}');
    UnlinkedTypeParam typeParameter = cls.typeParameters[0];
    _assertCodeRange(typeParameter.codeRange, 19, 11);
  }

  test_type_param_not_shadowed_by_constructor() {
    UnlinkedClass cls =
        serializeClassText('class C<D> { D x; C.D(); } class D {}');
    checkParamTypeRef(cls.fields[0].type, 1);
  }

  test_type_param_not_shadowed_by_field_in_extends() {
    UnlinkedClass cls =
        serializeClassText('class C<T> extends D<T> { T x; } class D<T> {}');
    checkParamTypeRef(cls.supertype.typeArguments[0], 1);
  }

  test_type_param_not_shadowed_by_field_in_implements() {
    UnlinkedClass cls =
        serializeClassText('class C<T> implements D<T> { T x; } class D<T> {}');
    checkParamTypeRef(cls.interfaces[0].typeArguments[0], 1);
  }

  test_type_param_not_shadowed_by_field_in_with() {
    UnlinkedClass cls = serializeClassText(
        'class C<T> extends Object with D<T> { T x; } class D<T> {}');
    checkParamTypeRef(cls.mixins[0].typeArguments[0], 1);
  }

  test_type_param_not_shadowed_by_method_parameter() {
    UnlinkedClass cls = serializeClassText('class C<T> { f(int T, T x) {} }');
    checkParamTypeRef(cls.executables[0].parameters[1].type, 1);
  }

  test_type_param_not_shadowed_by_setter() {
    // The code under test should not produce a compile-time error, but it
    // does.
    bool workAroundBug25525 = true;
    UnlinkedClass cls = serializeClassText(
        'class C<D> { D x; void set D(value) {} } class D {}',
        allowErrors: workAroundBug25525);
    checkParamTypeRef(cls.fields[0].type, 1);
  }

  test_type_param_not_shadowed_by_typedef_parameter() {
    UnlinkedTypedef typedef =
        serializeTypedefText('typedef void F<T>(int T, T x);');
    checkParamTypeRef(typedef.parameters[1].type, 1);
  }

  test_type_param_shadowed_by_field() {
    UnlinkedClass cls = serializeClassText(
        'class C<D> { D x; int D; } class D {}',
        allowErrors: true);
    checkDynamicTypeRef(cls.fields[0].type);
  }

  test_type_param_shadowed_by_getter() {
    UnlinkedClass cls = serializeClassText(
        'class C<D> { D x; int get D => null; } class D {}',
        allowErrors: true);
    checkDynamicTypeRef(cls.fields[0].type);
  }

  test_type_param_shadowed_by_method() {
    UnlinkedClass cls = serializeClassText(
        'class C<D> { D x; void D() {} } class D {}',
        allowErrors: true);
    checkDynamicTypeRef(cls.fields[0].type);
  }

  test_type_param_shadowed_by_type_param() {
    UnlinkedClass cls =
        serializeClassText('class C<T> { T f<T>(T x) => null; }');
    checkParamTypeRef(cls.executables[0].returnType, 1);
    checkParamTypeRef(cls.executables[0].parameters[0].type, 1);
  }

  test_type_reference_from_part() {
    addNamedSource('/a.dart', 'part of foo; C v;');
    serializeLibraryText('library foo; part "a.dart"; class C {}');
    checkTypeRef(findVariable('v', variables: unlinkedUnits[1].variables).type,
        null, 'C',
        expectedKind: ReferenceKind.classOrEnum,
        linkedSourceUnit: linked.units[1],
        unlinkedSourceUnit: unlinkedUnits[1]);
  }

  test_type_reference_from_part_withPrefix() {
    addNamedSource('/a.dart', 'class C {}');
    addNamedSource('/p.dart', 'part of foo; a.C v;');
    serializeLibraryText(
        'library foo; import "a.dart"; import "a.dart" as a; part "p.dart";',
        allowErrors: true);
    checkTypeRef(findVariable('v', variables: unlinkedUnits[1].variables).type,
        absUri('/a.dart'), 'C',
        expectedPrefix: 'a',
        linkedSourceUnit: linked.units[1],
        unlinkedSourceUnit: unlinkedUnits[1]);
  }

  test_type_reference_to_class_argument() {
    UnlinkedClass cls = serializeClassText('class C<T, U> { T t; U u; }');
    {
      EntityRef typeRef =
          findVariable('t', variables: cls.fields, failIfAbsent: true).type;
      checkParamTypeRef(typeRef, 2);
    }
    {
      EntityRef typeRef =
          findVariable('u', variables: cls.fields, failIfAbsent: true).type;
      checkParamTypeRef(typeRef, 1);
    }
  }

  test_type_reference_to_import_of_export() {
    addNamedSource('/a.dart', 'library a; export "b.dart";');
    addNamedSource('/b.dart', 'library b; class C {}');
    checkTypeRef(serializeTypeText('C', otherDeclarations: 'import "a.dart";'),
        absUri('/b.dart'), 'C');
  }

  test_type_reference_to_import_of_export_via_prefix() {
    addNamedSource('/a.dart', 'library a; export "b.dart";');
    addNamedSource('/b.dart', 'library b; class C {}');
    checkTypeRef(
        serializeTypeText('p.C', otherDeclarations: 'import "a.dart" as p;'),
        absUri('/b.dart'),
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
        'C',
        expectedPrefix: 'p',
        expectedTargetUnit: 1);
  }

  test_type_reference_to_internal_class() {
    checkTypeRef(
        serializeTypeText('C', otherDeclarations: 'class C {}'), null, 'C');
  }

  test_type_reference_to_internal_class_alias() {
    checkTypeRef(
        serializeTypeText('C',
            otherDeclarations: 'class C = D with E; class D {} class E {}'),
        null,
        'C');
  }

  test_type_reference_to_internal_enum() {
    checkTypeRef(serializeTypeText('E', otherDeclarations: 'enum E { value }'),
        null, 'E');
  }

  test_type_reference_to_local_part() {
    addNamedSource('/a.dart', 'part of my.lib; class C {}');
    checkTypeRef(
        serializeTypeText('C',
            otherDeclarations: 'library my.lib; part "a.dart";'),
        null,
        'C',
        expectedTargetUnit: 1);
  }

  test_type_reference_to_nonexistent_file_via_prefix() {
    allowMissingFiles = true;
    EntityRef typeRef = serializeTypeText('p.C',
        otherDeclarations: 'import "foo.dart" as p;', allowErrors: true);
    checkUnresolvedTypeRef(typeRef, 'p', 'C');
  }

  test_type_reference_to_part() {
    addNamedSource('/a.dart', 'part of foo; class C { C(); }');
    serializeLibraryText('library foo; part "a.dart"; C c;');
    checkTypeRef(unlinkedUnits[0].variables.single.type, null, 'C',
        expectedKind: ReferenceKind.classOrEnum, expectedTargetUnit: 1);
  }

  test_type_reference_to_type_visible_via_multiple_import_prefixes() {
    addNamedSource('/lib1.dart', 'class C');
    addNamedSource('/lib2.dart', 'export "lib1.dart";');
    addNamedSource('/lib3.dart', 'export "lib1.dart";');
    addNamedSource('/lib4.dart', 'export "lib1.dart";');
    serializeLibraryText('''
import 'lib2.dart';
import 'lib3.dart' as a;
import 'lib4.dart' as b;
C c2;
a.C c3;
b.C c4;''');
    // Note: it is important that each reference to class C records the prefix
    // used to find it; otherwise it's possible that relinking might produce an
    // incorrect result after a change to lib2.dart, lib3.dart, or lib4.dart.
    checkTypeRef(findVariable('c2').type, absUri('/lib1.dart'), 'C');
    checkTypeRef(findVariable('c3').type, absUri('/lib1.dart'), 'C',
        expectedPrefix: 'a');
    checkTypeRef(findVariable('c4').type, absUri('/lib1.dart'), 'C',
        expectedPrefix: 'b');
  }

  test_type_reference_to_typedef() {
    checkTypeRef(serializeTypeText('F', otherDeclarations: 'typedef void F();'),
        null, 'F',
        expectedKind: ReferenceKind.typedef);
  }

  test_type_unit_counts_unreferenced_units() {
    addNamedSource('/a.dart', 'library a; part "b.dart"; part "c.dart";');
    addNamedSource('/b.dart', 'part of a;');
    addNamedSource('/c.dart', 'part of a; class C {}');
    EntityRef typeRef =
        serializeTypeText('C', otherDeclarations: 'import "a.dart";');
    // The referenced unit should be 2, since unit 0 is a.dart and unit 1 is
    // b.dart.  a.dart and b.dart are counted even though nothing is imported
    // from them.
    checkTypeRef(typeRef, absUri('/a.dart'), 'C', expectedTargetUnit: 2);
  }

  test_type_unresolved() {
    EntityRef typeRef = serializeTypeText('Foo', allowErrors: true);
    checkUnresolvedTypeRef(typeRef, null, 'Foo');
  }

  test_typedef_codeRange() {
    if (!includeInformative) return;
    UnlinkedTypedef type = serializeTypedefText('typedef F();');
    _assertCodeRange(type.codeRange, 0, 12);
  }

  test_typedef_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
typedef F();''';
    UnlinkedTypedef typedef = serializeTypedefText(text);
    expect(typedef.documentationComment, isNotNull);
    checkDocumentationComment(typedef.documentationComment, text);
  }

  test_typedef_genericFunction_reference() {
    EntityRef typeRef = serializeTypeText('F',
        otherDeclarations: 'typedef F<S> = S Function<T>(T x);');
    checkTypeRef(typeRef, null, 'F',
        numTypeParameters: 1,
        expectedKind: ReferenceKind.genericFunctionTypedef);
  }

  test_typedef_genericFunction_typeNames() {
    UnlinkedTypedef typedef =
        serializeTypedefText('typedef F<S> = S Function(int x, String y);');
    expect(typedef.style, TypedefStyle.genericFunctionType);
    expect(typedef.typeParameters, hasLength(1));
    expect(typedef.typeParameters[0].name, 'S');
    expect(typedef.parameters, isEmpty);

    EntityRef genericFunction = typedef.returnType;
    expect(genericFunction.entityKind, EntityRefKind.genericFunctionType);
    expect(genericFunction.typeParameters, isEmpty);

    List<UnlinkedParam> functionParameters = genericFunction.syntheticParams;
    expect(functionParameters, hasLength(2));
    expect(functionParameters[0].name, 'x');
    expect(functionParameters[1].name, 'y');
    checkLinkedTypeRef(functionParameters[0].type, 'dart:core', 'int');
    checkLinkedTypeRef(functionParameters[1].type, 'dart:core', 'String');

    checkParamTypeRef(genericFunction.syntheticReturnType, 1);
  }

  test_typedef_genericFunction_typeParameters() {
    UnlinkedTypedef typedef =
        serializeTypedefText('typedef F<S> = S Function<T1, T2>(T1 x, T2 y);');
    expect(typedef.style, TypedefStyle.genericFunctionType);
    expect(typedef.typeParameters, hasLength(1));
    expect(typedef.typeParameters[0].name, 'S');
    expect(typedef.parameters, isEmpty);

    EntityRef genericFunction = typedef.returnType;
    expect(genericFunction.entityKind, EntityRefKind.genericFunctionType);

    expect(genericFunction.typeParameters, hasLength(2));
    expect(genericFunction.typeParameters[0].name, 'T1');
    expect(genericFunction.typeParameters[1].name, 'T2');

    expect(genericFunction.syntheticParams, hasLength(2));
    expect(genericFunction.syntheticParams[0].name, 'x');
    expect(genericFunction.syntheticParams[1].name, 'y');
    checkParamTypeRef(genericFunction.syntheticParams[0].type, 2);
    checkParamTypeRef(genericFunction.syntheticParams[1].type, 1);

    checkParamTypeRef(genericFunction.syntheticReturnType, 3);
  }

  test_typedef_name() {
    String text = 'typedef F();';
    UnlinkedTypedef type = serializeTypedefText(text);
    expect(type.name, 'F');
    if (includeInformative) {
      expect(type.nameOffset, text.indexOf('F'));
    }
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(
        unlinkedUnits[0].publicNamespace.names[0].kind, ReferenceKind.typedef);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'F');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
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

  test_typedef_private() {
    serializeTypedefText('typedef _F();', '_F');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_typedef_reference_generic() {
    EntityRef typeRef =
        serializeTypeText('F', otherDeclarations: 'typedef void F<A, B>();');
    checkTypeRef(typeRef, null, 'F',
        numTypeParameters: 2, expectedKind: ReferenceKind.typedef);
  }

  test_typedef_reference_generic_imported() {
    addNamedSource('/lib.dart', 'typedef void F<A, B>();');
    EntityRef typeRef =
        serializeTypeText('F', otherDeclarations: 'import "lib.dart";');
    checkTypeRef(typeRef, absUri('/lib.dart'), 'F',
        numTypeParameters: 2, expectedKind: ReferenceKind.typedef);
  }

  test_typedef_return_type_explicit() {
    UnlinkedTypedef type = serializeTypedefText('typedef int F();');
    checkTypeRef(type.returnType, 'dart:core', 'int');
  }

  test_typedef_type_param_in_parameter() {
    UnlinkedTypedef type = serializeTypedefText('typedef F<T>(T t);');
    checkParamTypeRef(type.parameters[0].type, 1);
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 1);
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

  test_unit_codeRange() {
    if (!includeInformative) return;
    serializeLibraryText('  int a = 1;  ');
    UnlinkedUnit unit = unlinkedUnits[0];
    _assertCodeRange(unit.codeRange, 0, 14);
  }

  test_unresolved_export() {
    allowMissingFiles = true;
    serializeLibraryText("export 'foo.dart';", allowErrors: true);
    expect(unlinkedUnits[0].publicNamespace.exports, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.exports[0].uri, 'foo.dart');
    expect(linked.exportDependencies, hasLength(1));
    checkDependency(linked.exportDependencies[0], absUri('/foo.dart'));
  }

  test_unresolved_import() {
    allowMissingFiles = true;
    serializeLibraryText("import 'foo.dart';", allowErrors: true);
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].uri, 'foo.dart');
    // Note: imports[1] is the implicit import of dart:core.
    expect(unlinkedUnits[0].imports[1].isImplicit, true);
    expect(linked.importDependencies, hasLength(2));
    checkDependency(linked.importDependencies[0], absUri('/foo.dart'));
  }

  test_unresolved_part() {
    allowMissingFiles = true;
    serializeLibraryText("part 'foo.dart';", allowErrors: true);
    expect(unlinkedUnits[0].publicNamespace.parts, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.parts[0], 'foo.dart');
  }

  test_unresolved_reference_in_multiple_parts() {
    addNamedSource('/a.dart', 'part of foo; int x; Unresolved y;');
    serializeLibraryText('library foo; part "a.dart"; Unresolved z;',
        allowErrors: true);
    // The unresolved types in the defining compilation unit and the part
    // should both work correctly even though they use different reference
    // indices.
    checkUnresolvedTypeRef(
        unlinkedUnits[0].variables[0].type, null, 'Unresolved');
    checkUnresolvedTypeRef(
        unlinkedUnits[1].variables[1].type, null, 'Unresolved',
        linkedSourceUnit: linked.units[1],
        unlinkedSourceUnit: unlinkedUnits[1]);
  }

  test_unresolved_reference_shared() {
    // Both `x` and `y` use unresolved identifier `C` as their type.  Verify
    // that they both use the same unresolved reference.
    serializeLibraryText('C x; C y;', allowErrors: true);
    EntityRef xType = findVariable('x').type;
    EntityRef yType = findVariable('y').type;
    expect(xType.reference, yType.reference);
  }

  test_unused_type_parameter() {
    if (!strongMode || skipFullyLinkedData) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
class C<T> {
  void f() {}
}
C<int> c;
var v = c.f;
''');
    EntityRef type =
        getTypeRefForSlot(variable.initializer.inferredReturnTypeSlot);
    expect(type.typeArguments, hasLength(1));
    checkLinkedTypeRef(type.typeArguments[0], 'dart:core', 'int');
  }

  test_variable() {
    String text = 'int i;';
    UnlinkedVariable v = serializeVariableText(text, variableName: 'i');
    if (includeInformative) {
      expect(v.nameOffset, text.indexOf('i;'));
    }
    expect(findExecutable('i'), isNull);
    expect(findExecutable('i='), isNull);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(2));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.topLevelPropertyAccessor);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'i');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
    expect(unlinkedUnits[0].publicNamespace.names[1].kind,
        ReferenceKind.topLevelPropertyAccessor);
    expect(unlinkedUnits[0].publicNamespace.names[1].name, 'i=');
    expect(unlinkedUnits[0].publicNamespace.names[1].numTypeParameters, 0);
  }

  test_variable_codeRange() {
    if (!includeInformative) return;
    serializeLibraryText(' int a = 1, b = 22;');
    List<UnlinkedVariable> variables = unlinkedUnits[0].variables;
    _assertCodeRange(variables[0].codeRange, 1, 18);
    _assertCodeRange(variables[1].codeRange, 1, 18);
  }

  test_variable_const() {
    UnlinkedVariable variable =
        serializeVariableText('const int i = 0;', variableName: 'i');
    expect(variable.isConst, isTrue);
  }

  test_variable_documented() {
    if (!includeInformative) return;
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
var v;''';
    UnlinkedVariable variable = serializeVariableText(text);
    expect(variable.documentationComment, isNotNull);
    checkDocumentationComment(variable.documentationComment, text);
  }

  test_variable_explicit_dynamic() {
    UnlinkedVariable variable = serializeVariableText('dynamic v;');
    checkDynamicTypeRef(variable.type);
  }

  test_variable_final_top_level() {
    UnlinkedVariable variable =
        serializeVariableText('final int i = 0;', variableName: 'i');
    expect(variable.isFinal, isTrue);
    expect(variable.initializer.bodyExpr, isNull);
  }

  test_variable_final_top_level_untyped() {
    UnlinkedVariable variable = serializeVariableText('final v = 0;');
    expect(variable.initializer.bodyExpr, isNotNull);
  }

  test_variable_implicit_dynamic() {
    UnlinkedVariable variable = serializeVariableText('var v;');
    expect(variable.type, isNull);
  }

  test_variable_inferred_type_explicit_initialized() {
    UnlinkedVariable v = serializeVariableText('int v = 0;');
    expect(v.inferredTypeSlot, 0);
  }

  test_variable_inferred_type_implicit_initialized() {
    UnlinkedVariable v = serializeVariableText('var v = 0;');
    checkInferredTypeSlot(v.inferredTypeSlot, 'dart:core', 'int');
  }

  test_variable_inferred_type_implicit_uninitialized() {
    UnlinkedVariable v = serializeVariableText('var v;');
    expect(v.inferredTypeSlot, 0);
  }

  test_variable_initializer_literal() {
    UnlinkedVariable variable = serializeVariableText('var v = 42;');
    UnlinkedExecutable initializer = variable.initializer;
    expect(initializer, isNotNull);
    if (includeInformative) {
      expect(initializer.nameOffset, 8);
    }
    expect(initializer.name, isEmpty);
    expect(initializer.localFunctions, isEmpty);
  }

  test_variable_initializer_noInitializer() {
    UnlinkedVariable variable = serializeVariableText('var v;');
    expect(variable.initializer, isNull);
  }

  test_variable_initializer_withLocals() {
    String text = 'var v = <dynamic, dynamic>{"1": () { f1() {} var v1; }, '
        '"2": () { f2() {} var v2; }};';
    UnlinkedVariable variable = serializeVariableText(text);
    UnlinkedExecutable initializer = variable.initializer;
    expect(initializer, isNotNull);
    if (includeInformative) {
      expect(initializer.nameOffset, text.indexOf('<dynamic, dynamic>{"1'));
    }
    expect(initializer.name, isEmpty);
    expect(initializer.localFunctions, hasLength(2));
    // closure: () { f1() {} var v1; }
    {
      UnlinkedExecutable closure = initializer.localFunctions[0];
      if (includeInformative) {
        expect(closure.nameOffset, text.indexOf('() { f1()'));
      }
      expect(closure.name, isEmpty);
      // closure - f1
      expect(closure.localFunctions, hasLength(1));
      expect(closure.localFunctions[0].name, 'f1');
      if (includeInformative) {
        expect(closure.localFunctions[0].nameOffset, text.indexOf('f1()'));
      }
    }
    // closure: () { f2() {} var v2; }
    {
      UnlinkedExecutable closure = initializer.localFunctions[1];
      if (includeInformative) {
        expect(closure.nameOffset, text.indexOf('() { f2()'));
      }
      expect(closure.name, isEmpty);
      // closure - f1
      expect(closure.localFunctions, hasLength(1));
      expect(closure.localFunctions[0].name, 'f2');
      if (includeInformative) {
        expect(closure.localFunctions[0].nameOffset, text.indexOf('f2()'));
      }
    }
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

  test_variable_private() {
    serializeVariableText('int _i;', variableName: '_i');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_variable_static() {
    UnlinkedVariable variable =
        serializeClassText('class C { static int i; }').fields[0];
    expect(variable.isStatic, isTrue);
  }

  test_variable_type() {
    UnlinkedVariable variable =
        serializeVariableText('int i;', variableName: 'i');
    checkTypeRef(variable.type, 'dart:core', 'int');
  }

  /**
   * Verify invariants of the given [linkedLibrary].
   */
  void validateLinkedLibrary(LinkedLibrary linkedLibrary) {
    for (LinkedUnit unit in linkedLibrary.units) {
      for (LinkedReference reference in unit.references) {
        switch (reference.kind) {
          case ReferenceKind.classOrEnum:
          case ReferenceKind.topLevelPropertyAccessor:
          case ReferenceKind.topLevelFunction:
          case ReferenceKind.typedef:
            // This reference can have either a zero or a nonzero dependency,
            // since it refers to top level element which might or might not be
            // imported from another library.
            break;
          case ReferenceKind.prefix:
            // Prefixes should have a dependency of 0, since they come from the
            // current library.
            expect(reference.dependency, 0,
                reason: 'Nonzero dependency for prefix');
            break;
          case ReferenceKind.unresolved:
            // Unresolved references always have a dependency of 0.
            expect(reference.dependency, 0,
                reason: 'Nonzero dependency for undefined');
            break;
          default:
            // This reference should have a dependency of 0, since it refers to
            // an element that is contained within some other element.
            expect(reference.dependency, 0,
                reason: 'Nonzero dependency for ${reference.kind}');
        }
      }
    }
  }

  /**
   * Assert that serializing the given [expr] of form `(a op= 1 + 2) + 3`
   * uses the given [expectedAssignOperator].
   */
  void _assertAssignmentOperator(
      String expr, UnlinkedExprAssignOperator expectedAssignOperator) {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
int a = 0;
final v = $expr;
    ''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.add,
          UnlinkedExprOperation.assignToRef,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.add,
        ],
        assignmentOperators: [
          expectedAssignOperator
        ],
        ints: [
          1,
          2,
          3
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'a',
              expectedKind: ReferenceKind.topLevelPropertyAccessor)
        ]);
  }

  void _assertCodeRange(CodeRange codeRange, int offset, int length) {
    expect(codeRange, isNotNull);
    expect(codeRange.offset, offset);
    expect(codeRange.length, length);
  }

  void _assertParameterVisible(
      String code, UnlinkedParam p, String visibleBegin, String visibleEnd) {
    int expectedVisibleOffset = code.indexOf(visibleBegin);
    int expectedVisibleLength =
        code.indexOf(visibleEnd) - expectedVisibleOffset + 1;
    expect(p.visibleOffset, expectedVisibleOffset);
    expect(p.visibleLength, expectedVisibleLength);
  }

  void _assertParameterZeroVisibleRange(UnlinkedParam p) {
    expect(p.visibleOffset, isZero);
    expect(p.visibleLength, isZero);
  }

  /**
   * Assert that the [expr] of the form `++a + 2` is serialized with the
   * [expectedAssignmentOperator].
   */
  void _assertRefPrefixPostfixIncrementDecrement(
      String expr, UnlinkedExprAssignOperator expectedAssignmentOperator) {
    if (skipNonConstInitializers) {
      return;
    }
    UnlinkedVariable variable = serializeVariableText('''
int a = 0;
final v = $expr;
''');
    assertUnlinkedConst(variable.initializer.bodyExpr,
        isValidConst: false,
        operators: [
          UnlinkedExprOperation.assignToRef,
          UnlinkedExprOperation.pushInt,
          UnlinkedExprOperation.add,
        ],
        assignmentOperators: [
          expectedAssignmentOperator
        ],
        ints: [
          2
        ],
        strings: [],
        referenceValidators: [
          (EntityRef r) => checkTypeRef(r, null, 'a',
              expectedKind: ReferenceKind.topLevelPropertyAccessor)
        ]);
  }
}

/**
 * Description of expectations for a prelinked prefix reference.
 */
class _PrefixExpectation {
  final ReferenceKind kind;
  final String name;
  final String absoluteUri;
  final int numTypeParameters;

  _PrefixExpectation(this.kind, this.name,
      {this.absoluteUri, this.numTypeParameters: 0});
}
