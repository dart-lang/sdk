dart_library.library('async_helper', null, /* Imports */[
  "dart_runtime/dart",
  'dart/core',
  'dart/isolate'
], /* Lazy imports */[
], function(exports, dart, core, isolate) {
  'use strict';
  let dartx = dart.dartx;
  exports._initialized = false;
  exports._port = null;
  exports._asyncLevel = 0;
  function _buildException(msg) {
    return core.Exception.new(`Fatal: ${msg}. This is most likely a bug in your test.`);
  }
  dart.fn(_buildException, core.Exception, [core.String]);
  function asyncStart() {
    if (dart.notNull(exports._initialized) && exports._asyncLevel == 0) {
      dart.throw(_buildException('asyncStart() was called even though we are done ' + 'with testing.'));
    }
    if (!dart.notNull(exports._initialized)) {
      core.print('unittest-suite-wait-for-done');
      exports._initialized = true;
      exports._port = isolate.ReceivePort.new();
    }
    exports._asyncLevel = dart.notNull(exports._asyncLevel) + 1;
  }
  dart.fn(asyncStart, dart.void, []);
  function asyncEnd() {
    if (dart.notNull(exports._asyncLevel) <= 0) {
      if (!dart.notNull(exports._initialized)) {
        dart.throw(_buildException('asyncEnd() was called before asyncStart().'));
      } else {
        dart.throw(_buildException('asyncEnd() was called more often than ' + 'asyncStart().'));
      }
    }
    exports._asyncLevel = dart.notNull(exports._asyncLevel) - 1;
    if (exports._asyncLevel == 0) {
      exports._port.close();
      exports._port = null;
      core.print('unittest-suite-success');
    }
  }
  dart.fn(asyncEnd, dart.void, []);
  function asyncSuccess(_) {
    return asyncEnd();
  }
  dart.fn(asyncSuccess, dart.void, [dart.dynamic]);
  function asyncTest(f) {
    asyncStart();
    dart.dsend(f(), 'then', asyncSuccess);
  }
  dart.fn(asyncTest, dart.void, [dart.functionType(dart.dynamic, [])]);
  // Exports:
  exports.asyncStart = asyncStart;
  exports.asyncEnd = asyncEnd;
  exports.asyncSuccess = asyncSuccess;
  exports.asyncTest = asyncTest;
});
