// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.proposal;

import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'change.dart';

/**
 * [CorrectionProposal] for adding new dependency into pubspec.
 */
class AddDependencyCorrectionProposal extends CorrectionProposal {
  final JavaFile file;

  final String packageName;

  AddDependencyCorrectionProposal(this.file, this.packageName, CorrectionKind kind, List<Object> arguments) : super(kind, arguments);
}

/**
 * [CorrectionProposal] with some [Change].
 */
class ChangeCorrectionProposal extends CorrectionProposal {
  final Change change;

  ChangeCorrectionProposal(this.change, CorrectionKind kind, List<Object> arguments) : super(kind, arguments);
}

/**
 * Enumeration of images used by correction processors.
 */
class CorrectionImage extends Enum<CorrectionImage> {
  static const CorrectionImage IMG_CORRECTION_CHANGE = const CorrectionImage('IMG_CORRECTION_CHANGE', 0);

  static const CorrectionImage IMG_CORRECTION_CLASS = const CorrectionImage('IMG_CORRECTION_CLASS', 1);

  static const List<CorrectionImage> values = const [IMG_CORRECTION_CHANGE, IMG_CORRECTION_CLASS];

  const CorrectionImage(String name, int ordinal) : super(name, ordinal);
}

/**
 * Identifier of [CorrectionProposal].
 */
class CorrectionKind extends Enum<CorrectionKind> {
  static const CorrectionKind QA_ADD_PART_DIRECTIVE = const CorrectionKind.con1('QA_ADD_PART_DIRECTIVE', 0, 30, "Add 'part' directive");

  static const CorrectionKind QA_ADD_TYPE_ANNOTATION = const CorrectionKind.con1('QA_ADD_TYPE_ANNOTATION', 1, 30, "Add type annotation");

  static const CorrectionKind QA_ASSIGN_TO_LOCAL_VARIABLE = const CorrectionKind.con1('QA_ASSIGN_TO_LOCAL_VARIABLE', 2, 30, "Assign value to new local variable");

  static const CorrectionKind QA_CONVERT_INTO_BLOCK_BODY = const CorrectionKind.con1('QA_CONVERT_INTO_BLOCK_BODY', 3, 30, "Convert into block body");

  static const CorrectionKind QA_CONVERT_INTO_EXPRESSION_BODY = const CorrectionKind.con1('QA_CONVERT_INTO_EXPRESSION_BODY', 4, 30, "Convert into expression body");

  static const CorrectionKind QA_CONVERT_INTO_IS_NOT = const CorrectionKind.con1('QA_CONVERT_INTO_IS_NOT', 5, 30, "Convert into is!");

  static const CorrectionKind QA_CONVERT_INTO_IS_NOT_EMPTY = const CorrectionKind.con1('QA_CONVERT_INTO_IS_NOT_EMPTY', 6, 30, "Convert into 'isNotEmpty'");

  static const CorrectionKind QA_EXCHANGE_OPERANDS = const CorrectionKind.con1('QA_EXCHANGE_OPERANDS', 7, 30, "Exchange operands");

  static const CorrectionKind QA_EXTRACT_CLASS = const CorrectionKind.con1('QA_EXTRACT_CLASS', 8, 30, "Extract class into file '%s'");

  static const CorrectionKind QA_IMPORT_ADD_SHOW = const CorrectionKind.con1('QA_IMPORT_ADD_SHOW', 9, 30, "Add explicit 'show' combinator");

  static const CorrectionKind QA_INVERT_IF_STATEMENT = const CorrectionKind.con1('QA_INVERT_IF_STATEMENT', 10, 30, "Invert 'if' statement");

  static const CorrectionKind QA_JOIN_IF_WITH_INNER = const CorrectionKind.con1('QA_JOIN_IF_WITH_INNER', 11, 30, "Join 'if' statement with inner 'if' statement");

  static const CorrectionKind QA_JOIN_IF_WITH_OUTER = const CorrectionKind.con1('QA_JOIN_IF_WITH_OUTER', 12, 30, "Join 'if' statement with outer 'if' statement");

  static const CorrectionKind QA_JOIN_VARIABLE_DECLARATION = const CorrectionKind.con1('QA_JOIN_VARIABLE_DECLARATION', 13, 30, "Join variable declaration");

  static const CorrectionKind QA_REMOVE_TYPE_ANNOTATION = const CorrectionKind.con1('QA_REMOVE_TYPE_ANNOTATION', 14, 29, "Remove type annotation");

  static const CorrectionKind QA_REPLACE_CONDITIONAL_WITH_IF_ELSE = const CorrectionKind.con1('QA_REPLACE_CONDITIONAL_WITH_IF_ELSE', 15, 30, "Replace conditional with 'if-else'");

  static const CorrectionKind QA_REPLACE_IF_ELSE_WITH_CONDITIONAL = const CorrectionKind.con1('QA_REPLACE_IF_ELSE_WITH_CONDITIONAL', 16, 30, "Replace 'if-else' with conditional ('c ? x : y')");

  static const CorrectionKind QA_SPLIT_AND_CONDITION = const CorrectionKind.con1('QA_SPLIT_AND_CONDITION', 17, 30, "Split && condition");

  static const CorrectionKind QA_SPLIT_VARIABLE_DECLARATION = const CorrectionKind.con1('QA_SPLIT_VARIABLE_DECLARATION', 18, 30, "Split variable declaration");

  static const CorrectionKind QA_SURROUND_WITH_BLOCK = const CorrectionKind.con1('QA_SURROUND_WITH_BLOCK', 19, 30, "Surround with block");

  static const CorrectionKind QA_SURROUND_WITH_DO_WHILE = const CorrectionKind.con1('QA_SURROUND_WITH_DO_WHILE', 20, 30, "Surround with 'do-while'");

  static const CorrectionKind QA_SURROUND_WITH_FOR = const CorrectionKind.con1('QA_SURROUND_WITH_FOR', 21, 30, "Surround with 'for'");

  static const CorrectionKind QA_SURROUND_WITH_FOR_IN = const CorrectionKind.con1('QA_SURROUND_WITH_FOR_IN', 22, 30, "Surround with 'for-in'");

  static const CorrectionKind QA_SURROUND_WITH_IF = const CorrectionKind.con1('QA_SURROUND_WITH_IF', 23, 30, "Surround with 'if'");

  static const CorrectionKind QA_SURROUND_WITH_TRY_CATCH = const CorrectionKind.con1('QA_SURROUND_WITH_TRY_CATCH', 24, 30, "Surround with 'try-catch'");

  static const CorrectionKind QA_SURROUND_WITH_TRY_FINALLY = const CorrectionKind.con1('QA_SURROUND_WITH_TRY_FINALLY', 25, 30, "Surround with 'try-finally'");

  static const CorrectionKind QA_SURROUND_WITH_WHILE = const CorrectionKind.con1('QA_SURROUND_WITH_WHILE', 26, 30, "Surround with 'while'");

  static const CorrectionKind QF_ADD_PACKAGE_DEPENDENCY = const CorrectionKind.con1('QF_ADD_PACKAGE_DEPENDENCY', 27, 50, "Add dependency on package '%s'");

  static const CorrectionKind QF_ADD_SUPER_CONSTRUCTOR_INVOCATION = const CorrectionKind.con1('QF_ADD_SUPER_CONSTRUCTOR_INVOCATION', 28, 50, "Add super constructor %s invocation");

  static const CorrectionKind QF_CHANGE_TO = const CorrectionKind.con1('QF_CHANGE_TO', 29, 51, "Change to '%s'");

  static const CorrectionKind QF_CHANGE_TO_STATIC_ACCESS = const CorrectionKind.con1('QF_CHANGE_TO_STATIC_ACCESS', 30, 50, "Change access to static using '%s'");

  static const CorrectionKind QF_CREATE_CLASS = const CorrectionKind.con2('QF_CREATE_CLASS', 31, 50, "Create class '%s'", CorrectionImage.IMG_CORRECTION_CLASS);

  static const CorrectionKind QF_CREATE_CONSTRUCTOR = const CorrectionKind.con1('QF_CREATE_CONSTRUCTOR', 32, 50, "Create constructor '%s'");

  static const CorrectionKind QF_CREATE_CONSTRUCTOR_SUPER = const CorrectionKind.con1('QF_CREATE_CONSTRUCTOR_SUPER', 33, 50, "Create constructor to call %s");

  static const CorrectionKind QF_CREATE_FUNCTION = const CorrectionKind.con1('QF_CREATE_FUNCTION', 34, 49, "Create function '%s'");

  static const CorrectionKind QF_CREATE_METHOD = const CorrectionKind.con1('QF_CREATE_METHOD', 35, 50, "Create method '%s'");

  static const CorrectionKind QF_CREATE_MISSING_OVERRIDES = const CorrectionKind.con1('QF_CREATE_MISSING_OVERRIDES', 36, 50, "Create %d missing override(s)");

  static const CorrectionKind QF_CREATE_NO_SUCH_METHOD = const CorrectionKind.con1('QF_CREATE_NO_SUCH_METHOD', 37, 49, "Create 'noSuchMethod' method");

  static const CorrectionKind QF_CREATE_PART = const CorrectionKind.con1('QF_CREATE_PART', 38, 50, "Create part '%s'");

  static const CorrectionKind QF_IMPORT_LIBRARY_PREFIX = const CorrectionKind.con1('QF_IMPORT_LIBRARY_PREFIX', 39, 51, "Use imported library '%s' with prefix '%s'");

  static const CorrectionKind QF_IMPORT_LIBRARY_PROJECT = const CorrectionKind.con1('QF_IMPORT_LIBRARY_PROJECT', 40, 51, "Import library '%s'");

  static const CorrectionKind QF_IMPORT_LIBRARY_SDK = const CorrectionKind.con1('QF_IMPORT_LIBRARY_SDK', 41, 51, "Import library '%s'");

  static const CorrectionKind QF_IMPORT_LIBRARY_SHOW = const CorrectionKind.con1('QF_IMPORT_LIBRARY_SHOW', 42, 51, "Update library '%s' import");

  static const CorrectionKind QF_INSERT_SEMICOLON = const CorrectionKind.con1('QF_INSERT_SEMICOLON', 43, 50, "Insert ';'");

  static const CorrectionKind QF_MAKE_CLASS_ABSTRACT = const CorrectionKind.con1('QF_MAKE_CLASS_ABSTRACT', 44, 50, "Make class '%s' abstract");

  static const CorrectionKind QF_REMOVE_PARAMETERS_IN_GETTER_DECLARATION = const CorrectionKind.con1('QF_REMOVE_PARAMETERS_IN_GETTER_DECLARATION', 45, 50, "Remove parameters in getter declaration");

  static const CorrectionKind QF_REMOVE_PARENTHESIS_IN_GETTER_INVOCATION = const CorrectionKind.con1('QF_REMOVE_PARENTHESIS_IN_GETTER_INVOCATION', 46, 50, "Remove parentheses in getter invocation");

  static const CorrectionKind QF_REMOVE_UNNECASSARY_CAST = const CorrectionKind.con1('QF_REMOVE_UNNECASSARY_CAST', 47, 50, "Remove unnecessary cast");

  static const CorrectionKind QF_REMOVE_UNUSED_IMPORT = const CorrectionKind.con1('QF_REMOVE_UNUSED_IMPORT', 48, 50, "Remove unused import");

  static const CorrectionKind QF_REPLACE_BOOLEAN_WITH_BOOL = const CorrectionKind.con1('QF_REPLACE_BOOLEAN_WITH_BOOL', 49, 50, "Replace 'boolean' with 'bool'");

  static const CorrectionKind QF_USE_CONST = const CorrectionKind.con1('QF_USE_CONST', 50, 50, "Change to constant");

  static const CorrectionKind QF_USE_EFFECTIVE_INTEGER_DIVISION = const CorrectionKind.con1('QF_USE_EFFECTIVE_INTEGER_DIVISION', 51, 50, "Use effective integer division ~/");

  static const CorrectionKind QF_USE_EQ_EQ_NULL = const CorrectionKind.con1('QF_USE_EQ_EQ_NULL', 52, 50, "Use == null instead of 'is Null'");

  static const CorrectionKind QF_USE_NOT_EQ_NULL = const CorrectionKind.con1('QF_USE_NOT_EQ_NULL', 53, 50, "Use != null instead of 'is! Null'");

  static const List<CorrectionKind> values = const [
      QA_ADD_PART_DIRECTIVE,
      QA_ADD_TYPE_ANNOTATION,
      QA_ASSIGN_TO_LOCAL_VARIABLE,
      QA_CONVERT_INTO_BLOCK_BODY,
      QA_CONVERT_INTO_EXPRESSION_BODY,
      QA_CONVERT_INTO_IS_NOT,
      QA_CONVERT_INTO_IS_NOT_EMPTY,
      QA_EXCHANGE_OPERANDS,
      QA_EXTRACT_CLASS,
      QA_IMPORT_ADD_SHOW,
      QA_INVERT_IF_STATEMENT,
      QA_JOIN_IF_WITH_INNER,
      QA_JOIN_IF_WITH_OUTER,
      QA_JOIN_VARIABLE_DECLARATION,
      QA_REMOVE_TYPE_ANNOTATION,
      QA_REPLACE_CONDITIONAL_WITH_IF_ELSE,
      QA_REPLACE_IF_ELSE_WITH_CONDITIONAL,
      QA_SPLIT_AND_CONDITION,
      QA_SPLIT_VARIABLE_DECLARATION,
      QA_SURROUND_WITH_BLOCK,
      QA_SURROUND_WITH_DO_WHILE,
      QA_SURROUND_WITH_FOR,
      QA_SURROUND_WITH_FOR_IN,
      QA_SURROUND_WITH_IF,
      QA_SURROUND_WITH_TRY_CATCH,
      QA_SURROUND_WITH_TRY_FINALLY,
      QA_SURROUND_WITH_WHILE,
      QF_ADD_PACKAGE_DEPENDENCY,
      QF_ADD_SUPER_CONSTRUCTOR_INVOCATION,
      QF_CHANGE_TO,
      QF_CHANGE_TO_STATIC_ACCESS,
      QF_CREATE_CLASS,
      QF_CREATE_CONSTRUCTOR,
      QF_CREATE_CONSTRUCTOR_SUPER,
      QF_CREATE_FUNCTION,
      QF_CREATE_METHOD,
      QF_CREATE_MISSING_OVERRIDES,
      QF_CREATE_NO_SUCH_METHOD,
      QF_CREATE_PART,
      QF_IMPORT_LIBRARY_PREFIX,
      QF_IMPORT_LIBRARY_PROJECT,
      QF_IMPORT_LIBRARY_SDK,
      QF_IMPORT_LIBRARY_SHOW,
      QF_INSERT_SEMICOLON,
      QF_MAKE_CLASS_ABSTRACT,
      QF_REMOVE_PARAMETERS_IN_GETTER_DECLARATION,
      QF_REMOVE_PARENTHESIS_IN_GETTER_INVOCATION,
      QF_REMOVE_UNNECASSARY_CAST,
      QF_REMOVE_UNUSED_IMPORT,
      QF_REPLACE_BOOLEAN_WITH_BOOL,
      QF_USE_CONST,
      QF_USE_EFFECTIVE_INTEGER_DIVISION,
      QF_USE_EQ_EQ_NULL,
      QF_USE_NOT_EQ_NULL];

  final int relevance;

  final String message;

  final CorrectionImage image;

  const CorrectionKind.con1(String name, int ordinal, int relevance, String message) : this.con2(name, ordinal, relevance, message, CorrectionImage.IMG_CORRECTION_CHANGE);

  const CorrectionKind.con2(String name, int ordinal, this.relevance, this.message, this.image) : super(name, ordinal);
}

/**
 * Proposal for some change.
 */
class CorrectionProposal {
  /**
   * An empty array of [CorrectionProposal]s.
   */
  static List<CorrectionProposal> EMPTY_ARRAY = new List<CorrectionProposal>(0);

  final CorrectionKind kind;

  String _name;

  CorrectionProposal(this.kind, List<Object> arguments) {
    this._name = formatList(kind.message, arguments);
  }

  /**
   * @return the name to display for user.
   */
  String get name => _name;
}

/**
 * [CorrectionProposal] to create new file.
 */
class CreateFileCorrectionProposal extends CorrectionProposal {
  final JavaFile file;

  final String content;

  CreateFileCorrectionProposal(this.file, this.content, CorrectionKind kind, List<Object> arguments) : super(kind, arguments);
}

/**
 * Proposal for linked position.
 */
class LinkedPositionProposal {
  final CorrectionImage icon;

  final String text;

  LinkedPositionProposal(this.icon, this.text);
}

/**
 * [CorrectionProposal] with single [Source] change.
 */
class SourceCorrectionProposal extends CorrectionProposal {
  final SourceChange change;

  Map<String, List<SourceRange>> _linkedPositions = {};

  Map<String, List<LinkedPositionProposal>> _linkedPositionProposals = {};

  SourceRange endRange;

  SourceCorrectionProposal(this.change, CorrectionKind kind, List<Object> arguments) : super(kind, arguments);

  /**
   * @return the [Map] or position IDs to their proposals.
   */
  Map<String, List<LinkedPositionProposal>> get linkedPositionProposals => _linkedPositionProposals;

  /**
   * @return the [Map] of position IDs to their locations.
   */
  Map<String, List<SourceRange>> get linkedPositions => _linkedPositions;

  /**
   * Sets [Map] of position IDs to their proposals.
   */
  void set linkedPositionProposals(Map<String, List<LinkedPositionProposal>> linkedPositionProposals) {
    this._linkedPositionProposals = {};
  }

  /**
   * Sets the [Map] or position IDs to their locations.
   */
  void set linkedPositions(Map<String, List<SourceRange>> linkedPositions) {
    this._linkedPositions = {};
  }
}