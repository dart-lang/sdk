// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/restricted_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resynthesize_common.dart';
import 'test_strategies.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeAst2Test);
  });
}

@reflectiveTest
class ResynthesizeAst2Test extends ResynthesizeTestStrategyTwoPhase
    with ResynthesizeTestCases {
  /// The shared SDK bundle, computed once and shared among test invocations.
  static LinkedNodeBundle _sdkBundle;

  LinkedNodeBundle get sdkBundle {
    if (_sdkBundle != null) return _sdkBundle;

    var inputLibraries = <LinkInputLibrary>[];
    for (var sdkLibrary in sdk.sdkLibraries) {
      var source = sourceFactory.resolveUri(null, sdkLibrary.shortName);
      var text = getFile(source.fullName).readAsStringSync();
      var unit = parseText(text, featureSet);

      var inputUnits = <LinkInputUnit>[];
      _addLibraryUnits(source, unit, inputUnits);
      inputLibraries.add(
        LinkInputLibrary(source, inputUnits),
      );
    }

    var elementFactory = LinkedElementFactory(
      RestrictedAnalysisContext(
        SynchronousSession(
          AnalysisOptionsImpl(),
          declaredVariables,
        ),
        sourceFactory,
      ),
      _AnalysisSessionForLinking(),
      Reference.root(),
    );

    var sdkLinkResult = link(elementFactory, inputLibraries);

    var bytes = sdkLinkResult.bundle.toBuffer();
    return _sdkBundle = LinkedNodeBundle.fromBuffer(bytes);
  }

  @override
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors = false, bool dumpSummaries = false}) async {
    var source = addTestSource(text);

    var inputLibraries = <LinkInputLibrary>[];
    _addNonDartLibraries(Set(), inputLibraries, source);

    var analysisContext = RestrictedAnalysisContext(
      SynchronousSession(
        AnalysisOptionsImpl()..contextFeatures = featureSet,
        declaredVariables,
      ),
      sourceFactory,
    );

    var elementFactory = LinkedElementFactory(
      analysisContext,
      _AnalysisSessionForLinking(),
      Reference.root(),
    );
    elementFactory.addBundle(
      LinkedBundleContext(elementFactory, sdkBundle),
    );

    var linkResult = link(
      elementFactory,
      inputLibraries,
    );

    elementFactory.addBundle(
      LinkedBundleContext(elementFactory, linkResult.bundle),
    );

    // Set informative data.
    for (var inputLibrary in inputLibraries) {
      var libraryUriStr = '${inputLibrary.source.uri}';
      for (var inputUnit in inputLibrary.units) {
        var unitSource = inputUnit.source;
        if (unitSource != null) {
          var unitUriStr = '${unitSource.uri}';
          var informativeData = createInformativeData(inputUnit.unit);
          elementFactory.setInformativeData(
            libraryUriStr,
            unitUriStr,
            informativeData,
          );
        }
      }
    }

    if (analysisContext.typeProvider == null) {
      var dartCore = elementFactory.libraryOfUri('dart:core');
      var dartAsync = elementFactory.libraryOfUri('dart:async');
      var typeProvider = TypeProviderImpl(dartCore, dartAsync);
      analysisContext.typeProvider = typeProvider;

      dartCore.createLoadLibraryFunction(typeProvider);
      dartAsync.createLoadLibraryFunction(typeProvider);
    }

    return elementFactory.libraryOfUri('${source.uri}');
  }

  void _addLibraryUnits(
    Source definingSource,
    CompilationUnit definingUnit,
    List<LinkInputUnit> units,
  ) {
    units.add(
      LinkInputUnit(null, definingSource, false, definingUnit),
    );
    for (var directive in definingUnit.directives) {
      if (directive is PartDirective) {
        var relativeUriStr = directive.uri.stringValue;

        var partSource = sourceFactory.resolveUri(
          definingSource,
          relativeUriStr,
        );

        if (partSource != null) {
          var text = _readSafely(partSource.fullName);
          var unit = parseText(text, featureSet);
          units.add(
            LinkInputUnit(relativeUriStr, partSource, false, unit),
          );
        } else {
          var unit = parseText('', featureSet);
          units.add(
            LinkInputUnit(relativeUriStr, partSource, false, unit),
          );
        }
      }
    }
  }

  void _addNonDartLibraries(
    Set<Source> addedLibraries,
    List<LinkInputLibrary> libraries,
    Source source,
  ) {
    if (source == null ||
        source.uri.isScheme('dart') ||
        !addedLibraries.add(source)) {
      return;
    }

    var text = _readSafely(source.fullName);
    var unit = parseText(text, featureSet);

    var units = <LinkInputUnit>[];
    _addLibraryUnits(source, unit, units);
    libraries.add(
      LinkInputLibrary(source, units),
    );

    void addRelativeUriStr(StringLiteral uriNode) {
      var uriStr = uriNode.stringValue;
      var uriSource = sourceFactory.resolveUri(source, uriStr);
      _addNonDartLibraries(addedLibraries, libraries, uriSource);
    }

    for (var directive in unit.directives) {
      if (directive is NamespaceDirective) {
        addRelativeUriStr(directive.uri);
        for (var configuration in directive.configurations) {
          addRelativeUriStr(configuration.uri);
        }
      }
    }
  }

  String _readSafely(String path) {
    try {
      var file = resourceProvider.getFile(path);
      return file.readAsStringSync();
    } catch (_) {
      return '';
    }
  }
}

class _AnalysisSessionForLinking implements AnalysisSession {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
