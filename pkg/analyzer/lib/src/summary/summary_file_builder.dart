// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.summary_file_builder;

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';

class SummaryBuilder {
  final Iterable<Source> librarySources;
  final AnalysisContext context;
  final bool strong;

  /**
   * Create a summary builder for these [librarySources] and [context].
   */
  SummaryBuilder(this.librarySources, this.context, this.strong);

  /**
   * Create an SDK summary builder for the dart SDK at the given [sdkPath].
   */
  factory SummaryBuilder.forSdk(String sdkPath, bool strong) {
    //
    // Prepare SDK.
    //
    ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    FolderBasedDartSdk sdk = new FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(sdkPath), strong);
    sdk.useSummary = false;
    sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = strong;

    //
    // Prepare 'dart:' URIs to serialize.
    //
    Set<String> uriSet =
        sdk.sdkLibraries.map((SdkLibrary library) => library.shortName).toSet();
    if (!strong) {
      uriSet.add('dart:html/nativewrappers.dart');
    }
    uriSet.add('dart:html_common/html_common_dart2js.dart');

    Set<Source> librarySources = new HashSet<Source>();
    for (String uri in uriSet) {
      librarySources.add(sdk.mapDartUri(uri));
    }

    return new SummaryBuilder(librarySources, sdk.context, strong);
  }

  /**
   * Build the linked bundle and return its bytes.
   */
  List<int> build() => new _Builder(context, librarySources).build();
}

class _Builder {
  final AnalysisContext context;
  final Iterable<Source> librarySources;

  final Set<Source> processedSources = new Set<Source>();
  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();

  _Builder(this.context, this.librarySources);

  /**
   * Build the linked bundle and return its bytes.
   */
  List<int> build() {
    librarySources.forEach(_serializeLibrary);
    return bundleAssembler.assemble().toBuffer();
  }

  /**
   * Serialize the library with the given [source] and all its direct or
   * indirect imports and exports.
   */
  void _serializeLibrary(Source source) {
    if (!processedSources.add(source)) {
      return;
    }
    LibraryElement element = context.computeLibraryElement(source);
    bundleAssembler.serializeLibraryElement(element);
    element.importedLibraries.forEach((e) => _serializeLibrary(e.source));
    element.exportedLibraries.forEach((e) => _serializeLibrary(e.source));
  }
}
