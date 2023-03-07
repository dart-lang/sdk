// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'static_type.dart';
import 'witness.dart';

/// Indicates whether the "fallback" exhaustiveness algorithm (based on flow
/// analysis) should be used instead of full exhaustiveness.  This is a
/// temporary measure to allow for the possibility of turning on pattern support
/// before the full exhaustiveness algorithm is complete.
///
/// TODO(paulberry): remove this flag (and the implementation of the fallback
/// exhaustiveness algorithm) when it is no longer needed.
bool useFallbackExhaustivenessAlgorithm = true;

class ExhaustivenessError {}

class NonExhaustiveError implements ExhaustivenessError {
  final StaticType valueType;

  final List<Space> cases;

  final String witness;

  NonExhaustiveError(this.valueType, this.cases, this.witness);

  @override
  String toString() =>
      '$valueType is not exhaustively matched by ${cases.join('|')}.';
}

class UnreachableCaseError implements ExhaustivenessError {
  final StaticType valueType;
  final List<Space> cases;
  final int index;

  UnreachableCaseError(this.valueType, this.cases, this.index);

  @override
  String toString() => 'Case #${index + 1} ${cases[index]} is unreachable.';
}
