// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

// Coverage-ignore(suite): Not run.
class ExpressionCompilationData {
  final List<TypeParameter> typeParameters;
  final List<PositionalParameter> positionalParameters;
  final int fileOffset;
  int transformerFlags;

  new({
    required this.typeParameters,
    required this.positionalParameters,
    required this.fileOffset,
    required this.transformerFlags,
  });
}
