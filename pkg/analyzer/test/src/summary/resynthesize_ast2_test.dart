// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resynthesize_common.dart';
import 'test_strategies.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeAst2Test);
  });
}

@reflectiveTest
class ResynthesizeAst2Test extends AbstractResynthesizeTest
    with ResynthesizeTestCases {
  /// The shared SDK bundle, computed once and shared among test invocations.
  static _SdkBundle _sdkBundle;

  _SdkBundle get sdkBundle {
    if (_sdkBundle != null) {
      return _sdkBundle;
    }

    var featureSet = FeatureSet.latestLanguageVersion();
    var inputLibraries = <LinkInputLibrary>[];
    for (var sdkLibrary in sdk.sdkLibraries) {
      var source = sourceFactory.resolveUri(null, sdkLibrary.shortName);
      var text = getFile(source.fullName).readAsStringSync();
      var unit = parseText(text, featureSet);

      var inputUnits = <LinkInputUnit>[];
      _addLibraryUnits(source, unit, inputUnits, featureSet);
      inputLibraries.add(
        LinkInputLibrary(source, inputUnits),
      );
    }

    var elementFactory = LinkedElementFactory(
      AnalysisContextImpl(
        SynchronousSession(
          AnalysisOptionsImpl(),
          declaredVariables,
        ),
        sourceFactory,
      ),
      _AnalysisSessionForLinking(),
      Reference.root(),
    );

    var sdkLinkResult = link(elementFactory, inputLibraries, true);

    return _sdkBundle = _SdkBundle(
      astBytes: sdkLinkResult.astBytes,
      resolutionBytes: sdkLinkResult.resolutionBytes,
    );
  }

  @override
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors = false, bool dumpSummaries = false}) async {
    var source = addTestSource(text);

    var inputLibraries = <LinkInputLibrary>[];
    _addNonDartLibraries({}, inputLibraries, source);

    var analysisContext = AnalysisContextImpl(
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
      BundleReader(
        elementFactory: elementFactory,
        astBytes: sdkBundle.astBytes,
        resolutionBytes: sdkBundle.resolutionBytes,
      ),
    );

    var linkResult = NullSafetyUnderstandingFlag.enableNullSafetyTypes(
      () {
        return link(elementFactory, inputLibraries, true);
      },
    );

    elementFactory.addBundle(
      BundleReader(
        elementFactory: elementFactory,
        astBytes: linkResult.astBytes,
        resolutionBytes: linkResult.resolutionBytes,
      ),
    );

    return elementFactory.libraryOfUri('${source.uri}');
  }

  void setUp() {
    featureSet = FeatureSets.nullSafe;
  }

  void _addLibraryUnits(
    Source definingSource,
    CompilationUnit definingUnit,
    List<LinkInputUnit> units,
    FeatureSet featureSet,
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
    _addLibraryUnits(source, unit, units, featureSet);
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

class _AnalysisSessionForLinking implements AnalysisSessionImpl {
  @override
  final ClassHierarchy classHierarchy = ClassHierarchy();

  @override
  InheritanceManager3 inheritanceManager = InheritanceManager3();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SdkBundle {
  final Uint8List astBytes;
  final Uint8List resolutionBytes;

  _SdkBundle({
    @required this.astBytes,
    @required this.resolutionBytes,
  });
}
