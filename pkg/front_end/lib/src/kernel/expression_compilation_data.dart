// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'internal_ast.dart' show InternalVariable;

// Coverage-ignore(suite): Not run.
class ExpressionCompilationData {
  final List<TypeParameter> typeParameters;
  final List<PositionalParameter> positionalParameters;
  final List<InternalVariable> extraKnownVariables;
  final Map<String, PositionalParameter> extraParametersIfNotShadowing;
  final int fileOffset;
  bool containsSuperCalls = false;

  new({
    required this.typeParameters,
    required this.positionalParameters,
    required this.extraKnownVariables,
    required this.extraParametersIfNotShadowing,
    required this.fileOffset,
  });
}
