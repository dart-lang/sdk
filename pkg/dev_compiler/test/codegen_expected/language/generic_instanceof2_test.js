dart_library.library('language/generic_instanceof2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_instanceof2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_instanceof2_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(generic_instanceof2_test.Foo$()))();
  let Moo = () => (Moo = dart.constFn(generic_instanceof2_test.Moo$()))();
  let FooOfint$num = () => (FooOfint$num = dart.constFn(generic_instanceof2_test.Foo$(core.int, core.num)))();
  let FooOfint$String = () => (FooOfint$String = dart.constFn(generic_instanceof2_test.Foo$(core.int, core.String)))();
  let MooOfint$num = () => (MooOfint$num = dart.constFn(generic_instanceof2_test.Moo$(core.int, core.num)))();
  let MooOfint$String = () => (MooOfint$String = dart.constFn(generic_instanceof2_test.Moo$(core.int, core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_instanceof2_test.Foo$ = dart.generic((K, V) => {
    let FooOfK$V = () => (FooOfK$V = dart.constFn(generic_instanceof2_test.Foo$(K, V)))();
    let FooOfK$String = () => (FooOfK$String = dart.constFn(generic_instanceof2_test.Foo$(K, core.String)))();
    class Foo extends core.Object {
      new() {
      }
      static fac() {
        return new (FooOfK$V())();
      }
      FooString() {
        return FooOfK$String().fac();
      }
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      constructors: () => ({
        new: dart.definiteFunctionType(generic_instanceof2_test.Foo$(K, V), []),
        fac: dart.definiteFunctionType(generic_instanceof2_test.Foo$(K, V), [])
      }),
      methods: () => ({FooString: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return Foo;
  });
  generic_instanceof2_test.Foo = Foo();
  generic_instanceof2_test.Moo$ = dart.generic((K, V) => {
    let MooOfK$String = () => (MooOfK$String = dart.constFn(generic_instanceof2_test.Moo$(K, core.String)))();
    class Moo extends core.Object {
      new() {
      }
      MooString() {
        return new (MooOfK$String())();
      }
    }
    dart.addTypeTests(Moo);
    dart.setSignature(Moo, {
      constructors: () => ({new: dart.definiteFunctionType(generic_instanceof2_test.Moo$(K, V), [])}),
      methods: () => ({MooString: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return Moo;
  });
  generic_instanceof2_test.Moo = Moo();
  generic_instanceof2_test.testAll = function() {
    let foo_int_num = new (FooOfint$num())();
    expect$.Expect.isTrue(FooOfint$num().is(foo_int_num));
    expect$.Expect.isTrue(!FooOfint$String().is(foo_int_num));
    expect$.Expect.isTrue(!FooOfint$num().is(foo_int_num.FooString()));
    expect$.Expect.isTrue(FooOfint$String().is(foo_int_num.FooString()));
    let foo_raw = new generic_instanceof2_test.Foo();
    expect$.Expect.isTrue(FooOfint$num().is(foo_raw));
    expect$.Expect.isTrue(FooOfint$String().is(foo_raw));
    expect$.Expect.isTrue(!FooOfint$num().is(foo_raw.FooString()));
    expect$.Expect.isTrue(FooOfint$String().is(foo_raw.FooString()));
    let moo_int_num = new (MooOfint$num())();
    expect$.Expect.isTrue(MooOfint$num().is(moo_int_num));
    expect$.Expect.isTrue(!MooOfint$String().is(moo_int_num));
    expect$.Expect.isTrue(!MooOfint$num().is(moo_int_num.MooString()));
    expect$.Expect.isTrue(MooOfint$String().is(moo_int_num.MooString()));
    let moo_raw = new generic_instanceof2_test.Moo();
    expect$.Expect.isTrue(MooOfint$num().is(moo_raw));
    expect$.Expect.isTrue(MooOfint$String().is(moo_raw));
    expect$.Expect.isTrue(!MooOfint$num().is(moo_raw.MooString()));
    expect$.Expect.isTrue(MooOfint$String().is(moo_raw.MooString()));
  };
  dart.fn(generic_instanceof2_test.testAll, VoidTodynamic());
  generic_instanceof2_test.main = function() {
    for (let i = 0; i < 5; i++) {
      generic_instanceof2_test.testAll();
    }
  };
  dart.fn(generic_instanceof2_test.main, VoidTodynamic());
  // Exports:
  exports.generic_instanceof2_test = generic_instanceof2_test;
});
