// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var assert = chai.assert;
var dart_sdk = dart_library.import('dart_sdk');
var core = dart_sdk.core;
var collection = dart_sdk.collection;
var dart = dart_sdk.dart;
var dartx = dart.dartx;

suite('generic', () => {
  "use strict";

  let generic = dart.generic;

  test('zero arguments is not allowed', () => {
    assert.throws(() => { generic(function(){}); });
  });

  test('dcall noSuchMethod has correct error target', () => {
    assert.throws(() => dart.dcall(42),
        new RegExp('NoSuchMethodError.*\nReceiver: 42', 'm'),
        'Calls with non-function receiver should throw a NoSuchMethodError' +
        ' with correct target');

    // TODO(jmesserly): we should show the name "print" in there somewhere.
    assert.throws(() => dart.dcall(core.print, 1, 2, 3),
        new RegExp('NoSuchMethodError.*\n' +
        "Receiver: Instance of '\\(Object\\) -> void'", 'm'),
        'Calls with incorrect argument types should throw a NoSuchMethodError' +
        ' with correct target');
  });

  test('can throw number', () => {
    try {
      dart.throw(42);
    } catch (e) {
      assert.equal(e, 42);
    }
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
    assert.equal(dart.getGenericClass(someValue), SomeType);
    assert.deepEqual(dart.getGenericArgs(someValue), ['hi', 123]);
  });

  test('proper type constructor is called', () => {
    // This tests https://github.com/dart-lang/dev_compiler/issues/178
    let l = dart.list([1, 2, 3], core.int);
    let s = l[dartx.join]();
    assert.equal(s, '123');
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
  let strongInstanceOf = dart.strongInstanceOf;
  let getReifiedType = dart.getReifiedType;
  let functionType = dart.functionType;
  let typedef = dart.typedef;
  let isSubtype = dart.isSubtype;

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
  dart.fn(bar1, A, [C, String]);

  // bar2(B b, String s) => null;
  function bar2(b, s) { return null; }
  dart.fn(bar2, dynamic, [B, String]);

  // B bar3(B b, Object o) => null;
  function bar3(b, o) { return null; }
  dart.fn(bar3, B, [B, Object]);

  // B bar4(B b, o) => null;
  function bar4(b, o) { return null; }
  dart.fn(bar4, B, [B, dynamic]);

  // C bar5(A a, Object o) => null;
  function bar5(a, o) { return null; }
  dart.fn(bar5, C, [A, Object]);

  // B bar6(B b, String s, String o) => null;
  function bar6(b, s, o) { return null; }
  dart.fn(bar6, B, [B, String, String]);

  // B bar7(B b, String s, [Object o]) => null;
  function bar7(b, s, o) { return null; }
  dart.fn(bar7, B, [B, String], [Object]);

  // B bar8(B b, String s, {Object p}) => null;
  function bar8(b, s, o) { return null; }
  dart.fn(bar8, B, [B, String], {p: Object});

  let cls1 = dart.fn((c, s) => { return null; }, A, [C, String]);

  let cls2 = dart.fn((b, s) => { return null; }, dynamic, [B, String]);

  let cls3 = dart.fn((b, o) => { return null; }, B, [B, Object]);

  let cls4 = dart.fn((b, o) => { return null; }, B, [B, dynamic]);

  let cls5 = dart.fn((a, o) => { return null; }, C, [A, Object]);

  let cls6 = dart.fn((b, s, o) => { return null; }, B, [B, String, String]);

  let cls7 = dart.fn((b, s, o) => { return null; }, B, [B, String], [Object]);

  let cls8 =
    dart.fn((b, s, o) => { return null; }, B, [B, String], {p: Object});

  function checkType(x, type, expectedTrue, strongOnly) {
    if (expectedTrue === undefined) expectedTrue = true;
    if (strongOnly == undefined) strongOnly = false;
    if (!strongOnly) {
      expect(instanceOf(x, type), expectedTrue);
    } else {
      assert.throws(() => instanceOf(x, type), dart.StrongModeError);
      expect(strongInstanceOf(x, type), expectedTrue);
    }
  }

  test('int', () => {
    expect(isGroundType(int), true);
    expect(isGroundType(getReifiedType(5)), true);

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
    expect(isGroundType(getReifiedType("foo")), true);
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
    let m6 = new (Map$(String, dart.dynamic))();


    expect(isGroundType(Map), true);
    expect(isGroundType(getReifiedType(m1)), false);
    expect(isGroundType(Map$(String, String)), false);
    expect(isGroundType(getReifiedType(m2)), true);
    expect(isGroundType(Map$(Object, Object)), true);
    expect(isGroundType(getReifiedType(m3)), true);
    expect(isGroundType(Map), true);
    expect(isGroundType(getReifiedType(m4)), true);
    expect(isGroundType(collection.HashMap$(dynamic, dynamic)), true);
    expect(isGroundType(getReifiedType(m5)), true);
    expect(isGroundType(collection.LinkedHashMap), true);
    expect(isGroundType(collection.LinkedHashMap), true);

    // Map<T1,T2> <: Map
    checkType(m1, Map);
    checkType(m1, Object);

    // Instance of self
    checkType(m1, getReifiedType(m1));
    checkType(m1, Map$(String, String));

    // Covariance on generics
    checkType(m1, getReifiedType(m2));
    checkType(m1, Map$(Object, Object));

    // No contravariance on generics.
    checkType(m2, getReifiedType(m1), false, true);
    checkType(m2, Map$(String, String), false, true);

    // null is! Map
    checkType(null, Map, false);

    // Raw generic types
    checkType(m5, Map);
    checkType(m4, Map);

    // Is checks
    assert.throws(() => dart.is(m3, Map$(String, String)),
      dart.StrongModeError);
    assert.throws(() => dart.is(m6, Map$(String, String)),
      dart.StrongModeError);
    assert.isTrue(dart.is(m1, Map$(String, String)));
    assert.throws(() => dart.is(m2, Map$(String, String)),
      dart.StrongModeError);

    // As checks
    // TODO(vsm): Enable these.  We're currently only logging warnings on
    // StrongModeErrors.
    // assert.throws(() => dart.as(m3, Map$(String, String)),
    //   dart.StrongModeError);
    // assert.throws(() => dart.as(m6, Map$(String, String)),
    //   dart.StrongModeError);
    assert.equal(dart.as(m1, Map$(String, String)), m1);
    // assert.throws(() => dart.as(m2, Map$(String, String)),
    //   dart.StrongModeError);
  });

  test('constructors', () => {
    class C extends core.Object {
      C(x) {};
      named(x, y) {};
    }
    dart.defineNamedConstructor(C, 'named');
    dart.setSignature(C, {
      constructors: () => ({
        C: [C, [core.int]],
        named: [C, [core.int, core.int]]
      })
    });
    let getType = dart.classGetConstructorType;
    isSubtype(getType(C), dart.functionType(C, [core.int]));
    isSubtype(getType(C), dart.functionType(C, [core.String]), false);
    isSubtype(getType(C, 'C'), dart.functionType(C, [core.int]));
    isSubtype(getType(C, 'C'), dart.functionType(C, [core.String]), false);
    isSubtype(getType(C, 'named'), dart.functionType(C, [core.int, core.int]));
    isSubtype(getType(C, 'named'),
              dart.functionType(C, [core.int, core.String]), false);
  });

  test('generic and inheritance', () => {
    let aaraw = new AA();
    let aarawtype = getReifiedType(aaraw);
    let aadynamic = new (AA$(dynamic, dynamic))();
    let aadynamictype = getReifiedType(aadynamic);
    let aa = new (AA$(String, List))();
    let aatype = getReifiedType(aa);
    let bb = new (BB$(String, List))();
    let bbtype = getReifiedType(bb);
    let cc = new CC();
    let cctype = getReifiedType(cc);
    // We don't allow constructing bad types.
    // This was AA<String> in Dart (wrong number of type args).
    let aabad = new (AA$(dart.dynamic, dart.dynamic))();
    let aabadtype = getReifiedType(aabad);

    expect(isGroundType(aatype), false);
    expect(isGroundType(AA$(String, List)), false);
    expect(isGroundType(bbtype), false);
    expect(isGroundType(BB$(String, List)), false);
    expect(isGroundType(cctype), true);
    expect(isGroundType(CC), true);
    checkType(cc, aatype, false, true);
    checkType(cc, AA$(String, List), false, true);
    checkType(cc, bbtype);
    checkType(cc, BB$(String, List));
    checkType(aa, cctype, false);
    checkType(aa, CC, false);
    checkType(aa, bbtype, false, true);
    checkType(aa, BB$(String, List), false, true);
    checkType(bb, cctype, false);
    checkType(bb, CC, false);
    checkType(aa, aabadtype);
    checkType(aa, dynamic);
    checkType(aabad, aatype, false, true);
    checkType(aabad, AA$(String, List), false, true);
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
    checkType(s1, c.IterableMixin$(int), false, true);

    checkType(s1, c.SetMixin);
    checkType(s1, c.SetMixin$(String));
    checkType(s1, c.SetMixin$(int), false, true);
  });

  test('Type', () => {
    checkType(int, core.Type, true);
    checkType(num, core.Type, true);
    checkType(bool, core.Type, true);
    checkType(String, core.Type, true);
    checkType(dynamic, core.Type, true);
    checkType(Object, core.Type, true);
    checkType(List, core.Type, true);
    checkType(Map, core.Type, true);
    checkType(Map$(int, String), core.Type, true);
    checkType(Func2, core.Type, true);
    checkType(functionType(dynamic, [dynamic]), core.Type, true);
    checkType(core.Type, core.Type, true);

    checkType(3, core.Type, false);
    checkType("hello", core.Type, false);
  })

  test('Functions', () => {
    // - return type: Dart is bivariant.  We're covariant.
    // - param types: Dart is bivariant.  We're contravariant.
    expect(isGroundType(Func2), true);
    expect(isGroundType(Foo), false);
    expect(isGroundType(functionType(B, [B, String])), false);
    checkType(bar1, Foo, false, true);
    checkType(cls1, Foo, false, true);
    checkType(bar1, functionType(B, [B, String]), false, true);
    checkType(cls1, functionType(B, [B, String]), false, true);
    checkType(bar2, Foo, false, true);
    checkType(cls2, Foo, false, true);
    checkType(bar2, functionType(B, [B, String]), false, true);
    checkType(cls2, functionType(B, [B, String]), false, true);
    checkType(bar3, Foo);
    checkType(cls3, Foo);
    checkType(bar3, functionType(B, [B, String]));
    checkType(cls3, functionType(B, [B, String]));
    checkType(bar4, Foo, true);
    checkType(cls4, Foo, true);
    checkType(bar4, functionType(B, [B, String]), true);
    checkType(cls4, functionType(B, [B, String]), true);
    checkType(bar5, Foo);
    checkType(cls5, Foo);
    checkType(bar5, functionType(B, [B, String]));
    checkType(cls5, functionType(B, [B, String]));
    checkType(bar6, Foo, false, true);
    checkType(cls6, Foo, false, true);
    checkType(bar6, functionType(B, [B, String]), false, true);
    checkType(cls6, functionType(B, [B, String]), false, true);
    checkType(bar7, Foo);
    checkType(cls7, Foo);
    checkType(bar7, functionType(B, [B, String]));
    checkType(cls7, functionType(B, [B, String]));
    checkType(bar7, getReifiedType(bar6));
    checkType(cls7, getReifiedType(bar6));
    checkType(bar8, Foo);
    checkType(cls8, Foo);
    checkType(bar8, functionType(B, [B, String]));
    checkType(cls8, functionType(B, [B, String]));
    checkType(bar8, getReifiedType(bar6), false, true);
    checkType(cls8, getReifiedType(bar6), false, true);
    checkType(bar7, getReifiedType(bar8), false, true);
    checkType(cls7, getReifiedType(bar8), false, true);
    checkType(bar8, getReifiedType(bar7), false, true);
    checkType(cls8, getReifiedType(bar7), false, true);

    // Parameterized typedefs
    expect(isGroundType(FuncG), true);
    expect(isGroundType(FuncG$(B, String)), false);
    checkType(bar1, FuncG$(B, String), false, true);
    checkType(cls1, FuncG$(B, String), false, true);
    checkType(bar3, FuncG$(B, String));
    checkType(cls3, FuncG$(B, String));
  });

  test('dcall', () => {
    function dd2d(x, y) {return x};
    dart.fn(dd2d);
    function ii2i(x, y) {return x};
    dart.fn(ii2i, core.int, [core.int, core.int]);
    function ii_2i(x, y) {return x};
    dart.fn(ii_2i, core.int, [core.int], [core.int]);
    function i_i2i(x, opts) {return x};
    dart.fn(i_i2i, core.int, [core.int], {extra: core.int});

    assert.equal(dart.dcall(dd2d, 0, 1), 0);
    assert.equal(dart.dcall(dd2d, "hello", "world"), "hello");
    assert.throws(() => dart.dcall(dd2d, 0));
    assert.throws(() => dart.dcall(dd2d, 0, 1, 2));
    assert.throws(() => dart.dcall(dd2d, 0, 1, {extra : 3}));
    // This should throw but currently doesn't.
    //    assert.throws(() => dart.dcall(dd2d, 0, {extra:3}));

    assert.equal(dart.dcall(ii2i, 0, 1), 0);
    assert.throws(() => dart.dcall(ii2i, "hello", "world"));
    assert.throws(() => dart.dcall(ii2i, 0));
    assert.throws(() => dart.dcall(ii2i, 0, 1, 2));

    assert.equal(dart.dcall(ii_2i, 0, 1), 0);
    assert.throws(() => dart.dcall(ii_2i, "hello", "world"));
    assert.equal(dart.dcall(ii_2i, 0), 0);
    assert.throws(() => dart.dcall(ii_2i, 0, 1, 2));

    assert.throws(() => dart.dcall(i_i2i, 0, 1));
    assert.throws(() => dart.dcall(i_i2i, "hello", "world"));
    assert.equal(dart.dcall(i_i2i, 0), 0);
    assert.throws(() => dart.dcall(i_i2i, 0, 1, 2));
    assert.equal(dart.dcall(i_i2i, 0, {extra: 3}), 0);
  });

  test('dsend', () => {
    class Tester extends core.Object {
      Tester() {
        this.f = dart.fn(x => x, core.int, [core.int]);
        this.me = this;
      }
      m(x, y) {return x;}
      call(x) {return x;}
      static s(x, y) { return x;}
    }
    dart.setSignature(Tester, {
      methods: () => ({
        m: [core.int, [core.int, core.int]],
        call: [core.int, [core.int]]
      }),
      statics: () => ({
        s: [core.String, [core.String]]
      }),
      names: ['s']
    })
    let o = new Tester();

    // Method send
    assert.equal(dart.dsend(o, 'm', 3, 4), 3);
    assert.equal(dart.dsend(o, 'm', null, 4), null);
    assert.throws(() => dart.dsend(o, 'm', 3));
    assert.throws(() => dart.dsend(o, 'm', "hello", "world"));
    assert.throws(() => dart.dsend(o, 'q', 3));

    // Method send through a field
    assert.equal(dart.dsend(o, 'f', 3), 3);
    assert.equal(dart.dsend(o, 'f', null), null);
    assert.throws(() => dart.dsend(o, 'f', "hello"));
    assert.throws(() => dart.dsend(o, 'f', 3, 4));

    // Static method call
    assert.equal(dart.dcall(Tester.s, "hello"), "hello");
    assert.equal(dart.dcall(Tester.s, null), null);
    assert.throws(() => dart.dcall(Tester.s, "hello", "world"));
    assert.throws(() => dart.dcall(Tester.s, 0, 1));

    // Calling an object with a call method
    assert.equal(dart.dcall(o, 3), 3);
    assert.equal(dart.dcall(o, null), null);
    assert.throws(() => dart.dcall(o, "hello"));
    assert.throws(() => dart.dcall(o, 3, 4));

    // Calling through a field containing an object with a call method
    assert.equal(dart.dsend(o, 'me', 3), 3);
    assert.equal(dart.dsend(o, 'me', null), null);
    assert.throws(() => dart.dsend(o, 'me', "hello"));
    assert.throws(() => dart.dsend(o, 'me', 3, 4));
  });

  test('Types on top level functions', () => {
    // Test some generated code
    // Test the lazy path
    checkType(core.identityHashCode,
              dart.functionType(core.int, [core.Object]));
    // Test the normal path
    checkType(core.identical,
              dart.functionType(core.bool,
                                [core.Object, core.Object]));

    // Hand crafted tests
    // All dynamic
    function dd2d(x, y) {return x};
    dart.fn(dd2d);
    checkType(dd2d, dart.functionType(dart.dynamic,
                                      [dart.dynamic, dart.dynamic]));

    // Set the type eagerly
    function ii2i(x, y) {return x};
    dart.fn(ii2i, core.int, [core.int, core.int]);
    checkType(ii2i, dart.functionType(core.int,
                                      [core.int, core.int]));

    // Set the type lazily
    function ss2s(x, y) {return x};
    var coreString;
    dart.lazyFn(ss2s, () => [coreString, [coreString, coreString]]);
    coreString = core.String;
    checkType(ss2s, dart.functionType(core.String,
                                      [core.String, core.String]));

    // Optional types
    function ii_2i(x, y) {return x};
    dart.fn(ii_2i, core.int, [core.int], [core.int]);
    checkType(ii_2i, dart.functionType(core.int, [core.int],
                                       [core.int]));
    checkType(ii_2i, dart.functionType(core.int, [core.int,
                                                  core.int]));
    checkType(ii_2i, dart.functionType(core.int, [], [core.int,
                                                      core.int]),
              false, true);
    checkType(ii_2i, dart.functionType(core.int, [core.int],
                                       {extra: core.int}), false, true);

    // Named types
    function i_i2i(x, opts) {return x};
    dart.fn(i_i2i, core.int, [core.int], {extra: core.int});
    checkType(i_i2i, dart.functionType(core.int, [core.int],
                                       {extra: core.int}));
    checkType(i_i2i, dart.functionType(core.int,
                                       [core.int, core.int]), false, true);
    checkType(i_i2i, dart.functionType(core.int, [core.int], {}));
    checkType(i_i2i,
        dart.functionType(core.int, [], {extra: core.int,
                                         also: core.int}), false, true);
    checkType(i_i2i,
        dart.functionType(core.int, [core.int], [core.int]), false, true);
  });

  test('Method tearoffs', () => {
    let c = collection;
    // Tear off of an inherited method
    let map = new (Map$(core.int, core.String))();
    checkType(dart.bind(map, 'toString'),
        dart.functionType(String, []));
    checkType(dart.bind(map, 'toString'),
        dart.functionType(int, []), false, true);

    // Tear off of a method directly on the object
    let smap = new (c.SplayTreeMap$(core.int, core.String))();
    checkType(dart.bind(smap, 'forEach'),
        dart.functionType(dart.void,
            [dart.functionType(dart.void, [core.int, core.String])]));
    checkType(dart.bind(smap, 'forEach'),
        dart.functionType(dart.void,
            [dart.functionType(dart.void,
                [core.String, core.String])]), false, true);

    // Tear off of a mixed in method
    let mapB = new (c.MapBase$(core.int, core.int))();
    checkType(dart.bind(mapB, 'forEach'),
        dart.functionType(dart.void, [
            dart.functionType(dart.void, [core.int, core.int])]));
    checkType(dart.bind(mapB, 'forEach'),
        dart.functionType(dart.void, [
            dart.functionType(dart.void, [core.int, core.String])]),
              false, true);

    // Tear off of a method with a symbol name
    let listB = new (c.ListBase$(core.int))();
    checkType(dart.bind(listB, dartx.add),
              dart.functionType(dart.void, [core.int]));
    checkType(dart.bind(listB, dartx.add),
              dart.functionType(dart.void, [core.String]), false, true);

    // Tear off of a static method
    checkType(c.ListBase.listToString,
              dart.functionType(core.String, [core.List]));
    checkType(c.ListBase.listToString,
              dart.functionType(core.String, [core.String]), false, true);

    // Tear-off of extension methods on primitives
    checkType(dart.bind(3.0, dartx.floor),
              dart.functionType(core.int, []));
    checkType(dart.bind(3.0, dartx.floor),
              dart.functionType(core.String, []), false, true);
    checkType(dart.bind("", dartx.endsWith),
              dart.functionType(core.bool, [core.String]));
    checkType(dart.bind("", dartx.endsWith),
              dart.functionType(core.bool, [core.int]), false, true);

    // Tear off a mixin method
    class Base {
      m(x) {return x;}
    };
    dart.setSignature(Base, {
      methods: () => ({
        m: [core.int, [core.int]],
      })
    });

    class M1 {
      m(x) {return x;}
    };
    dart.setSignature(M1, {
      methods: () => ({
        m: [core.num, [core.int]],
      })
    });

    class M2 {
      m(x) {return x;}
    };
    dart.setSignature(M2, {
      methods: () => ({
        m: [core.Object, [core.int]],
      })
    });

    class O extends dart.mixin(Base, M1, M2) {
      O() {};
    };
    dart.setSignature(O, {});
    var obj = new O();
    var m = dart.bind(obj, 'm');
    checkType(m, dart.functionType(core.Object, [core.int]));
    checkType(m, dart.functionType(core.int, [core.int]), false, true);

    // Test inherited signatures
    class P extends O {
      P() {};
      m(x) {return x;};
    };
    dart.setSignature(P, {});
    var obj = new P();
    var m = dart.bind(obj, 'm');
    checkType(m, dart.functionType(core.Object, [core.int]));
    checkType(m, dart.functionType(core.int, [core.int]), false, true);
  });

  test('Object members', () => {
    let nullHash = dart.hashCode(null);
    assert.equal(nullHash, 0);
    let nullString = dart.toString(null);
    assert.equal(nullString, 'null');

    let map = new Map();
    let mapHash = dart.hashCode(map);
    checkType(mapHash, core.int);
    assert.equal(mapHash, map.hashCode);

    let mapString = dart.toString(map);
    assert.equal(mapString, map.toString());
    checkType(mapString, core.String);

    let str = "A string";
    let strHash = dart.hashCode(str);
    checkType(strHash, core.int);

    let strString = dart.toString(str);
    checkType(strString, core.String);
    assert.equal(str, strString);

    let n = 42;
    let intHash = dart.hashCode(n);
    checkType(intHash, core.int);

    let intString = dart.toString(n);
    assert.equal(intString, '42');
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
