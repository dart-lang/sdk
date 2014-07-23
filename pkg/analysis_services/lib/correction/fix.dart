// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.correction.fix;

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/correction/fix.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';


/**
 * Computes [Fix]s for the given [AnalysisError].
 *
 * Returns the computed [Fix]s, not `null`.
 */
List<Fix> computeFixes(SearchEngine searchEngine, String file,
    CompilationUnit unit, AnalysisError error) {
  var processor = new FixProcessor(searchEngine, file, unit, error);
  return processor.compute();
}


/**
 * A description of a single proposed fix for some problem.
 */
class Fix {
  final FixKind kind;
  final Change change;

  Fix(this.kind, this.change);

  @override
  String toString() {
    return '[kind=$kind, change=$change]';
  }
}


/**
 * An enumeration of possible quick fix kinds.
 */
class FixKind {
  static const ADD_PACKAGE_DEPENDENCY =
      const FixKind('ADD_PACKAGE_DEPENDENCY', 50, "Add dependency on package '%s'");
  static const ADD_SUPER_CONSTRUCTOR_INVOCATION =
      const FixKind(
          'ADD_SUPER_CONSTRUCTOR_INVOCATION',
          50,
          "Add super constructor %s invocation");
  static const CHANGE_TO = const FixKind('CHANGE_TO', 51, "Change to '%s'");
  static const CHANGE_TO_STATIC_ACCESS =
      const FixKind(
          'CHANGE_TO_STATIC_ACCESS',
          50,
          "Change access to static using '%s'");
  static const CREATE_CLASS =
      const FixKind('CREATE_CLASS', 50, "Create class '%s'");
  static const CREATE_CONSTRUCTOR =
      const FixKind('CREATE_CONSTRUCTOR', 50, "Create constructor '%s'");
  static const CREATE_CONSTRUCTOR_SUPER =
      const FixKind('CREATE_CONSTRUCTOR_SUPER', 50, "Create constructor to call %s");
  static const CREATE_FUNCTION =
      const FixKind('CREATE_FUNCTION', 49, "Create function '%s'");
  static const CREATE_METHOD =
      const FixKind('CREATE_METHOD', 50, "Create method '%s'");
  static const CREATE_MISSING_OVERRIDES =
      const FixKind('CREATE_MISSING_OVERRIDES', 50, "Create %d missing override(s)");
  static const CREATE_NO_SUCH_METHOD =
      const FixKind('CREATE_NO_SUCH_METHOD', 49, "Create 'noSuchMethod' method");
  static const CREATE_PART =
      const FixKind('CREATE_PART', 50, "Create part '%s'");
  static const IMPORT_LIBRARY_PREFIX =
      const FixKind(
          'IMPORT_LIBRARY_PREFIX',
          51,
          "Use imported library '%s' with prefix '%s'");
  static const IMPORT_LIBRARY_PROJECT =
      const FixKind('IMPORT_LIBRARY_PROJECT', 51, "Import library '%s'");
  static const IMPORT_LIBRARY_SDK =
      const FixKind('IMPORT_LIBRARY_SDK', 51, "Import library '%s'");
  static const IMPORT_LIBRARY_SHOW =
      const FixKind('IMPORT_LIBRARY_SHOW', 51, "Update library '%s' import");
  static const INSERT_SEMICOLON =
      const FixKind('INSERT_SEMICOLON', 50, "Insert ';'");
  static const MAKE_CLASS_ABSTRACT =
      const FixKind('MAKE_CLASS_ABSTRACT', 50, "Make class '%s' abstract");
  static const REMOVE_PARAMETERS_IN_GETTER_DECLARATION =
      const FixKind(
          'REMOVE_PARAMETERS_IN_GETTER_DECLARATION',
          50,
          "Remove parameters in getter declaration");
  static const REMOVE_PARENTHESIS_IN_GETTER_INVOCATION =
      const FixKind(
          'REMOVE_PARENTHESIS_IN_GETTER_INVOCATION',
          50,
          "Remove parentheses in getter invocation");
  static const REMOVE_UNNECASSARY_CAST =
      const FixKind('REMOVE_UNNECASSARY_CAST', 50, "Remove unnecessary cast");
  static const REMOVE_UNUSED_IMPORT =
      const FixKind('REMOVE_UNUSED_IMPORT', 50, "Remove unused import");
  static const REPLACE_BOOLEAN_WITH_BOOL =
      const FixKind('REPLACE_BOOLEAN_WITH_BOOL', 50, "Replace 'boolean' with 'bool'");
  static const USE_CONST = const FixKind('USE_CONST', 50, "Change to constant");
  static const USE_EFFECTIVE_INTEGER_DIVISION =
      const FixKind(
          'USE_EFFECTIVE_INTEGER_DIVISION',
          50,
          "Use effective integer division ~/");
  static const USE_EQ_EQ_NULL =
      const FixKind('USE_EQ_EQ_NULL', 50, "Use == null instead of 'is Null'");
  static const USE_NOT_EQ_NULL =
      const FixKind('USE_NOT_EQ_NULL', 50, "Use != null instead of 'is! Null'");

  final name;
  final int relevance;
  final String message;

  const FixKind(this.name, this.relevance, this.message);

  @override
  String toString() => name;
}


///**
// * An enumeration of possible quick assist kinds.
// */
//class AssistKind {
//  static const QA_ADD_PART_DIRECTIVE =
//      const AssistKind('QA_ADD_PART_DIRECTIVE', 30, "Add 'part' directive");
//  static const QA_ADD_TYPE_ANNOTATION =
//      const AssistKind('QA_ADD_TYPE_ANNOTATION', 30, "Add type annotation");
//  static const QA_ASSIGN_TO_LOCAL_VARIABLE =
//      const AssistKind(
//          'QA_ASSIGN_TO_LOCAL_VARIABLE',
//          30,
//          "Assign value to new local variable");
//  static const QA_CONVERT_INTO_BLOCK_BODY =
//      const AssistKind('QA_CONVERT_INTO_BLOCK_BODY', 30, "Convert into block body");
//  static const QA_CONVERT_INTO_EXPRESSION_BODY =
//      const AssistKind(
//          'QA_CONVERT_INTO_EXPRESSION_BODY',
//          30,
//          "Convert into expression body");
//  static const QA_CONVERT_INTO_IS_NOT =
//      const AssistKind('QA_CONVERT_INTO_IS_NOT', 30, "Convert into is!");
//  static const QA_CONVERT_INTO_IS_NOT_EMPTY =
//      const AssistKind(
//          'QA_CONVERT_INTO_IS_NOT_EMPTY',
//          30,
//          "Convert into 'isNotEmpty'");
//  static const QA_EXCHANGE_OPERANDS =
//      const AssistKind('QA_EXCHANGE_OPERANDS', 30, "Exchange operands");
//  static const QA_EXTRACT_CLASS =
//      const AssistKind('QA_EXTRACT_CLASS', 30, "Extract class into file '%s'");
//  static const QA_IMPORT_ADD_SHOW =
//      const AssistKind('QA_IMPORT_ADD_SHOW', 30, "Add explicit 'show' combinator");
//  static const QA_INVERT_IF_STATEMENT =
//      const AssistKind('QA_INVERT_IF_STATEMENT', 30, "Invert 'if' statement");
//  static const QA_JOIN_IF_WITH_INNER =
//      const AssistKind(
//          'QA_JOIN_IF_WITH_INNER',
//          30,
//          "Join 'if' statement with inner 'if' statement");
//  static const QA_JOIN_IF_WITH_OUTER =
//      const AssistKind(
//          'QA_JOIN_IF_WITH_OUTER',
//          30,
//          "Join 'if' statement with outer 'if' statement");
//  static const QA_JOIN_VARIABLE_DECLARATION =
//      const AssistKind(
//          'QA_JOIN_VARIABLE_DECLARATION',
//          30,
//          "Join variable declaration");
//  static const QA_REMOVE_TYPE_ANNOTATION =
//      const AssistKind('QA_REMOVE_TYPE_ANNOTATION', 29, "Remove type annotation");
//  static const QA_REPLACE_CONDITIONAL_WITH_IF_ELSE =
//      const AssistKind(
//          'QA_REPLACE_CONDITIONAL_WITH_IF_ELSE',
//          30,
//          "Replace conditional with 'if-else'");
//  static const QA_REPLACE_IF_ELSE_WITH_CONDITIONAL =
//      const AssistKind(
//          'QA_REPLACE_IF_ELSE_WITH_CONDITIONAL',
//          30,
//          "Replace 'if-else' with conditional ('c ? x : y')");
//  static const QA_SPLIT_AND_CONDITION =
//      const AssistKind('QA_SPLIT_AND_CONDITION', 30, "Split && condition");
//  static const QA_SPLIT_VARIABLE_DECLARATION =
//      const AssistKind(
//          'QA_SPLIT_VARIABLE_DECLARATION',
//          30,
//          "Split variable declaration");
//  static const QA_SURROUND_WITH_BLOCK =
//      const AssistKind('QA_SURROUND_WITH_BLOCK', 30, "Surround with block");
//  static const QA_SURROUND_WITH_DO_WHILE =
//      const AssistKind('QA_SURROUND_WITH_DO_WHILE', 30, "Surround with 'do-while'");
//  static const QA_SURROUND_WITH_FOR =
//      const AssistKind('QA_SURROUND_WITH_FOR', 30, "Surround with 'for'");
//  static const QA_SURROUND_WITH_FOR_IN =
//      const AssistKind('QA_SURROUND_WITH_FOR_IN', 30, "Surround with 'for-in'");
//  static const QA_SURROUND_WITH_IF =
//      const AssistKind('QA_SURROUND_WITH_IF', 30, "Surround with 'if'");
//  static const QA_SURROUND_WITH_TRY_CATCH =
//      const AssistKind('QA_SURROUND_WITH_TRY_CATCH', 30, "Surround with 'try-catch'");
//  static const QA_SURROUND_WITH_TRY_FINALLY =
//      const AssistKind(
//          'QA_SURROUND_WITH_TRY_FINALLY',
//          30,
//          "Surround with 'try-finally'");
//  static const QA_SURROUND_WITH_WHILE =
//      const AssistKind('QA_SURROUND_WITH_WHILE', 30, "Surround with 'while'");
//
//  final name;
//  final int relevance;
//  final String message;
//
//  const AssistKind(this.name, this.relevance, this.message);
//}
