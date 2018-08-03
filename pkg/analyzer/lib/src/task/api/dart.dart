// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/dart.dart';

/**
 * The analysis errors associated with a [Source] representing a compilation
 * unit.
 */
final ListResultDescriptor<AnalysisError> DART_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'DART_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The sources of the libraries that are explicitly imported into a library.
 *
 * The list will be empty if there are no explicit imports, but will not be
 * `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> EXPLICITLY_IMPORTED_LIBRARIES =
    new ListResultDescriptor<Source>(
        'EXPLICITLY_IMPORTED_LIBRARIES', Source.EMPTY_LIST);

/**
 * The sources of the libraries that are exported from a library.
 *
 * The list will be empty if there are no exported libraries, but will not be
 * `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> EXPORTED_LIBRARIES =
    new ListResultDescriptor<Source>('EXPORTED_LIBRARIES', Source.EMPTY_LIST);

/**
 * The sources of the libraries that are implicitly or explicitly imported into
 * a library.
 *
 * The list will minimally contain the source for `dart:core` because it is
 * implicitly imported into every library, and therefore will never be `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> IMPORTED_LIBRARIES =
    new ListResultDescriptor<Source>('IMPORTED_LIBRARIES', Source.EMPTY_LIST);

/**
 * The sources of the parts that are included in a library.
 *
 * The list will be empty if there are no parts, but will not be `null`. The
 * list does *not* include the source for the defining compilation unit.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> INCLUDED_PARTS =
    new ListResultDescriptor<Source>('INCLUDED_PARTS', Source.EMPTY_LIST);

/**
 * A flag specifying whether a library is launchable.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<bool> IS_LAUNCHABLE =
    new ResultDescriptor<bool>('IS_LAUNCHABLE', false);

/**
 * The fully built [LibraryElement] associated with a library.
 *
 * The result is only available for [Source]s representing a library.
 */
final ResultDescriptor<LibraryElement> LIBRARY_ELEMENT =
    new ResultDescriptor<LibraryElement>('LIBRARY_ELEMENT', null);

/**
 * The compilation unit AST produced while parsing a compilation unit.
 *
 * The AST structure will not have resolution information associated with it.
 *
 * The result is only available for [Source]s representing a compilation unit.
 */
final ResultDescriptor<CompilationUnit> PARSED_UNIT =
    new ResultDescriptor<CompilationUnit>('PARSED_UNIT', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The resolved [CompilationUnit] associated with a compilation unit, with
 * constants resolved.
 *
 * The result is only available for [LibrarySpecificUnit]s.
 */
final ResultDescriptor<CompilationUnit> RESOLVED_UNIT =
    new ResultDescriptor<CompilationUnit>('RESOLVED_UNIT', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * The kind of a [Source].
 */
final ResultDescriptor<SourceKind> SOURCE_KIND =
    new ResultDescriptor<SourceKind>('SOURCE_KIND', SourceKind.UNKNOWN);

/**
 * The token stream produced while scanning a compilation unit.
 *
 * The value is the first token in the file, or the special end-of-file marker
 * at the end of the stream if the file does not contain any tokens.
 *
 * The result is only available for [Source]s representing a compilation unit.
 */
final ResultDescriptor<Token> TOKEN_STREAM = new ResultDescriptor<Token>(
    'TOKEN_STREAM', null,
    cachingPolicy: TOKEN_STREAM_CACHING_POLICY);

/**
 * The sources of the Dart files that a library consists of.
 *
 * The list will include the source of the defining unit and [INCLUDED_PARTS].
 * So, it is never empty or `null`.
 *
 * The result is only available for [Source]s representing a library.
 */
final ListResultDescriptor<Source> UNITS =
    new ListResultDescriptor<Source>('UNITS', Source.EMPTY_LIST);

/**
 * A specific compilation unit in a specific library.
 *
 * This kind of target is associated with information about a compilation unit
 * that differs based on the library that the unit is a part of. For example,
 * the result of resolving a compilation unit depends on the imports, which can
 * change if a single part is included in more than one library.
 */
class LibrarySpecificUnit implements AnalysisTarget {
  static const List<LibrarySpecificUnit> EMPTY_LIST =
      const <LibrarySpecificUnit>[];

  /**
   * The defining compilation unit of the library in which the [unit]
   * is analyzed.
   */
  final Source library;

  /**
   * The compilation unit which belongs to the [library].
   */
  final Source unit;

  /**
   * Initialize a newly created target for the [unit] in the [library].
   */
  LibrarySpecificUnit(this.library, this.unit);

  @override
  int get hashCode {
    return JenkinsSmiHash.combine(library.hashCode, unit.hashCode);
  }

  @override
  Source get librarySource => library;

  @override
  Source get source => unit;

  @override
  bool operator ==(other) {
    return other is LibrarySpecificUnit &&
        other.library == library &&
        other.unit == unit;
  }

  @override
  String toString() => '$unit in $library';
}
