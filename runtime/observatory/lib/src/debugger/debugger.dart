// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of debugger;

// TODO(turnidge): Move more of ObservatoryDebugger to this class.
abstract class Debugger {
  VM get vm;
  Isolate get isolate;
  M.ObjectRepository objects;
  ServiceMap get stack;
  int get currentFrame;
}
