// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';

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
    FolderBasedDartSdk sdk = new FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(sdkPath), true);
    sdk.useSummary = false;
    sdk.analysisOptions = new AnalysisOptionsImpl();

    //
    // Prepare 'dart:' URIs to serialize.
    //
    Set<String> uriSet =
        sdk.sdkLibraries.map((SdkLibrary library) => library.shortName).toSet();
    uriSet.add('dart:html_common/html_common_dart2js.dart');

    Set<Source> librarySources = new HashSet<Source>();
    for (String uri in uriSet) {
      librarySources.add(sdk.mapDartUri(uri));
    }

    return new SummaryBuilder(librarySources, sdk.context);
  }

  /**
   * Build the linked bundle and return its bytes.
   */
  List<int> build() => new _Builder(context, librarySources).build();
}

class _Builder {
  final AnalysisContext context;
  final Iterable<Source> librarySources;

  final Set<String> libraryUris = new Set<String>();
  final Map<String, UnlinkedUnit> unlinkedMap = <String, UnlinkedUnit>{};

  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();

  _Builder(this.context, this.librarySources);

  /**
   * Build the linked bundle and return its bytes.
   */
  List<int> build() {
    librarySources.forEach(_addLibrary);

    Map<String, LinkedLibraryBuilder> map = link(libraryUris, (uri) {
      throw new StateError('Unexpected call to GetDependencyCallback($uri).');
    }, (uri) {
      UnlinkedUnit unlinked = unlinkedMap[uri];
      if (unlinked == null) {
        throw new StateError('Unable to find unresolved unit $uri.');
      }
      return unlinked;
    }, DeclaredVariables(), context.analysisOptions);
    map.forEach(bundleAssembler.addLinkedLibrary);

    return bundleAssembler.assemble().toBuffer();
  }

  void _addLibrary(Source source) {
    String uriStr = source.uri.toString();
    if (!libraryUris.add(uriStr)) {
      return;
    }
    CompilationUnit unit = _addUnlinked(source);
    for (Directive directive in unit.directives) {
      if (directive is NamespaceDirective) {
        String libUri = directive.uri.stringValue;
        Source libSource = context.sourceFactory.resolveUri(source, libUri);
        _addLibrary(libSource);
      } else if (directive is PartDirective) {
        String partUri = directive.uri.stringValue;
        Source partSource = context.sourceFactory.resolveUri(source, partUri);
        _addUnlinked(partSource);
      }
    }
  }

  CompilationUnit _addUnlinked(Source source) {
    String uriStr = source.uri.toString();
    CompilationUnit unit = _parse(source);
    UnlinkedUnitBuilder unlinked = serializeAstUnlinked(unit);
    unlinkedMap[uriStr] = unlinked;
    bundleAssembler.addUnlinkedUnit(source, unlinked);
    return unit;
  }

  CompilationUnit _parse(Source source) {
    AnalysisErrorListener errorListener = AnalysisErrorListener.NULL_LISTENER;
    String code = source.contents.data;
    CharSequenceReader reader = new CharSequenceReader(code);
    // TODO(paulberry): figure out the appropriate featureSet to use here
    var featureSet = FeatureSet.fromEnableFlags([]);
    Scanner scanner = new Scanner(source, reader, errorListener)
      ..configureFeatures(featureSet);
    Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);
    Parser parser = new Parser(source, errorListener,
        featureSet: featureSet,
        useFasta: context.analysisOptions.useFastaParser);
    parser.enableOptionalNewAndConst = true;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }
}
