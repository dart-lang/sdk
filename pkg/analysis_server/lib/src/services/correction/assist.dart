// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.correction.assist;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Computes [Assist]s at the given location.
 *
 * Returns the computed [Assist]s, not `null`.
 */
List<Assist> computeAssists(SearchEngine searchEngine, CompilationUnit unit,
    int offset, int length) {
  Source source = unit.element.source;
  String file = source.fullName;
  AssistProcessor processor =
      new AssistProcessor(searchEngine, source, file, unit, offset, length);
  return processor.compute();
}


/**
 * A description of a single proposed assist.
 */
class Assist {
  final AssistKind kind;
  final SourceChange change;

  Assist(this.kind, this.change);

  @override
  String toString() {
    return 'Assist(kind=$kind, change=$change)';
  }
}


/**
 * An enumeration of possible quick assist kinds.
 */
class AssistKind {
  static const ADD_PART_DIRECTIVE =
      const AssistKind('ADD_PART_DIRECTIVE', 30, "Add 'part' directive");
  static const ADD_TYPE_ANNOTATION =
      const AssistKind('ADD_TYPE_ANNOTATION', 30, "Add type annotation");
  static const ASSIGN_TO_LOCAL_VARIABLE = const AssistKind(
      'ASSIGN_TO_LOCAL_VARIABLE',
      30,
      "Assign value to new local variable");
  static const CONVERT_INTO_BLOCK_BODY =
      const AssistKind('CONVERT_INTO_BLOCK_BODY', 30, "Convert into block body");
  static const CONVERT_INTO_EXPRESSION_BODY = const AssistKind(
      'CONVERT_INTO_EXPRESSION_BODY',
      30,
      "Convert into expression body");
  static const CONVERT_INTO_IS_NOT =
      const AssistKind('CONVERT_INTO_IS_NOT', 30, "Convert into is!");
  static const CONVERT_INTO_IS_NOT_EMPTY =
      const AssistKind('CONVERT_INTO_IS_NOT_EMPTY', 30, "Convert into 'isNotEmpty'");
  static const EXCHANGE_OPERANDS =
      const AssistKind('EXCHANGE_OPERANDS', 30, "Exchange operands");
  static const EXTRACT_CLASS =
      const AssistKind('EXTRACT_CLASS', 30, "Extract class into file '{0}'");
  static const IMPORT_ADD_SHOW =
      const AssistKind('IMPORT_ADD_SHOW', 30, "Add explicit 'show' combinator");
  static const INTRODUCE_LOCAL_CAST_TYPE = const AssistKind(
      'INTRODUCE_LOCAL_CAST_TYPE',
      30,
      "Introduce new local with tested type");
  static const INVERT_IF_STATEMENT =
      const AssistKind('INVERT_IF_STATEMENT', 30, "Invert 'if' statement");
  static const JOIN_IF_WITH_INNER = const AssistKind(
      'JOIN_IF_WITH_INNER',
      30,
      "Join 'if' statement with inner 'if' statement");
  static const JOIN_IF_WITH_OUTER = const AssistKind(
      'JOIN_IF_WITH_OUTER',
      30,
      "Join 'if' statement with outer 'if' statement");
  static const JOIN_VARIABLE_DECLARATION =
      const AssistKind('JOIN_VARIABLE_DECLARATION', 30, "Join variable declaration");
  static const REMOVE_TYPE_ANNOTATION =
      const AssistKind('REMOVE_TYPE_ANNOTATION', 29, "Remove type annotation");
  static const REPLACE_CONDITIONAL_WITH_IF_ELSE = const AssistKind(
      'REPLACE_CONDITIONAL_WITH_IF_ELSE',
      30,
      "Replace conditional with 'if-else'");
  static const REPLACE_IF_ELSE_WITH_CONDITIONAL = const AssistKind(
      'REPLACE_IF_ELSE_WITH_CONDITIONAL',
      30,
      "Replace 'if-else' with conditional ('c ? x : y')");
  static const SPLIT_AND_CONDITION =
      const AssistKind('SPLIT_AND_CONDITION', 30, "Split && condition");
  static const SPLIT_VARIABLE_DECLARATION = const AssistKind(
      'SPLIT_VARIABLE_DECLARATION',
      30,
      "Split variable declaration");
  static const SURROUND_WITH_BLOCK =
      const AssistKind('SURROUND_WITH_BLOCK', 30, "Surround with block");
  static const SURROUND_WITH_DO_WHILE =
      const AssistKind('SURROUND_WITH_DO_WHILE', 30, "Surround with 'do-while'");
  static const SURROUND_WITH_FOR =
      const AssistKind('SURROUND_WITH_FOR', 30, "Surround with 'for'");
  static const SURROUND_WITH_FOR_IN =
      const AssistKind('SURROUND_WITH_FOR_IN', 30, "Surround with 'for-in'");
  static const SURROUND_WITH_IF =
      const AssistKind('SURROUND_WITH_IF', 30, "Surround with 'if'");
  static const SURROUND_WITH_TRY_CATCH =
      const AssistKind('SURROUND_WITH_TRY_CATCH', 30, "Surround with 'try-catch'");
  static const SURROUND_WITH_TRY_FINALLY = const AssistKind(
      'SURROUND_WITH_TRY_FINALLY',
      30,
      "Surround with 'try-finally'");
  static const SURROUND_WITH_WHILE =
      const AssistKind('SURROUND_WITH_WHILE', 30, "Surround with 'while'");

  final name;
  final int relevance;
  final String message;

  const AssistKind(this.name, this.relevance, this.message);

  @override
  String toString() => name;
}
