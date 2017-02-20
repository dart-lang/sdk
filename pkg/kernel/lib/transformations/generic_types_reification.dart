// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformation.generic_types_reification;

import '../ast.dart' show Program;

import '../transformations/reify/reify_transformer.dart' as reify
    show transformProgram;

Program transformProgram(Program program) {
  return reify.transformProgram(program);
}
