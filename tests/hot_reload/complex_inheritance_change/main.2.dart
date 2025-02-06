// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L959

class X {
  String name;
  X(this.name);
}

class A extends X {
  A(name) : super(name);
}

class B extends X {
  B(name) : super(name);
}

class C extends A {
  C(name) : super(name);
}

helper() {}

var list;

check() {
  Expect.type<A>(list[0]);
  Expect.notType<B>(list[0]);
  Expect.notType<C>(list[0]);
  Expect.type<X>(list[0]);
  Expect.notType<A>(list[1]);
  Expect.type<B>(list[1]);
  Expect.notType<C>(list[1]);
  Expect.type<X>(list[1]);
  Expect.type<A>(list[2]);
  Expect.notType<B>(list[2]);
  Expect.type<C>(list[2]);
  Expect.type<X>(list[2]);
  Expect.notType<A>(list[3]);
  Expect.notType<B>(list[3]);
  Expect.notType<C>(list[3]);
  Expect.type<X>(list[3]);
}

Future<void> main() async {
  check();
  await hotReload();

  helper();
  check();
  await hotReload();

  // Revive the class B and make sure all allocated instances take
  // their place in the inheritance hierarchy.
  check();
}

/** DIFF **/
/*
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L959
 
-class C {
+class X {
   String name;
-  C(this.name);
-}
-
-class X extends C {
-  X(name) : super(name);
+  X(this.name);
 }
 
 class A extends X {
   A(name) : super(name);
 }
 
-helper() {
-  list.add(new X('x'));
+class B extends X {
+  B(name) : super(name);
 }
 
+class C extends A {
+  C(name) : super(name);
+}
+
+helper() {}
+
 var list;
 
 check() {
   Expect.type<A>(list[0]);
-  Expect.type<C>(list[0]);
+  Expect.notType<B>(list[0]);
+  Expect.notType<C>(list[0]);
   Expect.type<X>(list[0]);
-  Expect.type<A>(list[1]);
-  Expect.type<C>(list[1]);
+  Expect.notType<A>(list[1]);
+  Expect.type<B>(list[1]);
+  Expect.notType<C>(list[1]);
   Expect.type<X>(list[1]);
-  Expect.notType<A>(list[2]);
+  Expect.type<A>(list[2]);
+  Expect.notType<B>(list[2]);
   Expect.type<C>(list[2]);
-  Expect.notType<X>(list[2]);
+  Expect.type<X>(list[2]);
   Expect.notType<A>(list[3]);
-  Expect.type<C>(list[3]);
+  Expect.notType<B>(list[3]);
+  Expect.notType<C>(list[3]);
   Expect.type<X>(list[3]);
 }
 
*/
