// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/ddc.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
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
    var resourceProvider = options.resourceProvider;
    var contextBuilder = options.createContextBuilder();

    var analysisOptions = contextBuilder
        .getAnalysisOptions(options.analysisRoot) as AnalysisOptionsImpl;

    analysisOptions.enabledExperiments =
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
    /// The URI resolution logic for this build unit.
    var sourceFactory = createSourceFactory(options,
        sdkResolver: DartUriResolver(dartSdk), summaryData: summaryData);

    /// A fresh file system state for this list of [explicitSources].
    var fsState = _createFileSystemState(sourceFactory);

    var declaredVariables = DeclaredVariables.fromMap(
        Map.of(options.declaredVariables)..addAll(sdkLibraryVariables));

    var resynthesizerBuilder = DevCompilerResynthesizerBuilder(
      fsState: fsState,
      analysisOptions: analysisOptions,
      declaredVariables: declaredVariables,
      sourceFactory: sourceFactory,
      summaryData: summaryData,
      explicitSources: explicitSources,
    );
    resynthesizerBuilder.build();

    _extensionTypes ??= ExtensionTypeSet(
      resynthesizerBuilder.context.typeProvider,
      resynthesizerBuilder.resynthesizer,
      resynthesizerBuilder.elementFactory,
    );

    return LinkedAnalysisDriver(
      analysisOptions,
      resynthesizerBuilder.resynthesizer,
      resynthesizerBuilder.elementFactory,
      sourceFactory,
      resynthesizerBuilder.libraryUris,
      declaredVariables,
      resynthesizerBuilder.summaryBytes,
      fsState,
      _resourceProvider,
    );
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
  final LinkedElementFactory elementFactory;
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
      this.elementFactory,
      this.sourceFactory,
      this.libraryUris,
      this.declaredVariables,
      this.summaryBytes,
      this._fsState,
      this._resourceProvider);

  TypeProvider get typeProvider {
    if (resynthesizer != null) {
      return resynthesizer.typeProvider;
    } else {
      return elementFactory.analysisContext.typeProvider;
    }
  }

  /// True if [uri] refers to a Dart library (i.e. a Dart source file exists
  /// with this uri, and it is not a part file).
  bool _isLibraryUri(String uri) {
    if (resynthesizer != null) {
      return resynthesizer.hasLibrarySummary(uri);
    } else {
      return elementFactory.isLibraryUri(uri);
    }
  }

  /// Analyzes the library at [uri] and returns the results of analysis for all
  /// file(s) in that library.
  Map<FileState, UnitAnalysisResult> analyzeLibrary(String libraryUri) {
    if (!_isLibraryUri(libraryUri)) {
      throw ArgumentError('"$libraryUri" is not a library');
    }

    AnalysisContext analysisContext;
    if (resynthesizer != null) {
      analysisContext = resynthesizer.context;
    } else {
      analysisContext = elementFactory.analysisContext;
    }

    var libraryFile = _fsState.getFileForUri(Uri.parse(libraryUri));
    var analyzer = LibraryAnalyzer(
        analysisOptions as AnalysisOptionsImpl,
        declaredVariables,
        sourceFactory,
        (uri) => _isLibraryUri('$uri'),
        analysisContext,
        resynthesizer,
        elementFactory,
        InheritanceManager2(analysisContext.typeSystem),
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
    if (resynthesizer != null) {
      return resynthesizer.getLibraryElement(uri);
    } else {
      return elementFactory.libraryOfUri(uri);
    }
  }
}
