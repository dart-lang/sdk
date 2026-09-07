// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// A global variable defined in a module.
class GlobalBuilder with Builder<ir.DefinedGlobal> {
  final ModuleBuilder moduleBuilder;
  final ir.DefinedGlobal global;
  InstructionsBuilder? _initializer;

  GlobalBuilder(this.moduleBuilder, this.global)
    : _initializer = InstructionsBuilder(moduleBuilder, [], [
        global.type.type,
      ], constantExpression: true);

  ir.GlobalType get type => global.type;
  ir.FinalizableIndex get finalizableIndex => global.finalizableIndex;
  ir.Module get enclosingModule => global.enclosingModule;
  String? get globalName => global.globalName;

  InstructionsBuilder get initializer => _initializer!;

  @override
  ir.DefinedGlobal forceBuild() {
    global.initializer = initializer.build();
    _initializer = null;
    return global;
  }

  @override
  String toString() => global.toString();
}
