// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
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

  /// Return the URI converter used to convert between URI's and file paths.
  UriConverter get uriConverter;

  /// Return a future that will complete with information about the errors
  /// contained in the file with the given absolute, normalized [path].
  ///
  /// If the file cannot be analyzed by this session, then the result will have
  /// a result state indicating the nature of the problem.
  @Deprecated('Use getErrors2() instead')
  Future<ErrorsResult> getErrors(String path);

  /// Return a future that will complete with information about the errors
  /// contained in the file with the given absolute, normalized [path].
  ///
  /// If the file cannot be analyzed by this session, then the result will have
  /// a result state indicating the nature of the problem.
  Future<SomeErrorsResult> getErrors2(String path);

  /// Return information about the file at the given absolute, normalized
  /// [path].
  @Deprecated('Use getFile2() instead')
  FileResult getFile(String path);

  /// Return information about the file at the given absolute, normalized
  /// [path].
  SomeFileResult getFile2(String path);

  /// Return a future that will complete with the library element representing
  /// the library with the given [uri].
  @Deprecated('Use getLibraryByUri2() instead')
  Future<LibraryElement> getLibraryByUri(String uri);

  /// Return a future that will complete with information about the library
  /// element representing the library with the given [uri].
  Future<SomeLibraryElementResult> getLibraryByUri2(String uri);

  /// Return information about the results of parsing units of the library file
  /// with the given absolute, normalized [path].
  ///
  /// Throw [ArgumentError] if the given [path] is not the defining compilation
  /// unit for a library (that is, is a part of a library).
  @Deprecated('Use getParsedLibrary2() instead')
  ParsedLibraryResult getParsedLibrary(String path);

  /// Return information about the results of parsing units of the library file
  /// with the given absolute, normalized [path].
  SomeParsedLibraryResult getParsedLibrary2(String path);

  /// Return information about the results of parsing units of the library file
  /// with the given library [element].
  ///
  /// Throw [ArgumentError] if the [element] was not produced by this session.
  @Deprecated('Use getParsedLibraryByElement2() instead')
  ParsedLibraryResult getParsedLibraryByElement(LibraryElement element);

  /// Return information about the results of parsing units of the library file
  /// with the given library [element].
  SomeParsedLibraryResult getParsedLibraryByElement2(LibraryElement element);

  /// Return information about the results of parsing the file with the given
  /// absolute, normalized [path].
  @Deprecated('Use getParsedUnit2() instead')
  ParsedUnitResult getParsedUnit(String path);

  /// Return information about the results of parsing the file with the given
  /// absolute, normalized [path].
  SomeParsedUnitResult getParsedUnit2(String path);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the given absolute,
  /// normalized [path].
  ///
  /// Throw [ArgumentError] if the given [path] is not the defining compilation
  /// unit for a library (that is, is a part of a library).
  @Deprecated('Use getResolvedLibrary2() instead')
  Future<ResolvedLibraryResult> getResolvedLibrary(String path);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the given absolute,
  /// normalized [path].
  Future<SomeResolvedLibraryResult> getResolvedLibrary2(String path);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the library [element].
  ///
  /// Throw [ArgumentError] if the [element] was not produced by this session.
  @Deprecated('Use getResolvedLibraryByElement2() instead')
  Future<ResolvedLibraryResult> getResolvedLibraryByElement(
      LibraryElement element);

  /// Return a future that will complete with information about the results of
  /// resolving all of the files in the library with the library [element].
  ///
  /// Throw [ArgumentError] if the [element] was not produced by this session.
  Future<SomeResolvedLibraryResult> getResolvedLibraryByElement2(
      LibraryElement element);

  /// Return a future that will complete with information about the results of
  /// resolving the file with the given absolute, normalized [path].
  @Deprecated('Use getResolvedUnit2() instead')
  Future<ResolvedUnitResult> getResolvedUnit(String path);

  /// Return a future that will complete with information about the results of
  /// resolving the file with the given absolute, normalized [path].
  Future<SomeResolvedUnitResult> getResolvedUnit2(String path);

  /// Return a future that will complete with the source kind of the file with
  /// the given absolute, normalized [path]. If the path does not represent a
  /// file or if the kind of the file cannot be determined, then the future will
  /// complete with [SourceKind.UNKNOWN].
  ///
  /// TODO(migration): should not be nullable
  @Deprecated('Use getFile2() instead')
  Future<SourceKind?> getSourceKind(String path);

  /// Return a future that will complete with information about the results of
  /// building the element model for the file with the given absolute,
  /// normalized [path].
  @Deprecated('Use getUnitElement2() instead')
  Future<UnitElementResult> getUnitElement(String path);

  /// Return a future that will complete with information about the results of
  /// building the element model for the file with the given absolute,
  /// normalized [path].
  Future<SomeUnitElementResult> getUnitElement2(String path);

  /// Return a future that will complete with the signature for the file with
  /// the given absolute, normalized [path], or `null` if the file cannot be
  /// analyzed. This is the same signature returned in the result from
  /// [getUnitElement2].
  ///
  /// The signature is based on the APIs of the files of the library (including
  /// the file itself), and the transitive closure of files imported and
  /// exported by the library. If the signature of a file has not changed, then
  /// there have been no changes that would cause any files that depend on it to
  /// need to be re-analyzed.
  @Deprecated('This method is not used and will be removed')
  Future<String> getUnitElementSignature(String path);
}

/// The exception thrown by an [AnalysisSession] if a result is requested that
/// might be inconsistent with any previously returned results.
class InconsistentAnalysisException extends AnalysisException {
  InconsistentAnalysisException()
      : super('Requested result might be inconsistent with previously '
            'returned results');
}
