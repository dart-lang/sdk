define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.fnTypeFuzzy(dart.dynamic, [])))();
  let StringToException = () => (StringToException = dart.constFn(dart.fnType(core.Exception, [core.String])))();
  let _Action0Tovoid = () => (_Action0Tovoid = dart.constFn(dart.fnType(dart.void, [async_helper._Action0])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.fnType(dart.void, [dart.dynamic])))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.fnType(dart.void, [VoidTodynamic()])))();
  dart.defineLazy(async_helper, {
    get _initialized() {
      return false;
    },
    set _initialized(_) {}
  });
  async_helper._Action0 = dart.typedef('_Action0', () => dart.fnTypeFuzzy(dart.void, []));
  dart.defineLazy(async_helper, {
    get _onAsyncEnd() {
      return null;
    },
    set _onAsyncEnd(_) {},
    get _asyncLevel() {
      return 0;
    },
    set _asyncLevel(_) {}
  });
  async_helper._buildException = function(msg) {
    return core.Exception.new(dart.str`Fatal: ${msg}. This is most likely a bug in your test.`);
  };
  dart.fn(async_helper._buildException, StringToException());
  async_helper.asyncTestInitialize = function(callback) {
    async_helper._asyncLevel = 0;
    async_helper._initialized = false;
    async_helper._onAsyncEnd = callback;
  };
  dart.fn(async_helper.asyncTestInitialize, _Action0Tovoid());
  dart.copyProperties(async_helper, {
    get asyncTestStarted() {
      return async_helper._initialized;
    }
  });
  async_helper.asyncStart = function() {
    if (dart.test(async_helper._initialized) && async_helper._asyncLevel === 0) {
      dart.throw(async_helper._buildException('asyncStart() was called even though we are done ' + 'with testing.'));
    }
    if (!dart.test(async_helper._initialized)) {
      if (async_helper._onAsyncEnd == null) {
        dart.throw(async_helper._buildException('asyncStart() was called before asyncTestInitialize()'));
      }
      core.print('unittest-suite-wait-for-done');
      async_helper._initialized = true;
    }
    async_helper._asyncLevel = dart.notNull(async_helper._asyncLevel) + 1;
  };
  dart.fn(async_helper.asyncStart, VoidTovoid());
  async_helper.asyncEnd = function() {
    if (dart.notNull(async_helper._asyncLevel) <= 0) {
      if (!dart.test(async_helper._initialized)) {
        dart.throw(async_helper._buildException('asyncEnd() was called before asyncStart().'));
      } else {
        dart.throw(async_helper._buildException('asyncEnd() was called more often than ' + 'asyncStart().'));
      }
    }
    async_helper._asyncLevel = dart.notNull(async_helper._asyncLevel) - 1;
    if (async_helper._asyncLevel === 0) {
      let callback = async_helper._onAsyncEnd;
      async_helper._onAsyncEnd = null;
      callback();
      core.print('unittest-suite-success');
    }
  };
  dart.fn(async_helper.asyncEnd, VoidTovoid());
  async_helper.asyncSuccess = function(_) {
    return async_helper.asyncEnd();
  };
  dart.fn(async_helper.asyncSuccess, dynamicTovoid());
  async_helper.asyncTest = function(f) {
    async_helper.asyncStart();
    dart.dsend(f(), 'then', async_helper.asyncSuccess);
  };
  dart.fn(async_helper.asyncTest, FnTovoid());
  dart.trackLibraries("async_helper", {
    "async_helper.dart": async_helper
  }, null);
  // Exports:
  return {
    async_helper: async_helper
  };
});
