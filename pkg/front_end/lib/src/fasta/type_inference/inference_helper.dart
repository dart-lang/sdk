// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show FunctionType;

import '../fasta_codes.dart' show LocatedMessage, Message;

abstract class InferenceHelper<Expression, Statement, Arguments> {
  Expression wrapInCompileTimeError(Expression expression, Message message);

  Expression buildCompileTimeError(Message message, int charOffset, int length,
      {List<LocatedMessage> context});

  LocatedMessage checkArgumentsForType(
      FunctionType function, Arguments arguments, int offset);

  void addProblem(Message message, int charOffset, int length);
}
