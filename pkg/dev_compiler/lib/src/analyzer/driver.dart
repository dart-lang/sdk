// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/restricted_analysis_context.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart' as summary_link;
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:meta/meta.dart';

import '../compiler/shared_command.dart' show sdkLibraryVariables;
import 'context.dart' show AnalyzerOptions, createSourceFactory;
import 'extension_types.dart' show ExtensionTypeSet;

/// The analysis driver for `dartdevc`.
///
/// [linkLibraries] can be used to link input sources and input summaries,
/// producing a [LinkedAnalysisDriver] that can analyze those sources.
///
/// This class can be reused to link different input files if they share the
/// same [analysisOptions] and [summaryData].
class CompilerAnalysisDriver {
  /// The Analyzer options used for analyzing the input sources.
  final AnalysisOptionsImpl analysisOptions;

  /// The input summaries used for analyzing/compiling the input sources.
  ///
  /// This should contain the summary of all imported/exported libraries and
  /// transitive dependencies, including the Dart SDK.
  final SummaryDataStore summaryData;

  final ResourceProvider _resourceProvider;

  final List<String> _summaryPaths;

  @visibleForTesting
  final DartSdk dartSdk;

  /// SDK summary path, used by [isCompatibleWith] for batch/worker mode.
  final String _dartSdkSummaryPath;

  ExtensionTypeSet _extensionTypes;

  CompilerAnalysisDriver._(this.dartSdk, this._summaryPaths, this.summaryData,
      this.analysisOptions, this._resourceProvider, this._dartSdkSummaryPath) {
    var bundle = dartSdk.getLinkedBundle();
    if (bundle != null) summaryData.addBundle(null, bundle);
  }

  /// Information about native extension types.
  ///
  /// This will be `null` until [linkLibraries] has been called (because we
  /// could be compiling the Dart SDK, so it would not be available yet).
  ExtensionTypeSet get extensionTypes => _extensionTypes;

  factory CompilerAnalysisDriver(AnalyzerOptions options,
      {SummaryDataStore summaryData,
      List<String> summaryPaths = const [],
      Map<String, bool> experiments = const {}}) {
    AnalysisEngine.instance.processRequiredPlugins();

    var resourceProvider = options.resourceProvider;
    var contextBuilder = options.createContextBuilder();

    var analysisOptions =
        contextBuilder.getAnalysisOptions(options.analysisRoot);

    (analysisOptions as AnalysisOptionsImpl).enabledExperiments =
        experiments.entries.where((e) => e.value).map((e) => e.key).toList();

    var dartSdk = contextBuilder.findSdk(null, analysisOptions);

    // Read the summaries.
    summaryData ??= SummaryDataStore(summaryPaths,
        resourceProvider: resourceProvider,
        // TODO(vsm): Reset this to true once we cleanup internal build rules.
        disallowOverlappingSummaries: false);

    return CompilerAnalysisDriver._(dartSdk, summaryPaths, summaryData,
        analysisOptions, resourceProvider, options.dartSdkSummaryPath);
  }

  /// Whether this driver can be reused for the given [dartSdkSummaryPath] and
  /// [summaryPaths].
  bool isCompatibleWith(AnalyzerOptions options, List<String> summaryPaths) {
    return _dartSdkSummaryPath == options.dartSdkSummaryPath &&
        _summaryPaths.toSet().containsAll(summaryPaths);
  }

  /// Parses [explicitSources] and any imports/exports/parts (that are not
  /// included in [summaryData]), and links the results so
  /// [LinkedAnalysisDriver.analyzeLibrary] can be called.
  ///
  /// The analyzer [options] are used to configure URI resolution (Analyzer's
  /// [SourceFactory]) and declared variables, if any (`-Dfoo=bar`).
  LinkedAnalysisDriver linkLibraries(
      List<Uri> explicitSources, AnalyzerOptions options) {
    /// This code was ported from analyzer_cli (with a few changes/improvements).
    ///
    /// Here's a summary of the process:
    ///
    /// 1. starting with [explicitSources], visit all transitive
    ///    imports/exports/parts, and create an unlinked unit for each
    ///    (unless it's provided by an input summary). Add these to [assembler].
    ///
    /// 2. call [summary_link.link] to create the linked libraries, and add the
    ///    results to the assembler.
    ///
    /// 3. serialize the data into [summaryBytes], then deserialize it back into
    ///    the [bundle] that contains the summary for all [explicitSources] and
    ///    their transitive dependencies.
    ///
    /// 4. create the analysis [context] and element [resynthesizer], and use
    ///    them to return a new [LinkedAnalysisDriver] that can analyze all of
    ///    the compilation units (and provide the resolved AST/errors for each).
    var assembler = PackageBundleAssembler();

    /// The URI resolution logic for this build unit.
    var sourceFactory = createSourceFactory(options,
        sdkResolver: DartUriResolver(dartSdk), summaryData: summaryData);

    /// A fresh file system state for this list of [explicitSources].
    var fsState = _createFileSystemState(sourceFactory);

    var uriToUnit = <String, UnlinkedUnit>{};

    /// The sources that have been added to [sourcesToProcess], used to ensure
    /// we only visit a given source once.
    var knownSources = HashSet<Uri>.from(explicitSources);

    /// The pending list of sources to visit.
    var sourcesToProcess = Queue<Uri>.from(explicitSources);

    /// Prepare URIs of unlinked units (for libraries) that should be linked.
    var libraryUris = <String>[];

    /// Ensure that the [UnlinkedUnit] for [absoluteUri] is available.
    ///
    /// If the unit is in the input [summaryData], do nothing.
    /// Otherwise compute it and store into the [uriToUnit] and [assembler].
    void prepareUnlinkedUnit(Uri uri) {
      var absoluteUri = uri.toString();
      // Maybe an input package contains the source.
      if (summaryData.unlinkedMap[absoluteUri] != null) {
        return;
      }
      // Parse the source and serialize its AST.
      var source = sourceFactory.forUri2(uri);
      if (source == null || !source.exists()) {
        // Skip this source. We don't need to report an error here because it
        // will be reported later during analysis.
        return;
      }
      var file = fsState.getFileForPath(source.fullName);
      var unit = file.parse();
      var unlinkedUnit = serializeAstUnlinked(unit);
      uriToUnit[absoluteUri] = unlinkedUnit;
      assembler.addUnlinkedUnit(source, unlinkedUnit);

      /// The URI to resolve imports/exports/parts against.
      var baseUri = uri;
      if (baseUri.scheme == 'dart' && baseUri.pathSegments.length == 1) {
        // Add a trailing slash so relative URIs will resolve correctly, e.g.
        // "map.dart" from "dart:core/" yields "dart:core/map.dart".
        baseUri = Uri(scheme: 'dart', path: baseUri.path + '/');
      }

      void enqueueSource(String relativeUri) {
        var sourceUri = baseUri.resolve(relativeUri);
        if (knownSources.add(sourceUri)) {
          sourcesToProcess.add(sourceUri);
        }
      }

      // Add reachable imports/exports/parts, if any.
      var isPart = false;
      for (var directive in unit.directives) {
        if (directive is UriBasedDirective) {
          enqueueSource(directive.uri.stringValue);
          // Handle conditional imports.
          if (directive is NamespaceDirective) {
            for (var config in directive.configurations) {
              enqueueSource(config.uri.stringValue);
            }
          }
        } else if (directive is PartOfDirective) {
          isPart = true;
        }
      }

      // Remember library URIs, so we can use it for linking libraries and
      // compiling them.
      if (!isPart) libraryUris.add(absoluteUri);
    }

    // Collect the unlinked units for all transitive sources.
    //
    // TODO(jmesserly): consider using parallelism via asynchronous IO here,
    // once we fix debugger extension (web/web_command.dart) to allow async.
    //
    // It would let computation tasks (parsing/serializing unlinked units)
    // proceed in parallel with reading the sources from disk.
    while (sourcesToProcess.isNotEmpty) {
      prepareUnlinkedUnit(sourcesToProcess.removeFirst());
    }

    var declaredVariables = DeclaredVariables.fromMap(
        Map.of(options.declaredVariables)..addAll(sdkLibraryVariables));

    /// Perform the linking step and store the result.
    ///
    /// TODO(jmesserly): can we pass in `getAst` to reuse existing ASTs we
    /// created when we did `file.parse()` in [prepareUnlinkedUnit]?
    var linkResult = summary_link.link(
        libraryUris.toSet(),
        (uri) => summaryData.linkedMap[uri],
        (uri) => summaryData.unlinkedMap[uri] ?? uriToUnit[uri],
        declaredVariables.get,
        analysisOptions);
    linkResult.forEach(assembler.addLinkedLibrary);

    var summaryBytes = assembler.assemble().toBuffer();
    var bundle = PackageBundle.fromBuffer(summaryBytes);

    /// Create an analysis context to contain the state for this build unit.
    var context = RestrictedAnalysisContext(
        analysisOptions, declaredVariables, sourceFactory);
    var resultProvider = InputPackagesResultProvider(
        context,
        SummaryDataStore([])
          ..addStore(summaryData)
          ..addBundle(null, bundle));

    var resynthesizer = resultProvider.resynthesizer;
    _extensionTypes ??= ExtensionTypeSet(context.typeProvider, resynthesizer);

    return LinkedAnalysisDriver(
        analysisOptions,
        resynthesizer,
        sourceFactory,
        libraryUris,
        declaredVariables,
        summaryBytes,
        fsState,
        _resourceProvider);
  }

  FileSystemState _createFileSystemState(SourceFactory sourceFactory) {
    var unlinkedSalt =
        Uint32List(1 + AnalysisOptionsImpl.unlinkedSignatureLength);
    unlinkedSalt[0] = AnalysisDriver.DATA_VERSION;
    unlinkedSalt.setAll(1, analysisOptions.unlinkedSignature);

    var linkedSalt = Uint32List(1 + AnalysisOptions.signatureLength);
    linkedSalt[0] = AnalysisDriver.DATA_VERSION;
    linkedSalt.setAll(1, analysisOptions.signature);

    return FileSystemState(
        PerformanceLog(StringBuffer()),
        MemoryByteStore(),
        FileContentOverlay(),
        _resourceProvider,
        sourceFactory,
        analysisOptions,
        unlinkedSalt,
        linkedSalt,
        externalSummaries: summaryData);
  }
}

/// The analysis driver used after linking all input summaries and explicit
/// sources, produced by [CompilerAnalysisDriver.linkLibraries].
class LinkedAnalysisDriver {
  final AnalysisOptions analysisOptions;
  final SummaryResynthesizer resynthesizer;
  final SourceFactory sourceFactory;
  final List<String> libraryUris;
  final DeclaredVariables declaredVariables;

  /// The summary bytes for this linked build unit.
  final List<int> summaryBytes;

  final FileSystemState _fsState;

  final ResourceProvider _resourceProvider;

  LinkedAnalysisDriver(
      this.analysisOptions,
      this.resynthesizer,
      this.sourceFactory,
      this.libraryUris,
      this.declaredVariables,
      this.summaryBytes,
      this._fsState,
      this._resourceProvider);

  TypeProvider get typeProvider => resynthesizer.typeProvider;

  /// True if [uri] refers to a Dart library (i.e. a Dart source file exists
  /// with this uri, and it is not a part file).
  bool _isLibraryUri(String uri) {
    return resynthesizer.hasLibrarySummary(uri);
  }

  /// Analyzes the library at [uri] and returns the results of analysis for all
  /// file(s) in that library.
  Map<FileState, UnitAnalysisResult> analyzeLibrary(String libraryUri) {
    if (!_isLibraryUri(libraryUri)) {
      throw ArgumentError('"$libraryUri" is not a library');
    }

    var libraryFile = _fsState.getFileForUri(Uri.parse(libraryUri));
    var analyzer = LibraryAnalyzer(
        analysisOptions,
        declaredVariables,
        resynthesizer.sourceFactory,
        (uri) => _isLibraryUri('$uri'),
        resynthesizer.context,
        resynthesizer,
        InheritanceManager2(resynthesizer.typeSystem),
        libraryFile,
        _resourceProvider);
    // TODO(jmesserly): ideally we'd use the existing public `analyze()` method,
    // but it's async. We can't use `async` here because it would break our
    // developer tools extension (see web/web_command.dart). We should be able
    // to fix it, but it requires significant changes to code outside of this
    // repository.
    return analyzer.analyzeSync();
  }

  ClassElement getClass(String uri, String name) {
    return getLibrary(uri).getType(name);
  }

  LibraryElement getLibrary(String uri) {
    return resynthesizer.getLibraryElement(uri);
  }
}
