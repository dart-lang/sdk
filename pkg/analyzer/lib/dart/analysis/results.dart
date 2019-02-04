// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/// The result of performing some kind of analysis on a single file. Every
/// result that implements this interface will also implement a sub-interface.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisResult {
  /// The absolute and normalized path of the file that was analyzed.
  String get path;

  /// Return the session used to compute this result.
  AnalysisSession get session;

  /// The state of the results.
  ResultState get state;

  /// The absolute URI of the file that was analyzed.
  Uri get uri;
}

/// An analysis result that includes the errors computed during analysis.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisResultWithErrors implements FileResult {
  /// The analysis errors that were computed during analysis.
  List<AnalysisError> get errors;
}

/// The declaration of an [Element].
abstract class ElementDeclarationResult {
  /// The [Element] that this object describes.
  Element get element;

  /// The node that declares the [element]. Depending on whether it is returned
  /// from [ResolvedLibraryResult] or [ParsedLibraryResult] it might be resolved
  /// or just parsed.
  AstNode get node;

  /// If this declaration is returned from [ParsedLibraryResult], the parsed
  /// unit that contains the [node]. Otherwise `null`.
  ParsedUnitResult get parsedUnit;

  /// If this declaration is returned from [ResolvedLibraryResult], the
  /// resolved unit that contains the [node]. Otherwise `null`.
  ResolvedUnitResult get resolvedUnit;
}

/// The result of computing all of the errors contained in a single file, both
/// syntactic and semantic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ErrorsResult implements AnalysisResultWithErrors {}

/// The result of computing some cheap information for a single file, when full
/// parsed file is not required, so [ParsedUnitResult] is not necessary.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FileResult implements AnalysisResult {
  /// Whether the file is a part.
  bool get isPart;

  /// Information about lines in the content.
  LineInfo get lineInfo;
}

/// The result of building parsed AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParsedLibraryResult implements AnalysisResult {
  /// The parsed units of the library.
  List<ParsedUnitResult> get units;

  /// Return the declaration of the [element], or `null` if the [element]
  /// is synthetic. Throw [ArgumentError] if the [element] is not defined in
  /// this library.
  ElementDeclarationResult getElementDeclaration(Element element);
}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Clients may not extend, implement or mix-in this class.
// ignore: deprecated_member_use_from_same_package
abstract class ParsedUnitResult implements ParseResult {}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Clients may not extend, implement or mix-in this class.
@deprecated
abstract class ParseResult implements AnalysisResultWithErrors {
  /// The content of the file that was scanned and parsed.
  String get content;

  /// The parsed, unresolved compilation unit for the [content].
  CompilationUnit get unit;
}

/// The result of building resolved AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ResolvedLibraryResult implements AnalysisResult {
  /// The element representing this library.
  LibraryElement get element;

  /// The type provider used when resolving the library.
  TypeProvider get typeProvider;

  /// The resolved units of the library.
  List<ResolvedUnitResult> get units;

  /// Return the declaration of the [element], or `null` if the [element]
  /// is synthetic. Throw [ArgumentError] if the [element] is not defined in
  /// this library.
  ElementDeclarationResult getElementDeclaration(Element element);
}

/// The result of building a resolved AST for a single file. The errors returned
/// include both syntactic and semantic errors.
///
/// Clients may not extend, implement or mix-in this class.
// ignore: deprecated_member_use_from_same_package
abstract class ResolvedUnitResult implements ResolveResult {}

/// The result of building a resolved AST for a single file. The errors returned
/// include both syntactic and semantic errors.
///
/// Clients may not extend, implement or mix-in this class.
@deprecated
abstract class ResolveResult implements AnalysisResultWithErrors {
  /// The content of the file that was scanned, parsed and resolved.
  String get content;

  /// The element representing the library containing the compilation [unit].
  LibraryElement get libraryElement;

  /// The type provider used when resolving the compilation [unit].
  TypeProvider get typeProvider;

  /// The type system used when resolving the compilation [unit].
  TypeSystem get typeSystem;

  /// The fully resolved compilation unit for the [content].
  CompilationUnit get unit;
}

/// An indication of whether an analysis result is valid, and if not why.
enum ResultState {
  /// An indication that analysis could not be performed because the path
  /// represents a file of a type that cannot be analyzed.
  INVALID_FILE_TYPE,

  /// An indication that analysis could not be performed because the path does
  /// not represent a file. It might represent something else, such as a
  /// directory, or it might not represent anything.
  NOT_A_FILE,

  /// An indication that analysis completed normally and the results are valid.
  VALID
}

/// The result of building the element model for a single file.
///
/// Clients may not extend, implement or mix-in this class.
abstract class UnitElementResult implements AnalysisResult {
  /// The element of the file.
  CompilationUnitElement get element;

  /// The signature of the library containing the [element]. This is the same
  /// signature returned by the method [AnalysisSession.getUnitElementSignature]
  /// when given the path to the compilation unit represented by the [element].
  ///
  /// The signature is based on the APIs of the files of the library (including
  /// the file itself), and the transitive closure of files imported and
  /// exported by the library. If the signature of a file has not changed, then
  /// there have been no changes that would cause any files that depend on it
  /// to need to be re-analyzed.
  String get signature;
}
