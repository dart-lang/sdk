// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/450678575.
//
// Verifies that compiler uses correct calling conventions (!regcc)
// when using unreachable field as an interface target.

import 'package:expect/expect.dart';

bool opaqueTrue = int.parse('1') == 1;

int listener = -1;

abstract class ChangeNotifier {
  void addListener();
}

class Notifier1 implements ChangeNotifier {
  @pragma('vm:never-inline')
  void addListener() {
    listener = 1;
  }
}

class Notifier2 implements ChangeNotifier {
  @pragma('vm:never-inline')
  void addListener() {
    listener = 2;
  }
}

abstract class M {
  // This field is unreachable and only serves as
  // an interface target.
  @pragma("vm:entry-point")
  final ChangeNotifier accessibilityFocus = Notifier2();
}

class B implements M {
  @pragma("vm:entry-point")
  final ChangeNotifier accessibilityFocus = Notifier1();
}

class C implements M {
  @pragma("vm:entry-point")
  final ChangeNotifier accessibilityFocus = Notifier2();
}

// Clobber values on top of the stack.
@pragma('vm:never-inline')
@pragma("vm:entry-point")
void boxed(int a, int b) {
  print(a);
  print(b);
}

M instance = opaqueTrue ? B() : C();

void main(List<String> args) {
  boxed(1, 2);
  instance.accessibilityFocus.addListener();
  Expect.equals(1, listener);
}
