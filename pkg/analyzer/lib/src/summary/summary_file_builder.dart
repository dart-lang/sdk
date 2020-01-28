// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary2/link.dart' as summary2;
import 'package:analyzer/src/summary2/linked_element_factory.dart' as summary2;
import 'package:analyzer/src/summary2/reference.dart' as summary2;
import 'package:meta/meta.dart';

class SummaryBuilder {
  final Iterable<Source> librarySources;
  final AnalysisContext context;

  /**
   * Create a summary builder for these [librarySources] and [context].
   */
  SummaryBuilder(this.librarySources, this.context);

  /**
   * Create an SDK summary builder for the dart SDK at the given [sdkPath].
   */
  factory SummaryBuilder.forSdk(String sdkPath) {
    //
    // Prepare SDK.
    //
    ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    FolderBasedDartSdk sdk = FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(sdkPath));
    sdk.useSummary = false;
    sdk.analysisOptions = AnalysisOptionsImpl();

    //
    // Prepare 'dart:' URIs to serialize.
    //
    Set<String> uriSet =
        sdk.sdkLibraries.map((SdkLibrary library) => library.shortName).toSet();
    uriSet.add('dart:html_common/html_common_dart2js.dart');

    Set<Source> librarySources = HashSet<Source>();
    for (String uri in uriSet) {
      librarySources.add(sdk.mapDartUri(uri));
    }

    return SummaryBuilder(librarySources, sdk.context);
  }

  /**
   * Build the linked bundle and return its bytes.
   */
  List<int> build({
    @required FeatureSet featureSet,
  }) {
    return _Builder(context, featureSet, librarySources).build();
  }
}

class _Builder {
  final AnalysisContext context;
  final FeatureSet featureSet;
  final Iterable<Source> librarySources;

  final Set<String> libraryUris = <String>{};
  final List<summary2.LinkInputLibrary> inputLibraries = [];

  final PackageBundleAssembler bundleAssembler = PackageBundleAssembler();

  _Builder(this.context, this.featureSet, this.librarySources);

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

  CompilationUnit _parse(Source source) {
    AnalysisErrorListener errorListener = AnalysisErrorListener.NULL_LISTENER;
    String code = source.contents.data;
    CharSequenceReader reader = CharSequenceReader(code);
    Scanner scanner = Scanner(source, reader, errorListener)
      ..configureFeatures(featureSet);
    Token token = scanner.tokenize();
    LineInfo lineInfo = LineInfo(scanner.lineStarts);
    Parser parser = Parser(source, errorListener,
        featureSet: scanner.featureSet,
        useFasta: context.analysisOptions.useFastaParser);
    parser.enableOptionalNewAndConst = true;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }
}
