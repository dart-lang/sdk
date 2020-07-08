// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Build summary for SDK at the given [sdkPath].
///
/// If [embedderYamlPath] is provided, then libraries from this file are
/// appended to the libraries of the specified SDK.
Uint8List buildSdkSummary({
  @required ResourceProvider resourceProvider,
  @required String sdkPath,
  String embedderYamlPath,
}) {
  var sdk = FolderBasedDartSdk(
    resourceProvider,
    resourceProvider.getFolder(sdkPath),
  );
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

class _Builder {
  final AnalysisContext context;
  final String allowedExperimentsJson;
  final Iterable<Source> librarySources;

  final Set<String> libraryUris = <String>{};
  final List<LinkInputLibrary> inputLibraries = [];

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
  Uint8List build() {
    librarySources.forEach(_addLibrary);

    var elementFactory = LinkedElementFactory(
      context,
      AnalysisSessionImpl(null),
      Reference.root(),
    );

    var linkResult = link(elementFactory, inputLibraries);
    bundleAssembler.setBundle2(linkResult.bundle);

    var buffer = PackageBundleBuilder(
      bundle2: linkResult.bundle,
      sdk: PackageBundleSdkBuilder(
        allowedExperimentsJson: allowedExperimentsJson,
      ),
    ).toBuffer();

    return buffer is Uint8List ? buffer : Uint8List.fromList(buffer);
  }

  void _addLibrary(Source source) {
    String uriStr = source.uri.toString();
    if (!libraryUris.add(uriStr)) {
      return;
    }

    var inputUnits = <LinkInputUnit>[];

    CompilationUnit definingUnit = _parse(source);
    inputUnits.add(
      LinkInputUnit(null, source, false, definingUnit),
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
          LinkInputUnit(partUri, partSource, false, partUnit),
        );
      }
    }

    inputLibraries.add(
      LinkInputLibrary(source, inputUnits),
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
