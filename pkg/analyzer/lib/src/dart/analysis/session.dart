// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as driver;
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/analysis/uri_converter.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A concrete implementation of an analysis session.
 */
class AnalysisSessionImpl implements AnalysisSession {
  /**
   * The analysis driver performing analysis for this session.
   */
  final driver.AnalysisDriver _driver;

  /**
   * The type provider being used by the analysis driver.
   */
  TypeProvider _typeProvider;

  /**
   * The type system being used by the analysis driver.
   */
  TypeSystem _typeSystem;

  /**
   * The URI converter used to convert between URI's and file paths.
   */
  UriConverter _uriConverter;

  /**
   * The cache of libraries for URIs.
   */
  final Map<String, LibraryElement> _uriToLibraryCache = {};

  /**
   * Initialize a newly created analysis session.
   */
  AnalysisSessionImpl(this._driver);

  @override
  ResourceProvider get resourceProvider => _driver.resourceProvider;

  @override
  SourceFactory get sourceFactory => _driver.sourceFactory;

  @override
  Future<TypeProvider> get typeProvider async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    _checkConsistency();
    if (_typeProvider == null) {
      LibraryElement coreLibrary = await _driver.getLibraryByUri('dart:core');
      LibraryElement asyncLibrary = await _driver.getLibraryByUri('dart:async');
      _typeProvider = new TypeProviderImpl(coreLibrary, asyncLibrary);
    }
    return _typeProvider;
  }

  @override
  Future<TypeSystem> get typeSystem async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    _checkConsistency();
    if (_typeSystem == null) {
      _typeSystem = new StrongTypeSystemImpl(await typeProvider);
    }
    return _typeSystem;
  }

  @override
  UriConverter get uriConverter {
    return _uriConverter ??= new DriverBasedUriConverter(_driver);
  }

  @override
  Future<ErrorsResult> getErrors(String path) {
    _checkConsistency();
    return _driver.getErrors(path);
  }

  @override
  Future<LibraryElement> getLibraryByUri(String uri) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    _checkConsistency();
    var libraryElement = _uriToLibraryCache[uri];
    if (libraryElement == null) {
      libraryElement = await _driver.getLibraryByUri(uri);
      _uriToLibraryCache[uri] = libraryElement;
    }
    return libraryElement;
  }

  @override
  Future<ParseResult> getParsedAst(String path) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    return getParsedAstSync(path);
  }

  @override
  ParseResult getParsedAstSync(String path) {
    _checkConsistency();
    return _driver.parseFileSync(path);
  }

  @override
  Future<ResolveResult> getResolvedAst(String path) {
    _checkConsistency();
    return _driver.getResult(path);
  }

  @override
  Future<SourceKind> getSourceKind(String path) {
    _checkConsistency();
    return _driver.getSourceKind(path);
  }

  @override
  Future<List<TopLevelDeclarationInSource>> getTopLevelDeclarations(
      String name) {
    _checkConsistency();
    return _driver.getTopLevelNameDeclarations(name);
  }

  @override
  Future<UnitElementResult> getUnitElement(String path) {
    _checkConsistency();
    return _driver.getUnitElement(path);
  }

  @override
  Future<String> getUnitElementSignature(String path) {
    _checkConsistency();
    return _driver.getUnitElementSignature(path);
  }

  /**
   * Check to see that results from this session will be consistent, and throw
   * an [InconsistentAnalysisException] if they might not be.
   */
  void _checkConsistency() {
    if (_driver.currentSession != this) {
      throw new InconsistentAnalysisException();
    }
  }
}
