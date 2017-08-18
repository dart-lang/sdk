// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test for dartNativeDispatchHooksTransformer
//  - uncached, instance, leaf and interior caching modes.
//  - composition of getTag.

@Native("T1A")
class T1A {
  foo() native;
}

@Native("T1B")
class T1B {
  foo() native;
}

@Native("T1C")
class T1C {
  foo() native;
}

@Native("T1D")
class T1D {
  foo() native;
}

makeT1A() native;
makeT1B() native;
makeT1C() native;
makeT1D() native;

int getTagCallCount() native;
void clearTagCallCount() native;

void setup() {
  JS('', r'''
(function(){
function T1A() { this.v = "a"; }
function T1B() { this.v = "b"; }
function T1C() { this.v = "c"; }
function T1D() { this.v = "d"; }

// T1B, T1C and T1D extend T1A in the implementation but not the declared types.
// T1A must not be leaf-cached otherwise we will pick up the interceptor for T1A
// when looking for the dispatch record for an uncached or not-yet-cached T1B,
// T1C or T1D.
T1B.prototype.__proto__ = T1A.prototype;
T1C.prototype.__proto__ = T1A.prototype;
T1D.prototype.__proto__ = T1A.prototype;

// All classes share one implementation of native method 'foo'.
T1A.prototype.foo = function() { return this.v + this.name(); };
T1A.prototype.name = function() { return "A"; };
T1B.prototype.name = function() { return "B"; };
T1C.prototype.name = function() { return "C"; };
T1D.prototype.name = function() { return "D"; };

makeT1A = function(){return new T1A()};
makeT1B = function(){return new T1B()};
makeT1C = function(){return new T1C()};
makeT1D = function(){return new T1D()};

self.nativeConstructor(T1A);
self.nativeConstructor(T1B);
self.nativeConstructor(T1C);
self.nativeConstructor(T1D);

var getTagCount = 0;
getTagCallCount = function() { return getTagCount; };
clearTagCallCount = function() { getTagCount = 0; };

function transformer1(hooks) {
  var getTag = hooks.getTag;

  function getTagNew(obj) {
    var tag = getTag(obj);
    // Dependency to test composition, rename T1D -> Dep -> -T1D.
    if (tag == "T1D") return "Dep";
    return tag;
  }

  hooks.getTag = getTagNew;
}

function transformer2(hooks) {
  var getTag = hooks.getTag;

  function getTagNew(obj) {
    ++getTagCount;
    var tag = getTag(obj);
    if (tag == "T1A") return "+T1A";  // Interior cached on prototype
    if (tag == "T1B") return "~T1B";  // Uncached
    if (tag == "T1C") return "!T1C";  // Instance cached
    if (tag == "Dep") return "-T1D";  // Leaf cached on prototype
    return tag;
  }

  hooks.getTag = getTagNew;
}

dartNativeDispatchHooksTransformer = [transformer1, transformer2];
})()''');
}

main() {
  nativeTesting();
  setup();

  var t1a = makeT1A();
  var t1b = makeT1B();
  var t1c = makeT1C();
  var t1d = makeT1D();

  clearTagCallCount();
  Expect.equals("aA", confuse(t1a).foo(), 't1a is T1A');
  Expect.equals("bB", confuse(t1b).foo(), 't1b is T1B');
  Expect.equals("cC", confuse(t1c).foo(), 't1c is T1C');
  Expect.equals("dD", confuse(t1d).foo(), 't1d is T1D');
  Expect.equals(4, getTagCallCount(), '4 fresh instances / types');

  clearTagCallCount();
  Expect.equals("aA", confuse(t1a).foo(), 't1a is T1A');
  Expect.equals("bB", confuse(t1b).foo(), 't1b is T1B');
  Expect.equals("cC", confuse(t1c).foo(), 't1c is T1C');
  Expect.equals("dD", confuse(t1d).foo(), 't1d is T1D');
  Expect.equals(1, getTagCallCount(), '1 = 1 uncached + (3 cached)');

  t1a = makeT1A();
  t1b = makeT1B();
  t1c = makeT1C();
  t1d = makeT1D();

  clearTagCallCount();
  Expect.equals("aA", confuse(t1a).foo(), 't1a is T1A');
  Expect.equals("bB", confuse(t1b).foo(), 't1b is T1B');
  Expect.equals("cC", confuse(t1c).foo(), 't1c is T1C');
  Expect.equals("dD", confuse(t1d).foo(), 't1d is T1D');
  Expect.equals(2, getTagCallCount(),
      '2 = 1 fresh instance + 1 uncached (+ 2 proto cached)');

  clearTagCallCount();
  Expect.equals("aA", confuse(t1a).foo(), 't1a is T1A');
  Expect.equals("bB", confuse(t1b).foo(), 't1b is T1B');
  Expect.equals("cC", confuse(t1c).foo(), 't1c is T1C');
  Expect.equals("dD", confuse(t1d).foo(), 't1d is T1D');
  Expect.equals(1, getTagCallCount(),
      '1 = 2 proto cached + 1 instance cached + 1 uncached');
}
