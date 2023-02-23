// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'space.dart';
import 'static_type.dart';
import 'witness.dart' as witness;

/// Checks the [cases] representing a series of switch cases to see if they
/// exhaustively cover all possible values of the matched [valueType]. Also
/// checks to see if any case can't be matched because it's covered by previous
/// cases.
///
/// Returns a string containing any unreachable case or non-exhaustive match
/// errors. Returns an empty string if all cases are reachable and the cases
/// are exhaustive.

List<ExhaustivenessError> reportErrors(StaticType valueType, List<Space> cases,
    [List<Space>? remainingSpaces]) {
  return witness.reportErrors(valueType, cases);
}

class ExhaustivenessError {}

class NonExhaustiveError implements ExhaustivenessError {
  final StaticType valueType;

  final List<Space> cases;

  final String witness;

  NonExhaustiveError(this.valueType, this.cases, this.witness);

  @override
  String toString() =>
      '$valueType is not exhaustively matched by ${new Space.union(cases)}.';
}

class UnreachableCaseError implements ExhaustivenessError {
  final StaticType valueType;
  final List<Space> cases;
  final int index;

  UnreachableCaseError(this.valueType, this.cases, this.index);

  @override
  String toString() => 'Case #${index + 1} ${cases[index]} is unreachable.';
}
