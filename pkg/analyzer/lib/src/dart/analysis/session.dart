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

/// A concrete implementation of an analysis session.
class AnalysisSessionImpl implements AnalysisSession {
  /// The analysis driver performing analysis for this session.
  final driver.AnalysisDriver _driver;

  /// The URI converter used to convert between URI's and file paths.
  UriConverter? _uriConverter;

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

  @override
  Future<SomeErrorsResult> getErrors(String path) {
    _checkConsistency();
    return _driver.getErrors(path);
  }

  @override
  SomeFileResult getFile(String path) {
    _checkConsistency();
    return _driver.getFileSync(path);
  }

  @override
  Future<SomeLibraryElementResult> getLibraryByUri(String uri) {
    _checkConsistency();
    return _driver.getLibraryByUri(uri);
  }

  @override
  SomeParsedLibraryResult getParsedLibrary(String path) {
    _checkConsistency();
    return _driver.getParsedLibrary(path);
  }

  @override
  SomeParsedLibraryResult getParsedLibraryByElement(LibraryElement element) {
    _checkConsistency();

    if (element.session != this) {
      return NotElementOfThisSessionResult();
    }

    return _driver.getParsedLibraryByUri(element.source.uri);
  }

  @override
  SomeParsedUnitResult getParsedUnit(String path) {
    _checkConsistency();
    return _driver.parseFileSync(path);
  }

  @override
  Future<SomeResolvedLibraryResult> getResolvedLibrary(String path) {
    _checkConsistency();
    return _driver.getResolvedLibrary(path);
  }

  @override
  Future<SomeResolvedLibraryResult> getResolvedLibraryByElement(
    LibraryElement element,
  ) {
    _checkConsistency();

    if (element.session != this) {
      return Future.value(
        NotElementOfThisSessionResult(),
      );
    }

    return _driver.getResolvedLibraryByUri(element.source.uri);
  }

  @override
  Future<SomeResolvedUnitResult> getResolvedUnit(String path) {
    _checkConsistency();
    return _driver.getResult(path);
  }

  @override
  Future<SomeUnitElementResult> getUnitElement(String path) {
    _checkConsistency();
    return _driver.getUnitElement(path);
  }

  /// Check to see that results from this session will be consistent, and throw
  /// an [InconsistentAnalysisException] if they might not be.
  void _checkConsistency() {
    if (_driver.currentSession != this) {
      throw InconsistentAnalysisException();
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
      strictCasts: analysisOptions.strictCasts,
      strictInference: analysisOptions.strictInference,
    );

    _typeSystemNonNullableByDefault?.updateOptions(
      implicitCasts: analysisOptions.implicitCasts,
      strictCasts: analysisOptions.strictCasts,
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

    _typeSystemLegacy = TypeSystemImpl(
      implicitCasts: _analysisOptions.implicitCasts,
      isNonNullableByDefault: false,
      strictCasts: _analysisOptions.strictCasts,
      strictInference: _analysisOptions.strictInference,
      typeProvider: legacy,
    );

    _typeSystemNonNullableByDefault = TypeSystemImpl(
      implicitCasts: _analysisOptions.implicitCasts,
      isNonNullableByDefault: true,
      strictCasts: _analysisOptions.strictCasts,
      strictInference: _analysisOptions.strictInference,
      typeProvider: nonNullableByDefault,
    );

    _typeProviderLegacy = legacy;
    _typeProviderNonNullableByDefault = nonNullableByDefault;
  }
}
