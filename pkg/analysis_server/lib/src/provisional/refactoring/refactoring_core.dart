// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * Abstract interface for all refactorings.
 */
abstract class Refactoring {
  /**
   * Return the ids of source edits that are not known to be valid.
   *
   * An edit is not known to be valid if there was insufficient type information
   * for the server to be able to determine whether or not the code needs to be
   * modified, such as when a member is being renamed and there is a reference
   * to a member from an unknown type. This field will be omitted if the change
   * field is omitted or if there are no potential edits for the refactoring.
   */
  List<String> get potentialEditIds;

  /**
   * Return the human readable name of this refactoring.
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
   * Return the [Change] to apply to perform this refactoring.
   */
  Future<SourceChange> createChange();

  /**
   * Return `true` if the [Change] created by refactoring may be unsafe,
   * so we want user to review the [Change] to ensure that he understands it.
   */
  bool requiresPreview();
}

/**
 *
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class RefactoringContributor {
  /**
   *
   */
  Refactoring createRefactoring(AnalysisContext context, RefactoringKind kind,
      Source source, int offset, int length);

  /**
   *
   */
  List<RefactoringKind> getAvailableRefactorings(
      AnalysisContext context, Source source, int offset, int length);
}

/**
 *
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class RefactoringKind {
  factory RefactoringKind(String name, bool requiresOptions) {
    // TODO(brianwilkerson) Redirect to impl class.
    return null;
  }
  bool get requiresOptions;
}

/**
 *
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class RefactoringStatus {
  // TODO(brianwilkerson) Fill this in.
}
