// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';
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

  @override
  bool get isAstBasedSummary => true;

  LinkedNodeBundle get sdkBundle {
    if (_sdkBundle != null) return _sdkBundle;

    var inputLibraries = <LinkInputLibrary>[];
    for (var sdkLibrary in sdk.sdkLibraries) {
      var source = sourceFactory.resolveUri(null, sdkLibrary.shortName);
      var text = getFile(source.fullName).readAsStringSync();
      var unit = parseText(text);

      var inputUnits = <LinkInputUnit>[];
      _addLibraryUnits(source, unit, inputUnits);
      inputLibraries.add(
        LinkInputLibrary(source, inputUnits),
      );
    }

    var sdkLinkResult = link(
      AnalysisOptionsImpl(),
      sourceFactory,
      declaredVariables,
      [],
      inputLibraries,
    );

    var bytes = sdkLinkResult.bundle.toBuffer();
    return _sdkBundle = LinkedNodeBundle.fromBuffer(bytes);
  }

  @override
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors = false, bool dumpSummaries = false}) async {
    var source = addTestSource(text);

    var inputLibraries = <LinkInputLibrary>[];
    _addNonDartLibraries(Set(), inputLibraries, source);

    var linkResult = link(
      AnalysisOptionsImpl(),
      sourceFactory,
      declaredVariables,
      [sdkBundle],
      inputLibraries,
    );

    var analysisContext = _FakeAnalysisContext(sourceFactory);

    var rootReference = Reference.root();
    rootReference.getChild('dart:core').getChild('dynamic').element =
        DynamicElementImpl.instance;

    var elementFactory = LinkedElementFactory(
      analysisContext,
      null,
      rootReference,
    );
    elementFactory.addBundle(
      LinkedBundleContext(elementFactory, sdkBundle),
    );
    elementFactory.addBundle(
      LinkedBundleContext(elementFactory, linkResult.bundle),
    );

    var dartCore = elementFactory.libraryOfUri('dart:core');
    var dartAsync = elementFactory.libraryOfUri('dart:async');
    var typeProvider = SummaryTypeProvider()
      ..initializeCore(dartCore)
      ..initializeAsync(dartAsync);
    analysisContext.typeProvider = typeProvider;
    analysisContext.typeSystem = Dart2TypeSystem(typeProvider);

    dartCore.createLoadLibraryFunction(typeProvider);
    dartAsync.createLoadLibraryFunction(typeProvider);

    return elementFactory.libraryOfUri('${source.uri}');
  }

  @override
  @failingTest
  test_const_constructor_inferred_args() async {
    await super.test_const_constructor_inferred_args();
  }

  @override
  @failingTest
  test_implicitConstructor_named_const() async {
    await super.test_implicitConstructor_named_const();
  }

  @override
  @failingTest
  test_import_short_absolute() async {
    // TODO(scheglov) fails on Windows
    fail('test_import_short_absolute on Windows');
//    await super.test_import_short_absolute();
  }

  @override
  @failingTest
  test_inferredType_implicitCreation() async {
    await super.test_inferredType_implicitCreation();
  }

  @override
  @failingTest
  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    // TODO(scheglov) unexpectedly passes on Windows
    fail('unexpectedly passes on Windows');
//    await super.test_nameConflict_importWithRelativeUri_exportWithAbsolute();
  }

  @override
  @failingTest
  test_parameter_covariant_inherited() async {
    await super.test_parameter_covariant_inherited();
  }

  @override
  @failingTest
  test_syntheticFunctionType_genericClosure() async {
    // TODO(scheglov) Bug in TypeSystem.getLeastUpperBound().
    // LUB(<T>(T) → int, <T>(T) → int) gives `(T) → int`, note absence of `<T>`.
    await super.test_syntheticFunctionType_genericClosure();
  }

  void _addLibraryUnits(
    Source definingSource,
    CompilationUnit definingUnit,
    List<LinkInputUnit> units,
  ) {
    units.add(
      LinkInputUnit(definingSource, definingUnit),
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
          var unit = parseText(text, experimentStatus: experimentStatus);
          units.add(
            LinkInputUnit(partSource, unit),
          );
        } else {
          var unit = parseText('', experimentStatus: experimentStatus);
          units.add(
            LinkInputUnit(partSource, unit),
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
    var unit = parseText(text, experimentStatus: experimentStatus);

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

class _FakeAnalysisContext implements AnalysisContext {
  final SourceFactory sourceFactory;
  TypeProvider typeProvider;
  Dart2TypeSystem typeSystem;

  _FakeAnalysisContext(this.sourceFactory);

  @override
  AnalysisOptions get analysisOptions {
    return AnalysisOptionsImpl();
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
