// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/nullability_migration_impl.dart';

/// Description of fixes that might be performed by nullability migration.
class NullabilityFixDescription {
  /// An if-test or conditional expression needs to have its "then" branch
  /// discarded.
  static const discardThen = const NullabilityFixDescription._(
    appliedMessage: 'Discarded an unreachable conditional then branch',
  );

  /// An if-test or conditional expression needs to have its "else" branch
  /// discarded.
  static const discardElse = const NullabilityFixDescription._(
    appliedMessage: 'Discarded an unreachable conditional else branch',
  );

  /// An expression's value needs to be null-checked.
  static const checkExpression = const NullabilityFixDescription._(
    appliedMessage: 'Added a non-null assertion to nullable expression',
  );

  /// A message used by dartfix to indicate a fix has been applied.
  final String appliedMessage;

  /// A formal parameter needs to have a required keyword added.
  factory NullabilityFixDescription.addRequired(
          String className, String functionName, String paramName) =>
      NullabilityFixDescription._(
          appliedMessage:
              "Add 'required' keyword to parameter '$paramName' in " +
                  (className == null
                      ? functionName
                      : "'$className.$functionName'"));

  /// An explicit type mentioned in the source program needs to be made
  /// nullable.
  factory NullabilityFixDescription.makeTypeNullable(String type) =>
      NullabilityFixDescription._(
        appliedMessage: "Changed type '$type' to be nullable",
      );

  const NullabilityFixDescription._({@required this.appliedMessage});
}

/// Provisional API for DartFix to perform nullability migration.
///
/// Usage: pass each input source file to [prepareInput].  Then pass each input
/// source file to [processInput].  Then call [finish] to obtain the
/// modifications that need to be made to each source file.
abstract class NullabilityMigration {
  /// Prepares to perform nullability migration.
  ///
  /// If [permissive] is `true`, exception handling logic will try to proceed
  /// as far as possible even though the migration algorithm is not yet
  /// complete.  TODO(paulberry): remove this mode once the migration algorithm
  /// is fully implemented.
  factory NullabilityMigration(NullabilityMigrationListener listener,
          {bool permissive,
          NullabilityMigrationInstrumentation instrumentation}) =
      NullabilityMigrationImpl;

  void finish();

  void prepareInput(ResolvedUnitResult result);

  void processInput(ResolvedUnitResult result);
}

/// [NullabilityMigrationListener] is used by [NullabilityMigration]
/// to communicate source changes or "fixes" to the client.
abstract class NullabilityMigrationListener {
  /// [addEdit] is called once for each source edit, in the order in which they
  /// appear in the source file.
  void addEdit(SingleNullabilityFix fix, SourceEdit edit);

  /// [addFix] is called once for each source change.
  void addFix(SingleNullabilityFix fix);

  /// [reportException] is called once for each exception that occurs in
  /// "permissive mode", reporting the location of the exception and the
  /// exception details.
  void reportException(
      Source source, AstNode node, Object exception, StackTrace stackTrace);
}

/// Representation of a single conceptual change made by the nullability
/// migration algorithm.  This change might require multiple source edits to
/// achieve.
abstract class SingleNullabilityFix {
  /// What kind of fix this is.
  NullabilityFixDescription get description;

  /// Location of the change, for reporting to the user.
  Location get location;

  /// File to change.
  Source get source;
}
