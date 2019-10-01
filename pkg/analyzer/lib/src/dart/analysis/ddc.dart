// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/restricted_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/link.dart' as summary2;
import 'package:analyzer/src/summary2/linked_bundle_context.dart' as summary2;
import 'package:analyzer/src/summary2/linked_element_factory.dart' as summary2;
import 'package:analyzer/src/summary2/reference.dart' as summary2;
import 'package:meta/meta.dart';

class DevCompilerResynthesizerBuilder {
  final FileSystemState _fsState;
  final SourceFactory _sourceFactory;
  final DeclaredVariables _declaredVariables;
  final AnalysisOptionsImpl _analysisOptions;
  final SummaryDataStore _summaryData;
  final List<Uri> _explicitSources;

  _SourceCrawler _fileCrawler;

  final List<_UnitInformativeData> _informativeData = [];

  final PackageBundleAssembler _assembler;
  List<int> summaryBytes;

  RestrictedAnalysisContext context;
  summary2.LinkedElementFactory elementFactory;

  DevCompilerResynthesizerBuilder({
    @required FileSystemState fsState,
    @required SourceFactory sourceFactory,
    @required DeclaredVariables declaredVariables,
    @required AnalysisOptionsImpl analysisOptions,
    @required SummaryDataStore summaryData,
    @required List<Uri> explicitSources,
  })  : _fsState = fsState,
        _sourceFactory = sourceFactory,
        _declaredVariables = declaredVariables,
        _analysisOptions = analysisOptions,
        _summaryData = summaryData,
        _explicitSources = explicitSources,
        _assembler = PackageBundleAssembler();

  /// URIs of libraries that should be linked.
  List<String> get libraryUris => _fileCrawler.libraryUris;

  /// Link explicit sources, serialize [PackageBundle] into [summaryBytes].
  ///
  /// Create a new [context], [resynthesizer] and [elementFactory].
  void build() {
    _fileCrawler = _SourceCrawler(
      _fsState,
      _sourceFactory,
      _summaryData,
      _explicitSources,
    );
    _fileCrawler.crawl();

    _computeLinkedLibraries2();
    summaryBytes = _assembler.assemble().toBuffer();
    var bundle = PackageBundle.fromBuffer(summaryBytes);

    // Create an analysis context to contain the state for this build unit.
    var synchronousSession = SynchronousSession(
      _analysisOptions,
      _declaredVariables,
    );
    context = RestrictedAnalysisContext(synchronousSession, _sourceFactory);

    _createElementFactory(bundle);
  }

  /// Link libraries, and fill [_assembler].
  void _computeLinkedLibraries2() {
    var inputLibraries = <summary2.LinkInputLibrary>[];

    var sourceToUnit = _fileCrawler.sourceToUnit;
    var librarySourcesToLink = <Source>[]
      ..addAll(_fileCrawler.librarySources)
      ..addAll(_fileCrawler._invalidLibrarySources);
    for (var librarySource in librarySourcesToLink) {
      var libraryUriStr = '${librarySource.uri}';
      var unit = sourceToUnit[librarySource];

      var inputUnits = <summary2.LinkInputUnit>[];
      inputUnits.add(
        summary2.LinkInputUnit(null, librarySource, false, unit),
      );

      _informativeData.add(
        _UnitInformativeData(
          libraryUriStr,
          libraryUriStr,
          createInformativeData(unit),
        ),
      );

      for (var directive in unit.directives) {
        if (directive is PartDirective) {
          var partRelativeUriStr = directive.uri.stringValue;
          var partSource = _sourceFactory.resolveUri(
            librarySource,
            partRelativeUriStr,
          );

          // Add empty synthetic units for unresolved `part` URIs.
          if (partSource == null) {
            inputUnits.add(
              summary2.LinkInputUnit(
                partRelativeUriStr,
                null,
                true,
                _fsState.unresolvedFile.parse(),
              ),
            );
            continue;
          }

          var partUnit = sourceToUnit[partSource];
          inputUnits.add(
            summary2.LinkInputUnit(
              partRelativeUriStr,
              partSource,
              partSource == null,
              partUnit,
            ),
          );

          var unitUriStr = '${partSource.uri}';
          _informativeData.add(
            _UnitInformativeData(
              libraryUriStr,
              unitUriStr,
              createInformativeData(partUnit),
            ),
          );
        }
      }

      inputLibraries.add(
        summary2.LinkInputLibrary(librarySource, inputUnits),
      );
    }

    var analysisContext = RestrictedAnalysisContext(
      SynchronousSession(_analysisOptions, _declaredVariables),
      _sourceFactory,
    );

    var elementFactory = summary2.LinkedElementFactory(
      analysisContext,
      null,
      summary2.Reference.root(),
    );

    for (var bundle in _summaryData.bundles) {
      elementFactory.addBundle(
        summary2.LinkedBundleContext(elementFactory, bundle.bundle2),
      );
    }

    var linkResult = summary2.link(elementFactory, inputLibraries);
    _assembler.setBundle2(linkResult.bundle);
  }

  void _createElementFactory(PackageBundle newBundle) {
    elementFactory = summary2.LinkedElementFactory(
      context,
      null,
      summary2.Reference.root(),
    );
    for (var bundle in _summaryData.bundles) {
      elementFactory.addBundle(
        summary2.LinkedBundleContext(elementFactory, bundle.bundle2),
      );
    }
    elementFactory.addBundle(
      summary2.LinkedBundleContext(elementFactory, newBundle.bundle2),
    );

    for (var unitData in _informativeData) {
      elementFactory.setInformativeData(
        unitData.libraryUriStr,
        unitData.unitUriStr,
        unitData.data,
      );
    }

    var dartCore = elementFactory.libraryOfUri('dart:core');
    var dartAsync = elementFactory.libraryOfUri('dart:async');
    var typeProvider = TypeProviderImpl(dartCore, dartAsync);
    context.typeProvider = typeProvider;

    dartCore.createLoadLibraryFunction(typeProvider);
    dartAsync.createLoadLibraryFunction(typeProvider);
  }
}

class _SourceCrawler {
  final FileSystemState _fsState;
  final SourceFactory _sourceFactory;
  final SummaryDataStore _summaryData;
  final List<Uri> _explicitSources;

  /// The pending list of sources to visit.
  var _pendingSource = Queue<Uri>();

  /// The sources that have been added to [_pendingSource], used to ensure
  /// we only visit a given source once.
  var _knownSources = Set<Uri>();

  /// The set of URIs that expected to be libraries.
  ///
  /// Some of the might turn out to have `part of` directive, and so reported
  /// later. However we still must be able to provide some element for them
  /// when requested via `import` or `export` directives.
  final Set<Uri> _expectedLibraryUris = Set<Uri>();

  /// The list of sources with URIs that [_expectedLibraryUris], but turned
  /// out to be parts. We still add them into summaries, but don't resolve
  /// them as units.
  final List<Source> _invalidLibrarySources = [];

  final Map<Source, CompilationUnit> sourceToUnit = {};
  final List<String> libraryUris = [];
  final List<Source> librarySources = [];

  _SourceCrawler(
    this._fsState,
    this._sourceFactory,
    this._summaryData,
    this._explicitSources,
  );

  /// Starting with [_explicitSources], visit all transitive imports, exports,
  /// parts, and create an unlinked unit for each (unless it is provided by an
  /// input summary from [_summaryData]).
  void crawl() {
    _pendingSource.addAll(_explicitSources);
    _knownSources.addAll(_explicitSources);

    // Collect the unlinked units for all transitive sources.
    //
    // TODO(jmesserly): consider using parallelism via asynchronous IO here,
    // once we fix debugger extension (web/web_command.dart) to allow async.
    //
    // It would let computation tasks (parsing/serializing unlinked units)
    // proceed in parallel with reading the sources from disk.
    while (_pendingSource.isNotEmpty) {
      _visit(_pendingSource.removeFirst());
    }
  }

  /// Visit the file with the given [uri], and fill its data.
  void _visit(Uri uri) {
    var uriStr = uri.toString();

    // Maybe an input package contains the source.
    if (_summaryData.hasUnlinkedUnit(uriStr)) {
      return;
    }

    var source = _sourceFactory.forUri2(uri);
    if (source == null) {
      return;
    }

    var file = _fsState.getFileForPath(source.fullName);
    var unit = file.parse();
    sourceToUnit[source] = unit;

    void enqueueSource(String relativeUri, bool shouldBeLibrary) {
      var sourceUri = resolveRelativeUri(uri, Uri.parse(relativeUri));
      if (_knownSources.add(sourceUri)) {
        _pendingSource.add(sourceUri);
        if (shouldBeLibrary) {
          _expectedLibraryUris.add(sourceUri);
        }
      }
    }

    // Add reachable imports/exports/parts, if any.
    var isPart = false;
    for (var directive in unit.directives) {
      if (directive is UriBasedDirective) {
        if (directive is NamespaceDirective) {
          enqueueSource(directive.uri.stringValue, true);
          for (var config in directive.configurations) {
            enqueueSource(config.uri.stringValue, true);
          }
        } else {
          enqueueSource(directive.uri.stringValue, false);
        }
      } else if (directive is PartOfDirective) {
        isPart = true;
      }
    }

    // Remember library URIs, for linking and compiling.
    if (!isPart) {
      libraryUris.add(uriStr);
      librarySources.add(source);
    } else if (_expectedLibraryUris.contains(uri)) {
      _invalidLibrarySources.add(source);
    }
  }
}

class _UnitInformativeData {
  final String libraryUriStr;
  final String unitUriStr;
  final List<UnlinkedInformativeData> data;

  _UnitInformativeData(this.libraryUriStr, this.unitUriStr, this.data);
}
