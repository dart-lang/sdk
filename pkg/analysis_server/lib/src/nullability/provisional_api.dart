// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/nullability/transitional_api.dart'
    as analyzer;
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';

/// Kinds of fixes that might be performed by nullability migration.
class NullabilityFixKind {
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
///
/// TODO(paulberry): figure out whether this API is what we want, and figure out
/// what file/folder it belongs in.
class NullabilityMigration {
  final _analyzerMigration = analyzer.NullabilityMigration();
  final NullabilityMigrationListener listener;

  NullabilityMigration(this.listener);

  void finish() {
    _analyzerMigration.finish().forEach((pm) {
      listener.addFix(_SingleNullabilityFix(pm));
    });
  }

  void prepareInput(ResolvedUnitResult result) {
    _analyzerMigration.prepareInput(result.unit);
  }

  void processInput(ResolvedUnitResult result) {
    _analyzerMigration.processInput(result.unit, result.typeProvider);
  }
}

/// [NullabilityMigrationListener] is used by [NullabilityMigration]
/// to communicate source changes or "fixes" to the client.
abstract class NullabilityMigrationListener {
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

  /// Individual source edits to achieve the change.  May be returned in any
  /// order.
  Iterable<SourceEdit> get sourceEdits;
}

/// Implementation of [SingleNullabilityFix] used internally by
/// [NullabilityMigration].
class _SingleNullabilityFix extends SingleNullabilityFix {
  @override
  final List<SourceEdit> sourceEdits;

  @override
  final Source source;

  @override
  final NullabilityFixKind kind;

  factory _SingleNullabilityFix(
      analyzer.PotentialModification potentialModification) {
    // TODO(paulberry): once everything is migrated into the analysis server,
    // the migration engine can just create SingleNullabilityFix objects
    // directly and set their kind appropriately; we won't need to translate the
    // kinds using a bunch of `is` checks.
    NullabilityFixKind kind;
    if (potentialModification is analyzer.CheckExpression) {
      kind = NullabilityFixKind.checkExpression;
    } else if (potentialModification is analyzer.NullableTypeAnnotation) {
      kind = NullabilityFixKind.makeTypeNullable;
    } else if (potentialModification is analyzer.ConditionalModification) {
      kind = potentialModification.discard.keepFalse.value
          ? NullabilityFixKind.discardThen
          : NullabilityFixKind.discardElse;
    } else {
      throw new UnimplementedError('TODO(paulberry)');
    }
    return _SingleNullabilityFix._(
        potentialModification.modifications
            .map((m) => SourceEdit(m.location, 0, m.insert))
            .toList(),
        potentialModification.source,
        kind);
  }

  _SingleNullabilityFix._(this.sourceEdits, this.source, this.kind);

  /// TODO(paulberry): do something better
  Location get location => null;
}
