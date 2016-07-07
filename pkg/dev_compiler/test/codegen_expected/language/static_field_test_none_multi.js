dart_library.library('language/static_field_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_field_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_field_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_field_test_none_multi.First = class First extends core.Object {
    new() {
    }
    static setValues() {
      static_field_test_none_multi.First.a = 24;
      static_field_test_none_multi.First.b = 10;
      return dart.dsend(dart.dsend(static_field_test_none_multi.First.a, '+', static_field_test_none_multi.First.b), '+', static_field_test_none_multi.First.c);
    }
  };
  dart.setSignature(static_field_test_none_multi.First, {
    constructors: () => ({new: dart.definiteFunctionType(static_field_test_none_multi.First, [])}),
    statics: () => ({setValues: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['setValues']
  });
  static_field_test_none_multi.First.a = null;
  static_field_test_none_multi.First.b = null;
  static_field_test_none_multi.First.c = 1;
  static_field_test_none_multi.InitializerTest = class InitializerTest extends core.Object {
    static checkValueOfThree() {
      expect$.Expect.equals(3, static_field_test_none_multi.InitializerTest.three);
    }
    static testStaticFieldInitialization() {
      expect$.Expect.equals(null, static_field_test_none_multi.InitializerTest.one);
      expect$.Expect.equals(2, static_field_test_none_multi.InitializerTest.two);
      static_field_test_none_multi.InitializerTest.one = 11;
      static_field_test_none_multi.InitializerTest.two = 22;
      expect$.Expect.equals(11, static_field_test_none_multi.InitializerTest.one);
      expect$.Expect.equals(22, static_field_test_none_multi.InitializerTest.two);
      static_field_test_none_multi.InitializerTest.three = dart.notNull(static_field_test_none_multi.InitializerTest.three) + 1;
      static_field_test_none_multi.InitializerTest.checkValueOfThree();
    }
  };
  dart.setSignature(static_field_test_none_multi.InitializerTest, {
    statics: () => ({
      checkValueOfThree: dart.definiteFunctionType(dart.dynamic, []),
      testStaticFieldInitialization: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['checkValueOfThree', 'testStaticFieldInitialization']
  });
  static_field_test_none_multi.InitializerTest.one = null;
  static_field_test_none_multi.InitializerTest.two = 2;
  static_field_test_none_multi.InitializerTest.three = 2;
  static_field_test_none_multi.StaticFieldTest = class StaticFieldTest extends core.Object {
    static testMain() {
      static_field_test_none_multi.First.a = 3;
      static_field_test_none_multi.First.b = static_field_test_none_multi.First.a;
      expect$.Expect.equals(3, static_field_test_none_multi.First.a);
      expect$.Expect.equals(static_field_test_none_multi.First.a, static_field_test_none_multi.First.b);
      static_field_test_none_multi.First.b = static_field_test_none_multi.First.a = 10;
      expect$.Expect.equals(10, static_field_test_none_multi.First.a);
      expect$.Expect.equals(10, static_field_test_none_multi.First.b);
      static_field_test_none_multi.First.b = static_field_test_none_multi.First.a = 15;
      expect$.Expect.equals(15, static_field_test_none_multi.First.a);
      expect$.Expect.equals(15, static_field_test_none_multi.First.b);
      expect$.Expect.equals(35, static_field_test_none_multi.First.setValues());
      expect$.Expect.equals(24, static_field_test_none_multi.First.a);
      expect$.Expect.equals(10, static_field_test_none_multi.First.b);
    }
  };
  dart.setSignature(static_field_test_none_multi.StaticFieldTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  static_field_test_none_multi.StaticField1RunNegativeTest = class StaticField1RunNegativeTest extends core.Object {
    new() {
      this.x = null;
    }
    testMain() {
      let foo = new static_field_test_none_multi.StaticField1RunNegativeTest();
      core.print(this.x);
      let result = foo.x;
    }
  };
  dart.setSignature(static_field_test_none_multi.StaticField1RunNegativeTest, {
    methods: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])})
  });
  static_field_test_none_multi.StaticField1aRunNegativeTest = class StaticField1aRunNegativeTest extends core.Object {
    m() {}
    testMain() {
      let foo = new static_field_test_none_multi.StaticField1aRunNegativeTest();
      core.print(dart.bind(this, 'm'));
      let result = dart.bind(foo, 'm');
    }
  };
  dart.setSignature(static_field_test_none_multi.StaticField1aRunNegativeTest, {
    methods: () => ({
      m: dart.definiteFunctionType(dart.void, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  static_field_test_none_multi.StaticField2RunNegativeTest = class StaticField2RunNegativeTest extends core.Object {
    new() {
      this.x = null;
    }
    testMain() {
      let foo = new static_field_test_none_multi.StaticField2RunNegativeTest();
      core.print(this.x);
      foo.x = 1;
    }
  };
  dart.setSignature(static_field_test_none_multi.StaticField2RunNegativeTest, {
    methods: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])})
  });
  static_field_test_none_multi.StaticField2aRunNegativeTest = class StaticField2aRunNegativeTest extends core.Object {
    m() {}
    testMain() {
      let foo = new static_field_test_none_multi.StaticField2aRunNegativeTest();
      core.print(dart.bind(this, 'm'));
    }
  };
  dart.setSignature(static_field_test_none_multi.StaticField2aRunNegativeTest, {
    methods: () => ({
      m: dart.definiteFunctionType(dart.void, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  static_field_test_none_multi.main = function() {
    static_field_test_none_multi.StaticFieldTest.testMain();
    static_field_test_none_multi.InitializerTest.testStaticFieldInitialization();
    new static_field_test_none_multi.StaticField1RunNegativeTest().testMain();
    new static_field_test_none_multi.StaticField1aRunNegativeTest().testMain();
    new static_field_test_none_multi.StaticField2RunNegativeTest().testMain();
    new static_field_test_none_multi.StaticField2aRunNegativeTest().testMain();
  };
  dart.fn(static_field_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.static_field_test_none_multi = static_field_test_none_multi;
});
