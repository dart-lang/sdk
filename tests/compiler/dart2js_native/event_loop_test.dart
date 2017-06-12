// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:async_helper/async_helper.dart";
import "native_testing.dart";

typedef void Callback0();

@Native("A")
class A {
  foo(Callback0 f) native;
}

makeA() native;

void setup() native r"""
function A() {}
A.prototype.foo = function(f) { return f(); };
makeA = function() { return new A; };
self.nativeConstructor(A);
""";

main() {
  nativeTesting();
  setup();

  // Makes sure that we don't run the event-loop when we have a reentrant
  // call from JS to Dart code.
  // We start by setting up a microtask that should only run after main has
  // finished. We then pass a closure into JavaScript. That closure is
  // immediately invoked. Dart2js had a bug, that it would start the event-loop
  // at this moment (a JS->Dart transition), and execute the scheduled
  // microtask.

  var events = [];
  asyncStart();
  var a = makeA();
  new Future.microtask(() {
    events.add("scheduleMicrotask");
  }).whenComplete(asyncEnd);

  Expect.equals(499, a.foo(() {
    events.add("closure to foo");
    return 499;
  }));

  events.add("after native call");
  Expect.listEquals(["closure to foo", "after native call"], events);
}
