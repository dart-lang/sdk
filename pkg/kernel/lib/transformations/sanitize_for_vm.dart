// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.fixvm;

import '../ast.dart';

/// Ensures that classes all have either a constructor or a procedure.
///
/// VM-specific constraints that don't fit in anywhere else can be put here.
class SanitizeForVM {
  void transform(Program program) {
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        if (class_.constructors.isEmpty && class_.procedures.isEmpty) {
          class_.addMember(new Constructor(
              new FunctionNode(new EmptyStatement()),
              name: new Name(''),
              isSynthetic: true));
        }
      }
    }
  }
}
