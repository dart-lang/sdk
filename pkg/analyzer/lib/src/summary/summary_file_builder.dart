// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary2/link.dart' as summary2;
import 'package:analyzer/src/summary2/linked_element_factory.dart' as summary2;
import 'package:analyzer/src/summary2/reference.dart' as summary2;
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Build summary for SDK the at the given [sdkPath].
///
/// If [embedderYamlPath] is provided, then libraries from this file are
/// appended to the libraries of the specified SDK.
List<int> buildSdkSummary({
  @required ResourceProvider resourceProvider,
  @required String sdkPath,
  String embedderYamlPath,
}) {
  var sdk = FolderBasedDartSdk(
    resourceProvider,
    resourceProvider.getFolder(sdkPath),
  );
  sdk.useSummary = false;
  sdk.analysisOptions = AnalysisOptionsImpl();

  // Append libraries from the embedder.
  if (embedderYamlPath != null) {
    var file = resourceProvider.getFile(embedderYamlPath);
    var content = file.readAsStringSync();
    var map = loadYaml(content) as YamlMap;
    var embedderSdk = EmbedderSdk(resourceProvider, {file.parent: map});
    for (var library in embedderSdk.sdkLibraries) {
      var uriStr = library.shortName;
      if (sdk.libraryMap.getLibrary(uriStr) == null) {
        sdk.libraryMap.setLibrary(uriStr, library);
      }
    }
  }

  var librarySources = sdk.sdkLibraries.map((e) {
    return sdk.mapDartUri(e.shortName);
  }).toList();

  return _Builder(
    sdk.context,
    sdk.allowedExperimentsJson,
    librarySources,
  ).build();
}

@Deprecated('Use buildSdkSummary()')
class SummaryBuilder {
  final ResourceProvider resourceProvider;
  final String sdkPath;

  /// The list of SDK summaries, might also include Flutter libraries.
  /// Used for backward compatibility with `build_resolvers`.
  /// TODO(scheglov) Create a better API for this, and remove it.
  Iterable<Source> _librarySources;

  /// The formal analysis context.
  /// Used for backward compatibility with `build_resolvers`.
  /// TODO(scheglov) Remove it.
  AnalysisContext _context;

  /// Create a summary builder for these [librarySources] and [context].
  SummaryBuilder(Iterable<Source> librarySources, AnalysisContext context)
      : _librarySources = librarySources,
        _context = context,
        resourceProvider = PhysicalResourceProvider.INSTANCE,
        sdkPath = null;

  factory SummaryBuilder.forSdk(String sdkPath) {
    return SummaryBuilder.forSdk2(
      resourceProvider: PhysicalResourceProvider.INSTANCE,
      sdkPath: sdkPath,
    );
  }

  SummaryBuilder.forSdk2({
    @required this.resourceProvider,
    @required this.sdkPath,
  });

  /// Build the linked bundle and return its bytes.
  List<int> build({@deprecated FeatureSet featureSet}) {
    if (_librarySources != null) {
      return _build();
    }

    return buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkPath,
    );
  }

  /// The implementation that provides backward compatibility for
  /// `build_resolvers`.
  List<int> _build() {
    var dartCorePath = _librarySources
        .singleWhere((element) => '${element.uri}' == 'dart:core')
        .fullName;
    var sdkLib = resourceProvider.getFile(dartCorePath).parent.parent;

    String allowedExperimentsJson;
    try {
      allowedExperimentsJson = sdkLib
          .getChildAssumingFolder('_internal')
          .getChildAssumingFile('allowed_experiments.json')
          .readAsStringSync();
    } catch (_) {}

    return _Builder(
      _context,
      allowedExperimentsJson,
      _librarySources,
    ).build();
  }
}

class _Builder {
  final AnalysisContext context;
  final String allowedExperimentsJson;
  final Iterable<Source> librarySources;

  final Set<String> libraryUris = <String>{};
  final List<summary2.LinkInputLibrary> inputLibraries = [];

  AllowedExperiments allowedExperiments;
  final PackageBundleAssembler bundleAssembler = PackageBundleAssembler();

  _Builder(
    this.context,
    this.allowedExperimentsJson,
    this.librarySources,
  ) {
    allowedExperiments = _parseAllowedExperiments(allowedExperimentsJson);
  }

  /// Build the linked bundle and return its bytes.
  List<int> build() {
    librarySources.forEach(_addLibrary);

    var elementFactory = summary2.LinkedElementFactory(
      context,
      AnalysisSessionImpl(null),
      summary2.Reference.root(),
    );

    var linkResult = summary2.link(elementFactory, inputLibraries);
    bundleAssembler.setBundle2(linkResult.bundle);

    return PackageBundleBuilder(
      bundle2: linkResult.bundle,
      sdk: PackageBundleSdkBuilder(
        allowedExperimentsJson: allowedExperimentsJson,
      ),
    ).toBuffer();
  }

  void _addLibrary(Source source) {
    String uriStr = source.uri.toString();
    if (!libraryUris.add(uriStr)) {
      return;
    }

    var inputUnits = <summary2.LinkInputUnit>[];

    CompilationUnit definingUnit = _parse(source);
    inputUnits.add(
      summary2.LinkInputUnit(null, source, false, definingUnit),
    );

    for (Directive directive in definingUnit.directives) {
      if (directive is NamespaceDirective) {
        String libUri = directive.uri.stringValue;
        Source libSource = context.sourceFactory.resolveUri(source, libUri);
        _addLibrary(libSource);
      } else if (directive is PartDirective) {
        String partUri = directive.uri.stringValue;
        Source partSource = context.sourceFactory.resolveUri(source, partUri);
        CompilationUnit partUnit = _parse(partSource);
        inputUnits.add(
          summary2.LinkInputUnit(partUri, partSource, false, partUnit),
        );
      }
    }

    inputLibraries.add(
      summary2.LinkInputLibrary(source, inputUnits),
    );
  }

  /// Return the [FeatureSet] for the given [uri], must be a `dart:` URI.
  FeatureSet _featureSet(Uri uri) {
    if (uri.isScheme('dart')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var libraryName = pathSegments.first;
        var experiments = allowedExperiments.forSdkLibrary(libraryName);
        return FeatureSet.fromEnableFlags(experiments);
      }
    }
    throw StateError('Expected a valid dart: URI: $uri');
  }

  CompilationUnit _parse(Source source) {
    var result = parseString(
      content: source.contents.data,
      featureSet: _featureSet(source.uri),
      throwIfDiagnostics: false,
    );

    if (result.errors.isNotEmpty) {
      var errorsStr = result.errors.map((e) {
        var location = result.lineInfo.getLocation(e.offset);
        return '${source.fullName}:$location - ${e.message}';
      }).join('\n');
      throw StateError(
        'Unexpected diagnostics:\n$errorsStr',
      );
    }

    var unit = result.unit as CompilationUnitImpl;
    unit.languageVersion = LibraryLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: null,
    );

    return result.unit;
  }

  static AllowedExperiments _parseAllowedExperiments(String content) {
    if (content == null) {
      return AllowedExperiments(
        sdkDefaultExperiments: [],
        sdkLibraryExperiments: {},
        packageExperiments: {},
      );
    }

    return parseAllowedExperiments(content);
  }
}
