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
  let runtimeType = dart.realRuntimeType;
  let setRuntimeType = dart.setRuntimeType;
  let functionType = dart.functionType;
  let typedef = dart.typedef;

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

  let Func2 = typedef('Func2', () => functionType(dynamic, [dynamic, dynamic]));
  let Foo = typedef('Foo', () => functionType(B, [B, String]));

  let FuncG$ = generic((T, U) => typedef('FuncG', () => functionType(T, [T, U])))
  let FuncG = FuncG$();

  // TODO(vsm): Revisit when we encode types on functions properly.
  // A bar1(C c, String s) => null;
  function bar1(c, s) { return null; }
  setRuntimeType(bar1, functionType(A, [C, String]));

  // bar2(B b, String s) => null;
  function bar2(b, s) { return null; }
  setRuntimeType(bar2, functionType(dynamic, [B, String]));

  // B bar3(B b, Object o) => null;
  function bar3(b, o) { return null; }
  setRuntimeType(bar3, functionType(B, [B, Object]));

  // B bar4(B b, o) => null;
  function bar4(b, o) { return null; }
  setRuntimeType(bar4, functionType(B, [B, dynamic]));

  // C bar5(A a, Object o) => null;
  function bar5(a, o) { return null; }
  setRuntimeType(bar5, functionType(C, [A, Object]));

  // B bar6(B b, String s, String o) => null;
  function bar6(b, s, o) { return null; }
  setRuntimeType(bar6, functionType(B, [B, String, String]));

  // B bar7(B b, String s, [Object o]) => null;
  function bar7(b, s, o) { return null; }
  setRuntimeType(bar7, functionType(B, [B, String], [Object]));

  // B bar8(B b, String s, {Object p}) => null;
  function bar8(b, s, o) { return null; }
  setRuntimeType(bar8, functionType(B, [B, String], {p: Object}));

  function checkType(x, type, expectedTrue) {
    if (expectedTrue === undefined) expectedTrue = true;
    expect(instanceOf(x, type), expectedTrue);
  }

  test('int', () => {
    expect(isGroundType(int), true);
    expect(isGroundType(runtimeType(5)), true);

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
    expect(isGroundType(runtimeType("foo")), true);
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
    expect(isGroundType(runtimeType(m1)), false);
    expect(isGroundType(Map$(String, String)), false);
    expect(isGroundType(runtimeType(m2)), true);
    expect(isGroundType(Map$(Object, Object)), true);
    expect(isGroundType(runtimeType(m3)), true);
    expect(isGroundType(Map), true);
    expect(isGroundType(runtimeType(m4)), true);
    expect(isGroundType(collection.HashMap$(dynamic, dynamic)), true);
    expect(isGroundType(runtimeType(m5)), true);
    expect(isGroundType(collection.LinkedHashMap), true);
    expect(isGroundType(collection.LinkedHashMap), true);

    // Map<T1,T2> <: Map
    checkType(m1, Map);
    checkType(m1, Object);

    // Instance of self
    checkType(m1, runtimeType(m1));
    checkType(m1, Map$(String, String));

    // Covariance on generics
    checkType(m1, runtimeType(m2));
    checkType(m1, Map$(Object, Object));

    // No contravariance on generics.
    checkType(m2, runtimeType(m1), false);
    checkType(m2, Map$(String, String), false);

    // null is! Map
    checkType(null, Map, false);

    // Raw generic types
    checkType(m5, Map);
    checkType(m4, Map);
  });

  test('generic and inheritance', () => {
    let aaraw = new AA();
    let aarawtype = runtimeType(aaraw);
    let aadynamic = new (AA$(dynamic, dynamic))();
    let aadynamictype = runtimeType(aadynamic);
    let aa = new (AA$(String, List))();
    let aatype = runtimeType(aa);
    let bb = new (BB$(String, List))();
    let bbtype = runtimeType(bb);
    let cc = new CC();
    let cctype = runtimeType(cc);
    // We don't allow constructing bad types.
    // This was AA<String> in Dart (wrong number of type args).
    let aabad = new (AA$(dart.dynamic, dart.dynamic))();
    let aabadtype = runtimeType(aabad);

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

  test('Functions', () => {
    // - return type: Dart is bivariant.  We're covariant.
    // - param types: Dart is bivariant.  We're contravariant.
    expect(isGroundType(Func2), true);
    expect(isGroundType(Foo), false);
    expect(isGroundType(functionType(B, [B, String])), false);
    checkType(bar1, Foo, false);
    checkType(bar1, functionType(B, [B, String]), false);
    checkType(bar2, Foo, false);
    checkType(bar2, functionType(B, [B, String]), false);
    checkType(bar3, Foo);
    checkType(bar3, functionType(B, [B, String]));
    checkType(bar4, Foo, false);
    // TODO(vsm): Revisit.  bar4 is (B, *) -> B.  Perhaps it should be treated as top for a reified object.
    checkType(bar4, functionType(B, [B, String]), false);
    checkType(bar5, Foo);
    checkType(bar5, functionType(B, [B, String]));
    checkType(bar6, Foo, false);
    checkType(bar6, functionType(B, [B, String]), false);
    checkType(bar7, Foo);
    checkType(bar7, functionType(B, [B, String]));
    checkType(bar7, runtimeType(bar6));
    checkType(bar8, Foo);
    checkType(bar8, functionType(B, [B, String]));
    checkType(bar8, runtimeType(bar6), false);
    checkType(bar7, runtimeType(bar8), false);
    checkType(bar8, runtimeType(bar7), false);

    // Parameterized typedefs
    expect(isGroundType(FuncG), true);
    expect(isGroundType(FuncG$(B, String)), false);
    checkType(bar1, FuncG$(B, String), false);
    checkType(bar3, FuncG$(B, String));
  });

  test('Object members', () => {
    let nullHash = dart.hashCode(null);
    assert.equal(nullHash, 0);
    let nullString = dart.toString(null);
    assert.equal(nullString, 'null');
    let nullType = dart.runtimeType(null);
    assert.equal(nullType, core.Null);

    let map = new Map();
    let mapHash = dart.hashCode(map);
    checkType(mapHash, core.int);
    assert.equal(mapHash, map.hashCode);

    let mapString = dart.toString(map);
    assert.equal(mapString, map.toString());
    checkType(mapString, core.String);
    let mapType = dart.runtimeType(map);
    assert.equal(mapType, map.runtimeType);

    let str = "A string";
    let strHash = dart.hashCode(str);
    checkType(strHash, core.int);

    let strString = dart.toString(str);
    checkType(strString, core.String);
    assert.equal(str, strString);
    let strType = dart.runtimeType(str);
    assert.equal(strType, core.String);

    let n = 42;
    let intHash = dart.hashCode(n);
    checkType(intHash, core.int);

    let intString = dart.toString(n);
    assert.equal(intString, '42');
    let intType = dart.runtimeType(n);
    assert.equal(intType, core.int);
  });
});

suite('primitives', function() {
  'use strict';

  test('fixed length list', () => {
    let list = new core.List(10);
    list[0] = 42;
    assert.throws(() => list.add(42));
  });
});
