// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summary_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/public_namespace_computer.dart'
    as public_namespace;
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart'
    as summarize_elements;
import 'package:unittest/unittest.dart';

import '../../generated/resolver_test.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(SummarizeElementsTest);
  runReflectiveTests(PrelinkerTest);
  runReflectiveTests(UnlinkedSummarizeAstTest);
}

/**
 * The public namespaces of the sdk are computed once so that we don't bog
 * down the test.  Structured as a map from absolute URI to the corresponding
 * public namespace.
 *
 * Note: should an exception occur during computation of this variable, it
 * will silently be set to null to allow other tests to run.
 */
final Map<String, UnlinkedPublicNamespace> sdkPublicNamespace = () {
  try {
    AnalysisContext analysisContext = AnalysisContextFactory.contextWithCore();
    Map<String, UnlinkedPublicNamespace> uriToNamespace =
        <String, UnlinkedPublicNamespace>{};
    List<LibraryElement> libraries = [
      analysisContext.typeProvider.objectType.element.library,
      analysisContext.typeProvider.futureType.element.library
    ];
    for (LibraryElement library in libraries) {
      summarize_elements.LibrarySerializationResult serializedLibrary =
          summarize_elements.serializeLibrary(
              library, analysisContext.typeProvider);
      for (int i = 0; i < serializedLibrary.unlinkedUnits.length; i++) {
        uriToNamespace[serializedLibrary.unitUris[i]] =
            new UnlinkedUnit.fromBuffer(
                serializedLibrary.unlinkedUnits[i].toBuffer()).publicNamespace;
      }
    }
    return uriToNamespace;
  } catch (_) {
    return null;
  }
}();

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
      if (obj is UnlinkedPublicNamespace && key == 'names') {
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
  parser.parseGenericMethods = true;
  CompilationUnit unit = parser.parseCompilationUnit(scanner.tokenize());
  UnlinkedPublicNamespace namespace = new UnlinkedPublicNamespace.fromBuffer(
      public_namespace.computePublicNamespace(unit).toBuffer());
  return namespace;
}

/**
 * Override of [SummaryTest] which verifies the correctness of the prelinker by
 * creating summaries from the element model, discarding their prelinked
 * information, and then recreating it using the prelinker.
 */
@reflectiveTest
class PrelinkerTest extends SummarizeElementsTest {
  final Map<String, UnlinkedPublicNamespace> uriToPublicNamespace =
      <String, UnlinkedPublicNamespace>{};

  @override
  bool get expectAbsoluteUrisInDependencies => false;

  @override
  Source addNamedSource(String filePath, String contents) {
    Source source = super.addNamedSource(filePath, contents);
    uriToPublicNamespace[absUri(filePath)] =
        computePublicNamespaceFromText(contents, source);
    return source;
  }

  String resolveToAbsoluteUri(LibraryElement library, String relativeUri) {
    Source resolvedSource =
        analysisContext.sourceFactory.resolveUri(library.source, relativeUri);
    if (resolvedSource == null) {
      fail('Failed to resolve relative uri "$relativeUri"');
    }
    return resolvedSource.uri.toString();
  }

  @override
  void serializeLibraryElement(LibraryElement library) {
    super.serializeLibraryElement(library);
    Map<String, UnlinkedUnit> uriToUnit = <String, UnlinkedUnit>{};
    expect(unlinkedUnits.length, unitUris.length);
    for (int i = 1; i < unlinkedUnits.length; i++) {
      uriToUnit[unitUris[i]] = unlinkedUnits[i];
    }
    UnlinkedUnit getPart(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(library, relativeUri);
      UnlinkedUnit unit = uriToUnit[absoluteUri];
      if (unit == null) {
        fail('Prelinker unexpectedly requested unit for "$relativeUri"'
            ' (resolves to "$absoluteUri").');
      }
      return unit;
    }
    UnlinkedPublicNamespace getImport(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(library, relativeUri);
      UnlinkedPublicNamespace namespace = sdkPublicNamespace[absoluteUri];
      if (namespace == null) {
        namespace = uriToPublicNamespace[absoluteUri];
      }
      if (namespace == null && !allowMissingFiles) {
        fail('Prelinker unexpectedly requested namespace for "$relativeUri"'
            ' (resolves to "$absoluteUri").'
            '  Namespaces available: ${uriToPublicNamespace.keys}');
      }
      return namespace;
    }
    linked = new LinkedLibrary.fromBuffer(
        prelink(unlinkedUnits[0], getPart, getImport).toBuffer());
  }
}

/**
 * Override of [SummaryTest] which creates summaries from the element model.
 */
@reflectiveTest
class SummarizeElementsTest extends ResolverTestCase with SummaryTest {
  /**
   * The list of absolute unit URIs corresponding to the compilation units in
   * [unlinkedUnits].
   */
  List<String> unitUris;

  /**
   * Map containing all source files in this test, and their corresponding file
   * contents.
   */
  final Map<Source, String> _fileContents = <Source, String>{};

  @override
  LinkedLibrary linked;

  @override
  List<UnlinkedUnit> unlinkedUnits;

  @override
  bool get checkAstDerivedData => false;

  @override
  bool get expectAbsoluteUrisInDependencies => true;

  @override
  Source addNamedSource(String filePath, String contents) {
    Source source = super.addNamedSource(filePath, contents);
    _fileContents[source] = contents;
    return source;
  }

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
   * resulting summary in [linked] and [unlinkedUnits].
   */
  void serializeLibraryElement(LibraryElement library) {
    summarize_elements.LibrarySerializationResult serializedLib =
        summarize_elements.serializeLibrary(library, typeProvider);
    {
      List<int> buffer = serializedLib.linked.toBuffer();
      linked = new LinkedLibrary.fromBuffer(buffer);
    }
    unlinkedUnits = serializedLib.unlinkedUnits.map((UnlinkedUnitBuilder b) {
      List<int> buffer = b.toBuffer();
      return new UnlinkedUnit.fromBuffer(buffer);
    }).toList();
    unitUris = serializedLib.unitUris;
  }

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Source source = addSource(text);
    _fileContents[source] = text;
    LibraryElement library = resolve2(source);
    if (!allowErrors) {
      assertNoErrors(source);
    }
    serializeLibraryElement(library);
    expect(unlinkedUnits[0].imports.length, linked.importDependencies.length);
    expect(linked.units.length, unlinkedUnits.length);
    for (int i = 0; i < linked.units.length; i++) {
      expect(unlinkedUnits[i].references.length,
          linked.units[i].references.length);
    }
    verifyPublicNamespace();
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
    expect(cls.hasNoSupertype, isTrue);
  }

  /**
   * Verify that [public_namespace.computePublicNamespace] produces data that's
   * equivalent to that produced by [summarize_elements.serializeLibrary].
   */
  void verifyPublicNamespace() {
    for (int i = 0; i < unlinkedUnits.length; i++) {
      Source source = analysisContext.sourceFactory.forUri(unitUris[i]);
      String text = _fileContents[source];
      if (text == null) {
        if (!allowMissingFiles) {
          fail('Could not find file while verifying public namespace: '
              '${unitUris[i]}');
        }
      } else {
        UnlinkedPublicNamespace namespace =
            computePublicNamespaceFromText(text, source);
        expect(canonicalize(namespace),
            canonicalize(unlinkedUnits[i].publicNamespace),
            reason: 'publicNamespace(${unitUris[i]})');
      }
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
   * `true` if the summary was created directly from the AST (and hence
   * contains information that is not obtainable from the element model alone).
   * TODO(paulberry): modify the element model so that it contains all the data
   * that summaries need, so that this flag is no longer needed.
   */
  bool get checkAstDerivedData;

  /**
   * Get access to the linked defining compilation unit.
   */
  LinkedUnit get definingUnit => linked.units[0];

  /**
   * `true` if the linked portion of the summary is expected to contain
   * absolute URIs.  This happens because the element model doesn't (yet) store
   * enough information to recover relative URIs, TODO(paulberry): fix this.
   */
  bool get expectAbsoluteUrisInDependencies;

  /**
   * Get access to the linked summary that results from serializing and
   * then deserializing the library under test.
   */
  LinkedLibrary get linked;

  /**
   * Get access to the unlinked compilation unit summaries that result from
   * serializing and deserializing the library under test.
   */
  List<UnlinkedUnit> get unlinkedUnits;

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
  Source addNamedSource(String filePath, String contents);

  /**
   * Verify that the [dependency]th element of the dependency table represents
   * a file reachable via the given [absoluteUri] and [relativeUri].
   */
  void checkDependency(int dependency, String absoluteUri, String relativeUri) {
    if (expectAbsoluteUrisInDependencies) {
      // The element model doesn't (yet) store enough information to recover
      // relative URIs, so we have to use the absolute URI.
      // TODO(paulberry): fix this.
      relativeUri = absoluteUri;
    }
    expect(dependency, new isInstanceOf<int>());
    expect(linked.dependencies[dependency].uri, relativeUri);
  }

  /**
   * Verify that the given [dependency] lists the given [absoluteUris] or
   * [relativeUris] as its parts.
   */
  void checkDependencyParts(LinkedDependency dependency,
      List<String> absoluteUris, List<String> relativeUris) {
    if (expectAbsoluteUrisInDependencies) {
      // The element model doesn't (yet) store enough information to recover
      // relative URIs, so we have to use the absolute URI.
      // TODO(paulberry): fix this.
      relativeUris = absoluteUris;
    }
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
    expect(documentationComment.offset, commentStart);
    expect(documentationComment.length, commentEnd - commentStart);
  }

  /**
   * Verify that the given [typeRef] represents the type `dynamic`.
   */
  void checkDynamicTypeRef(UnlinkedTypeRef typeRef) {
    checkTypeRef(typeRef, null, null, null);
  }

  /**
   * Verify that the given [exportName] represents a reference to an entity
   * declared in a file reachable via [absoluteUri] and [relativeUri], having
   * name [expectedName].  [expectedKind] is the kind of object referenced.
   * [expectedTargetUnit] is the index of the compilation unit in which the
   * target of the [exportName] is expected to appear; if not specified it is
   * assumed to be the defining compilation unit.
   */
  void checkExportName(LinkedExportName exportName, String absoluteUri,
      String relativeUri, String expectedName, ReferenceKind expectedKind,
      {int expectedTargetUnit: 0}) {
    expect(exportName, new isInstanceOf<LinkedExportName>());
    // Exported names must come from other libraries.
    expect(exportName.dependency, isNot(0));
    checkDependency(exportName.dependency, absoluteUri, relativeUri);
    expect(exportName.name, expectedName);
    expect(exportName.kind, expectedKind);
    expect(exportName.unit, expectedTargetUnit);
  }

  /**
   * Verify that the dependency table contains an entry for a file reachable
   * via the given [absoluteUri] and [relativeUri].
   *
   * The [LinkedDependency] is returned.
   */
  LinkedDependency checkHasDependency(String absoluteUri, String relativeUri) {
    if (expectAbsoluteUrisInDependencies) {
      // The element model doesn't (yet) store enough information to recover
      // relative URIs, so we have to use the absolute URI.
      // TODO(paulberry): fix this.
      relativeUri = absoluteUri;
    }
    List<String> found = <String>[];
    for (LinkedDependency dep in linked.dependencies) {
      if (dep.uri == relativeUri) {
        return dep;
      }
      found.add(dep.uri);
    }
    fail('Did not find dependency $relativeUri.  Found: $found');
    return null;
  }

  /**
   * Verify that the dependency table *does not* contain any entries for a file
   * reachable via the given [absoluteUri] and [relativeUri].
   */
  void checkLacksDependency(String absoluteUri, String relativeUri) {
    if (expectAbsoluteUrisInDependencies) {
      // The element model doesn't (yet) store enough information to recover
      // relative URIs, so we have to use the absolute URI.
      // TODO(paulberry): fix this.
      relativeUri = absoluteUri;
    }
    for (LinkedDependency dep in linked.dependencies) {
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
   * Verify that the given [typeRef] represents a reference to a type declared
   * in a file reachable via [absoluteUri] and [relativeUri], having name
   * [expectedName].  If [expectedPrefix] is supplied, verify that the type is
   * reached via the given prefix.  If [allowTypeParameters] is true, allow the
   * type reference to supply type parameters.  [expectedKind] is the kind of
   * object referenced.  [linkedSourceUnit] and [unlinkedSourceUnit] refer
   * to the compilation unit within which the [typeRef] appears; if not
   * specified they are assumed to refer to the defining compilation unit.
   * [expectedTargetUnit] is the index of the compilation unit in which the
   * target of the [typeRef] is expected to appear; if not specified it is
   * assumed to be the defining compilation unit.  [numTypeParameters] is the
   * number of type parameters of the thing being referred to.
   */
  void checkTypeRef(UnlinkedTypeRef typeRef, String absoluteUri,
      String relativeUri, String expectedName,
      {String expectedPrefix,
      bool allowTypeParameters: false,
      ReferenceKind expectedKind: ReferenceKind.classOrEnum,
      int expectedTargetUnit: 0,
      LinkedUnit linkedSourceUnit,
      UnlinkedUnit unlinkedSourceUnit,
      int numTypeParameters: 0}) {
    linkedSourceUnit ??= definingUnit;
    unlinkedSourceUnit ??= unlinkedUnits[0];
    expect(typeRef, new isInstanceOf<UnlinkedTypeRef>());
    expect(typeRef.paramReference, 0);
    int index = typeRef.reference;
    UnlinkedReference reference = unlinkedSourceUnit.references[index];
    LinkedReference referenceResolution = linkedSourceUnit.references[index];
    if (index == 0) {
      // Index 0 is reserved for "dynamic".
      expect(reference.name, isEmpty);
      expect(reference.prefixReference, 0);
    }
    if (absoluteUri == null) {
      expect(referenceResolution.dependency, 0);
    } else {
      checkDependency(referenceResolution.dependency, absoluteUri, relativeUri);
    }
    if (!allowTypeParameters) {
      expect(typeRef.typeArguments, isEmpty);
    }
    if (expectedKind == ReferenceKind.unresolved && !checkAstDerivedData) {
      // summarize_elements.dart isn't yet able to record the name or prefix of
      // unresolved references.  TODO(paulberry): fix this.
      expect(reference.name, '*unresolved*');
      expect(reference.prefixReference, 0);
    } else {
      if (expectedName == null) {
        expect(reference.name, isEmpty);
      } else {
        expect(reference.name, expectedName);
      }
      if (expectedPrefix == null) {
        expect(reference.prefixReference, 0);
      } else {
        checkPrefix(reference.prefixReference, expectedPrefix);
      }
    }
    expect(referenceResolution.kind, expectedKind);
    expect(referenceResolution.unit, expectedTargetUnit);
    expect(referenceResolution.numTypeParameters, numTypeParameters);
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
        expectedPrefix: expectedPrefix, expectedKind: ReferenceKind.unresolved);
  }

  fail_enum_value_documented() {
    // TODO(paulberry): currently broken because of dartbug.com/25385
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
        serializeClassText('class C = _D with _E; class _D {} class _E {}');
    expect(cls.isAbstract, false);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.classOrEnum);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'C');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
  }

  test_class_alias_documented() {
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

  test_class_alias_private() {
    serializeClassText('class _C = _D with _E; class _D {} class _E {}',
        className: '_C');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_class_alias_reference_generic() {
    UnlinkedTypeRef typeRef = serializeTypeText('C',
        otherDeclarations: 'class C<D, E> = F with G; class F {} class G {}');
    checkTypeRef(typeRef, null, null, 'C', numTypeParameters: 2);
  }

  test_class_alias_reference_generic_imported() {
    addNamedSource(
        '/lib.dart', 'class C<D, E> = F with G; class F {} class G {}');
    UnlinkedTypeRef typeRef =
        serializeTypeText('C', otherDeclarations: 'import "lib.dart";');
    checkTypeRef(typeRef, absUri('/lib.dart'), 'lib.dart', 'C',
        numTypeParameters: 2);
  }

  test_class_alias_supertype() {
    UnlinkedClass cls =
        serializeClassText('class C = D with E; class D {} class E {}');
    checkTypeRef(cls.supertype, null, null, 'D');
    expect(cls.hasNoSupertype, isFalse);
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

  test_class_documented() {
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

  test_class_documented_with_references() {
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
    expect(cls.nameOffset, classText.indexOf('C'));
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
    UnlinkedTypeRef typeRef =
        serializeTypeText('C', otherDeclarations: 'class C<D, E> {}');
    checkTypeRef(typeRef, null, null, 'C', numTypeParameters: 2);
  }

  test_class_reference_generic_imported() {
    addNamedSource('/lib.dart', 'class C<D, E> {}');
    UnlinkedTypeRef typeRef =
        serializeTypeText('C', otherDeclarations: 'import "lib.dart";');
    checkTypeRef(typeRef, absUri('/lib.dart'), 'lib.dart', 'C',
        numTypeParameters: 2);
  }

  test_class_superclass() {
    UnlinkedClass cls = serializeClassText('class C {}');
    expect(cls.supertype, isNull);
    expect(cls.hasNoSupertype, isFalse);
  }

  test_class_superclass_explicit() {
    UnlinkedClass cls = serializeClassText('class C extends D {} class D {}');
    expect(cls.supertype, isNotNull);
    checkTypeRef(cls.supertype, null, null, 'D');
    expect(cls.hasNoSupertype, isFalse);
  }

  test_class_type_param_bound() {
    UnlinkedClass cls = serializeClassText('class C<T extends List> {}');
    expect(cls.typeParameters, hasLength(1));
    expect(cls.typeParameters[0].name, 'T');
    expect(cls.typeParameters[0].bound, isNotNull);
    checkTypeRef(cls.typeParameters[0].bound, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true, numTypeParameters: 1);
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
    String text = 'class C<T> {}';
    UnlinkedClass cls = serializeClassText(text);
    expect(cls.typeParameters, hasLength(1));
    expect(cls.typeParameters[0].name, 'T');
    expect(cls.typeParameters[0].nameOffset, text.indexOf('T'));
    expect(cls.typeParameters[0].bound, isNull);
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 1);
  }

  test_constructor() {
    String text = 'class C { C(); }';
    UnlinkedExecutable executable =
        findExecutable('', executables: serializeClassText(text).executables);
    expect(executable.kind, UnlinkedExecutableKind.constructor);
    expect(executable.hasImplicitReturnType, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.nameOffset, text.indexOf('C();'));
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

  test_constructor_initializing_formal_implicit_type() {
    // Note: the implicit type of an initializing formal is the type of the
    // field.
    UnlinkedExecutable executable = findExecutable('',
        executables:
            serializeClassText('class C { C(this.x); int x; }').executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.type, isNull);
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

  test_constructor_initializing_formal_typedef() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText(
                'typedef F<T>(T x); class C<X> { C(this.f); F<X> f; }')
            .executables);
    UnlinkedParam parameter = executable.parameters[0];
    expect(parameter.isFunctionTyped, isFalse);
    expect(parameter.parameters, isEmpty);
  }

  test_constructor_named() {
    String text = 'class C { C.foo(); }';
    UnlinkedExecutable executable = findExecutable('foo',
        executables: serializeClassText(text).executables);
    expect(executable.name, 'foo');
    expect(executable.nameOffset, text.indexOf('foo'));
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
    expect(executable.returnType, isNull);
  }

  test_constructor_return_type_parameterized() {
    UnlinkedExecutable executable = findExecutable('',
        executables: serializeClassText('class C<T, U> { C(); }').executables);
    expect(executable.returnType, isNull);
  }

  test_dependencies_export_to_export_unused() {
    // TODO(paulberry): fix this test.
    addNamedSource('/a.dart', 'export "b.dart";');
    addNamedSource('/b.dart', '');
    serializeLibraryText('export "a.dart";');
    // The main test library depends on b.dart, even though it doesn't
    // re-export any names defined in b.dart, because a change to b.dart might
    // cause it to start exporting a name that the main test library *does*
    // use.
    checkHasDependency(absUri('/b.dart'), 'b.dart');
  }

  test_dependencies_export_unused() {
    // TODO(paulberry): fix this test.
    addNamedSource('/a.dart', '');
    serializeLibraryText('export "a.dart";');
    // The main test library depends on a.dart, even though it doesn't
    // re-export any names defined in a.dart, because a change to a.dart might
    // cause it to start exporting a name that the main test library *will*
    // re-export.
    checkHasDependency(absUri('/a.dart'), 'a.dart');
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
    checkHasDependency(absUri('/a/b/b.dart'), absUri('/a/b/b.dart'));
  }

  test_dependencies_import_to_export_in_subdirs_absolute_import() {
    addNamedSource('/a/a.dart', 'library a; export "b/b.dart"; class A {}');
    addNamedSource('/a/b/b.dart', 'library b;');
    serializeLibraryText('import "${absUri('/a/a.dart')}"; A a;');
    checkHasDependency(absUri('/a/a.dart'), absUri('/a/a.dart'));
    // The main test library depends on b.dart, because names defined in
    // b.dart are exported by a.dart.
    checkHasDependency(absUri('/a/b/b.dart'), absUri('/a/b/b.dart'));
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

  test_dependencies_import_to_export_unused() {
    addNamedSource('/a.dart', 'export "b.dart";');
    addNamedSource('/b.dart', '');
    serializeLibraryText('import "a.dart";', allowErrors: true);
    // The main test library depends on b.dart, even though it doesn't use any
    // names defined in b.dart, because a change to b.dart might cause it to
    // start exporting a name that the main test library *does* use.
    checkHasDependency(absUri('/b.dart'), 'b.dart');
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

  test_dependencies_import_unused() {
    addNamedSource('/a.dart', '');
    serializeLibraryText('import "a.dart";', allowErrors: true);
    // The main test library depends on a.dart, even though it doesn't use any
    // names defined in a.dart, because a change to a.dart might cause it to
    // start exporting a name that the main test library *does* use.
    checkHasDependency(absUri('/a.dart'), 'a.dart');
  }

  test_dependencies_parts() {
    addNamedSource(
        '/a.dart', 'library a; part "b.dart"; part "c.dart"; class A {}');
    addNamedSource('/b.dart', 'part of a;');
    addNamedSource('/c.dart', 'part of a;');
    serializeLibraryText('import "a.dart"; A a;');
    LinkedDependency dep = checkHasDependency(absUri('/a.dart'), 'a.dart');
    checkDependencyParts(
        dep, [absUri('/b.dart'), absUri('/c.dart')], ['b.dart', 'c.dart']);
  }

  test_dependencies_parts_relative_to_importing_library() {
    addNamedSource('/a/b.dart', 'export "c/d.dart";');
    addNamedSource('/a/c/d.dart',
        'library d; part "e/f.dart"; part "g/h.dart"; class D {}');
    addNamedSource('/a/c/e/f.dart', 'part of d;');
    addNamedSource('/a/c/g/h.dart', 'part of d;');
    serializeLibraryText('import "a/b.dart"; D d;');
    LinkedDependency dep =
        checkHasDependency(absUri('/a/c/d.dart'), 'a/c/d.dart');
    checkDependencyParts(
        dep,
        [absUri('/a/c/e/f.dart'), absUri('/a/c/g/h.dart')],
        ['a/c/e/f.dart', 'a/c/g/h.dart']);
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
    expect(e.nameOffset, text.indexOf('E'));
    expect(e.values, hasLength(1));
    expect(e.values[0].name, 'v1');
    expect(e.values[0].nameOffset, text.indexOf('v1'));
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.classOrEnum);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'E');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
  }

  test_enum_documented() {
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
    expect(executable.hasImplicitReturnType, isTrue);
    checkDynamicTypeRef(executable.returnType);
    expect(executable.isExternal, isFalse);
    expect(executable.nameOffset, text.indexOf('f'));
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.topLevelFunction);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'f');
    expect(unlinkedUnits[0].publicNamespace.names[0].numTypeParameters, 0);
  }

  test_executable_function_explicit_return() {
    UnlinkedExecutable executable =
        serializeExecutableText('dynamic f() => null;');
    expect(executable.hasImplicitReturnType, isFalse);
    checkDynamicTypeRef(executable.returnType);
  }

  test_executable_function_external() {
    UnlinkedExecutable executable = serializeExecutableText('external f();');
    expect(executable.isExternal, isTrue);
  }

  test_executable_function_private() {
    serializeExecutableText('_f() {}', '_f');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }

  test_executable_getter() {
    String text = 'int get f => 1;';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.kind, UnlinkedExecutableKind.getter);
    expect(executable.hasImplicitReturnType, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.nameOffset, text.indexOf('f'));
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
    serializeExecutableText('int get _f => 1;', '_f');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
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
    expect(executable.isExternal, isFalse);
  }

  test_executable_member_function_explicit_return() {
    UnlinkedExecutable executable = findExecutable('f',
        executables:
            serializeClassText('class C { dynamic f() => null; }').executables);
    expect(executable.hasImplicitReturnType, isFalse);
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
    expect(executable.hasImplicitReturnType, isFalse);
    expect(executable.isExternal, isFalse);
    expect(findVariable('f', variables: cls.fields), isNull);
    expect(findExecutable('f=', executables: cls.executables), isNull);
  }

  test_executable_member_getter_external() {
    UnlinkedClass cls = serializeClassText('class C { external int get f; }');
    UnlinkedExecutable executable =
        findExecutable('f', executables: cls.executables, failIfAbsent: true);
    expect(executable.isExternal, isTrue);
  }

  test_executable_member_setter() {
    UnlinkedClass cls = serializeClassText('class C { void set f(value) {} }');
    UnlinkedExecutable executable =
        findExecutable('f=', executables: cls.executables, failIfAbsent: true);
    expect(executable.kind, UnlinkedExecutableKind.setter);
    expect(executable.hasImplicitReturnType, isFalse);
    expect(executable.isExternal, isFalse);
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
    expect(executable.hasImplicitReturnType, isTrue);
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

  test_executable_operator() {
    UnlinkedExecutable executable =
        serializeClassText('class C { C operator+(C c) => null; }').executables[
            0];
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.name, '+');
    expect(executable.hasImplicitReturnType, false);
    expect(executable.isAbstract, false);
    expect(executable.isConst, false);
    expect(executable.isFactory, false);
    expect(executable.isStatic, false);
    expect(executable.parameters, hasLength(1));
    checkTypeRef(executable.returnType, null, null, 'C');
    expect(executable.typeParameters, isEmpty);
    expect(executable.isExternal, false);
  }

  test_executable_operator_equal() {
    UnlinkedExecutable executable =
        serializeClassText('class C { bool operator==(C other) => false; }')
            .executables[0];
    expect(executable.name, '==');
  }

  test_executable_operator_external() {
    UnlinkedExecutable executable =
        serializeClassText('class C { external C operator+(C c); }')
            .executables[0];
    expect(executable.isExternal, true);
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
    expect(executable.hasImplicitReturnType, false);
    expect(executable.isAbstract, false);
    expect(executable.isConst, false);
    expect(executable.isFactory, false);
    expect(executable.isStatic, false);
    expect(executable.parameters, hasLength(1));
    checkTypeRef(executable.returnType, 'dart:core', 'dart:core', 'bool');
    expect(executable.typeParameters, isEmpty);
  }

  test_executable_operator_index_set() {
    UnlinkedExecutable executable = serializeClassText(
        'class C { void operator[]=(int i, bool v) => null; }').executables[0];
    expect(executable.kind, UnlinkedExecutableKind.functionOrMethod);
    expect(executable.name, '[]=');
    expect(executable.hasImplicitReturnType, false);
    expect(executable.isAbstract, false);
    expect(executable.isConst, false);
    expect(executable.isFactory, false);
    expect(executable.isStatic, false);
    expect(executable.parameters, hasLength(2));
    expect(executable.returnType, isNull);
    expect(executable.typeParameters, isEmpty);
  }

  test_executable_operator_less_equal() {
    UnlinkedExecutable executable =
        serializeClassText('class C { bool operator<=(C other) => false; }')
            .executables[0];
    expect(executable.name, '<=');
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
    String text = 'f(x) {}';
    UnlinkedExecutable executable = serializeExecutableText(text);
    expect(executable.parameters, hasLength(1));
    expect(executable.parameters[0].name, 'x');
    expect(executable.parameters[0].nameOffset, text.indexOf('x'));
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
    String text = 'void set f(value) {}';
    UnlinkedExecutable executable = serializeExecutableText(text, 'f=');
    expect(executable.kind, UnlinkedExecutableKind.setter);
    expect(executable.hasImplicitReturnType, isFalse);
    expect(executable.isExternal, isFalse);
    expect(executable.nameOffset, text.indexOf('f'));
    expect(findVariable('f'), isNull);
    expect(findExecutable('f'), isNull);
    expect(unlinkedUnits[0].publicNamespace.names, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.names[0].kind,
        ReferenceKind.topLevelPropertyAccessor);
    expect(unlinkedUnits[0].publicNamespace.names[0].name, 'f=');
  }

  test_executable_setter_external() {
    UnlinkedExecutable executable =
        serializeExecutableText('external void set f(value);', 'f=');
    expect(executable.isExternal, isTrue);
  }

  test_executable_setter_implicit_return() {
    UnlinkedExecutable executable =
        serializeExecutableText('set f(value) {}', 'f=');
    expect(executable.hasImplicitReturnType, isTrue);
    checkDynamicTypeRef(executable.returnType);
  }

  test_executable_setter_private() {
    serializeExecutableText('void set _f(value) {}', '_f=');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
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

  test_executable_type_param_f_bound_function() {
    UnlinkedExecutable ex =
        serializeExecutableText('void f<T, U extends List<T>>() {}');
    UnlinkedTypeRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 2);
  }

  test_executable_type_param_f_bound_method() {
    UnlinkedExecutable ex =
        serializeMethodText('void f<T, U extends List<T>>() {}');
    UnlinkedTypeRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 2);
  }

  test_executable_type_param_f_bound_self_ref_function() {
    UnlinkedExecutable ex =
        serializeExecutableText('void f<T, U extends List<U>>() {}');
    UnlinkedTypeRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
    checkParamTypeRef(typeArgument, 1);
  }

  test_executable_type_param_f_bound_self_ref_method() {
    UnlinkedExecutable ex =
        serializeMethodText('void f<T, U extends List<U>>() {}');
    UnlinkedTypeRef typeArgument = ex.typeParameters[1].bound.typeArguments[0];
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
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'C',
        ReferenceKind.classOrEnum);
  }

  test_export_class_alias() {
    addNamedSource(
        '/a.dart', 'class C extends _D with _E {} class _D {} class _E {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'C',
        ReferenceKind.classOrEnum);
  }

  test_export_enum() {
    addNamedSource('/a.dart', 'enum E { v }');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'E',
        ReferenceKind.classOrEnum);
  }

  test_export_from_part() {
    addNamedSource('/a.dart', 'library foo; part "b.dart";');
    addNamedSource('/b.dart', 'part of foo; f() {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'f',
        ReferenceKind.topLevelFunction,
        expectedTargetUnit: 1);
  }

  test_export_function() {
    addNamedSource('/a.dart', 'f() {}');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'f',
        ReferenceKind.topLevelFunction);
  }

  test_export_getter() {
    addNamedSource('/a.dart', 'get f => null');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'f',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_export_hide() {
    addNamedSource('/a.dart', 'f() {} g() {}');
    serializeLibraryText('export "a.dart" hide g;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'f',
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
    expect(linked.exportNames, isNotEmpty);
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
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'f',
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
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'f=',
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
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'v=',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_export_shadowed_variable_final() {
    // `v=` is shown in exportNames because the top level declaration
    // `final v = 0;` only shadows `v`, not `v=`.
    addNamedSource('/a.dart', 'var v;');
    serializeLibraryText('export "a.dart"; final v = 0;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'v=',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_export_show() {
    addNamedSource('/a.dart', 'f() {} g() {}');
    serializeLibraryText('export "a.dart" show f;');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'f',
        ReferenceKind.topLevelFunction);
  }

  test_export_show_order() {
    serializeLibraryText('export "dart:async" show Future, Stream;');
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
  }

  test_export_typedef() {
    addNamedSource('/a.dart', 'typedef F();');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(1));
    checkExportName(linked.exportNames[0], absUri('/a.dart'), 'a.dart', 'F',
        ReferenceKind.typedef);
  }

  test_export_uri() {
    addNamedSource('/a.dart', 'library my.lib;');
    String uriString = '"a.dart"';
    String libraryText = 'export $uriString;';
    serializeLibraryText(libraryText);
    expect(unlinkedUnits[0].publicNamespace.exports, hasLength(1));
    expect(unlinkedUnits[0].publicNamespace.exports[0].uri, 'a.dart');
  }

  test_export_variable() {
    addNamedSource('/a.dart', 'var v;');
    serializeLibraryText('export "a.dart";');
    expect(linked.exportNames, hasLength(2));
    LinkedExportName getter =
        linked.exportNames.firstWhere((e) => e.name == 'v');
    expect(getter, isNotNull);
    checkExportName(getter, absUri('/a.dart'), 'a.dart', 'v',
        ReferenceKind.topLevelPropertyAccessor);
    LinkedExportName setter =
        linked.exportNames.firstWhere((e) => e.name == 'v=');
    expect(setter, isNotNull);
    checkExportName(setter, absUri('/a.dart'), 'a.dart', 'v=',
        ReferenceKind.topLevelPropertyAccessor);
  }

  test_field() {
    UnlinkedClass cls = serializeClassText('class C { int i; }');
    UnlinkedVariable variable = findVariable('i', variables: cls.fields);
    expect(variable, isNotNull);
    expect(variable.isConst, isFalse);
    expect(variable.isStatic, isFalse);
    expect(variable.isFinal, isFalse);
    expect(findExecutable('i', executables: cls.executables), isNull);
    expect(findExecutable('i=', executables: cls.executables), isNull);
  }

  test_field_const() {
    UnlinkedVariable variable =
        serializeClassText('class C { static const int i = 0; }').fields[0];
    expect(variable.isConst, isTrue);
  }

  test_field_documented() {
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
  }

  test_field_static() {
    UnlinkedVariable variable =
        serializeClassText('class C { static int i; }').fields[0];
    expect(variable.isStatic, isTrue);
  }

  test_function_documented() {
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

  test_import_deferred() {
    serializeLibraryText(
        'import "dart:async" deferred as a; main() { print(a.Future); }');
    expect(unlinkedUnits[0].imports[0].isDeferred, isTrue);
  }

  test_import_dependency() {
    serializeLibraryText('import "dart:async"; Future x;');
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    checkDependency(linked.importDependencies[0], 'dart:async', 'dart:async');
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
  }

  test_import_implicit() {
    // The implicit import of dart:core is represented in the model.
    serializeLibraryText('');
    expect(unlinkedUnits[0].imports, hasLength(1));
    checkDependency(linked.importDependencies[0], 'dart:core', 'dart:core');
    expect(unlinkedUnits[0].imports[0].uri, isEmpty);
    expect(unlinkedUnits[0].imports[0].uriOffset, 0);
    expect(unlinkedUnits[0].imports[0].uriEnd, 0);
    expect(unlinkedUnits[0].imports[0].prefixReference, 0);
    expect(unlinkedUnits[0].imports[0].combinators, isEmpty);
    expect(unlinkedUnits[0].imports[0].isImplicit, isTrue);
  }

  test_import_missing() {
    if (!checkAstDerivedData) {
      // TODO(paulberry): At the moment unresolved imports are not included in
      // the element model, so we can't pass this test.
      return;
    }
    // Unresolved imports are included since this is necessary for proper
    // dependency tracking.
    allowMissingFiles = true;
    serializeLibraryText('import "foo.dart";', allowErrors: true);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    checkDependency(
        linked.importDependencies[0], absUri('/foo.dart'), 'foo.dart');
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
    checkTypeRef(findVariable('x').type, absUri('/foo.dart'), 'foo.dart', 'C');
  }

  test_import_of_missing_export() {
    // Other references in foo.dart should be resolved even though foo.dart's
    // re-export of bar.dart refers to a non-existent file.
    allowMissingFiles = true;
    addNamedSource('/foo.dart', 'export "bar.dart"; class C {}');
    serializeLibraryText('import "foo.dart"; C x;');
    checkTypeRef(findVariable('x').type, absUri('/foo.dart'), 'foo.dart', 'C');
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
    checkTypeRef(variable.type, 'dart:async', 'dart:async', 'Future',
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
    checkTypeRef(findVariable('aCls').type, absUri('/a.dart'), 'a.dart', 'A');
    checkTypeRef(findVariable('bCls').type, absUri('/b.dart'), 'b.dart', 'Cls',
        expectedPrefix: 'b');
    checkTypeRef(findVariable('cCls').type, absUri('/c.dart'), 'c.dart', 'Cls',
        expectedPrefix: 'c');
    checkTypeRef(findVariable('dCls').type, absUri('/d.dart'), 'd.dart', 'D');
  }

  test_import_reference() {
    UnlinkedVariable variable =
        serializeVariableText('import "dart:async"; Future v;');
    checkTypeRef(variable.type, 'dart:async', 'dart:async', 'Future',
        numTypeParameters: 1);
  }

  test_import_reference_merged_no_prefix() {
    serializeLibraryText('''
import "dart:async" show Future;
import "dart:async" show Stream;

Future f;
Stream s;
''');
    checkTypeRef(findVariable('f').type, 'dart:async', 'dart:async', 'Future',
        numTypeParameters: 1);
    checkTypeRef(findVariable('s').type, 'dart:async', 'dart:async', 'Stream',
        numTypeParameters: 1);
  }

  test_import_reference_merged_prefixed() {
    serializeLibraryText('''
import "dart:async" as a show Future;
import "dart:async" as a show Stream;

a.Future f;
a.Stream s;
''');
    checkTypeRef(findVariable('f').type, 'dart:async', 'dart:async', 'Future',
        expectedPrefix: 'a', numTypeParameters: 1);
    checkTypeRef(findVariable('s').type, 'dart:async', 'dart:async', 'Stream',
        expectedPrefix: 'a', numTypeParameters: 1);
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
    checkTypeRef(findVariable('a').type, absUri('/a.dart'), 'a.dart', 'A',
        expectedPrefix: 'p');
    checkTypeRef(findVariable('b').type, absUri('/b.dart'), 'b.dart', 'B',
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
  }

  test_import_uri() {
    String uriString = '"dart:async"';
    String libraryText = 'import $uriString; Future x;';
    serializeLibraryText(libraryText);
    // Second import is the implicit import of dart:core
    expect(unlinkedUnits[0].imports, hasLength(2));
    expect(unlinkedUnits[0].imports[0].uri, 'dart:async');
  }

  test_invalid_prefix_dynamic() {
    if (checkAstDerivedData) {
      // TODO(paulberry): get this to work properly.
      return;
    }
    checkUnresolvedTypeRef(
        serializeTypeText('dynamic.T', allowErrors: true), 'dynamic', 'T');
  }

  test_invalid_prefix_type_parameter() {
    if (checkAstDerivedData) {
      // TODO(paulberry): get this to work properly.
      return;
    }
    checkUnresolvedTypeRef(
        serializeClassText('class C<T> { T.U x; }', allowErrors: true).fields[0]
            .type,
        'T',
        'U');
  }

  test_invalid_prefix_void() {
    if (checkAstDerivedData) {
      // TODO(paulberry): get this to work properly.
      return;
    }
    checkUnresolvedTypeRef(
        serializeTypeText('void.T', allowErrors: true), 'void', 'T');
  }

  test_library_documented() {
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
    checkTypeRef(findVariable('c').type, null, null, 'C',
        expectedTargetUnit: 2);
  }

  test_local_names_take_precedence_over_imported_names() {
    addNamedSource('/a.dart', 'class C {} class D {}');
    serializeLibraryText('''
import 'a.dart';
class C {}
C c;
D d;''');
    checkTypeRef(findVariable('c').type, null, null, 'C');
    checkTypeRef(findVariable('d').type, absUri('/a.dart'), 'a.dart', 'D');
  }

  test_method_documented() {
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

  test_setter_documented() {
    String text = '''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set f(value) {}''';
    UnlinkedExecutable executable = serializeExecutableText(text, 'f=');
    expect(executable.documentationComment, isNotNull);
    checkDocumentationComment(executable.documentationComment, text);
  }

  test_type_arguments_explicit() {
    UnlinkedTypeRef typeRef = serializeTypeText('List<int>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true, numTypeParameters: 1);
    expect(typeRef.typeArguments, hasLength(1));
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'int');
  }

  test_type_arguments_explicit_dynamic() {
    UnlinkedTypeRef typeRef = serializeTypeText('List<dynamic>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true, numTypeParameters: 1);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_explicit_dynamic_dynamic() {
    UnlinkedTypeRef typeRef = serializeTypeText('Map<dynamic, dynamic>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'Map',
        allowTypeParameters: true, numTypeParameters: 2);
    // Trailing type arguments of type `dynamic` are omitted.
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_explicit_dynamic_int() {
    UnlinkedTypeRef typeRef = serializeTypeText('Map<dynamic, int>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'Map',
        allowTypeParameters: true, numTypeParameters: 2);
    // Leading type arguments of type `dynamic` are not omitted.
    expect(typeRef.typeArguments.length, 2);
    checkDynamicTypeRef(typeRef.typeArguments[0]);
    checkTypeRef(typeRef.typeArguments[1], 'dart:core', 'dart:core', 'int');
  }

  test_type_arguments_explicit_dynamic_typedef() {
    UnlinkedTypeRef typeRef =
        serializeTypeText('F<dynamic>', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, null, 'F',
        allowTypeParameters: true,
        expectedKind: ReferenceKind.typedef,
        numTypeParameters: 1);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_explicit_String_dynamic() {
    UnlinkedTypeRef typeRef = serializeTypeText('Map<String, dynamic>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'Map',
        allowTypeParameters: true, numTypeParameters: 2);
    // Trailing type arguments of type `dynamic` are omitted.
    expect(typeRef.typeArguments.length, 1);
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'String');
  }

  test_type_arguments_explicit_String_int() {
    UnlinkedTypeRef typeRef = serializeTypeText('Map<String, int>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'Map',
        allowTypeParameters: true, numTypeParameters: 2);
    expect(typeRef.typeArguments.length, 2);
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'String');
    checkTypeRef(typeRef.typeArguments[1], 'dart:core', 'dart:core', 'int');
  }

  test_type_arguments_explicit_typedef() {
    UnlinkedTypeRef typeRef =
        serializeTypeText('F<int>', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, null, 'F',
        allowTypeParameters: true,
        expectedKind: ReferenceKind.typedef,
        numTypeParameters: 1);
    expect(typeRef.typeArguments, hasLength(1));
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'int');
  }

  test_type_arguments_implicit() {
    UnlinkedTypeRef typeRef = serializeTypeText('List');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'List',
        allowTypeParameters: true, numTypeParameters: 1);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_implicit_typedef() {
    UnlinkedTypeRef typeRef =
        serializeTypeText('F', otherDeclarations: 'typedef T F<T>();');
    checkTypeRef(typeRef, null, null, 'F',
        allowTypeParameters: true,
        expectedKind: ReferenceKind.typedef,
        numTypeParameters: 1);
    expect(typeRef.typeArguments, isEmpty);
  }

  test_type_arguments_order() {
    UnlinkedTypeRef typeRef = serializeTypeText('Map<int, Object>');
    checkTypeRef(typeRef, 'dart:core', 'dart:core', 'Map',
        allowTypeParameters: true, numTypeParameters: 2);
    expect(typeRef.typeArguments, hasLength(2));
    checkTypeRef(typeRef.typeArguments[0], 'dart:core', 'dart:core', 'int');
    checkTypeRef(typeRef.typeArguments[1], 'dart:core', 'dart:core', 'Object');
  }

  test_type_dynamic() {
    checkDynamicTypeRef(serializeTypeText('dynamic'));
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
        null, null, 'C',
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
        absUri('/a.dart'), 'a.dart', 'C',
        expectedPrefix: 'a',
        linkedSourceUnit: linked.units[1],
        unlinkedSourceUnit: unlinkedUnits[1]);
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
    if (!checkAstDerivedData) {
      // TODO(paulberry): this test currently fails because there is not enough
      // information in the element model to figure out that the unresolved
      // reference `p.C` uses the prefix `p`.
      return;
    }
    allowMissingFiles = true;
    UnlinkedTypeRef typeRef = serializeTypeText('p.C',
        otherDeclarations: 'import "foo.dart" as p;', allowErrors: true);
    checkUnresolvedTypeRef(typeRef, 'p', 'C');
  }

  test_type_reference_to_part() {
    addNamedSource('/a.dart', 'part of foo; class C { C(); }');
    serializeLibraryText('library foo; part "a.dart"; C c;');
    checkTypeRef(unlinkedUnits[0].variables.single.type, null, null, 'C',
        expectedKind: ReferenceKind.classOrEnum, expectedTargetUnit: 1);
  }

  test_type_reference_to_type_visible_via_multiple_import_prefixes() {
    if (!checkAstDerivedData) {
      // TODO(paulberry): this test currently fails because the element model
      // doesn't record enough information to track which prefix is used to
      // refer to a type.
      return;
    }
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
    checkTypeRef(
        findVariable('c2').type, absUri('/lib1.dart'), 'lib1.dart', 'C');
    checkTypeRef(
        findVariable('c3').type, absUri('/lib1.dart'), 'lib1.dart', 'C',
        expectedPrefix: 'a');
    checkTypeRef(
        findVariable('c4').type, absUri('/lib1.dart'), 'lib1.dart', 'C',
        expectedPrefix: 'b');
  }

  test_type_reference_to_typedef() {
    checkTypeRef(serializeTypeText('F', otherDeclarations: 'typedef void F();'),
        null, null, 'F',
        expectedKind: ReferenceKind.typedef);
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

  test_typedef_documented() {
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

  test_typedef_name() {
    String text = 'typedef F();';
    UnlinkedTypedef type = serializeTypedefText(text);
    expect(type.name, 'F');
    expect(type.nameOffset, text.indexOf('F'));
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
    UnlinkedTypeRef typeRef =
        serializeTypeText('F', otherDeclarations: 'typedef void F<A, B>();');
    checkTypeRef(typeRef, null, null, 'F',
        numTypeParameters: 2, expectedKind: ReferenceKind.typedef);
  }

  test_typedef_reference_generic_imported() {
    addNamedSource('/lib.dart', 'typedef void F<A, B>();');
    UnlinkedTypeRef typeRef =
        serializeTypeText('F', otherDeclarations: 'import "lib.dart";');
    checkTypeRef(typeRef, absUri('/lib.dart'), 'lib.dart', 'F',
        numTypeParameters: 2, expectedKind: ReferenceKind.typedef);
  }

  test_typedef_return_type_explicit() {
    UnlinkedTypedef type = serializeTypedefText('typedef int F();');
    checkTypeRef(type.returnType, 'dart:core', 'dart:core', 'int');
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

  test_variable() {
    String text = 'int i;';
    UnlinkedVariable v = serializeVariableText(text, variableName: 'i');
    expect(v.nameOffset, text.indexOf('i;'));
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

  test_variable_const() {
    UnlinkedVariable variable =
        serializeVariableText('const int i = 0;', variableName: 'i');
    expect(variable.isConst, isTrue);
  }

  test_variable_documented() {
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

  test_varible_private() {
    serializeVariableText('int _i;', variableName: '_i');
    expect(unlinkedUnits[0].publicNamespace.names, isEmpty);
  }
}

/**
 * Override of [SummaryTest] which creates unlinked summaries directly from the
 * AST.
 */
@reflectiveTest
class UnlinkedSummarizeAstTest extends Object with SummaryTest {
  @override
  LinkedLibrary linked;

  @override
  List<UnlinkedUnit> unlinkedUnits;

  /**
   * Map from absolute URI to the [UnlinkedUnit] for each compilation unit
   * passed to [addNamedSource].
   */
  Map<String, UnlinkedUnit> uriToUnit = <String, UnlinkedUnit>{};

  @override
  bool get checkAstDerivedData => true;

  @override
  bool get expectAbsoluteUrisInDependencies => false;

  @override
  addNamedSource(String filePath, String contents) {
    CompilationUnit unit = _parseText(contents);
    UnlinkedUnit unlinkedUnit =
        new UnlinkedUnit.fromBuffer(serializeAstUnlinked(unit).toBuffer());
    uriToUnit[absUri(filePath)] = unlinkedUnit;
  }

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Uri testDartUri = Uri.parse(absUri('/test.dart'));
    String resolveToAbsoluteUri(String relativeUri) =>
        testDartUri.resolve(relativeUri).toString();
    CompilationUnit unit = _parseText(text);
    UnlinkedUnit definingUnit =
        new UnlinkedUnit.fromBuffer(serializeAstUnlinked(unit).toBuffer());
    UnlinkedUnit getPart(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(relativeUri);
      UnlinkedUnit unit = uriToUnit[absoluteUri];
      if (unit == null && !allowMissingFiles) {
        fail('Prelinker unexpectedly requested unit for "$relativeUri"'
            ' (resolves to "$absoluteUri").');
      }
      return unit;
    }
    UnlinkedPublicNamespace getImport(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(relativeUri);
      UnlinkedPublicNamespace namespace = sdkPublicNamespace[absoluteUri];
      if (namespace == null) {
        namespace = uriToUnit[absoluteUri]?.publicNamespace;
      }
      if (namespace == null && !allowMissingFiles) {
        fail('Prelinker unexpectedly requested namespace for "$relativeUri"'
            ' (resolves to "$absoluteUri").'
            '  Namespaces available: ${uriToUnit.keys}');
      }
      return namespace;
    }
    linked = new LinkedLibrary.fromBuffer(
        prelink(definingUnit, getPart, getImport).toBuffer());
    unlinkedUnits = <UnlinkedUnit>[definingUnit];
    for (String relativeUri in definingUnit.publicNamespace.parts) {
      UnlinkedUnit unit = uriToUnit[resolveToAbsoluteUri(relativeUri)];
      if (unit == null) {
        if (!allowMissingFiles) {
          fail('Test referred to unknown unit $relativeUri');
        }
      } else {
        unlinkedUnits.add(unit);
      }
    }
  }

  CompilationUnit _parseText(String text) {
    CharSequenceReader reader = new CharSequenceReader(text);
    Scanner scanner =
        new Scanner(null, reader, AnalysisErrorListener.NULL_LISTENER);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, AnalysisErrorListener.NULL_LISTENER);
    parser.parseGenericMethods = true;
    return parser.parseCompilationUnit(token);
  }
}
