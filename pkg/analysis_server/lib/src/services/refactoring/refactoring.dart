// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.refactoring;

import 'dart:async';

import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/extract_local.dart';
import 'package:analysis_server/src/services/refactoring/rename_class_member.dart';
import 'package:analysis_server/src/services/refactoring/rename_constructor.dart';
import 'package:analysis_server/src/services/refactoring/rename_import.dart';
import 'package:analysis_server/src/services/refactoring/rename_library.dart';
import 'package:analysis_server/src/services/refactoring/rename_local.dart';
import 'package:analysis_server/src/services/refactoring/rename_unit_member.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';


/**
 * [Refactoring] to extract an expression into a local variable declaration.
 */
abstract class ExtractLocalRefactoring implements Refactoring {
  /**
   * Returns a new [ExtractLocalRefactoring] instance.
   */
  factory ExtractLocalRefactoring(CompilationUnit unit, int selectionOffset,
      int selectionLength) {
    return new ExtractLocalRefactoringImpl(
        unit,
        selectionOffset,
        selectionLength);
  }

  /**
   * True if all occurrences of the expression within the scope in which the
   * variable will be defined should be replaced by a reference to the local
   * variable. The expression used to initiate the refactoring will always be
   * replaced.
   */
  void set extractAll(bool extractAll);

  /**
   * The lengths of the expressions that would be replaced by a reference to the
   * variable. The lengths correspond to the offsets. In other words, for a
   * given expression, if the offset of that expression is offsets[i], then the
   * length of that expression is lengths[i].
   */
  List<int> get lengths;

  /**
   * The name that the local variable should be given.
   */
  void set name(String name);

  /**
   * The proposed names for the local variable.
   *
   * The first proposal should be used as the "best guess" (if it exists).
   */
  List<String> get names;

  /**
   * The offsets of the expressions that would be replaced by a reference to
   * the variable.
   */
  List<int> get offsets;

  /**
   * Validates that the [name] is a valid identifier and is appropriate for
   * local variable.
   *
   * It does not perform all the checks (such as checking for conflicts with any
   * existing names in any of the scopes containing the current name), as many
   * of these checkes require search engine. Use [checkFinalConditions] for this
   * level of checking.
   */
  RefactoringStatus checkName();
}


/**
 * Abstract interface for all refactorings.
 */
abstract class Refactoring {
  /**
   * The ids of source edits that are not known to be valid.
   *
   * An edit is not known to be valid if there was insufficient type information
   * for the server to be able to determine whether or not the code needs to be
   * modified, such as when a member is being renamed and there is a reference
   * to a member from an unknown type. This field will be omitted if the change
   * field is omitted or if there are no potential edits for the refactoring.
   */
  List<String> get potentialEditIds;

  /**
   * Returns the human readable name of this [Refactoring].
   */
  String get refactoringName;

  /**
   * Checks all conditions - [checkInitialConditions] and
   * [checkFinalConditions] to decide if refactoring can be performed.
   */
  Future<RefactoringStatus> checkAllConditions();

  /**
   * Validates environment to check if this refactoring can be performed.
   *
   * This check may be slow, because many refactorings use search engine.
   */
  Future<RefactoringStatus> checkFinalConditions();

  /**
   * Validates arguments to check if this refactoring can be performed.
   *
   * This check should be quick because it is used often as arguments change.
   */
  Future<RefactoringStatus> checkInitialConditions();

  /**
   * Returns the [Change] to apply to perform this refactoring.
   */
  Future<Change> createChange();

  /**
   * Returs `true` if the [Change] created by refactoring may be unsafe,
   * so we want user to review the [Change] to ensure that he understands it.
   */
  bool requiresPreview();
}


/**
 * Abstract [Refactoring] for renaming some [Element].
 */
abstract class RenameRefactoring implements Refactoring {
  /**
   * Returns a new [RenameRefactoring] instance for renaming [element],
   * maybe `null` if there is no support for renaming [Element]s of the given
   * type.
   */
  factory RenameRefactoring(SearchEngine searchEngine, Element element) {
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element.enclosingElement is CompilationUnitElement) {
      return new RenameUnitMemberRefactoringImpl(searchEngine, element);
    }
    if (element is ConstructorElement) {
      return new RenameConstructorRefactoringImpl(searchEngine, element);
    }
    if (element is ImportElement) {
      return new RenameImportRefactoringImpl(searchEngine, element);
    }
    if (element is LibraryElement) {
      return new RenameLibraryRefactoringImpl(searchEngine, element);
    }
    if (element is LocalElement) {
      return new RenameLocalRefactoringImpl(searchEngine, element);
    }
    if (element.enclosingElement is ClassElement) {
      return new RenameClassMemberRefactoringImpl(searchEngine, element);
    }
    return null;
  }

  /**
   * Sets the new name for the [Element].
   */
  void set newName(String newName);

  /**
   * Returns the old name of the [Element] being renamed.
   */
  String get oldName;

  /**
   * Validates that the [newName] is a valid identifier and is appropriate for
   * the type of the [Element] being renamed.
   *
   * It does not perform all the checks (such as checking for conflicts with any
   * existing names in any of the scopes containing the current name), as many
   * of these checkes require search engine. Use [checkFinalConditions] for this
   * level of checking.
   */
  RefactoringStatus checkNewName();
}
