// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/nullability_migration_impl.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:nnbd_migration/src/utilities/hint_utils.dart' show HintComment;

/// Description of fixes that might be performed by nullability migration.
class NullabilityFixDescription {
  /// An import was added to the library.
  static const addImport = NullabilityFixDescription._(
      appliedMessage: 'Added import for use in migrated code',
      kind: NullabilityFixKind.addImport);

  /// A variable declaration needs to be marked as "late".
  static const addLate = NullabilityFixDescription._(
      appliedMessage: 'Added a late keyword', kind: NullabilityFixKind.addLate);

  /// A variable declaration needs to be marked as "late" due to the presence of
  /// a `/*late*/` hint.
  static const addLateDueToHint = NullabilityFixDescription._(
      appliedMessage: 'Added a late keyword, due to a hint',
      kind: NullabilityFixKind.addLateDueToHint);

  /// A variable declaration needs to be marked as "late" due to being certainly
  /// assigned in test setup.
  static const addLateDueToTestSetup = NullabilityFixDescription._(
      appliedMessage: 'Added a late keyword, due to assignment in `setUp`',
      kind: NullabilityFixKind.addLateDueToTestSetup);

  /// A variable declaration needs to be marked as "late" and "final" due to the
  /// presence of a `/*late final*/` hint.
  static const addLateFinalDueToHint = NullabilityFixDescription._(
      appliedMessage: 'Added late and final keywords, due to a hint',
      kind: NullabilityFixKind.addLateFinalDueToHint);

  /// An expression's value needs to be null-checked.
  static const checkExpression = NullabilityFixDescription._(
    appliedMessage: 'Added a non-null assertion to nullable expression',
    kind: NullabilityFixKind.checkExpression,
  );

  /// An expression's value will be null-checked due to a hint.
  static const checkExpressionDueToHint = NullabilityFixDescription._(
    appliedMessage: 'Accepted a null check hint',
    kind: NullabilityFixKind.checkExpressionDueToHint,
  );

  /// A compound assignment's combiner operator returns a type that isn't
  /// assignable to the LHS of the assignment.
  static const compoundAssignmentHasBadCombinedType =
      NullabilityFixDescription._(
    appliedMessage: 'Compound assignment has bad combined type',
    kind: NullabilityFixKind.compoundAssignmentHasBadCombinedType,
  );

  /// A compound assignment's LHS has a nullable type.
  static const compoundAssignmentHasNullableSource =
      NullabilityFixDescription._(
    appliedMessage: 'Compound assignment has nullable source',
    kind: NullabilityFixKind.compoundAssignmentHasNullableSource,
  );

  /// Informative message: a condition of an if-test or conditional expression
  /// will always evaluate to `false` in strong checking mode.
  static const conditionFalseInStrongMode = NullabilityFixDescription._(
      appliedMessage: 'Condition will always be false in strong checking mode',
      kind: NullabilityFixKind.conditionFalseInStrongMode);

  /// Informative message: a condition of an if-test or conditional expression
  /// will always evaluate to `true` in strong checking mode.
  static const conditionTrueInStrongMode = NullabilityFixDescription._(
      appliedMessage: 'Condition will always be true in strong checking mode',
      kind: NullabilityFixKind.conditionTrueInStrongMode);

  /// An if-test or conditional expression needs to have its condition
  /// discarded.
  static const discardCondition = NullabilityFixDescription._(
    appliedMessage: 'Discarded a condition which is always true',
    kind: NullabilityFixKind.removeDeadCode,
  );

  /// An if-test or conditional expression needs to have its condition and
  /// "else" branch discarded.
  static const discardElse = NullabilityFixDescription._(
    appliedMessage: 'Discarded an unreachable conditional else branch',
    kind: NullabilityFixKind.removeDeadCode,
  );

  /// An if-test or conditional expression needs to have its condition and
  /// "then" branch discarded.
  static const discardThen = NullabilityFixDescription._(
    appliedMessage:
        'Discarded a condition which is always false, and the "then" branch '
        'that follows',
    kind: NullabilityFixKind.removeDeadCode,
  );

  /// An if-test needs to be discarded completely.
  static const discardIf = NullabilityFixDescription._(
    appliedMessage: 'Discarded an if-test with no effect',
    kind: NullabilityFixKind.removeDeadCode,
  );

  static const downcastExpression = NullabilityFixDescription._(
    appliedMessage: 'Added a downcast to an expression',
    kind: NullabilityFixKind.downcastExpression,
  );

  /// Informative message: there is no valid migration for `null` in a
  /// non-nullable context.
  static const noValidMigrationForNull = NullabilityFixDescription._(
      appliedMessage: 'No valid migration for `null` in a non-nullable context',
      kind: NullabilityFixKind.noValidMigrationForNull);

  /// Informative message: a null-aware access won't be necessary in strong
  /// checking mode.
  static const nullAwarenessUnnecessaryInStrongMode =
      NullabilityFixDescription._(
          appliedMessage:
              'Null-aware access will be unnecessary in strong checking mode',
          kind: NullabilityFixKind.nullAwarenessUnnecessaryInStrongMode);

  /// Informative message: a null-aware assignment won't be necessary in strong
  /// checking mode.
  static const nullAwareAssignmentUnnecessaryInStrongMode =
      NullabilityFixDescription._(
          appliedMessage:
              'Null-aware assignment will be unnecessary in strong checking mode',
          kind: NullabilityFixKind.nullAwareAssignmentUnnecessaryInStrongMode);

  static const otherCastExpression = NullabilityFixDescription._(
    appliedMessage: 'Added a cast to an expression (non-downcast)',
    kind: NullabilityFixKind.otherCastExpression,
  );

  /// An unnecessary downcast has been discarded.
  static const removeLanguageVersionComment = NullabilityFixDescription._(
    appliedMessage: 'Removed language version comment so that NNBD features '
        'will be allowed in this file',
    kind: NullabilityFixKind.removeLanguageVersionComment,
  );

  /// An unnecessary downcast has been discarded.
  static const removeAs = NullabilityFixDescription._(
    appliedMessage: 'Discarded a downcast that is now unnecessary',
    kind: NullabilityFixKind.removeAs,
  );

  /// A null-aware operator needs to be changed into its non-null-aware
  /// equivalent.
  static const removeNullAwareness = NullabilityFixDescription._(
      appliedMessage:
          'Changed a null-aware access into an ordinary access, because the target cannot be null',
      kind: NullabilityFixKind.removeDeadCode);

  /// A null-aware assignment was removed because its LHS is non-nullable.
  static const removeNullAwareAssignment = NullabilityFixDescription._(
      appliedMessage:
          'Removed a null-aware assignment, because the target cannot be null',
      kind: NullabilityFixKind.removeDeadCode);

  /// A message used to indicate a fix has been applied.
  final String appliedMessage;

  /// The kind of fix described.
  final NullabilityFixKind kind;

  /// A formal parameter needs to have a required keyword added.
  factory NullabilityFixDescription.addRequired(
          String className, String functionName, String paramName) =>
      NullabilityFixDescription._(
        appliedMessage: "Add 'required' keyword to parameter '$paramName' in " +
            (className == null ? functionName : "'$className.$functionName'"),
        kind: NullabilityFixKind.addRequired,
      );

  /// An explicit type needs to be added.
  factory NullabilityFixDescription.addType(String typeText) =>
      NullabilityFixDescription._(
        appliedMessage: "Add the explicit type '$typeText'",
        kind: NullabilityFixKind.replaceVar,
      );

  /// A method call was changed from calling one method to another.
  factory NullabilityFixDescription.changeMethodName(
          String oldName, String newName) =>
      NullabilityFixDescription._(
          appliedMessage: "Changed method '$oldName' to '$newName'",
          kind: NullabilityFixKind.changeMethodName);

  /// An explicit type mentioned in the source program needs to be made
  /// nullable.
  factory NullabilityFixDescription.makeTypeNullable(String type) =>
      NullabilityFixDescription._(
        appliedMessage: "Changed type '$type' to be nullable",
        kind: NullabilityFixKind.makeTypeNullable,
      );

  /// An explicit type mentioned in the source program will be made
  /// nullable due to a nullability hint.
  factory NullabilityFixDescription.makeTypeNullableDueToHint(String type) =>
      NullabilityFixDescription._(
        appliedMessage:
            "Changed type '$type' to be nullable, due to a nullability hint",
        kind: NullabilityFixKind.makeTypeNullableDueToHint,
      );

  /// A 'var' declaration needs to be replaced with an explicit type.
  factory NullabilityFixDescription.replaceVar(String typeText) =>
      NullabilityFixDescription._(
        appliedMessage: "Replace 'var' with '$typeText'",
        kind: NullabilityFixKind.replaceVar,
      );

  /// An explicit type mentioned in the source program does not need to be made
  /// nullable.
  factory NullabilityFixDescription.typeNotMadeNullable(String type) =>
      NullabilityFixDescription._(
        appliedMessage: "Type '$type' was not made nullable",
        kind: NullabilityFixKind.typeNotMadeNullable,
      );

  /// An explicit type mentioned in the source program does not need to be made
  /// nullable.
  factory NullabilityFixDescription.typeNotMadeNullableDueToHint(String type) =>
      NullabilityFixDescription._(
        appliedMessage: "Type '$type' was not made nullable due to a hint",
        kind: NullabilityFixKind.typeNotMadeNullableDueToHint,
      );

  const NullabilityFixDescription._(
      {@required this.appliedMessage, @required this.kind})
      : assert(appliedMessage != null),
        assert(kind != null);

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, appliedMessage.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  bool operator ==(Object other) =>
      other is NullabilityFixDescription &&
      appliedMessage == other.appliedMessage &&
      kind == other.kind;

  @override
  String toString() =>
      'NullabilityFixDescription(${json.encode(appliedMessage)}, $kind)';
}

/// An enumeration of the various kinds of nullability fixes.
enum NullabilityFixKind {
  addImport,
  addLate,
  addLateDueToHint,
  addLateDueToTestSetup,
  addLateFinalDueToHint,
  addRequired,
  addType,
  changeMethodName,
  checkExpression,
  checkExpressionDueToHint,
  compoundAssignmentHasNullableSource,
  compoundAssignmentHasBadCombinedType,
  conditionFalseInStrongMode,
  conditionTrueInStrongMode,
  downcastExpression,
  makeTypeNullable,
  makeTypeNullableDueToHint,
  noValidMigrationForNull,
  nullAwarenessUnnecessaryInStrongMode,
  nullAwareAssignmentUnnecessaryInStrongMode,
  otherCastExpression,
  removeAs,
  removeDeadCode,
  removeLanguageVersionComment,
  replaceVar,
  typeNotMadeNullable,
  typeNotMadeNullableDueToHint,
}

/// Provisional API for DartFix to perform nullability migration.
///
/// Usage: pass each input source file to [prepareInput].  Then pass each input
/// source file to [processInput].  Then pass each input source file to
/// [finalizeInput].  Then call [finish] to obtain the modifications that need
/// to be made to each source file.
abstract class NullabilityMigration {
  /// Prepares to perform nullability migration.
  ///
  /// If [permissive] is `true`, exception handling logic will try to proceed
  /// as far as possible even though the migration algorithm is not yet
  /// complete.  TODO(paulberry): remove this mode once the migration algorithm
  /// is fully implemented.
  ///
  /// Optional parameter [removeViaComments] indicates whether code that the
  /// migration tool wishes to remove should instead be commenting it out.
  ///
  /// Optional parameter [warnOnWeakCode] indicates whether weak-only code
  /// should be warned about or removed (in the way specified by
  /// [removeViaComments]).
  factory NullabilityMigration(NullabilityMigrationListener listener,
      LineInfo Function(String) getLineInfo,
      {bool permissive,
      NullabilityMigrationInstrumentation instrumentation,
      bool removeViaComments,
      bool warnOnWeakCode}) = NullabilityMigrationImpl;

  /// Check if this migration is being run permissively.
  bool get isPermissive;

  /// Use this getter after any calls to [prepareInput] to obtain a list of URIs
  /// of unmigrated dependencies.  Ideally, this list should be empty before the
  /// user tries to migrate their package.
  List<String> get unmigratedDependencies;

  void finalizeInput(ResolvedUnitResult result);

  /// Finishes the migration.  Returns a map indicating packages that have been
  /// newly imported by the migration; the caller should ensure that these
  /// packages are properly imported by the package's pubspec.
  ///
  /// Keys of the returned map are package names; values indicate the minimum
  /// required version of each package.
  Map<String, Version> finish();

  void prepareInput(ResolvedUnitResult result);

  void processInput(ResolvedUnitResult result);

  /// Update the migration after an edge has been added or removed.
  void update();
}

/// [NullabilityMigrationListener] is used by [NullabilityMigration]
/// to communicate source changes or "fixes" to the client.
abstract class NullabilityMigrationListener {
  /// [addEdit] is called once for each source edit, in the order in which they
  /// appear in the source file.
  void addEdit(Source source, SourceEdit edit);

  void addSuggestion(String descriptions, Location location);

  /// [reportException] is called once for each exception that occurs in
  /// "permissive mode", reporting the location of the exception and the
  /// exception details.
  void reportException(
      Source source, AstNode node, Object exception, StackTrace stackTrace);
}
