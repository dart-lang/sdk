// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

define(['dart_sdk'], function(dart_sdk) {
  const assert = chai.assert;
  const async = dart_sdk.async;
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart.dartx;

  dart.trapRuntimeErrors(false);

  suite('ignore', () => {
    "use strict";

    let FutureOr = async.FutureOr$;
    let Future = async.Future$;
    let List = core.List$;

    setup(() => {
      dart_sdk.dart.ignoreWhitelistedErrors(false);
    });

    teardown(() => {
      dart_sdk.dart.ignoreWhitelistedErrors(false);
    });

    test('FutureOr', () => {
      let f = Future(dart.dynamic).value(42);
      let l = [1, 2, 3];

      assert.throws(() => { dart.as(f, FutureOr(core.int)); });
      assert.throws(() => { dart.as(l, FutureOr(List(core.int)))});

      dart_sdk.dart.ignoreWhitelistedErrors(true);
      assert.equal(f, dart.as(f, FutureOr(core.int)));
      assert.equal(l, dart.as(l, FutureOr(List(core.int))));
    });
  });

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

    setup(() => {
      dart_sdk.dart.failForWeakModeIsChecks(true);
    });

    teardown(() => {
      dart_sdk.dart.failForWeakModeIsChecks(false);
    });

    let expect = assert.equal;
    let isGroundType = dart.isGroundType;
    let generic = dart.generic;
    let intIsNonNullable = false;
    let cast = dart.as;
    let instanceOf = dart.is;
    let strongInstanceOf = dart.strongInstanceOf;
    let getReifiedType = dart.getReifiedType;
    let fnTypeFuzzy = dart.fnTypeFuzzy;
    let typedef = dart.typedef;
    let isSubtype = dart.isSubtype;

    let Object = core.Object;
    let String = core.String;
    let dynamic = dart.dynamic;
    let List = core.List;
    let Map = core.Map;
    let Map$ = core.Map$;
    let double = core.double;
    let int = core.int;
    let num = core.num;
    let bool = core.bool;

    class A {}
    class B extends A {}
    class C extends B {}

    let AA$ = generic((T, U) => {
      class AA extends core.Object {}
      (AA.new = function() {}).prototype = AA.prototype;
      return AA;
    });
    let AA = AA$();
    let BB$ = generic((T, U) => {
      class BB extends AA$(U, T) {}
      (BB.new = function() {}).prototype = BB.prototype;
      return BB;
    });
    let BB = BB$();
    class CC extends BB$(String, List) {}
    (CC.new = function() {}).prototype = CC.prototype;

    let Func2 = typedef('Func2', () => fnTypeFuzzy(dynamic, [dynamic, dynamic]));
    let Foo = typedef('Foo', () => fnTypeFuzzy(B, [B, String]));

    let FuncG$ = generic((T, U) => typedef('FuncG', () => fnTypeFuzzy(T, [T, U])))
    let FuncG = FuncG$();

    // TODO(vsm): Revisit when we encode types on functions properly.
    // A bar1(C c, String s) => null;
    function bar1(c, s) { return null; }
    dart.fn(bar1, dart.fnType(A, [C, String]));

    // bar2(B b, String s) => null;
    function bar2(b, s) { return null; }
    dart.fn(bar2, dart.fnType(dynamic, [B, String]));

    // B bar3(B b, Object o) => null;
    function bar3(b, o) { return null; }
    dart.fn(bar3, dart.fnType(B, [B, Object]));

    // B bar4(B b, o) => null;
    function bar4(b, o) { return null; }
    dart.fn(bar4, dart.fnType(B, [B, dynamic]));

    // C bar5(A a, Object o) => null;
    function bar5(a, o) { return null; }
    dart.fn(bar5, dart.fnType(C, [A, Object]));

    // B bar6(B b, String s, String o) => null;
    function bar6(b, s, o) { return null; }
    dart.fn(bar6, dart.fnType(B, [B, String, String]));

    // B bar7(B b, String s, [Object o]) => null;
    function bar7(b, s, o) { return null; }
    dart.fn(bar7, dart.fnType(B, [B, String], [Object]));

    // B bar8(B b, String s, {Object p}) => null;
    function bar8(b, s, o) { return null; }
    dart.fn(bar8, dart.fnType(B, [B, String], {p: Object}));

    let cls1 = dart.fn((c, s) => { return null; },
                       dart.fnType(A, [C, String]));

    let cls2 = dart.fn((b, s) => { return null; },
                       dart.fnType(dynamic, [B, String]));

    let cls3 = dart.fn((b, o) => { return null; },
                       dart.fnType(B, [B, Object]));

    let cls4 = dart.fn((b, o) => { return null; },
                       dart.fnType(B, [B, dynamic]));

    let cls5 = dart.fn((a, o) => { return null; },
                       dart.fnType(C, [A, Object]));

    let cls6 = dart.fn((b, s, o) => { return null; },
                       dart.fnType(B, [B, String, String]));

    let cls7 = dart.fn((b, s, o) => { return null; },
                       dart.fnType(B, [B, String], [Object]));

    let cls8 =
      dart.fn((b, s, o) => { return null; },
              dart.fnType(B, [B, String], {p: Object}));

    function checkType(x, type, expectedTrue, strongOnly) {
      if (expectedTrue === undefined) expectedTrue = true;
      if (strongOnly === undefined) strongOnly = false;
      if (!strongOnly) {
        assert.doesNotThrow(() => instanceOf(x, type));
        expect(instanceOf(x, type), expectedTrue,
          '"' + x + '" ' +
          (expectedTrue ? 'should' : 'should not') +
          ' be an instance of "' + dart.typeName(type) + '"');
      } else {
        assert.throws(() => instanceOf(x, type), dart.StrongModeError);
        expect(expectedTrue, false);
        expect(strongInstanceOf(x, type), null);
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
      checkType(new Object.new(), dynamic);
      checkType(null, dynamic);

      expect(cast(null, dynamic), null);
    });

    test('Object', () => {
      expect(isGroundType(Object), true);
      checkType(new Object.new(), dynamic);
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

    test('FutureOr', () => {
      let FutureOr = async.FutureOr$;

      assert.equal(dart.as(3, FutureOr(int)), 3);
      assert.equal(dart.as(3, FutureOr(double)), 3);
      assert.throws(() => dart.as(3.5, FutureOr(int)));
      assert.equal(dart.as(3.5, FutureOr(double)), 3.5);
      assert.isTrue(dart.is(3, FutureOr(int)));
      assert.isTrue(dart.is(3, FutureOr(double)));
      assert.isFalse(dart.is(3.5, FutureOr(int)));
      assert.isTrue(dart.is(3.5, FutureOr(double)));

      assert.equal(dart.as(3, FutureOr(FutureOr(double))), 3);
      assert.isTrue(dart.is(3, FutureOr(FutureOr(double))));

    });

    test('Map', () => {
      let m1 = Map$(String, String).new();
      let m2 = Map$(Object, Object).new();
      let m3 = Map.new();
      let m4 = collection.HashMap$(dart.dynamic, dart.dynamic).new();
      let m5 = collection.LinkedHashMap.new();
      let m6 = Map$(String, dart.dynamic).new();

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
      checkType(m2, getReifiedType(m1), false);
      checkType(m2, Map$(String, String), false);

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
      assert.isFalse(dart.is(m2, Map$(String, String)));

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
      }
      (C.new = function(x) {}).prototype = C.prototype;
      (C.named = function(x, y) {}).prototype = C.prototype;
      dart.setSignature(C, {
        constructors: () => ({
          new: dart.fnType(C, [core.int]),
          named: dart.fnType(C, [core.int, core.int])
        })
      });
      let getType = dart.classGetConstructorType;
      isSubtype(getType(C), dart.fnTypeFuzzy(C, [core.int]));
      isSubtype(getType(C), dart.fnTypeFuzzy(C, [core.String]), false);
      isSubtype(getType(C, 'new'), dart.fnTypeFuzzy(C, [core.int]));
      isSubtype(getType(C, 'new'), dart.fnTypeFuzzy(C, [core.String]), false);
      isSubtype(getType(C, 'named'), dart.fnTypeFuzzy(C, [core.int, core.int]));
      isSubtype(getType(C, 'named'),
                dart.fnTypeFuzzy(C, [core.int, core.String]), false);
    });

    test('generic and inheritance', () => {
      let aaraw = new AA.new();
      let aarawtype = getReifiedType(aaraw);
      let aadynamic = new (AA$(dynamic, dynamic).new)();
      let aadynamictype = getReifiedType(aadynamic);
      let aa = new (AA$(String, List).new)();
      let aatype = getReifiedType(aa);
      let bb = new (BB$(String, List).new)();
      let bbtype = getReifiedType(bb);
      let cc = new CC.new();
      let cctype = getReifiedType(cc);
      // We don't allow constructing bad types.
      // This was AA<String> in Dart (wrong number of type args).
      let aabad = new (AA$(dart.dynamic, dart.dynamic).new)();
      let aabadtype = getReifiedType(aabad);

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
      var s1 = new (c.SplayTreeSet$(String).new)();

      checkType(s1, c.IterableMixin);
      checkType(s1, c.IterableMixin$(String));
      checkType(s1, c.IterableMixin$(int), false);

      checkType(s1, c.SetMixin);
      checkType(s1, c.SetMixin$(String));
      checkType(s1, c.SetMixin$(int), false);
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
      checkType(fnTypeFuzzy(dynamic, [dynamic]), core.Type, true);
      checkType(core.Type, core.Type, true);

      checkType(3, core.Type, false);
      checkType("hello", core.Type, false);
    })

    test('Functions', () => {
      // - return type: Dart is bivariant.  We're covariant.
      // - param types: Dart is bivariant.  We're contravariant.
      expect(isGroundType(Func2), true);
      expect(isGroundType(Foo), false);
      expect(isGroundType(fnTypeFuzzy(B, [B, String])), false);
      checkType(bar1, Foo, false, true);
      checkType(cls1, Foo, false, true);
      checkType(bar1, fnTypeFuzzy(B, [B, String]), false, true);
      checkType(cls1, fnTypeFuzzy(B, [B, String]), false, true);
      checkType(bar2, Foo, false, true);
      checkType(cls2, Foo, false, true);
      checkType(bar2, fnTypeFuzzy(B, [B, String]), false, true);
      checkType(cls2, fnTypeFuzzy(B, [B, String]), false, true);
      checkType(bar3, Foo);
      checkType(cls3, Foo);
      checkType(bar3, fnTypeFuzzy(B, [B, String]));
      checkType(cls3, fnTypeFuzzy(B, [B, String]));
      checkType(bar4, Foo, true);
      checkType(cls4, Foo, true);
      checkType(bar4, fnTypeFuzzy(B, [B, String]), true);
      checkType(cls4, fnTypeFuzzy(B, [B, String]), true);
      checkType(bar5, Foo);
      checkType(cls5, Foo);
      checkType(bar5, fnTypeFuzzy(B, [B, String]));
      checkType(cls5, fnTypeFuzzy(B, [B, String]));
      checkType(bar6, Foo, false);
      checkType(cls6, Foo, false);
      checkType(bar6, fnTypeFuzzy(B, [B, String]), false);
      checkType(cls6, fnTypeFuzzy(B, [B, String]), false);
      checkType(bar7, Foo);
      checkType(cls7, Foo);
      checkType(bar7, fnTypeFuzzy(B, [B, String]));
      checkType(cls7, fnTypeFuzzy(B, [B, String]));
      checkType(bar7, getReifiedType(bar6));
      checkType(cls7, getReifiedType(bar6));
      checkType(bar8, Foo);
      checkType(cls8, Foo);
      checkType(bar8, fnTypeFuzzy(B, [B, String]));
      checkType(cls8, fnTypeFuzzy(B, [B, String]));
      checkType(bar8, getReifiedType(bar6), false);
      checkType(cls8, getReifiedType(bar6), false);
      checkType(bar7, getReifiedType(bar8), false);
      checkType(cls7, getReifiedType(bar8), false);
      checkType(bar8, getReifiedType(bar7), false);
      checkType(cls8, getReifiedType(bar7), false);

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
      dart.fn(ii2i, dart.fnType(core.int, [core.int, core.int]));
      function ii_2i(x, y) {return x};
      dart.fn(ii_2i, dart.fnType(core.int, [core.int], [core.int]));
      function i_i2i(x, opts) {return x};
      dart.fn(i_i2i,
              dart.fnType(core.int, [core.int], {extra: core.int}));

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
        m(x, y) {return x;}
        call(x) {return x;}
        static s(x, y) { return x;}
      }
      (Tester.new = function() {
        this.f = dart.fn(x => x,
                          dart.fnType(core.int, [core.int]));
        this.me = this;
      }).prototype = Tester.prototype;
      dart.setSignature(Tester, {
        methods: () => ({
          m: dart.fnType(core.int, [core.int, core.int]),
          call: dart.fnType(core.int, [core.int])
        }),
        statics: () => ({
          s: dart.fnType(core.String, [core.String])
        }),
        names: ['s']
      })
      let o = new Tester.new();

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
                dart.fnTypeFuzzy(core.int, [core.Object]));
      // Test the normal path
      checkType(core.identical,
                dart.fnTypeFuzzy(core.bool,
                                  [core.Object, core.Object]));

      // Hand crafted tests
      // All dynamic
      function dd2d(x, y) {return x};
      dart.fn(dd2d);
      checkType(dd2d, dart.fnTypeFuzzy(dart.dynamic,
                                        [dart.dynamic, dart.dynamic]));

      // Set the type eagerly
      function ii2i(x, y) {return x};
      dart.fn(ii2i, dart.fnType(core.int, [core.int, core.int]));
      checkType(ii2i, dart.fnTypeFuzzy(core.int,
                                        [core.int, core.int]));

      // Set the type lazily
      function ss2s(x, y) {return x};
      var coreString;
      dart.lazyFn(ss2s,
                  () => dart.fnType(coreString,
                                                  [coreString, coreString]));
      coreString = core.String;
      checkType(ss2s, dart.fnTypeFuzzy(core.String,
                                        [core.String, core.String]));

      // Optional types
      function ii_2i(x, y) {return x};
      dart.fn(ii_2i, dart.fnType(core.int, [core.int], [core.int]));
      checkType(ii_2i, dart.fnTypeFuzzy(core.int, [core.int],
                                         [core.int]));
      checkType(ii_2i, dart.fnTypeFuzzy(core.int, [core.int,
                                                    core.int]));
      checkType(ii_2i, dart.fnTypeFuzzy(core.int, [], [core.int,
                                                        core.int]),
                false);
      checkType(ii_2i, dart.fnTypeFuzzy(core.int, [core.int],
                                         {extra: core.int}), false);

      // Named types
      function i_i2i(x, opts) {return x};
      dart.fn(i_i2i, dart.fnType(core.int, [core.int],
                                               {extra: core.int}));
      checkType(i_i2i, dart.fnTypeFuzzy(core.int, [core.int],
                                         {extra: core.int}));
      checkType(i_i2i, dart.fnTypeFuzzy(core.int,
                                         [core.int, core.int]), false);
      checkType(i_i2i, dart.fnTypeFuzzy(core.int, [core.int], {}));
      checkType(i_i2i,
          dart.fnTypeFuzzy(core.int, [], {extra: core.int,
                                           also: core.int}), false);
      checkType(i_i2i,
          dart.fnTypeFuzzy(core.int, [core.int], [core.int]), false);
    });

    test('Method tearoffs', () => {
      let c = collection;
      // Tear off of an inherited method
      let map = Map$(core.int, core.String).new();
      checkType(dart.bind(map, 'toString'),
                dart.fnTypeFuzzy(String, []));
      checkType(dart.bind(map, 'toString'),
                dart.fnTypeFuzzy(int, []), false, true);

      // Tear off of a method directly on the object
      let smap = new (c.SplayTreeMap$(core.int, core.String).new)();
      checkType(dart.bind(smap, 'forEach'),
          dart.fnTypeFuzzy(dart.void,
                            [dart.fnTypeFuzzy(dart.void, [core.int, core.String])]));
      checkType(dart.bind(smap, 'forEach'),
          dart.fnTypeFuzzy(dart.void,
              [dart.fnTypeFuzzy(dart.void,
                  [core.String, core.String])]), false, true);

      // Tear off of a mixed in method
      let mapB = new (c.MapBase$(core.int, core.int).new)();
      checkType(dart.bind(mapB, 'forEach'),
          dart.fnTypeFuzzy(dart.void, [
              dart.fnTypeFuzzy(dart.void, [core.int, core.int])]));
      checkType(dart.bind(mapB, 'forEach'),
          dart.fnTypeFuzzy(dart.void, [
              dart.fnTypeFuzzy(dart.void, [core.int, core.String])]),
                false, true);

      // Tear off of a method with a symbol name
      let listB = new (c.ListBase$(core.int).new)();
      checkType(dart.bind(listB, dartx.add),
                dart.fnTypeFuzzy(dart.void, [core.int]));
      checkType(dart.bind(listB, dartx.add),
                dart.fnTypeFuzzy(dart.void, [core.String]), false, true);

      // Tear off of a static method
      checkType(c.ListBase.listToString,
                dart.fnTypeFuzzy(core.String, [core.List]));
      checkType(c.ListBase.listToString,
                dart.fnTypeFuzzy(core.String, [core.String]), false, true);

      // Tear-off of extension methods on primitives
      checkType(dart.bind(3.0, dartx.floor),
                dart.fnTypeFuzzy(core.int, []));
      checkType(dart.bind(3.0, dartx.floor),
                dart.fnTypeFuzzy(core.String, []), false, true);
      checkType(dart.bind("", dartx.endsWith),
                dart.fnTypeFuzzy(core.bool, [core.String]));
      checkType(dart.bind("", dartx.endsWith),
                dart.fnTypeFuzzy(core.bool, [core.int]), false, true);

      // Tear off a mixin method
      class Base {
        m(x) {return x;}
      };
      dart.setSignature(Base, {
        methods: () => ({
          m: dart.fnType(core.int, [core.int]),
        })
      });

      class M1 {
        m(x) {return x;}
      };
      dart.setSignature(M1, {
        methods: () => ({
          m: dart.fnType(core.num, [core.int]),
        })
      });

      class M2 {
        m(x) {return x;}
      };
      dart.setSignature(M2, {
        methods: () => ({
          m: dart.fnType(core.Object, [core.int]),
        })
      });

      class O extends dart.mixin(Base, M1, M2) {}
      (O.new = function() {}).prototype = O.prototype;
      dart.setSignature(O, {});
      var obj = new O.new();
      var m = dart.bind(obj, 'm');
      checkType(m, dart.fnTypeFuzzy(core.Object, [core.int]));
      checkType(m, dart.fnTypeFuzzy(core.int, [core.int]), false, true);

      // Test inherited signatures
      class P extends O {
        m(x) {return x;};
      };
      (P.new = function() {}).prototype = P.prototype;
      dart.setSignature(P, {});
      var obj = new P.new();
      var m = dart.bind(obj, 'm');
      checkType(m, dart.fnTypeFuzzy(core.Object, [core.int]));
      checkType(m, dart.fnTypeFuzzy(core.int, [core.int]), false, true);
    });

    test('Object members', () => {
      let nullHash = dart.hashCode(null);
      assert.equal(nullHash, 0);
      let nullString = dart.toString(null);
      assert.equal(nullString, 'null');

      let map = Map.new();
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

  suite('subtyping', function() {
    'use strict';

    let fnTypeFuzzy = dart.fnTypeFuzzy;
    let fnType = dart.fnType;
    let typedef = dart.typedef;
    let isSubtype = dart.isSubtype;
    let int = core.int;
    let num = core.num;
    let dyn = dart.dynamic;

    function always(t1, t2) {
      assert.equal(isSubtype(t1, t2), true,
          dart.toString(t1) +
          " should always be a subtype of " +
          dart.toString(t2));
    }
    function never(t1, t2) {
      assert.equal(isSubtype(t1, t2), false,
          dart.toString(t1) +
          " should never be a subtype of " +
          dart.toString(t2));
    }
    function maybe(t1, t2) {
      assert.equal(isSubtype(t1, t2), null,
          dart.toString(t1) +
          " should maybe be a subtype of " +
          dart.toString(t2));
    }

    function always2(t1, t2) {
      always(t1, t2);
      always(fnTypeFuzzy(t1, [t2]), fnTypeFuzzy(t2, [t1]));
    }
    function never2(t1, t2) {
      never(t1, t2);
      maybe(fnTypeFuzzy(t1, [t2]), fnTypeFuzzy(t2, [t1]));
    }
    function maybe2(t1, t2) {
      maybe(t1, t2);
      maybe(fnTypeFuzzy(t1, [t2]), fnTypeFuzzy(t2, [t1]));
    }

    function run_test(func1, func2, func2opt, func1extra, func2extra) {
      always2(func2(int, int), func2(int, int));
      always2(func2(int, num), func2(int, int));
      always2(func2(int, int), func2(num, int));

      always2(func2opt(int, int), func2opt(int, int));
      always2(func2opt(int, num), func2opt(int, int));
      always2(func2opt(int, int), func2opt(num, int));

      always2(func2opt(int, int), func2(int, int));
      always2(func2opt(int, num), func2(int, int));
      always2(func2opt(int, int), func2(num, int));

      always2(func2opt(int, int), func1(int));
      always2(func2opt(int, num), func1(int));
      always2(func2opt(int, int), func1(num));

      always2(func2extra(int, int), func2(int, int));
      always2(func2extra(int, num), func2(int, int));
      always2(func2extra(int, int), func2(num, int));

      maybe2(func2(int, int), func2(int, num));
      maybe2(func2(num, int), func2(int, int));

      maybe2(func2opt(num, num), func1(int));

      maybe2(func2opt(int, int), func2opt(int, num));
      maybe2(func2opt(num, int), func2opt(int, int));

      maybe2(func2opt(int, int), func2(int, num));
      maybe2(func2opt(num, int), func2(int, int));

      maybe2(func2extra(int, int), func2(int, num));
      maybe2(func2extra(num, int), func2(int, int));

      never2(func1(int), func2(int, num));
      never2(func1(num), func2(int, int));
      never2(func1(num), func2(num, num));

      never2(func2(int, int), func1(int));
      never2(func2(num, int), func1(int));
      never2(func2(num, num), func1(num));

      never2(func1(int), func2opt(int, num));
      never2(func1(num), func2opt(int, int));
      never2(func1(num), func2opt(num, num));

      never2(func2(int, int), func2opt(int, num));
      never2(func2(num, int), func2opt(int, int));
      never2(func2(num, num), func2opt(num, num));

      never2(func1extra(int), func2(int, num));
      never2(func1extra(num), func2(int, int));
      never2(func1extra(num), func2(num, num));

      never2(func1extra(int), func2opt(int, num));
      never2(func1extra(num), func2opt(int, int));
      never2(func1extra(num), func2opt(num, num));

      never2(func1(int), func1extra(int));
      never2(func1(num), func1extra(int));
      never2(func1(num), func1extra(num));

      never2(func2(int, int), func1extra(int));
      never2(func2(num, int), func1extra(int));
      never2(func2(num, num), func1extra(num));

      never2(func2(int, int), func2extra(int, int));
      never2(func2(num, int), func2extra(int, int));
      never2(func2(num, num), func2extra(num, num));
    };

    test('basic function types', () => {
      function func1(S) {
        return fnTypeFuzzy(S, []);
      }

      function func2(S, T) {
        return fnTypeFuzzy(S, [T]);
      }

      function func2opt(S, T) {
        return fnTypeFuzzy(S, [], [T]);
      }

      function func1extra(S) {
        return fnTypeFuzzy(S, [], {extra: int});
      }

      function func2extra(S, T) {
        return fnTypeFuzzy(S, [T], {extra: int});
      }

      run_test(func1, func2, func2opt, func1extra, func2extra);
    });

    test('top and bottom types', () => {
      let FutureOr = async.FutureOr$;
      let tops = [
        dart.dynamic,
        core.Object,
        dart.void,
        FutureOr(dart.dynamic),
        FutureOr(core.Object),
        FutureOr(dart.void),
        FutureOr(FutureOr(core.Object)),
        // ... skip the (infinite) rest of the top types :D
      ];
      let bottoms = [dart.bottom, core.Null];

      for (let top of tops) {
        for (let bottom of bottoms) {
          always(bottom, top);
          always(
              fnType(bottom, [top]),
              fnType(top, [bottom]));
        }
      }

      for (let equalTypes of [tops, bottoms]) {
        for (let t1 of equalTypes) {
          for (let t2 of equalTypes) {
            always(t1, t2);
            always(t2, t1);

            let t11 = fnType(t1, [t1]);
            let t22 = fnType(t2, [t2]);
            always(t11, t22);
            always(t22, t11);
          }
        }
      }
    });

    test('basic typedefs', () => {
      function func1(S) {
        return dart.typedef('Func1', () => fnTypeFuzzy(S, []))
      }

      function func2(S, T) {
        return dart.typedef('Func2', () => fnTypeFuzzy(S, [T]))
      }

      function func2opt(S, T) {
        return dart.typedef('Func2', () => fnTypeFuzzy(S, [], [T]))
      }

      function func1extra(S) {
        return dart.typedef('Func1', () => fnTypeFuzzy(S, [], {extra: int}))
      }

      function func2extra(S, T) {
        return dart.typedef('Func2', () => fnTypeFuzzy(S, [T], {extra: int}))
      }

      run_test(func1, func2, func2opt, func1extra, func2extra);
    });

    test('basic generic typedefs', () => {
      let func1 = dart.generic(
        (S) => dart.typedef('Func1', () => fnTypeFuzzy(S, [])));

      let func2 = dart.generic(
        (S, T) => dart.typedef('Func2', () => fnTypeFuzzy(S, [T])));

      let func2opt = dart.generic(
        (S, T) => dart.typedef('Func2', () => fnTypeFuzzy(S, [], [T])));

      let func1extra = dart.generic(
        (S) => dart.typedef('Func1', () => fnTypeFuzzy(S, [], {extra: int})));

      let func2extra = dart.generic(
        (S, T) => dart.typedef('Func2',
                               () => fnTypeFuzzy(S, [T], {extra: int})));

      run_test(func1, func2, func2opt, func1extra, func2extra);
    });

    test('fuzzy function types', () => {
      always(fnTypeFuzzy(int, [int]), fnTypeFuzzy(dyn, [dyn]));
      always(fnTypeFuzzy(int, [], [int]), fnTypeFuzzy(dyn, [], [dyn]));
      always(fnTypeFuzzy(int, [], [int]), fnTypeFuzzy(dyn, [dyn]));
      always(fnTypeFuzzy(int, [], [int]), fnTypeFuzzy(dyn, []));
      always(fnTypeFuzzy(int, [int], {extra: int}), fnTypeFuzzy(dyn, [dyn]));

      always(fnTypeFuzzy(dyn, [dyn]), fnTypeFuzzy(dyn, [dyn]));
      always(fnTypeFuzzy(dyn, [], [dyn]), fnTypeFuzzy(dyn, [], [dyn]));
      always(fnTypeFuzzy(dyn, [], [dyn]), fnTypeFuzzy(dyn, [dyn]));
      always(fnTypeFuzzy(dyn, [], [dyn]), fnTypeFuzzy(dyn, []));
      always(fnTypeFuzzy(dyn, [dyn], {extra: dyn}), fnTypeFuzzy(dyn, [dyn]));
    });

    test('void function types', () => {
      always(fnTypeFuzzy(int, [int]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(int, [], [int]), fnTypeFuzzy(dart.void, [], [dyn]));
      always(fnTypeFuzzy(int, [], [int]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(int, [], [int]), fnTypeFuzzy(dart.void, []));
      always(fnTypeFuzzy(int, [int], {extra: int}), fnTypeFuzzy(dart.void, [dyn]));

      always(fnTypeFuzzy(dart.void, [int]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(dart.void, [], [dyn]));
      always(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(dart.void, []));
      always(fnTypeFuzzy(dart.void, [int], {extra: int}), fnTypeFuzzy(dart.void, [dyn]));

      always(fnTypeFuzzy(dyn, [dyn]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(dyn, [], [dyn]), fnTypeFuzzy(dart.void, [], [dyn]));
      always(fnTypeFuzzy(dyn, [], [dyn]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(dyn, [], [dyn]), fnTypeFuzzy(dart.void, []));
      always(fnTypeFuzzy(dyn, [dyn], {extra: dyn}), fnTypeFuzzy(dart.void, [dyn]));

      always(fnTypeFuzzy(dart.void, [dyn]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(dart.void, [], [dyn]), fnTypeFuzzy(dart.void, [], [dyn]));
      always(fnTypeFuzzy(dart.void, [], [dyn]), fnTypeFuzzy(dart.void, [dyn]));
      always(fnTypeFuzzy(dart.void, [], [dyn]), fnTypeFuzzy(dart.void, []));
      always(fnTypeFuzzy(dart.void, [dyn], {extra: dyn}), fnTypeFuzzy(dart.void, [dyn]));

      always(fnTypeFuzzy(dart.void, [int]), fnTypeFuzzy(dyn, [dyn]));
      always(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(dyn, [], [dyn]));
      always(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(dyn, [dyn]));
      always(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(dyn, []));
      always(fnTypeFuzzy(dart.void, [int], {extra: int}), fnTypeFuzzy(dyn, [dyn]));

      never(fnTypeFuzzy(dart.void, [int]), fnTypeFuzzy(int, [dyn]));
      never(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(int, [], [dyn]));
      never(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(int, [dyn]));
      never(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(int, []));
      never(fnTypeFuzzy(dart.void, [int], {extra: int}), fnTypeFuzzy(int, [dyn]));

      never(fnTypeFuzzy(dart.void, [int]), fnTypeFuzzy(int, [int]));
      never(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(int, [], [int]));
      never(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(int, [int]));
      never(fnTypeFuzzy(dart.void, [], [int]), fnTypeFuzzy(int, []));
      never(fnTypeFuzzy(dart.void, [int], {extra: int}), fnTypeFuzzy(int, [int]));
    });

    test('higher-order typedef', () => {
      let Func$ = dart.generic((S, T) =>
                               dart.typedef('Func', () =>
                                            fnTypeFuzzy(T, [S])));
      let Func2$ = dart.generic((R, S, T) =>
                                dart.typedef('Func2', () =>
                                             fnTypeFuzzy(T, [Func$(R, S)])));

      maybe(fnTypeFuzzy(int, [fnTypeFuzzy(int, [num])]),
            fnTypeFuzzy(num, [fnTypeFuzzy(int, [int])]));
      maybe(fnTypeFuzzy(int, [Func$(num, int)]),
            fnTypeFuzzy(num, [Func$(int, int)]));
      maybe(Func2$(num, int, int), Func2$(int, int, num));
    });

    test('mixed types', () => {
      let AA$ = dart.generic((T) => {
        class AA extends core.Object {}
        (AA.new = function() {}).prototype = AA.prototype;
        return AA;
      });

      always(int, dyn);
      maybe(dyn, int);

      never(fnTypeFuzzy(int, [int]), int);

      never(int, fnTypeFuzzy(int, [int]));

      always(AA$(int), AA$(dyn));
      maybe(AA$(dyn), AA$(int));
      never(AA$(core.Object), AA$(int));

      always(AA$(fnTypeFuzzy(int, [int])), AA$(dyn));
      maybe(AA$(dyn), AA$(fnTypeFuzzy(int, [int])));
      never(AA$(core.Object), AA$(fnTypeFuzzy(int, [int])));

      always(AA$(fnTypeFuzzy(int, [int])), AA$(fnTypeFuzzy(dyn, [dyn])));
      maybe(AA$(fnTypeFuzzy(dyn, [dyn])), AA$(fnTypeFuzzy(int, [int])));
      maybe(AA$(fnTypeFuzzy(core.Object, [core.Object])),
            AA$(fnTypeFuzzy(int, [int])));
    });
  });

  suite('canonicalization', function() {
    'use strict';
    let fnTypeFuzzy = dart.fnTypeFuzzy;
    let fnType = dart.fnType;
    let typedef = dart.typedef;
    let generic = dart.generic;

    let Object = core.Object;
    let String = core.String;
    let int = core.int;
    let dynamic = dart.dynamic;
    let bottom = dart.bottom;
    let Map = core.Map;
    let Map$ = core.Map$;

    class A {}

    let AA$ = generic((T, U) => {
      class AA extends core.Object {}
      (AA.new = function() {}).prototype = AA.prototype;
      return AA;
    });
    let AA = AA$();

    let Func2 = typedef('Func2', () => fnTypeFuzzy(dynamic, [dynamic, dynamic]));

    let FuncG$ = generic((T, U) => typedef('FuncG', () => fnTypeFuzzy(T, [T, U])))
    let FuncG = FuncG$();

    test('base types', () => {
      assert.equal(Object, Object);
      assert.equal(String, String);
      assert.equal(dynamic, dynamic);
    });

    test('class types', () => {
      assert.equal(A, A);
    });

    test('generic class types', () => {
      assert.equal(AA, AA);
      assert.equal(AA, AA$(dynamic, dynamic));
      assert.equal(AA$(dynamic, dynamic), AA$(dynamic, dynamic));
      assert.equal(AA$(AA, Object), AA$(AA, Object));
      assert.equal(Map, Map);
      assert.equal(Map$(dynamic, dynamic), Map);
      assert.equal(Map$(int, Map$(int, int)), Map$(int, Map$(int, int)));
    });

    test('typedefs', () => {
      assert.equal(Func2, Func2);
      assert.equal(FuncG, FuncG$(dynamic, dynamic));
      assert.equal(FuncG$(dynamic, dynamic), FuncG$(dynamic, dynamic));
      assert.equal(FuncG$(String, Func2), FuncG$(String, Func2));
    });

    test('function types', () => {
      assert.equal(fnTypeFuzzy(dynamic, [dynamic, dynamic]),
                   fnTypeFuzzy(dynamic, [dynamic, dynamic]))

      assert.notEqual(fnType(dynamic, [dynamic, dynamic]),
                      fnTypeFuzzy(dynamic, [dynamic, dynamic]))

      assert.equal(fnTypeFuzzy(dynamic, [dynamic, dynamic]),
                   fnTypeFuzzy(dynamic, [bottom, bottom]))

      assert.equal(fnTypeFuzzy(dynamic, [], [dynamic, dynamic]),
                   fnTypeFuzzy(dynamic, [], [dynamic, dynamic]))

      assert.notEqual(fnType(dynamic, [], [dynamic, dynamic]),
                      fnTypeFuzzy(dynamic, [], [dynamic, dynamic]))

      assert.equal(fnTypeFuzzy(dynamic, [], [dynamic, dynamic]),
                   fnTypeFuzzy(dynamic, [], [bottom, bottom]))

      assert.equal(fnTypeFuzzy(dynamic, [], {extra: dynamic}),
                   fnTypeFuzzy(dynamic, [], {extra: dynamic}))

      assert.notEqual(fnType(dynamic, [], {extra: dynamic}),
                      fnTypeFuzzy(dynamic, [], {extra: dynamic}))

      assert.equal(fnTypeFuzzy(dynamic, [], {extra: dynamic}),
                   fnTypeFuzzy(dynamic, [], {extra: bottom}))

      assert.equal(fnTypeFuzzy(int, [int, int]),
                   fnTypeFuzzy(int, [int, int]))

      assert.equal(fnTypeFuzzy(int, [], [int, int]),
                   fnTypeFuzzy(int, [], [int, int]))

      assert.equal(fnTypeFuzzy(int, [int, int], {extra: int}),
                   fnTypeFuzzy(int, [int, int], {extra: int}))

      assert.equal(fnTypeFuzzy(int, [int, int, int, int, int]),
                   fnTypeFuzzy(int, [int, int, int, int, int]))

      assert.notEqual(fnTypeFuzzy(int, [int, int, int, int, int]),
                      fnTypeFuzzy(int, [int, int, int], [int, int]))

      assert.notEqual(fnTypeFuzzy(String, [int, int, int, int, int]),
                      fnTypeFuzzy(int, [int, int, int, int, int]))

      assert.notEqual(fnTypeFuzzy(String, []),
                   fnTypeFuzzy(int, []))
    });
  });

  suite('primitives', function() {
    'use strict';

    test('fixed length list', () => {
      let list = core.List.new(10);
      list[0] = 42;
      assert.throws(() => list.add(42));
    });

    test('toString on ES Symbol', () => {
      let sym = Symbol('_foobar');
      assert.equal(dart.toString(sym), 'Symbol(_foobar)');
    });
  });
});
