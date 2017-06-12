// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test for dartNativeDispatchHooksTransformer, getTag hook.
// Same as browser_compat_1_prepatched_test but with prepatching disabled.

@Native("T1A")
class T1A {}

@Native("T1B")
class T1B {}

@Native("T1C")
class T1C {}

makeT1A() native;
makeT1B() native;
makeT1C() native;

int getTagCallCount() native;

void setup() native r'''
function T1A() { } //       Normal native class.
function T1CrazyB() { }  // Native class with different constructor name.

var T1fakeA = (function(){
  function T1A() {} //      Native class with adversarial constructor name.
  return T1A;
})();

// Make constructors visible on 'window' for prepatching.
if (typeof window == "undefined") window = {}
window.T1A = T1A;
window.T1CrazyB = T1CrazyB;

makeT1A = function(){return new T1A;};
makeT1B = function(){return new T1CrazyB;};
makeT1C = function(){return new T1fakeA;};

self.nativeConstructor(T1A);
self.nativeConstructor(T1CrazyB);
self.nativeConstructor(T1fakeA);

var getTagCount = 0;
getTagCallCount = function() { return getTagCount; }

function transformer1(hooks) {
  var getTag = hooks.getTag;

  function getTagNew(obj) {
    ++getTagCount;

    // If something looks like a different native type we can check in advance
    // of the default algorithm.
    if (obj instanceof T1fakeA) return "T1C";

    var tag = getTag(obj);

    // New constructor names can be mapped here.
    if (tag == "T1CrazyB") return "T1B";

    return tag;
  }

  hooks.getTag = getTagNew;
  // Disable prepatching.
  hooks.prototypeForTag = function() { return null; }
}

dartNativeDispatchHooksTransformer = [transformer1];
''';

main() {
  nativeTesting();
  setup();

  var t1a = makeT1A();
  var t1b = makeT1B();
  var t1c = makeT1C();

  Expect.equals(true, t1a is T1A, '$t1a is T1A');
  Expect.equals(true, t1b is T1B, '$t1b is T1B');
  Expect.equals(true, t1c is T1C, '$t1c is T1C');

  Expect.equals(3, getTagCallCount());

  Expect.equals(true, confuse(t1a) is T1A, '$t1a is T1A');
  Expect.equals(true, confuse(t1b) is T1B, '$t1b is T1B');
  Expect.equals(true, confuse(t1c) is T1C, '$t1c is T1C');

  Expect.equals(3, getTagCallCount());
}
