// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.task.dart;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * The compilation unit associated with a [Source] after it has had all
 * declarations bound to the element defined by the declaration.
 *
 * The result is only available for targets representing a Dart compilation unit.
 */
final ResultDescriptor<CompilationUnit> BUILT_UNIT =
    new ResultDescriptor<CompilationUnit>('BUILT_UNIT', null);

/**
 * The element model associated with a single compilation unit.
 *
 * The result is only available for targets representing a Dart compilation unit.
 */
final ResultDescriptor<CompilationUnitElement> COMPILATION_UNIT_ELEMENT =
    new ResultDescriptor<CompilationUnitElement>('COMPILATION_UNIT_ELEMENT', null);

/**
 * The sources of the libraries that are exported from a library.
 *
 * The list will be empty if there are no exported libraries, but will not be
 * `null`.
 *
 * The result is only available for targets representing a Dart library.
 */
final ResultDescriptor<List<Source>> EXPORTED_LIBRARIES =
    new ResultDescriptor<List<Source>>('EXPORTED_LIBRARIES', Source.EMPTY_ARRAY);

/**
 * The sources of the libraries that are imported into a library.
 *
 * The list will be empty if there are no imported libraries, but will not be
 * `null`.
 *
 * The result is only available for targets representing a Dart library.
 */
final ResultDescriptor<List<Source>> IMPORTED_LIBRARIES =
    new ResultDescriptor<List<Source>>('IMPORTED_LIBRARIES', Source.EMPTY_ARRAY);

/**
 * The sources of the parts that are included in a library.
 *
 * The list will be empty if there are no parts, but will not be `null`. The
 * list does *not* include the source for the defining compilation unit.
 *
 * The result is only available for targets representing a Dart library.
 */
final ResultDescriptor<List<Source>> INCLUDED_PARTS =
    new ResultDescriptor<List<Source>>('INCLUDED_PARTS', Source.EMPTY_ARRAY);

/**
 * The errors produced while parsing a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for targets representing a Dart compilation unit.
 */
final ResultDescriptor<List<AnalysisError>> PARSE_ERRORS =
    new ResultDescriptor<List<AnalysisError>>(
        'PARSE_ERRORS',
        AnalysisError.NO_ERRORS,
        contributesTo: ANALYSIS_ERRORS);

/**
 * The compilation unit AST produced while parsing a compilation unit.
 *
 * The AST structure will not have resolution information associated with it.
 *
 * The result is only available for targets representing a Dart compilation unit.
 */
final ResultDescriptor<CompilationUnit> PARSED_UNIT =
    new ResultDescriptor<CompilationUnit>('PARSED_UNIT', null);

/**
 * The errors produced while scanning a compilation unit.
 *
 * The list will be empty if there were no errors, but will not be `null`.
 *
 * The result is only available for targets representing a Dart compilation unit.
 */
final ResultDescriptor<List<AnalysisError>> SCAN_ERRORS =
    new ResultDescriptor<List<AnalysisError>>(
        'SCAN_ERRORS',
        AnalysisError.NO_ERRORS,
        contributesTo: ANALYSIS_ERRORS);

/**
 * The token stream produced while scanning a compilation unit.
 *
 * The value is the first token in the file, or the special end-of-file marker
 * at the end of the stream if the file does not contain any tokens.
 *
 * The result is only available for targets representing a Dart compilation unit.
 */
final ResultDescriptor<Token> TOKEN_STREAM =
    new ResultDescriptor<Token>('TOKEN_STREAM', null);
