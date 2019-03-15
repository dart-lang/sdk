// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/restricted_analysis_context.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:path/path.dart' show posix;
import 'package:test/test.dart';

import 'resynthesize_common.dart';

/// Convert the given Posix style file [path] to the corresponding absolute URI.
String absUri(String path) {
  String absolutePath = posix.absolute(path);
  return posix.toUri(absolutePath).toString();
}

CompilationUnit parseText(
  String text, {
  ExperimentStatus experimentStatus,
}) {
  experimentStatus ??= ExperimentStatus();
  CharSequenceReader reader = new CharSequenceReader(text);
  Scanner scanner =
      new Scanner(null, reader, AnalysisErrorListener.NULL_LISTENER);
  Token token = scanner.tokenize();
  Parser parser = new Parser(
      NonExistingSource.unknown, AnalysisErrorListener.NULL_LISTENER)
    ..enableNonNullable = experimentStatus.non_nullable
    ..enableSpreadCollections = experimentStatus.spread_collections
    ..enableControlFlowCollections = experimentStatus.control_flow_collections;
  CompilationUnit unit = parser.parseCompilationUnit(token);
  unit.lineInfo = new LineInfo(scanner.lineStarts);
  return unit;
}

/// Verify invariants of the given [linkedLibrary].
void _validateLinkedLibrary(LinkedLibrary linkedLibrary) {
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

/// Abstract base class for tests of summary resynthesis.
///
/// Test classes should not extend this class directly; they should extend a
/// class that implements this class with methods that drive summary generation.
/// The tests themselves can then be provided via mixin, allowing summaries to
/// be tested in a variety of ways.
abstract class ResynthesizeTestStrategy {
  /// The set of [ExperimentStatus] enabled in this test.
  ExperimentStatus experimentStatus;

  void set allowMissingFiles(bool value);

  set declaredVariables(DeclaredVariables declaredVariables);

  bool get isAstBasedSummary => false;

  MemoryResourceProvider get resourceProvider;

  void set testFile(String value);

  Source get testSource;

  void addLibrary(String uri);

  Source addLibrarySource(String filePath, String contents);

  Source addSource(String path, String contents);

  Source addTestSource(String code, [Uri uri]);

  void checkMinimalResynthesisWork(TestSummaryResynthesizer resynthesizer,
      Uri expectedLibraryUri, List<Uri> expectedUnitUriList);

  TestSummaryResynthesizer encodeLibrary(Source source);
}

/// Implementation of [SummaryBlackBoxTestStrategy] that drives summary
/// generation using the old two-phase API.
class ResynthesizeTestStrategyTwoPhase extends AbstractResynthesizeTest
    implements ResynthesizeTestStrategy {
  @override
  ExperimentStatus experimentStatus = ExperimentStatus();

  final Set<Source> serializedSources = new Set<Source>();

  final Map<String, UnlinkedUnitBuilder> uriToUnit =
      <String, UnlinkedUnitBuilder>{};

  PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();

  @override
  bool get isAstBasedSummary => false;

  TestSummaryResynthesizer encodeLibrary(Source source) {
    _serializeLibrary(source);

    PackageBundle bundle =
        new PackageBundle.fromBuffer(bundleAssembler.assemble().toBuffer());

    Map<String, UnlinkedUnit> unlinkedSummaries = <String, UnlinkedUnit>{};
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      String uri = bundle.unlinkedUnitUris[i];
      unlinkedSummaries[uri] = bundle.unlinkedUnits[i];
    }

    LinkedLibrary getDependency(String absoluteUri) {
      Map<String, LinkedLibrary> sdkLibraries =
          SerializedMockSdk.instance.uriToLinkedLibrary;
      LinkedLibrary linkedLibrary = sdkLibraries[absoluteUri];
      if (linkedLibrary == null && !allowMissingFiles) {
        fail('Linker unexpectedly requested LinkedLibrary for "$absoluteUri".'
            '  Libraries available: ${sdkLibraries.keys}');
      }
      return linkedLibrary;
    }

    UnlinkedUnit getUnit(String absoluteUri) {
      UnlinkedUnit unit = uriToUnit[absoluteUri] ??
          SerializedMockSdk.instance.uriToUnlinkedUnit[absoluteUri];
      if (unit == null && !allowMissingFiles) {
        fail('Linker unexpectedly requested unit for "$absoluteUri".');
      }
      return unit;
    }

    Set<String> nonSdkLibraryUris = serializedSources
        .where((Source source) => !source.isInSystemLibrary)
        .map((Source source) => source.uri.toString())
        .toSet();

    var analysisOptions = AnalysisOptionsImpl()
      ..enabledExperiments = experimentStatus.toStringList();

    Map<String, LinkedLibrary> linkedSummaries = link(nonSdkLibraryUris,
        getDependency, getUnit, declaredVariables, analysisOptions);

    var analysisContext = RestrictedAnalysisContext(
      analysisOptions,
      declaredVariables,
      sourceFactory,
    );

    return new TestSummaryResynthesizer(
        analysisContext,
        new Map<String, UnlinkedUnit>()
          ..addAll(SerializedMockSdk.instance.uriToUnlinkedUnit)
          ..addAll(unlinkedSummaries),
        new Map<String, LinkedLibrary>()
          ..addAll(SerializedMockSdk.instance.uriToLinkedLibrary)
          ..addAll(linkedSummaries),
        allowMissingFiles);
  }

  UnlinkedUnit _getUnlinkedUnit(Source source) {
    if (source == null) {
      return new UnlinkedUnitBuilder();
    }

    String uriStr = source.uri.toString();
    {
      UnlinkedUnit unlinkedUnitInSdk =
          SerializedMockSdk.instance.uriToUnlinkedUnit[uriStr];
      if (unlinkedUnitInSdk != null) {
        return unlinkedUnitInSdk;
      }
    }
    return uriToUnit.putIfAbsent(uriStr, () {
      var file = getFile(source.fullName);

      String contents;
      if (file.exists) {
        contents = file.readAsStringSync();
      } else {
        // Source does not exist.
        if (!allowMissingFiles) {
          fail('Unexpectedly tried to get unlinked summary for $source');
        }
        contents = '';
      }

      CompilationUnit unit =
          parseText(contents, experimentStatus: experimentStatus);

      UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
      bundleAssembler.addUnlinkedUnit(source, unlinkedUnit);
      return unlinkedUnit;
    });
  }

  void _serializeLibrary(Source librarySource) {
    if (librarySource == null || librarySource.isInSystemLibrary) {
      return;
    }
    if (!serializedSources.add(librarySource)) {
      return;
    }

    UnlinkedUnit getPart(String absoluteUri) {
      Source source = sourceFactory.forUri(absoluteUri);
      return _getUnlinkedUnit(source);
    }

    UnlinkedPublicNamespace getImport(String relativeUri) {
      return getPart(relativeUri)?.publicNamespace;
    }

    UnlinkedUnit definingUnit = _getUnlinkedUnit(librarySource);
    if (definingUnit != null) {
      LinkedLibraryBuilder linkedLibrary = prelink(librarySource.uri.toString(),
          definingUnit, getPart, getImport, declaredVariables);
      linkedLibrary.dependencies.skip(1).forEach((LinkedDependency d) {
        Source source = sourceFactory.forUri(d.uri);
        _serializeLibrary(source);
      });
    }
  }
}

/// [SerializedMockSdk] is a singleton class representing the result of
/// serializing the mock SDK to summaries.  It is computed once and then shared
/// among test invocations so that we don't bog down the tests.
///
/// Note: should an exception occur during computation of [instance], it will
/// silently be set to null to allow other tests to complete quickly.
class SerializedMockSdk {
  static final SerializedMockSdk instance = _serializeMockSdk();

  final Map<String, UnlinkedUnit> uriToUnlinkedUnit;

  final Map<String, LinkedLibrary> uriToLinkedLibrary;

  SerializedMockSdk._(this.uriToUnlinkedUnit, this.uriToLinkedLibrary);

  static SerializedMockSdk _serializeMockSdk() {
    try {
      Map<String, UnlinkedUnit> uriToUnlinkedUnit = <String, UnlinkedUnit>{};
      Map<String, LinkedLibrary> uriToLinkedLibrary = <String, LinkedLibrary>{};
      var resourceProvider = new MemoryResourceProvider();
      PackageBundle bundle =
          new MockSdk(resourceProvider: resourceProvider).getLinkedBundle();
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

/// Abstract base class for tests involving summaries.
///
/// Test classes should not extend this class directly; they should extend a
/// class that implements this class with methods that drive summary generation.
/// The tests themselves can then be provided via mixin, allowing summaries to
/// be tested in a variety of ways.
abstract class SummaryBaseTestStrategy {
  /// The set of [ExperimentStatus] enabled in this test.
  ExperimentStatus experimentStatus;

  /// Add the given package bundle as a dependency so that it may be referenced
  /// by the files under test.
  void addBundle(String path, PackageBundle bundle);

  /// Add the given source file so that it may be referenced by the file under
  /// test.
  void addNamedSource(String filePath, String contents);

  /// Link together the given file, along with any other files passed to
  /// [addNamedSource], to form a package bundle.  Reset the state of the
  /// buffers accumulated by [addNamedSource] and [addBundle] so that further
  /// bundles can be created.
  PackageBundleBuilder createPackageBundle(String text,
      {String path: '/test.dart', String uri});
}

/// Abstract base class for black-box tests of summaries.
///
/// Test classes should not extend this class directly; they should extend a
/// class that implements this class with methods that drive summary generation.
/// The tests themselves can then be provided via mixin, allowing summaries to
/// be tested in a variety of ways.
abstract class SummaryBlackBoxTestStrategy extends SummaryBaseTestStrategy {
  /// A test will set this to `true` if it contains `import`, `export`, or
  /// `part` declarations that deliberately refer to non-existent files.
  void set allowMissingFiles(bool value);

  /// Indicates whether the summary contains expressions for non-const fields.
  ///
  /// When one-phase summarization is in use, only const field initializer
  /// expressions are stored in the summary.
  bool get containsNonConstExprs;

  /// Get access to the linked summary that results from serializing and
  /// then deserializing the library under test.
  LinkedLibrary get linked;

  /// `true` if the linked portion of the summary only contains prelinked data.
  /// This happens because we don't yet have a full linker; only a prelinker.
  bool get skipFullyLinkedData;

  /// Get access to the unlinked compilation unit summaries that result from
  /// serializing and deserializing the library under test.
  List<UnlinkedUnit> get unlinkedUnits;

  /// Serialize the given library [text], then deserialize it and store its
  /// summary in [lib].
  void serializeLibraryText(String text, {bool allowErrors: false});
}

/// Implementation of [SummaryBlackBoxTestStrategy] that drives summary
/// generation using the old two-phase API, and exercises the pre-linker only.
class SummaryBlackBoxTestStrategyPrelink
    extends _SummaryBlackBoxTestStrategyTwoPhase
    implements SummaryBlackBoxTestStrategy {
  @override
  bool get skipFullyLinkedData => true;

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    super.serializeLibraryText(text, allowErrors: allowErrors);

    UnlinkedUnit getPart(String absoluteUri) {
      return _linkerInputs.getUnit(absoluteUri);
    }

    UnlinkedPublicNamespace getImport(String absoluteUri) {
      return getPart(absoluteUri)?.publicNamespace;
    }

    linked = new LinkedLibrary.fromBuffer(prelink(
            _linkerInputs._testDartUri.toString(),
            _linkerInputs._unlinkedDefiningUnit,
            getPart,
            getImport,
            DeclaredVariables())
        .toBuffer());
    _validateLinkedLibrary(linked);
  }
}

/// Implementation of [SummaryBlackBoxTestStrategy] that drives summary
/// generation using the old two-phase API, and exercises full summary
/// generation.
class SummaryBlackBoxTestStrategyTwoPhase
    extends _SummaryBlackBoxTestStrategyTwoPhase
    implements SummaryBlackBoxTestStrategy {
  @override
  bool get skipFullyLinkedData => false;
}

/// Abstract base class for unit tests of the summary linker.
///
/// Test classes should not extend this class directly; they should extend a
/// class that implements this class with methods that drive summary generation.
/// The tests themselves can then be provided via mixin, allowing summaries to
/// be tested in a variety of ways.
abstract class SummaryLinkerTestStrategy extends SummaryBaseTestStrategy {
  Linker get linker;

  /// Gets the URI of the main library under test.
  ///
  /// May only be called after [createLinker].
  Uri get testDartUri;

  LibraryElementInBuildUnit get testLibrary;

  void createLinker(String text, {String path: '/test.dart'});
}

/// Implementation of [SummaryLinkerTestStrategy] that drives summary generation
/// using the old two-phase API.
class SummaryLinkerTestStrategyTwoPhase extends _SummaryBaseTestStrategyTwoPhase
    implements SummaryLinkerTestStrategy {
  LibraryElementInBuildUnit _testLibrary;

  @override
  Linker linker;

  @override
  Uri get testDartUri => _linkerInputs._testDartUri;

  @override
  LibraryElementInBuildUnit get testLibrary =>
      _testLibrary ??= linker.getLibrary(_linkerInputs._testDartUri)
          as LibraryElementInBuildUnit;

  @override
  bool get _allowMissingFiles => false;

  @override
  void createLinker(String text, {String path: '/test.dart'}) {
    _linkerInputs = _createLinkerInputs(text, path: path);
    Map<String, LinkedLibraryBuilder> linkedLibraries = setupForLink(
        _linkerInputs.linkedLibraries,
        _linkerInputs.getUnit,
        _linkerInputs.declaredVariables);
    linker = new Linker(linkedLibraries, _linkerInputs.getDependency,
        _linkerInputs.getUnit, null, analysisOptions);
  }
}

/// [_FilesToLink] stores information about a set of files to be linked
/// together.  This information is grouped into a class to allow it to be reset
/// easily when [_SummaryBaseTestStrategyTwoPhase._createLinkerInputs] is
/// called.
///
/// The generic parameter [U] is the type of information stored for each
/// compilation unit.
class _FilesToLink<U> {
  /// Map from absolute URI to the [U] for each compilation unit passed to
  /// [addNamedSource].
  Map<String, U> uriToUnit = <String, U>{};

  /// Information about summaries to be included in the link process.
  SummaryDataStore summaryDataStore = new SummaryDataStore([]);
}

/// Instances of the class [_LinkerInputs] encapsulate the necessary information
/// to pass to the summary linker.
class _LinkerInputs {
  final bool _allowMissingFiles;
  final Map<String, UnlinkedUnit> _uriToUnit;
  final Uri _testDartUri;
  final UnlinkedUnit _unlinkedDefiningUnit;
  final Map<String, LinkedLibrary> _dependentLinkedLibraries;
  final Map<String, UnlinkedUnit> _dependentUnlinkedUnits;

  _LinkerInputs(
      this._allowMissingFiles,
      this._uriToUnit,
      this._testDartUri,
      this._unlinkedDefiningUnit,
      this._dependentLinkedLibraries,
      this._dependentUnlinkedUnits);

  DeclaredVariables get declaredVariables => DeclaredVariables();

  Set<String> get linkedLibraries => _uriToUnit.keys.toSet();

  LinkedLibrary getDependency(String absoluteUri) {
    Map<String, LinkedLibrary> sdkLibraries =
        SerializedMockSdk.instance.uriToLinkedLibrary;
    LinkedLibrary linkedLibrary =
        sdkLibraries[absoluteUri] ?? _dependentLinkedLibraries[absoluteUri];
    if (linkedLibrary == null && !_allowMissingFiles) {
      Set<String> librariesAvailable = sdkLibraries.keys.toSet();
      librariesAvailable.addAll(_dependentLinkedLibraries.keys);
      fail('Linker unexpectedly requested LinkedLibrary for "$absoluteUri".'
          '  Libraries available: ${librariesAvailable.toList()}');
    }
    return linkedLibrary;
  }

  UnlinkedUnit getUnit(String absoluteUri) {
    if (absoluteUri == null) {
      return null;
    }
    UnlinkedUnit unit = _uriToUnit[absoluteUri] ??
        SerializedMockSdk.instance.uriToUnlinkedUnit[absoluteUri] ??
        _dependentUnlinkedUnits[absoluteUri];
    if (unit == null && !_allowMissingFiles) {
      fail('Linker unexpectedly requested unit for "$absoluteUri".');
    }
    return unit;
  }
}

/// Implementation of [SummaryBaseTestStrategy] that drives summary generation
/// using the old two-phase API.
abstract class _SummaryBaseTestStrategyTwoPhase
    implements SummaryBaseTestStrategy {
  /// Information about the files to be linked.
  _FilesToLink<UnlinkedUnitBuilder> _filesToLink =
      new _FilesToLink<UnlinkedUnitBuilder>();

  @override
  ExperimentStatus experimentStatus = ExperimentStatus();

  _LinkerInputs _linkerInputs;

  AnalysisOptions get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = experimentStatus.toStringList();

  bool get _allowMissingFiles;

  @override
  void addBundle(String path, PackageBundle bundle) {
    _filesToLink.summaryDataStore.addBundle(path, bundle);
  }

  @override
  void addNamedSource(String filePath, String contents) {
    CompilationUnit unit = parseText(contents);
    UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
    _filesToLink.uriToUnit[absUri(filePath)] = unlinkedUnit;
  }

  @override
  PackageBundleBuilder createPackageBundle(String text,
      {String path: '/test.dart', String uri}) {
    PackageBundleAssembler assembler = new PackageBundleAssembler();
    _LinkerInputs linkerInputs =
        _createLinkerInputs(text, path: path, uri: uri);
    Map<String, LinkedLibraryBuilder> linkedLibraries = link(
        linkerInputs.linkedLibraries,
        linkerInputs.getDependency,
        linkerInputs.getUnit,
        linkerInputs.declaredVariables,
        analysisOptions);
    linkedLibraries.forEach(assembler.addLinkedLibrary);
    linkerInputs._uriToUnit.forEach((String uri, UnlinkedUnit unit) {
      assembler.addUnlinkedUnitViaUri(uri, unit);
    });
    return assembler.assemble();
  }

  UnlinkedUnitBuilder createUnlinkedSummary(Uri uri, String text) =>
      serializeAstUnlinked(parseText(text, experimentStatus: experimentStatus));

  _LinkerInputs _createLinkerInputs(String text,
      {String path: '/test.dart', String uri}) {
    uri ??= absUri(path);
    Uri testDartUri = Uri.parse(uri);
    UnlinkedUnitBuilder unlinkedDefiningUnit =
        createUnlinkedSummary(testDartUri, text);
    _filesToLink.uriToUnit[testDartUri.toString()] = unlinkedDefiningUnit;
    _LinkerInputs linkerInputs = new _LinkerInputs(
        _allowMissingFiles,
        _filesToLink.uriToUnit,
        testDartUri,
        unlinkedDefiningUnit,
        _filesToLink.summaryDataStore.linkedMap,
        _filesToLink.summaryDataStore.unlinkedMap);
    // Reset _filesToLink in case the test needs to start a new package bundle.
    _filesToLink = new _FilesToLink<UnlinkedUnitBuilder>();
    return linkerInputs;
  }
}

/// Implementation of [SummaryBlackBoxTestStrategy] that drives summary
/// generation using the old two-phase API.
///
/// Not intended to be used directly; instead use a derived class that either
/// exercises the full summary algorithm or just pre-linking.
abstract class _SummaryBlackBoxTestStrategyTwoPhase
    extends _SummaryBaseTestStrategyTwoPhase
    implements SummaryBlackBoxTestStrategy {
  @override
  List<UnlinkedUnit> unlinkedUnits;

  @override
  LinkedLibrary linked;

  @override
  bool _allowMissingFiles = false;

  @override
  void set allowMissingFiles(bool value) {
    _allowMissingFiles = value;
  }

  @override
  bool get containsNonConstExprs => true;

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Map<String, UnlinkedUnitBuilder> uriToUnit = this._filesToLink.uriToUnit;
    _linkerInputs = _createLinkerInputs(text);
    linked = link(
        _linkerInputs.linkedLibraries,
        _linkerInputs.getDependency,
        _linkerInputs.getUnit,
        DeclaredVariables(),
        analysisOptions)[_linkerInputs._testDartUri.toString()];
    expect(linked, isNotNull);
    _validateLinkedLibrary(linked);
    unlinkedUnits = <UnlinkedUnit>[_linkerInputs._unlinkedDefiningUnit];
    for (String relativeUriStr
        in _linkerInputs._unlinkedDefiningUnit.publicNamespace.parts) {
      Uri relativeUri;
      try {
        relativeUri = Uri.parse(relativeUriStr);
      } on FormatException {
        unlinkedUnits.add(new UnlinkedUnitBuilder());
        continue;
      }

      UnlinkedUnit unit = uriToUnit[
          resolveRelativeUri(_linkerInputs._testDartUri, relativeUri)
              .toString()];
      if (unit == null) {
        if (!_allowMissingFiles) {
          fail('Test referred to unknown unit $relativeUriStr');
        }
      } else {
        unlinkedUnits.add(unit);
      }
    }
  }
}
