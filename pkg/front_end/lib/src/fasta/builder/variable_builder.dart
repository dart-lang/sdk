// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_variable_builder;

import 'package:kernel/ast.dart' show VariableDeclaration;

import '../builder/builder.dart';

abstract class VariableBuilder implements Builder {
  VariableDeclaration get variable;

  bool get isAssignable;
}
