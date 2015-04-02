// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var assert = chai.assert;

suite('generic', () => {
  "use strict";

  let generic = dart.generic;

  test('zero arguments is not allowed', () => {
    assert.throws(() => { generic(function(){}); });
  });

  test('argument count cannot change', () => {
    let SomeType = generic(function(x) { return {x: x}; });
    assert.throws(() => { SomeType(1,2) });
    let obj = {};
    assert.equal(SomeType(obj).x, obj);
    assert.equal(SomeType(obj).x, obj);
    assert.equal(SomeType().x, dart.dynamic);
  });

  test('undefined/null are not allowed', () => {
    let SomeType = generic(function(x) {});
    assert.throws(() => { SomeType(void 0) });
    SomeType(1);
    assert.throws(() => { SomeType(void 0) });
    SomeType(1);
    assert.throws(() => { SomeType(null) });
  });

  test('result is memoized', () => {
    let t1 = Object.create(null);
    let t2 = Object.create(null);

    let count = 0;
    let SomeType = generic(function(x, y) {
      count++;
      return Object.create(null);
    });

    let x12 = SomeType(1, 2);
    assert.strictEqual(SomeType(1, 2), x12);
    assert.strictEqual(SomeType(1, 2), x12);
    assert.strictEqual(count, 1);
    let x11 = SomeType(1, 1);
    assert.strictEqual(count, 2);
    assert.strictEqual(SomeType(1, 1), x11);
    assert.strictEqual(count, 2);
    count = 0;

    let t1t2 = SomeType(t1, t2);
    assert.strictEqual(count, 1);
    let t2t1 = SomeType(t2, t1);
    assert.strictEqual(count, 2);
    assert.notStrictEqual(t1t2, t2t1);
    assert.strictEqual(SomeType(t1, t2), t1t2);
    assert.strictEqual(SomeType(t2, t1), t2t1);
    assert.strictEqual(SomeType(t1, t2), t1t2);
    count = 0;

    // Nothing has been stored on the object
    assert.strictEqual(Object.keys(t1).length, 0);
    assert.strictEqual(Object.keys(t2).length, 0);
  });

  test('type constructor is reflectable', () => {
    let SomeType = generic(function(x, y) { return Object.create(null); });
    let someValue = SomeType('hi', 123);
    assert.equal(someValue[dart.originalDeclaration], SomeType);
    assert.deepEqual(someValue[dart.typeArguments], ['hi', 123]);
  });
});


suite('instanceOf', () => {
  "use strict";

  let expect = assert.equal;
  let isGroundType = dart.isGroundType;
  let generic = dart.generic;
  let intIsNonNullable = false;
  let cast = dart.as;
  let instanceOf = dart.is;
  let getRuntimeType = dart.getRuntimeType;

  let Object = core.Object;
  let String = core.String;
  let dynamic = dart.dynamic;
  let List = core.List;
  let Map = core.Map;
  let Map$ = core.Map$;
  let int = core.int;
  let num = core.num;
  let bool = core.bool;

  class A {}
  class B extends A {}
  class C extends B {}

  let AA$ = generic((T, U) => class AA extends core.Object {});
  let AA = AA$();
  let BB$ = generic((T, U) => class BB extends AA$(U, T) {});
  let BB = BB$();
  class CC extends BB$(String, List) {}

  function checkType(x, type, expectedTrue) {
    if (expectedTrue === undefined) expectedTrue = true;
    expect(instanceOf(x, type), expectedTrue);
  }

  test('int', () => {
    expect(isGroundType(int), true);
    expect(isGroundType(getRuntimeType(5)), true);

    checkType(5, int);
    checkType(5, dynamic);
    checkType(5, Object);
    checkType(5, num);

    checkType(5, bool, false);
    checkType(5, String, false);

    expect(cast(5, int), 5);
    if (intIsNonNullable) {
      expect(() => cast(null, int), throws);
    } else {
      expect(cast(null, int), null);
    }
  });

  test('dynamic', () => {
    expect(isGroundType(dynamic), true);
    checkType(new Object(), dynamic);
    checkType(null, dynamic);

    expect(cast(null, dynamic), null);
  });

  test('Object', () => {
    expect(isGroundType(Object), true);
    checkType(new Object(), dynamic);
    checkType(null, Object);

    expect(cast(null, Object), null);
  });

  test('null', () => {
    // Object, dynamic cases are already handled above.
    checkType(null, core.Null);
    checkType(null, core.String, false);
    checkType(null, core.int, false);
    checkType(null, Map, false);
    checkType(void 0, core.Null);
    checkType(void 0, core.Object);
    checkType(void 0, dart.dynamic);
  });

  test('String', () => {
    expect(isGroundType(String), true);
    expect(isGroundType(getRuntimeType("foo")), true);
    checkType("foo", String);
    checkType("foo", Object);
    checkType("foo", dynamic);

    expect(cast(null, String), null);
  });

  test('Map', () => {
    let m1 = new (Map$(String, String))();
    let m2 = new (Map$(Object, Object))();
    let m3 = new Map();
    let m4 = new (collection.HashMap$(dart.dynamic, dart.dynamic))();
    let m5 = new collection.LinkedHashMap();

    expect(isGroundType(Map), true);
    expect(isGroundType(getRuntimeType(m1)), false);
    expect(isGroundType(Map$(String, String)), false);
    expect(isGroundType(getRuntimeType(m2)), true);
    expect(isGroundType(Map$(Object, Object)), true);
    expect(isGroundType(getRuntimeType(m3)), true);
    expect(isGroundType(Map), true);
    expect(isGroundType(getRuntimeType(m4)), true);
    expect(isGroundType(collection.HashMap$(dynamic, dynamic)), true);
    expect(isGroundType(getRuntimeType(m5)), true);
    expect(isGroundType(collection.LinkedHashMap), true);
    expect(isGroundType(collection.LinkedHashMap), true);

    // Map<T1,T2> <: Map
    checkType(m1, Map);
    checkType(m1, Object);

    // Instance of self
    checkType(m1, getRuntimeType(m1));
    checkType(m1, Map$(String, String));

    // Covariance on generics
    checkType(m1, getRuntimeType(m2));
    checkType(m1, Map$(Object, Object));

    // No contravariance on generics.
    checkType(m2, getRuntimeType(m1), false);
    checkType(m2, Map$(String, String), false);

    // null is! Map
    checkType(null, Map, false);

    // Raw generic types
    checkType(m5, Map);
    checkType(m4, Map);
  });

  test('generic and inheritance', () => {
    let aaraw = new AA();
    let aarawtype = getRuntimeType(aaraw);
    let aadynamic = new (AA$(dynamic, dynamic))();
    let aadynamictype = getRuntimeType(aadynamic);
    let aa = new (AA$(String, List))();
    let aatype = getRuntimeType(aa);
    let bb = new (BB$(String, List))();
    let bbtype = getRuntimeType(bb);
    let cc = new CC();
    let cctype = getRuntimeType(cc);
    // We don't allow constructing bad types.
    // This was AA<String> in Dart (wrong number of type args).
    let aabad = new (AA$(dart.dynamic, dart.dynamic))();
    let aabadtype = getRuntimeType(aabad);

    expect(isGroundType(aatype), false);
    expect(isGroundType(AA$(String, List)), false);
    expect(isGroundType(bbtype), false);
    expect(isGroundType(BB$(String, List)), false);
    expect(isGroundType(cctype), true);
    expect(isGroundType(CC), true);
    checkType(cc, aatype, false);
    checkType(cc, AA$(String, List), false);
    checkType(cc, bbtype);
    checkType(cc, BB$(String, List));
    checkType(aa, cctype, false);
    checkType(aa, CC, false);
    checkType(aa, bbtype, false);
    checkType(aa, BB$(String, List), false);
    checkType(bb, cctype, false);
    checkType(bb, CC, false);
    checkType(aa, aabadtype);
    checkType(aa, dynamic);
    checkType(aabad, aatype, false);
    checkType(aabad, AA$(String, List), false);
    checkType(aabad, aarawtype);
    checkType(aabad, AA);
    checkType(aaraw, aabadtype);
    checkType(aaraw, AA$(dart.dynamic, dart.dynamic));
    checkType(aaraw, aadynamictype);
    checkType(aaraw, AA$(dynamic, dynamic));
    checkType(aadynamic, aarawtype);
    checkType(aadynamic, AA);
  });

  test('void', () => {
    //checkType((x) => x, type((void _(x)) {}));
  });

  test('mixins', () => {
    let c = collection;
    var s1 = new (c.SplayTreeSet$(String))();

    checkType(s1, c.IterableMixin);
    checkType(s1, c.IterableMixin$(String));
    checkType(s1, c.IterableMixin$(int), false);

    checkType(s1, c.SetMixin);
    checkType(s1, c.SetMixin$(String));
    checkType(s1, c.SetMixin$(int), false);
  });
});
