// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:meta/meta.dart';

@Deprecated('Use AnalysisResultWithDiagnostics instead')
typedef AnalysisResultWithErrors = AnalysisResultWithDiagnostics;

/// The result of performing some kind of analysis on a single file. Every
/// result that implements this interface will also implement a sub-interface.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisResult {
  /// Return the session used to compute this result.
  AnalysisSession get session;
}

/// An analysis result that includes the diagnostics computed during analysis.
///
/// Clients may not extend, implement or mix-in this class.
abstract class AnalysisResultWithDiagnostics implements FileResult {
  /// The diagnostics that were computed during analysis.
  List<Diagnostic> get diagnostics;

  @Deprecated("Use 'diagnostics' instead")
  List<Diagnostic> get errors => diagnostics;
}

/// The type of [InvalidResult] returned when the given URI cannot be resolved.
///
/// Clients may not extend, implement or mix-in this class.
class CannotResolveUriResult
    implements
        InvalidResult,
        SomeLibraryElementResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}

/// The type of [InvalidResult] returned when the AnalysisContext has been
/// disposed.
///
/// Clients may not extend, implement or mix-in this class.
class DisposedAnalysisContextResult
    implements
        InvalidResult,
        SomeErrorsResult,
        SomeFileResult,
        SomeParsedLibraryResult,
        SomeParsedUnitResult,
        SomeResolvedLibraryResult,
        SomeResolvedUnitResult,
        SomeUnitElementResult {}

/// The declaration of an [Element].
@Deprecated('Use FragmentDeclarationResult instead')
abstract class ElementDeclarationResult {
  /// The [Fragment] that this object describes.
  Fragment get fragment;

  /// The node that declares the [element]. Depending on whether it is returned
  /// from [ResolvedLibraryResult] or [ParsedLibraryResult] it might be resolved
  /// or just parsed.
  AstNode get node;

  /// If this declaration is returned from [ParsedLibraryResult], the parsed
  /// unit that contains the [node]. Otherwise `null`.
  ParsedUnitResult? get parsedUnit;

  /// If this declaration is returned from [ResolvedLibraryResult], the
  /// resolved unit that contains the [node]. Otherwise `null`.
  ResolvedUnitResult? get resolvedUnit;
}

/// The result of computing all of the errors contained in a single file, both
/// syntactic and semantic.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ErrorsResult
    implements SomeErrorsResult, AnalysisResultWithDiagnostics {}

/// The result of computing some cheap information for a single file, when full
/// parsed file is not required, so [ParsedUnitResult] is not necessary.
///
/// Clients may not extend, implement or mix-in this class.
abstract class FileResult implements SomeFileResult, AnalysisResult {
  /// The analysis options for this file.
  AnalysisOptions get analysisOptions;

  /// The latest read content of [file], the same that was used to compute
  /// other properties of this result.
  String get content;

  /// The file resource.
  File get file;

  /// Whether the file is a library.
  ///
  /// A file can't be both a library and a part, so when this getter returns
  /// `true`, the getter [isPart] returns `false`.
  bool get isLibrary;

  /// Whether the file is a part.
  ///
  /// A file can't be both a library and a part, so when this getter returns
  /// `true`, the getter [isLibrary] returns `false`.
  bool get isPart;

  /// Information about lines in the content.
  LineInfo get lineInfo;

  /// The absolute and normalized path of the file that was analyzed.
  String get path;

  /// The absolute URI of the file that was analyzed.
  Uri get uri;
}

/// The declaration of a [Fragment].
abstract class FragmentDeclarationResult {
  /// The [Fragment] that this object describes.
  Fragment get fragment;

  /// The node that declares the [fragment]. Depending on whether it is returned
  /// from [ResolvedLibraryResult] or [ParsedLibraryResult] it might be resolved
  /// or just parsed.
  AstNode get node;

  /// If this declaration is returned from [ParsedLibraryResult], the parsed
  /// unit that contains the [node]. Otherwise `null`.
  ParsedUnitResult? get parsedUnit;

  /// If this declaration is returned from [ResolvedLibraryResult], the
  /// resolved unit that contains the [node]. Otherwise `null`.
  ResolvedUnitResult? get resolvedUnit;
}

/// The type of [InvalidResult] returned when the given file path is invalid,
/// for example is not absolute and normalized.
///
/// Clients may not extend, implement or mix-in this class.
class InvalidPathResult
    implements
        InvalidResult,
        SomeErrorsResult,
        SomeFileResult,
        SomeParsedLibraryResult,
        SomeParsedUnitResult,
        SomeResolvedLibraryResult,
        SomeResolvedUnitResult,
        SomeUnitElementResult {}

/// The base class for any invalid result.
///
/// Clients may not extend, implement or mix-in this class.
abstract class InvalidResult {}

/// The result of building the element model for a library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class LibraryElementResult implements SomeLibraryElementResult {
  /// The element representing the library.
  @experimental
  LibraryElement get element;

  /// The element representing the library.
  @Deprecated('Use element instead')
  @experimental
  LibraryElement get element2;
}

/// The type of [InvalidResult] returned when the given element was not
/// created by the requested session.
///
/// Clients may not extend, implement or mix-in this class.
class NotElementOfThisSessionResult
    implements
        InvalidResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}

/// The type of [InvalidResult] returned when the given file is not a library,
/// but a part of a library.
///
/// Clients may not extend, implement or mix-in this class.
class NotLibraryButPartResult
    implements
        InvalidResult,
        SomeLibraryElementResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}

/// The type of [InvalidResult] returned when the given file path does not
/// represent the corresponding URI.
///
/// This usually happens in Blaze workspaces, when a URI is resolved to
/// a generated file, but there is also a writable file to which this URI
/// would be resolved, if there were no generated file.
///
/// Clients may not extend, implement or mix-in this class.
class NotPathOfUriResult
    implements
        InvalidResult,
        SomeErrorsResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult,
        SomeResolvedUnitResult,
        SomeUnitElementResult {}

/// The result of building parsed AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParsedLibraryResult
    implements SomeParsedLibraryResult, AnalysisResult {
  /// The parsed units of the library.
  List<ParsedUnitResult> get units;

  /// Returns the declaration of the [fragment].
  ///
  /// Returns `null` if the [fragment] is synthetic.
  ///
  /// Throws [ArgumentError] if the [fragment] is not defined in this library.
  @Deprecated('Use getFragmentDeclaration() instead')
  @experimental
  ElementDeclarationResult? getElementDeclaration2(Fragment fragment);

  /// Returns the declaration of the [fragment].
  ///
  /// Returns `null` if the [fragment] is synthetic.
  ///
  /// Throws [ArgumentError] if the [fragment] is not defined in this library.
  @experimental
  FragmentDeclarationResult? getFragmentDeclaration(Fragment fragment);
}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParsedUnitResult
    implements SomeParsedUnitResult, AnalysisResultWithDiagnostics {
  /// The parsed, unresolved compilation unit for the [content].
  CompilationUnit get unit;
}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Similar to [ParsedUnitResult], but does not allow access to an analysis
/// session.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ParseStringResult {
  /// The content of the file that was scanned and parsed.
  String get content;

  /// The analysis errors that were computed during analysis.
  List<Diagnostic> get errors;

  /// Information about lines in the content.
  LineInfo get lineInfo;

  /// The parsed, unresolved compilation unit for the [content].
  CompilationUnit get unit;
}

/// The result of building resolved AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ResolvedLibraryResult
    implements ParsedLibraryResult, SomeResolvedLibraryResult {
  /// The element representing this library.
  @experimental
  LibraryElement get element;

  /// The element representing this library.
  @Deprecated('Use element instead')
  @experimental
  LibraryElement get element2;

  /// The type provider used when resolving the library.
  TypeProvider get typeProvider;

  /// The resolved units of the library.
  @override
  List<ResolvedUnitResult> get units;

  /// Return the resolved unit corresponding to the [path], or `null` if there
  /// is no such unit.
  ResolvedUnitResult? unitWithPath(String path);
}

/// The result of building a resolved AST for a single file. The errors returned
/// include both syntactic and semantic errors.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ResolvedUnitResult
    implements ParsedUnitResult, SomeResolvedUnitResult {
  /// Return `true` if the file exists.
  bool get exists;

  /// The element representing the library containing the compilation [unit].
  @experimental
  LibraryElement get libraryElement;

  /// The element representing the library containing the compilation [unit].
  @Deprecated('Use libraryElement instead')
  @experimental
  LibraryElement get libraryElement2;

  /// The fragment corresponding to the [unit].
  @experimental
  LibraryFragment get libraryFragment;

  /// The type provider used when resolving the compilation [unit].
  TypeProvider get typeProvider;

  /// The type system used when resolving the compilation [unit].
  TypeSystem get typeSystem;
}

/// The result of computing all of the errors contained in a single file, both
/// syntactic and semantic.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ErrorsResult] represents a valid result.
abstract class SomeErrorsResult {}

/// The result of computing some cheap information for a single file, when full
/// parsed file is not required, so [ParsedUnitResult] is not necessary.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [FileResult] represents a valid result.
abstract class SomeFileResult {}

/// The result of building the element model for a library.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [LibraryElementResult] represents a valid result.
abstract class SomeLibraryElementResult {}

/// The result of building parsed AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ParsedLibraryResult] represents a valid result.
abstract class SomeParsedLibraryResult {}

/// The result of parsing of a single file. The errors returned include only
/// those discovered during scanning and parsing.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ParsedUnitResult] represents a valid result.
abstract class SomeParsedUnitResult {}

/// The result of building resolved AST(s) for the whole library.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ResolvedLibraryResult] represents a valid result.
abstract class SomeResolvedLibraryResult {}

/// The result of building a resolved AST for a single file. The errors returned
/// include both syntactic and semantic errors.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [ResolvedUnitResult] represents a valid result.
abstract class SomeResolvedUnitResult {}

/// The result of building the element model for a single file.
///
/// Clients may not extend, implement or mix-in this class.
///
/// There are existing implementations of this class.
/// [UnitElementResult] represents a valid result.
abstract class SomeUnitElementResult {}

/// The result of building the element model for a single file.
///
/// Clients may not extend, implement or mix-in this class.
///
// TODO(scheglov): Stop implementing [FileResult].
abstract class UnitElementResult implements SomeUnitElementResult, FileResult {
  /// The fragment representing the content of the file.
  @experimental
  LibraryFragment get fragment;
}

/// The type of [InvalidResult] returned when something is wrong, but we
/// don't know what exactly. Usually this result should not happen.
///
/// Clients may not extend, implement or mix-in this class.
class UnspecifiedInvalidResult
    implements
        InvalidResult,
        SomeErrorsResult,
        SomeFileResult,
        SomeLibraryElementResult,
        SomeParsedLibraryResult,
        SomeParsedUnitResult,
        SomeResolvedLibraryResult,
        SomeResolvedUnitResult,
        SomeUnitElementResult {}

/// The type of [InvalidResult] returned when the given URI corresponds to
/// a library that is served from an external summary bundle.
///
/// Clients may not extend, implement or mix-in this class.
class UriOfExternalLibraryResult
    implements
        InvalidResult,
        SomeParsedLibraryResult,
        SomeResolvedLibraryResult {}
