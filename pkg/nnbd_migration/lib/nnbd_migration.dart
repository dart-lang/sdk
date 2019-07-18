// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/nullability_migration_impl.dart';

/// Kinds of fixes that might be performed by nullability migration.
class NullabilityFixKind {
  /// An import needs to be added.
  static const addImport =
      const NullabilityFixKind._(appliedMessage: 'Add an import');

  /// A formal parameter needs to have a required modifier added.
  static const addRequired =
      const NullabilityFixKind._(appliedMessage: "Add a 'required' modifier");

  /// An expression's value needs to be null-checked.
  static const checkExpression = const NullabilityFixKind._(
    appliedMessage: 'Added a null check to an expression',
  );

  /// An explicit type mentioned in the source program needs to be made
  /// nullable.
  static const makeTypeNullable = const NullabilityFixKind._(
    appliedMessage: 'Changed a type to be nullable',
  );

  /// An if-test or conditional expression needs to have its "then" branch
  /// discarded.
  static const discardThen = const NullabilityFixKind._(
    appliedMessage: 'Discarded an unreachable conditional then branch',
  );

  /// An if-test or conditional expression needs to have its "else" branch
  /// discarded.
  static const discardElse = const NullabilityFixKind._(
    appliedMessage: 'Discarded an unreachable conditional else branch',
  );

  /// A message used by dartfix to indicate a fix has been applied.
  final String appliedMessage;

  const NullabilityFixKind._({@required this.appliedMessage});
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
      {bool permissive}) = NullabilityMigrationImpl;

  void finish();

  void prepareInput(ResolvedUnitResult result);

  void processInput(ResolvedUnitResult result);
}

/// [NullabilityMigrationListener] is used by [NullabilityMigration]
/// to communicate source changes or "fixes" to the client.
abstract class NullabilityMigrationListener {
  /// Add the given [detail] to the list of details to be returned to the
  /// client.
  void addDetail(String detail);

  /// [addEdit] is called once for each source edit, in the order in which they
  /// appear in the source file.
  void addEdit(SingleNullabilityFix fix, SourceEdit edit);

  /// [addFix] is called once for each source change.
  void addFix(SingleNullabilityFix fix);
}

/// Representation of a single conceptual change made by the nullability
/// migration algorithm.  This change might require multiple source edits to
/// achieve.
abstract class SingleNullabilityFix {
  /// What kind of fix this is.
  NullabilityFixKind get kind;

  /// Location of the change, for reporting to the user.
  Location get location;

  /// File to change.
  Source get source;
}
