dart_library.library('async_helper', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper = Object.create(null);
  async_helper._initialized = false;
  async_helper._Action0 = dart.typedef('_Action0', () => dart.functionType(dart.void, []));
  async_helper._onAsyncEnd = null;
  async_helper._asyncLevel = 0;
  async_helper._buildException = function(msg) {
    return core.Exception.new(`Fatal: ${msg}. This is most likely a bug in your test.`);
  };
  dart.fn(async_helper._buildException, core.Exception, [core.String]);
  async_helper.asyncTestInitialize = function(callback) {
    async_helper._asyncLevel = 0;
    async_helper._initialized = false;
    async_helper._onAsyncEnd = callback;
  };
  dart.fn(async_helper.asyncTestInitialize, dart.void, [async_helper._Action0]);
  dart.copyProperties(async_helper, {
    get asyncTestStarted() {
      return async_helper._initialized;
    }
  });
  async_helper.asyncStart = function() {
    if (dart.notNull(async_helper._initialized) && async_helper._asyncLevel == 0) {
      dart.throw(async_helper._buildException('asyncStart() was called even though we are done ' + 'with testing.'));
    }
    if (!dart.notNull(async_helper._initialized)) {
      if (async_helper._onAsyncEnd == null) {
        dart.throw(async_helper._buildException('asyncStart() was called before asyncTestInitialize()'));
      }
      core.print('unittest-suite-wait-for-done');
      async_helper._initialized = true;
    }
    async_helper._asyncLevel = dart.notNull(async_helper._asyncLevel) + 1;
  };
  dart.fn(async_helper.asyncStart, dart.void, []);
  async_helper.asyncEnd = function() {
    if (dart.notNull(async_helper._asyncLevel) <= 0) {
      if (!dart.notNull(async_helper._initialized)) {
        dart.throw(async_helper._buildException('asyncEnd() was called before asyncStart().'));
      } else {
        dart.throw(async_helper._buildException('asyncEnd() was called more often than ' + 'asyncStart().'));
      }
    }
    async_helper._asyncLevel = dart.notNull(async_helper._asyncLevel) - 1;
    if (async_helper._asyncLevel == 0) {
      let callback = async_helper._onAsyncEnd;
      async_helper._onAsyncEnd = null;
      callback();
      core.print('unittest-suite-success');
    }
  };
  dart.fn(async_helper.asyncEnd, dart.void, []);
  async_helper.asyncSuccess = function(_) {
    return async_helper.asyncEnd();
  };
  dart.fn(async_helper.asyncSuccess, dart.void, [dart.dynamic]);
  async_helper.asyncTest = function(f) {
    async_helper.asyncStart();
    dart.dsend(f(), 'then', async_helper.asyncSuccess);
  };
  dart.fn(async_helper.asyncTest, dart.void, [dart.functionType(dart.dynamic, [])]);
  // Exports:
  exports.async_helper = async_helper;
});
