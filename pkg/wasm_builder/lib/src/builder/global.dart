// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'globals.dart';

/// A global variable defined in a module.
class GlobalBuilder extends ir.Global with Builder<ir.DefinedGlobal> {
  final InstructionsBuilder initializer;

  GlobalBuilder(ModuleBuilder module, super.index, super.type)
      : initializer =
            InstructionsBuilder(module, [type.type], isGlobalInitializer: true);

  @override
  ir.DefinedGlobal forceBuild() =>
      ir.DefinedGlobal(initializer.build(), index, type);
}
