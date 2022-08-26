// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

abstract class Base {}

class Child1 extends Base {}

class Child2 extends Base {}

bool trivial(x) => true;
Base either = DateTime.now().millisecondsSinceEpoch > 0 ? Child2() : Child1();

test1() {
  Base child = either;
  if (trivial(child is Child1 && true)) return child;
  return null;
}

test2() {
  Base child = either;
  if (child is Child1 || trivial(child is Child1 && true)) return child;
  return null;
}

test3() {
  Base child = either;
  if (trivial(child is Child1 && true) && child is Child2) return child;
  return null;
}

test4() {
  Base child = either;
  if (child is Child2 && trivial(child is Child1 && true)) return child;
  return null;
}

test5() {
  Base child = either;
  if ((child is Child1 && true) == false) return child;
  return null;
}

test6() {
  Base child = either;
  if (trivial(child is Child1 ? false : true)) return child;
  return null;
}

test7() {
  Base child = either;
  if (trivial(trivial(child is Child1 && true))) return child;
  return null;
}

main() {
  Expect.isTrue(test1() is Child2, "test1");
  Expect.isTrue(test2() is Child2, "test2");
  Expect.isTrue(test3() is Child2, "test3");
  Expect.isTrue(test4() is Child2, "test4");
  Expect.isTrue(test5() is Child2, "test5");
  Expect.isTrue(test6() is Child2, "test6");
  Expect.isTrue(test7() is Child2, "test7");
}
