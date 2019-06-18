// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/// A consistent view of the results of analyzing one or more files.
///
/// The methods in this class that return analysis results will throw an
/// [InconsistentAnalysisException] if the result to be returned might be
/// inconsistent with any previously returned results.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisSession {
  /// The analysis context that created this session.
  AnalysisContext get analysisContext;

  /// The declared environment variables.
  DeclaredVariables get declaredVariables;

  /// Return the [ResourceProvider] that is used to access the file system.
  ResourceProvider get resourceProvider;

  /// Return the source factory used to resolve URIs.
  ///
  /// Deprecated: Use the methods on [uriConverter] instead.
  @deprecated
  SourceFactory get sourceFactory;

  /// Return a type provider that is consistent with the results returned by
  /// this session.
  Future<TypeProvider> get typeProvider;

  /// Return the type system being used by this session.
  Future<TypeSystem> get typeSystem;

  /// Return the URI converter used to convert between URI's and file paths.
  UriConverter get uriConverter;

  /// Return a future that will complete with information about the errors
  /// contained in the file with the given absolute, normalized [path].
  ///
  /// If the file cannot be analyzed by this session, then the result will have
  /// a result state indicating the nature of the problem.
  Future<ErrorsResult> getErrors(String path);

  /// Return a future that will complete with the library element representing
  /// the library with the given [uri].
  Future<LibraryElement> getLibraryByUri(String uri);

  /// Return a future that will complete with information about the results of
  /// parsing the file with the given absolute, normalized [path].
  ///
  /// Deprecated: Use [getParsedUnit] instead.
  @deprecated
  Future<ParseResult> getParsedAst(String path);

  /// Return information about the results of parsing the file with the given
  /// absolute, normalized [path].
  ///
  /// Deprecated: Use [getParsedUnit] instead.
  @deprecated
  ParseResult getParsedAstSync(String path);

  /// Return information about the results of parsing units of the library file
  /// with the given absolute, normalized [path].
  ///
  /// Throw [ArgumentError] if the given [path] is not the defining compilation
  /// unit for a library (that is, is a part of a library).
  ParsedLibraryResult getParsedLibrary(String path);

  /// Return information about the results of parsing units of the library file
  /// with the given library [element].
  ///
  /// Throw [ArgumentError] if the [element] was not produced by this session.
  ParsedLibraryResult getParsedLibraryByElement(LibraryElement element);

  /// Return information about the results of parsing the file with the given
  /// absolute, normalized [path].
  ParsedUnitResult getParsedUnit(String path);

  /// Return a future that will complete with information about the results of
  /// resolving the file with the given absolute, normalized [path].
  ///
  /// Deprecated: Use [getResolvedUnit] instead.
  @deprecated
  Future<ResolveResult> getResolvedAst(String path);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the given absolute,
  /// normalized [path].
  ///
  /// Throw [ArgumentError] if the given [path] is not the defining compilation
  /// unit for a library (that is, is a part of a library).
  Future<ResolvedLibraryResult> getResolvedLibrary(String path);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the library [element].
  ///
  /// Throw [ArgumentError] if the [element] was not produced by this session.
  Future<ResolvedLibraryResult> getResolvedLibraryByElement(
      LibraryElement element);

  /// Return a future that will complete with information about the results of
  /// resolving the file with the given absolute, normalized [path].
  Future<ResolvedUnitResult> getResolvedUnit(String path);

  /// Return a future that will complete with the source kind of the file with
  /// the given absolute, normalized [path]. If the path does not represent a
  /// file or if the kind of the file cannot be determined, then the future will
  /// complete with [SourceKind.UNKNOWN].
  Future<SourceKind> getSourceKind(String path);

  /// Return a future that will complete with a list of the top-level
  /// declarations with the given [name] in all known libraries.
  Future<List<TopLevelDeclarationInSource>> getTopLevelDeclarations(
      String name);

  /// Return a future that will complete with information about the results of
  /// building the element model for the file with the given absolute,
  /// normalized[path].
  Future<UnitElementResult> getUnitElement(String path);

  /// Return a future that will complete with the signature for the file with
  /// the given absolute, normalized [path], or `null` if the file cannot be
  /// analyzed. This is the same signature returned in the result from
  /// [getUnitElement].
  ///
  /// The signature is based on the APIs of the files of the library (including
  /// the file itself), and the transitive closure of files imported and
  /// exported by the library. If the signature of a file has not changed, then
  /// there have been no changes that would cause any files that depend on it to
  /// need to be re-analyzed.
  Future<String> getUnitElementSignature(String path);
}

/// The exception thrown by an [AnalysisSession] if a result is requested that
/// might be inconsistent with any previously returned results.
class InconsistentAnalysisException extends AnalysisException {
  InconsistentAnalysisException()
      : super('Requested result might be inconsistent with previously '
            'returned results');
}
