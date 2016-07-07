dart_library.library('language/await_for_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__await_for_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const await_for_test = Object.create(null);
  let JSArrayOfFuture = () => (JSArrayOfFuture = dart.constFn(_interceptors.JSArray$(async.Future)))();
  let VoidToStream = () => (VoidToStream = dart.constFn(dart.definiteFunctionType(async.Stream, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListTodynamic = () => (ListTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intToStream = () => (intToStream = dart.constFn(dart.definiteFunctionType(async.Stream, [core.int])))();
  await_for_test.Trace = class Trace extends core.Object {
    new() {
      this.trace = "";
    }
    record(x) {
      this.trace = dart.notNull(this.trace) + dart.notNull(dart.toString(x));
    }
    toString() {
      return this.trace;
    }
  };
  dart.setSignature(await_for_test.Trace, {
    methods: () => ({record: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  await_for_test.makeMeAStream = function() {
    return await_for_test.timedCounter(5);
  };
  dart.fn(await_for_test.makeMeAStream, VoidToStream());
  dart.defineLazy(await_for_test, {
    get t1() {
      return new await_for_test.Trace();
    },
    set t1(_) {}
  });
  await_for_test.consumeOne = function() {
    return dart.async(function*() {
      let s = await_for_test.makeMeAStream();
      let it = async.StreamIterator.new(s);
      while (dart.test(yield it.moveNext())) {
        let x = it.current;
        await_for_test.t1.record(x);
      }
      await_for_test.t1.record("X");
    }, dart.dynamic);
  };
  dart.fn(await_for_test.consumeOne, VoidTodynamic());
  dart.defineLazy(await_for_test, {
    get t2() {
      return new await_for_test.Trace();
    },
    set t2(_) {}
  });
  await_for_test.consumeTwo = function() {
    return dart.async(function*() {
      let it = async.StreamIterator.new(await_for_test.makeMeAStream());
      try {
        while (yield it.moveNext()) {
          let x = it.current;
          await_for_test.t2.record(x);
        }
      } finally {
        yield it.cancel();
      }
      await_for_test.t2.record("Y");
    }, dart.dynamic);
  };
  dart.fn(await_for_test.consumeTwo, VoidTodynamic());
  dart.defineLazy(await_for_test, {
    get t3() {
      return new await_for_test.Trace();
    },
    set t3(_) {}
  });
  await_for_test.consumeNested = function() {
    return dart.async(function*() {
      let it = async.StreamIterator.new(await_for_test.makeMeAStream());
      try {
        while (yield it.moveNext()) {
          let x = it.current;
          await_for_test.t3.record(x);
          let it$ = async.StreamIterator.new(await_for_test.makeMeAStream());
          try {
            while (yield it$.moveNext()) {
              let y = it$.current;
              await_for_test.t3.record(y);
            }
          } finally {
            yield it$.cancel();
          }
          await_for_test.t3.record("|");
        }
      } finally {
        yield it.cancel();
      }
      await_for_test.t3.record("Z");
    }, dart.dynamic);
  };
  dart.fn(await_for_test.consumeNested, VoidTodynamic());
  dart.defineLazy(await_for_test, {
    get t4() {
      return new await_for_test.Trace();
    },
    set t4(_) {}
  });
  await_for_test.consumeSomeOfInfinite = function() {
    return dart.async(function*() {
      let i = 0;
      let it = async.StreamIterator.new(await_for_test.infiniteStream());
      try {
        while (yield it.moveNext()) {
          let x = it.current;
          i++;
          if (i > 10) break;
          await_for_test.t4.record(x);
        }
      } finally {
        yield it.cancel();
      }
      await_for_test.t4.record("U");
    }, dart.dynamic);
  };
  dart.fn(await_for_test.consumeSomeOfInfinite, VoidTodynamic());
  await_for_test.main = function() {
    let f1 = await_for_test.consumeOne();
    await_for_test.t1.record("T1:");
    let f2 = await_for_test.consumeTwo();
    await_for_test.t2.record("T2:");
    let f3 = await_for_test.consumeNested();
    await_for_test.t3.record("T3:");
    let f4 = await_for_test.consumeSomeOfInfinite();
    await_for_test.t4.record("T4:");
    async_helper$.asyncStart();
    async.Future.wait(dart.dynamic)(JSArrayOfFuture().of([async.Future._check(f1), async.Future._check(f2), async.Future._check(f3), async.Future._check(f4)])).then(dart.dynamic)(dart.fn(_ => {
      expect$.Expect.equals("T1:12345X", dart.toString(await_for_test.t1));
      expect$.Expect.equals("T2:12345Y", dart.toString(await_for_test.t2));
      expect$.Expect.equals("T3:112345|212345|312345|412345|512345|Z", dart.toString(await_for_test.t3));
      expect$.Expect.equals("T4:12345678910U", dart.toString(await_for_test.t4));
      async_helper$.asyncEnd();
    }, ListTodynamic()));
  };
  dart.fn(await_for_test.main, VoidTodynamic());
  let const$;
  await_for_test.timedCounter = function(maxCount) {
    let controller = null;
    let timer = null;
    let counter = 0;
    function tick(_) {
      counter++;
      controller.add(counter);
      if (counter >= dart.notNull(maxCount)) {
        timer.cancel();
        controller.close();
      }
    }
    dart.fn(tick, dynamicTovoid());
    function startTimer() {
      timer = async.Timer.periodic(const$ || (const$ = dart.const(new core.Duration({milliseconds: 10}))), tick);
    }
    dart.fn(startTimer, VoidTovoid());
    function stopTimer() {
      if (timer != null) {
        timer.cancel();
        timer = null;
      }
    }
    dart.fn(stopTimer, VoidTovoid());
    controller = async.StreamController.new({onListen: startTimer, onPause: stopTimer, onResume: startTimer, onCancel: stopTimer});
    return controller.stream;
  };
  dart.fn(await_for_test.timedCounter, intToStream());
  let const$0;
  await_for_test.infiniteStream = function() {
    let controller = null;
    let timer = null;
    let counter = 0;
    function tick(_) {
      counter++;
      controller.add(counter);
    }
    dart.fn(tick, dynamicTovoid());
    function startTimer() {
      timer = async.Timer.periodic(const$0 || (const$0 = dart.const(new core.Duration({milliseconds: 10}))), tick);
    }
    dart.fn(startTimer, VoidTovoid());
    function stopTimer() {
      if (timer != null) {
        timer.cancel();
        timer = null;
      }
    }
    dart.fn(stopTimer, VoidTovoid());
    controller = async.StreamController.new({onListen: startTimer, onPause: stopTimer, onResume: startTimer, onCancel: stopTimer});
    return controller.stream;
  };
  dart.fn(await_for_test.infiniteStream, VoidToStream());
  // Exports:
  exports.await_for_test = await_for_test;
});
