// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var assert = chai.assert;

suite('dart_runtime generic', function() {
  "use strict";

  var generic = dart.generic;

  test('zero arguments is not allowed', function() {
    assert.throws(function() { generic(function(){}); });
  });

  test('argument count cannot change', function() {
    var SomeType = generic(function(x) {});
    assert.throws(function() { SomeType(1,2) });
    SomeType(1);
    SomeType(1);
    assert.throws(function() { SomeType() });
    SomeType(1);
  });

  test('undefined is not allowed as an argument', function() {
    var SomeType = generic(function(x) {});
    assert.throws(function() { SomeType(void 0) });
    SomeType(1);
    assert.throws(function() { SomeType(void 0) });
    SomeType(1);
    SomeType(null);
  });

  test('result is memoized', function() {
    var t1 = Object.create(null);
    var t2 = Object.create(null);

    var count = 0;
    var SomeType = generic(function(x, y) {
      count++;
      return Object.create(null);
    });

    var x12 = SomeType(1, 2);
    assert.strictEqual(SomeType(1, 2), x12);
    assert.strictEqual(SomeType(1, 2), x12);
    assert.strictEqual(count, 1);
    var x11 = SomeType(1, 1);
    assert.strictEqual(count, 2);
    assert.strictEqual(SomeType(1, 1), x11);
    assert.strictEqual(count, 2);
    count = 0;

    var t1t2 = SomeType(t1, t2);
    assert.strictEqual(count, 1);
    var t2t1 = SomeType(t2, t1);
    assert.strictEqual(count, 2);
    assert.notStrictEqual(t1t2, t2t1);
    assert.strictEqual(SomeType(t1, t2), t1t2);
    assert.strictEqual(SomeType(t2, t1), t2t1);
    assert.strictEqual(SomeType(t1, t2), t1t2);
    count = 0;

    var nullKeys = SomeType(null, null);
    assert.strictEqual(SomeType(null, null), nullKeys);
    assert.strictEqual(count, 1);
    count = 0;

    // Nothing has been stored on the object
    assert.strictEqual(Object.keys(t1).length, 0);
    assert.strictEqual(Object.keys(t2).length, 0);
  });

  test('type constructor is reflectable', function() {
    var SomeType = generic(function(x, y) { return Object.create(null); });
    var someValue = SomeType('hi', 123);
    assert.deepEqual(someValue[dart.typeSignature], [SomeType, 'hi', 123]);
  });
});
