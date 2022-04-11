// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/feature_sets.dart';
import 'test_strategies.dart';

/// A base for testing building elements.
@reflectiveTest
abstract class ElementsBaseTest with ResourceProviderMixin {
  /// The shared SDK bundle, computed once and shared among test invocations.
  static _SdkBundle? _sdkBundle;

  /// The set of features enabled in this test.
  FeatureSet featureSet = FeatureSets.latestWithExperiments;

  DeclaredVariables declaredVariables = DeclaredVariables();
  late final SourceFactory sourceFactory;
  late final FolderBasedDartSdk sdk;

  ElementsBaseTest() {
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);

    sourceFactory = SourceFactory([
      DartUriResolver(sdk),
      PackageMapUriResolver(resourceProvider, {
        'test': [
          getFolder('/home/test/lib'),
        ],
      }),
      ResourceUriResolver(resourceProvider),
    ]);
  }

  /// We need to test both cases - when we keep linking libraries (happens for
  /// new or invalidated libraries), and when we load libraries from bytes
  /// (happens internally in Blaze or when we have cached summaries).
  bool get keepLinkingLibraries;

  Future<_SdkBundle> get sdkBundle async {
    if (_sdkBundle != null) {
      return _sdkBundle!;
    }

    var featureSet = FeatureSet.latestLanguageVersion();
    var inputLibraries = <LinkInputLibrary>[];
    for (var sdkLibrary in sdk.sdkLibraries) {
      var source = sourceFactory.resolveUri(null, sdkLibrary.shortName)!;
      var text = getFile(source.fullName).readAsStringSync();
      var unit = parseText(source, text, featureSet);

      var inputUnits = <LinkInputUnit>[];
      _addLibraryUnits(source, unit, inputUnits, featureSet);
      inputLibraries.add(
        LinkInputLibrary(
          source: source,
          units: inputUnits,
        ),
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

    var sdkLinkResult = await link2(elementFactory, inputLibraries);

    return _sdkBundle = _SdkBundle(
      resolutionBytes: sdkLinkResult.resolutionBytes,
    );
  }

  String get testFilePath => '$testPackageLibPath/test.dart';

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '/home/test';

  void addSource(String path, String contents) {
    newFile2(path, contents);
  }

  Future<LibraryElementImpl> buildLibrary(
    String text, {
    bool allowErrors = false,
    bool dumpSummaries = false,
  }) async {
    var testFile = newFile2(testFilePath, text);
    var testUri = sourceFactory.pathToUri(testFile.path)!;
    var testSource = sourceFactory.forUri2(testUri)!;

    var inputLibraries = <LinkInputLibrary>[];
    _addNonDartLibraries({}, inputLibraries, testSource);

    var unitsInformativeBytes = <Uri, Uint8List>{};
    for (var inputLibrary in inputLibraries) {
      for (var inputUnit in inputLibrary.units) {
        var informativeBytes = writeUnitInformative(inputUnit.unit);
        unitsInformativeBytes[inputUnit.uri] = informativeBytes;
      }
    }

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
        unitsInformativeBytes: {},
        resolutionBytes: (await sdkBundle).resolutionBytes,
      ),
    );

    var linkResult = await link2(elementFactory, inputLibraries);

    if (!keepLinkingLibraries) {
      elementFactory.removeBundle(
        inputLibraries.map((e) => e.uriStr).toSet(),
      );
      elementFactory.addBundle(
        BundleReader(
          elementFactory: elementFactory,
          unitsInformativeBytes: unitsInformativeBytes,
          resolutionBytes: linkResult.resolutionBytes,
        ),
      );
    }

    return elementFactory.libraryOfUri2('$testUri');
  }

  void _addLibraryUnits(
    Source definingSource,
    CompilationUnit definingUnit,
    List<LinkInputUnit> units,
    FeatureSet featureSet,
  ) {
    units.add(
      LinkInputUnit(
        partDirectiveIndex: null,
        source: definingSource,
        isSynthetic: false,
        unit: definingUnit,
      ),
    );

    var partDirectiveIndex = -1;
    for (var directive in definingUnit.directives) {
      if (directive is PartDirective) {
        ++partDirectiveIndex;
        var relativeUriStr = directive.uri.stringValue;

        var partSource = sourceFactory.resolveUri(
          definingSource,
          relativeUriStr,
        );

        if (partSource != null) {
          var text = _readSafely(partSource.fullName);
          var unit = parseText(partSource, text, featureSet);
          units.add(
            LinkInputUnit(
              partDirectiveIndex: partDirectiveIndex,
              partUriStr: relativeUriStr,
              source: partSource,
              isSynthetic: false,
              unit: unit,
            ),
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
    if (source.uri.isScheme('dart') || !addedLibraries.add(source)) {
      return;
    }

    var text = _readSafely(source.fullName);
    var unit = parseText(source, text, featureSet);

    var units = <LinkInputUnit>[];
    _addLibraryUnits(source, unit, units, featureSet);
    libraries.add(
      LinkInputLibrary(
        source: source,
        units: units,
      ),
    );

    void addRelativeUriStr(StringLiteral uriNode) {
      var relativeUriStr = uriNode.stringValue;
      if (relativeUriStr == null) {
        return;
      }

      Uri relativeUri;
      try {
        relativeUri = Uri.parse(relativeUriStr);
      } on FormatException {
        return;
      }

      var absoluteUri = resolveRelativeUri(source.uri, relativeUri);
      var rewrittenUri = rewriteToCanonicalUri(sourceFactory, absoluteUri);
      if (rewrittenUri == null) {
        return;
      }

      var uriSource = sourceFactory.forUri2(rewrittenUri);
      if (uriSource == null) {
        return;
      }

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
  final Uint8List resolutionBytes;

  _SdkBundle({
    required this.resolutionBytes,
  });
}
