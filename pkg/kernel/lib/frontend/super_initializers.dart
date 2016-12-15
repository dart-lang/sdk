// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help move super calls last in the initializer list.
library kernel.frontend.super_calls;

import '../ast.dart';

/// Mutates the initializer list of [node] so that its super initializer occurs
/// last, while its arguments are evaluated at the correct place.
///
/// Does nothing if there is no super initializer or if it is already last.
void moveSuperInitializerLast(Constructor node) {
  List<Initializer> initializers = node.initializers;
  if (initializers.isEmpty) return;
  if (initializers.last is SuperInitializer) return;
  int superIndex = -1;
  for (int i = initializers.length - 1; i >= 0; --i) {
    Initializer initializer = initializers[i];
    if (initializer is SuperInitializer) {
      superIndex = i;
      break;
    }
  }
  if (superIndex == -1) return;
  SuperInitializer superCall = initializers[superIndex];
  Arguments arguments = superCall.arguments;
  int argumentCount = arguments.positional.length + arguments.named.length;

  // We move all initializers after the super call to the place where the super
  // call was, but reserve [argumentCount] slots before that for
  // [LocalInitializer]s.
  initializers.length += argumentCount;
  initializers.setRange(
      superIndex + argumentCount, // desination start (inclusive)
      initializers.length - 1, // desination end (exclusive)
      initializers, // source list
      superIndex + 1); // source start index
  initializers[initializers.length - 1] = superCall;

  // Fill in the [argumentCount] reserved slots with the evaluation expressions
  // of the arguments to the super constructor call.
  int storeIndex = superIndex;
  for (int i = 0; i < arguments.positional.length; ++i) {
    var variable = new VariableDeclaration.forValue(arguments.positional[i]);
    arguments.positional[i] = new VariableGet(variable)..parent = arguments;
    initializers[storeIndex++] = new LocalInitializer(variable)..parent = node;
  }
  for (int i = 0; i < arguments.named.length; ++i) {
    NamedExpression argument = arguments.named[i];
    var variable = new VariableDeclaration.forValue(argument.value);
    arguments.named[i].value = new VariableGet(variable)..parent = argument;
    initializers[storeIndex++] = new LocalInitializer(variable)..parent = node;
  }
}
