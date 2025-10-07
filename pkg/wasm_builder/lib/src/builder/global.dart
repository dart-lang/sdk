// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// A global variable defined in a module.
class GlobalBuilder extends ir.Global with IndexableBuilder<ir.DefinedGlobal> {
  final ModuleBuilder moduleBuilder;
  final InstructionsBuilder initializer;

  GlobalBuilder(
      this.moduleBuilder, ir.FinalizableIndex index, ir.GlobalType type,
      [String? globalName])
      : initializer = InstructionsBuilder(moduleBuilder, [], [type.type],
            constantExpression: true),
        super(moduleBuilder.module, index, type, globalName);

  @override
  ir.DefinedGlobal forceBuild() => ir.DefinedGlobal(
      enclosingModule, initializer.build(), finalizableIndex, type, globalName);
}
