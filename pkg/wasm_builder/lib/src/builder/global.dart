// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'globals.dart';

/// A global variable defined in a module.
class GlobalBuilder extends ir.Global with IndexableBuilder<ir.DefinedGlobal> {
  final InstructionsBuilder initializer;

  GlobalBuilder(super.enclosingModule, super.index, super.type,
      [super.globalName])
      : initializer = InstructionsBuilder(enclosingModule, [], [type.type],
            constantExpression: true);

  @override
  ir.DefinedGlobal forceBuild() => ir.DefinedGlobal(
      enclosingModule, initializer.build(), finalizableIndex, type, globalName);
}
