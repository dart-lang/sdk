// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as driver;
import 'package:analyzer/src/dart/analysis/uri_converter.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';

/// A concrete implementation of an analysis session.
class AnalysisSessionImpl implements AnalysisSession {
  /// The analysis driver performing analysis for this session.
  final driver.AnalysisDriver _driver;

  /// The URI converter used to convert between URI's and file paths.
  UriConverter? _uriConverter;

  /// The cache of libraries for URIs.
  final Map<String, LibraryElement> _uriToLibraryCache = {};

  ClassHierarchy classHierarchy = ClassHierarchy();
  InheritanceManager3 inheritanceManager = InheritanceManager3();

  /// Initialize a newly created analysis session.
  AnalysisSessionImpl(this._driver);

  @override
  AnalysisContext get analysisContext => _driver.analysisContext!;

  @override
  DeclaredVariables get declaredVariables => _driver.declaredVariables;

  @override
  ResourceProvider get resourceProvider => _driver.resourceProvider;

  @override
  UriConverter get uriConverter {
    return _uriConverter ??= DriverBasedUriConverter(_driver);
  }

  /// Clear hierarchies, to reduce memory consumption.
  void clearHierarchies() {
    classHierarchy = ClassHierarchy();
    inheritanceManager = InheritanceManager3();
  }

  @deprecated
  driver.AnalysisDriver getDriver() => _driver;

  @Deprecated('Use getErrors2() instead')
  @override
  Future<ErrorsResult> getErrors(String path) {
    _checkConsistency();
    return _driver.getErrors(path);
  }

  @override
  Future<SomeErrorsResult> getErrors2(String path) {
    _checkConsistency();
    return _driver.getErrors2(path);
  }

  @Deprecated('Use getFile2() instead')
  @override
  FileResult getFile(String path) {
    _checkConsistency();
    return _driver.getFileSync(path);
  }

  @override
  SomeFileResult getFile2(String path) {
    _checkConsistency();
    return _driver.getFileSync2(path);
  }

  @Deprecated('Use getLibraryByUri2() instead')
  @override
  Future<LibraryElement> getLibraryByUri(String uri) async {
    _checkConsistency();
    var libraryElement = _uriToLibraryCache[uri];
    if (libraryElement == null) {
      libraryElement = await _driver.getLibraryByUri(uri);
      _uriToLibraryCache[uri] = libraryElement;
    }
    return libraryElement;
  }

  @override
  Future<SomeLibraryElementResult> getLibraryByUri2(String uri) {
    _checkConsistency();
    return _driver.getLibraryByUri2(uri);
  }

  @Deprecated('Use getParsedLibrary2() instead')
  @override
  ParsedLibraryResult getParsedLibrary(String path) {
    _checkConsistency();
    return _driver.getParsedLibrary(path);
  }

  @override
  SomeParsedLibraryResult getParsedLibrary2(String path) {
    _checkConsistency();
    return _driver.getParsedLibrary2(path);
  }

  @Deprecated('Use getParsedLibraryByElement2() instead')
  @override
  ParsedLibraryResult getParsedLibraryByElement(LibraryElement element) {
    _checkConsistency();
    _checkElementOfThisSession(element);
    return _driver.getParsedLibraryByUri(element.source.uri);
  }

  @override
  SomeParsedLibraryResult getParsedLibraryByElement2(LibraryElement element) {
    _checkConsistency();

    if (element.session != this) {
      return NotElementOfThisSessionResult();
    }

    return _driver.getParsedLibraryByUri2(element.source.uri);
  }

  @Deprecated('Use getParsedUnit2() instead')
  @override
  ParsedUnitResult getParsedUnit(String path) {
    _checkConsistency();
    return _driver.parseFileSync(path);
  }

  @override
  SomeParsedUnitResult getParsedUnit2(String path) {
    _checkConsistency();
    return _driver.parseFileSync2(path);
  }

  @Deprecated('Use getResolvedLibrary2() instead')
  @override
  Future<ResolvedLibraryResult> getResolvedLibrary(String path) {
    _checkConsistency();
    return _driver.getResolvedLibrary(path);
  }

  @override
  Future<SomeResolvedLibraryResult> getResolvedLibrary2(String path) {
    _checkConsistency();
    return _driver.getResolvedLibrary2(path);
  }

  @Deprecated('Use getResolvedLibraryByElement2() instead')
  @override
  Future<ResolvedLibraryResult> getResolvedLibraryByElement(
      LibraryElement element) {
    _checkConsistency();
    _checkElementOfThisSession(element);
    return _driver.getResolvedLibraryByUri(element.source.uri);
  }

  @override
  Future<SomeResolvedLibraryResult> getResolvedLibraryByElement2(
    LibraryElement element,
  ) {
    _checkConsistency();

    if (element.session != this) {
      return Future.value(
        NotElementOfThisSessionResult(),
      );
    }

    return _driver.getResolvedLibraryByUri2(element.source.uri);
  }

  @Deprecated('Use getResolvedUnit2() instead')
  @override
  Future<ResolvedUnitResult> getResolvedUnit(String path) {
    _checkConsistency();
    return _driver.getResult(path);
  }

  @override
  Future<SomeResolvedUnitResult> getResolvedUnit2(String path) {
    _checkConsistency();
    return _driver.getResult2(path);
  }

  @Deprecated('Use getFile2() instead')
  @override
  Future<SourceKind?> getSourceKind(String path) {
    _checkConsistency();
    return _driver.getSourceKind(path);
  }

  @Deprecated('Use getUnitElement2() instead')
  @override
  Future<UnitElementResult> getUnitElement(String path) {
    _checkConsistency();
    return _driver.getUnitElement(path);
  }

  @override
  Future<SomeUnitElementResult> getUnitElement2(String path) {
    _checkConsistency();
    return _driver.getUnitElement2(path);
  }

  @Deprecated('This method is not used and will be removed')
  @override
  Future<String> getUnitElementSignature(String path) {
    _checkConsistency();
    return _driver.getUnitElementSignature(path);
  }

  /// Check to see that results from this session will be consistent, and throw
  /// an [InconsistentAnalysisException] if they might not be.
  void _checkConsistency() {
    if (_driver.currentSession != this) {
      throw InconsistentAnalysisException();
    }
  }

  void _checkElementOfThisSession(Element element) {
    if (element.session != this) {
      var elementStr = element.getDisplayString(withNullability: true);
      throw ArgumentError(
          '(${element.runtimeType}) $elementStr was not produced by '
          'this session.');
    }
  }
}

/// Data structure containing information about the analysis session that is
/// available synchronously.
class SynchronousSession {
  AnalysisOptionsImpl _analysisOptions;

  final DeclaredVariables declaredVariables;

  TypeProviderImpl? _typeProviderLegacy;
  TypeProviderImpl? _typeProviderNonNullableByDefault;

  TypeSystemImpl? _typeSystemLegacy;
  TypeSystemImpl? _typeSystemNonNullableByDefault;

  SynchronousSession(this._analysisOptions, this.declaredVariables);

  AnalysisOptionsImpl get analysisOptions => _analysisOptions;

  set analysisOptions(AnalysisOptionsImpl analysisOptions) {
    _analysisOptions = analysisOptions;

    _typeSystemLegacy?.updateOptions(
      implicitCasts: analysisOptions.implicitCasts,
      strictInference: analysisOptions.strictInference,
    );

    _typeSystemNonNullableByDefault?.updateOptions(
      implicitCasts: analysisOptions.implicitCasts,
      strictInference: analysisOptions.strictInference,
    );
  }

  bool get hasTypeProvider => _typeProviderNonNullableByDefault != null;

  TypeProviderImpl get typeProviderLegacy {
    return _typeProviderLegacy!;
  }

  TypeProviderImpl get typeProviderNonNullableByDefault {
    return _typeProviderNonNullableByDefault!;
  }

  TypeSystemImpl get typeSystemLegacy {
    return _typeSystemLegacy!;
  }

  TypeSystemImpl get typeSystemNonNullableByDefault {
    return _typeSystemNonNullableByDefault!;
  }

  void clearTypeProvider() {
    _typeProviderLegacy = null;
    _typeProviderNonNullableByDefault = null;

    _typeSystemLegacy = null;
    _typeSystemNonNullableByDefault = null;
  }

  void setTypeProviders({
    required TypeProviderImpl legacy,
    required TypeProviderImpl nonNullableByDefault,
  }) {
    if (_typeProviderLegacy != null ||
        _typeProviderNonNullableByDefault != null) {
      throw StateError('TypeProvider(s) can be set only once.');
    }

    _typeProviderLegacy = legacy;
    _typeProviderNonNullableByDefault = nonNullableByDefault;

    _typeSystemLegacy = TypeSystemImpl(
      implicitCasts: _analysisOptions.implicitCasts,
      isNonNullableByDefault: false,
      strictInference: _analysisOptions.strictInference,
      typeProvider: legacy,
    );

    _typeSystemNonNullableByDefault = TypeSystemImpl(
      implicitCasts: _analysisOptions.implicitCasts,
      isNonNullableByDefault: true,
      strictInference: _analysisOptions.strictInference,
      typeProvider: nonNullableByDefault,
    );
  }
}
