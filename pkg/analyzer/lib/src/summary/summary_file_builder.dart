// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary2/link.dart' as summary2;
import 'package:analyzer/src/summary2/linked_element_factory.dart' as summary2;
import 'package:analyzer/src/summary2/reference.dart' as summary2;
import 'package:meta/meta.dart';

List<int> buildSdkSummary({
  @required ResourceProvider resourceProvider,
  @required String sdkPath,
}) {
  //
  // Prepare SDK.
  //
  FolderBasedDartSdk sdk =
      FolderBasedDartSdk(resourceProvider, resourceProvider.getFolder(sdkPath));
  sdk.useSummary = false;
  sdk.analysisOptions = AnalysisOptionsImpl();

  //
  // Prepare 'dart:' URIs to serialize.
  //
  Set<String> uriSet =
      sdk.sdkLibraries.map((SdkLibrary library) => library.shortName).toSet();
  // TODO(scheglov) Why do we need it?
  uriSet.add('dart:html_common/html_common_dart2js.dart');

  Set<Source> librarySources = HashSet<Source>();
  for (String uri in uriSet) {
    var source = sdk.mapDartUri(uri);
    // TODO(scheglov) Fix the previous TODO and remove this check.
    if (source != null) {
      librarySources.add(source);
    }
  }

  var allowedExperiments = AllowedExperiments(
    sdkDefaultExperiments: [],
    sdkLibraryExperiments: {},
    packageExperiments: {},
  );
  try {
    var experimentsContent = sdk.directory
        .getChildAssumingFolder('lib')
        .getChildAssumingFolder('_internal')
        .getChildAssumingFile('allowed_experiments.json')
        .readAsStringSync();
    allowedExperiments = parseAllowedExperiments(experimentsContent);
  } catch (_) {}

  return _Builder(sdk.context, allowedExperiments, librarySources).build();
}

@Deprecated('Use buildSdkSummary()')
class SummaryBuilder {
  final ResourceProvider resourceProvider;
  final String sdkPath;

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

  /**
   * Build the linked bundle and return its bytes.
   */
  List<int> build() {
    return buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkPath,
    );
  }
}

class _Builder {
  final AnalysisContext context;
  final AllowedExperiments allowedExperiments;
  final Iterable<Source> librarySources;

  final Set<String> libraryUris = <String>{};
  final List<summary2.LinkInputLibrary> inputLibraries = [];

  final PackageBundleAssembler bundleAssembler = PackageBundleAssembler();

  _Builder(this.context, this.allowedExperiments, this.librarySources);

  /**
   * Build the linked bundle and return its bytes.
   */
  List<int> build() {
    librarySources.forEach(_addLibrary);

    var elementFactory = summary2.LinkedElementFactory(
      context,
      AnalysisSessionImpl(null),
      summary2.Reference.root(),
    );

    var linkResult = summary2.link(elementFactory, inputLibraries);
    bundleAssembler.setBundle2(linkResult.bundle);

    return bundleAssembler.assemble().toBuffer();
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

    return result.unit;
  }
}
