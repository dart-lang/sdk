// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help move super calls last in the initializer list.
library kernel.frontend.super_calls;

import '../ast.dart';

/// Mutates the initializer list of [node] so that its super call occurs last,
/// while its arguments are evaluated at the correct place.
///
/// Does nothing if there is no super call or if the super call is already last.
void moveSuperCallLast(Constructor node) {
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
  initializers.add(superCall);
  _insertEntriesAt(initializers, superIndex, argumentCount - 1);
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

/// Inserts new entries at the given index, shifting entries after that index
/// towards the end of the list.
void _insertEntriesAt(List<Initializer> list, int index, int count) {
  int originalLength = list.length;
  list.length += count;
  for (int i = 0; i < count; ++i) {
    list[list.length - i - 1] = list[originalLength - i - 1];
  }
}
