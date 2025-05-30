// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Runner V8/JSShell script for testing dart2wasm, takes ".wasm" files as
// arguments.
//
// Run as follows on D8:
//
// $> d8 run_wasm.js \
//       -- /abs/path/to/<dart_module>.mjs <dart_module>.wasm [<ffi_module>.wasm] \
//       [-- Dart commandline arguments...]
//
// Run as follows on JSC:
//
// $> jsc run_wasm.js -- <dart_module>.mjs <dart_module>.wasm [<ffi_module>.wasm] \
//       [-- Dart commandline arguments...]
//
// Run as follows on JSShell:
//
// $> js run_wasm.js \
//       /abs/path/to/<dart_module>.mjs <dart_module>.wasm [<ffi_module>.wasm] \
//       [-- Dart commandline arguments...]
//
// (Notice the missing -- here!)
//
// Please note we require an absolute path for the JS runtime. This is a
// workaround for a discrepancy in D8. Specifically, `import`(used to load .mjs
// files) searches for imports relative to run_wasm.js, but `readbuffer`(used to
// read in .wasm files) searches relative to CWD.  A path relative to
// `run_wasm.js` will also work.
//
// Or with the `run_dart2wasm_d8` helper script:
//
// $> sdk/bin/run_dart2wasm_d8 <dart_module>.wasm [<ffi_module>.wasm]
//
// If an FFI module is specified, it will be instantiated first, and its
// exports will be supplied as imports to the Dart module under the 'ffi'
// module name.
const jsRuntimeArg = 0;
const wasmArg = 1;
const ffiArg = 2;

// This script is intended to be used by D8, JSShell or JSC. We distinguish
// them by the functions they offer to read files:
//
// Engine         | Shell    | FileRead             |  Arguments
// --------------------------------------------------------------
// V8             | D8       | readbuffer           |  arguments (arg0 arg1)
// JavaScriptCore | JSC      | readFile             |  arguments (arg0 arg1)
// SpiderMonkey   | JSShell  | readRelativeToScript |  scriptArgs (-- arg0 arg1)
//
const isD8 = (typeof readbuffer === "function");
const isJSC = (typeof readFile === "function");
const isJSShell = (typeof readRelativeToScript === "function");

if (isD8) {
  // D8's performance.measure is API incompatible with the browser version.
  //
  // (see also dart2js's `sdk/**/js_runtime/lib/preambles/d8.js`)
  delete performance.measure;
}

var args = (isD8 || isJSC) ? arguments : scriptArgs;
var dartArgs = [];
const argsSplit = args.indexOf("--");
if (argsSplit != -1) {
  dartArgs = args.slice(argsSplit + 1);
  args = args.slice(0, argsSplit);
}

// d8's `setTimeout` doesn't work as expected (it doesn't wait before calling
// the callback), and d8 also doesn't have `setInterval` and `queueMicrotask`.
// So we define our own event loop with these functions.
//
// The code below is copied form dart2js, with some modifications:
// sdk/lib/_internal/js_runtime/lib/preambles/d8.js
(function (self, scriptArguments) {
  // Using strict mode to avoid accidentally defining global variables.
  "use strict"; // Should be first statement of this function.

  // Task queue as cyclic list queue.
  var taskQueue = new Array(8);  // Length is power of 2.
  var head = 0;
  var tail = 0;
  var mask = taskQueue.length - 1;
  var isEventLoopRunning = false;

  function addTask(elem) {
    taskQueue[head] = elem;
    head = (head + 1) & mask;
    if (head == tail) _growTaskQueue();
    if (!isEventLoopRunning) {
      eventLoop(removeTask());
    }
  }

  function removeTask() {
    if (head == tail) return;
    var result = taskQueue[tail];
    taskQueue[tail] = undefined;
    tail = (tail + 1) & mask;
    return result;
  }

  function _growTaskQueue() {
    // head == tail.
    var length = taskQueue.length;
    var split = head;
    taskQueue.length = length * 2;
    if (split * 2 < length) {  // split < length / 2
      for (var i = 0; i < split; i++) {
        taskQueue[length + i] = taskQueue[i];
        taskQueue[i] = undefined;
      }
      head += length;
    } else {
      for (var i = split; i < length; i++) {
        taskQueue[length + i] = taskQueue[i];
        taskQueue[i] = undefined;
      }
      tail += length;
    }
    mask = taskQueue.length - 1;
  }

  // Mapping from timer id to timer function.
  // The timer id is written on the function as .$timerId.
  // That field is cleared when the timer is cancelled, but it is not returned
  // from the queue until its time comes.
  var timerIds = {};
  var timerIdCounter = 1;  // Counter used to assign ids.

  // Zero-timer queue as simple array queue using push/shift.
  var zeroTimerQueue = [];

  function addTimer(f, ms) {
    ms = Math.max(0, ms);
    var id = timerIdCounter++;
    // A callback can be scheduled at most once.
    // (console.assert is only available on D8)
    if (isD8) console.assert(f.$timerId === undefined);
    f.$timerId = id;
    timerIds[id] = f;
    if (ms == 0 && !isNextTimerDue()) {
      zeroTimerQueue.push(f);
    } else {
      addDelayedTimer(f, ms);
    }
    return id;
  }

  function nextZeroTimer() {
    while (zeroTimerQueue.length > 0) {
      var action = zeroTimerQueue.shift();
      if (action.$timerId !== undefined) return action;
    }
  }

  function nextEvent() {
    var action = removeTask();
    if (action) {
      return action;
    }
    do {
      action = nextZeroTimer();
      if (action) break;
      var nextList = nextDelayedTimerQueue();
      if (!nextList) {
        return;
      }
      var newTime = nextList.shift();
      advanceTimeTo(newTime);
      zeroTimerQueue = nextList;
    } while (true)
    var id = action.$timerId;
    clearTimerId(action, id);
    return action;
  }

  // Mocking time.
  var timeOffset = 0;
  var now = function () {
    // Install the mock Date object only once.
    // Following calls to "now" will just use the new (mocked) Date.now
    // method directly.
    installMockDate();
    now = Date.now;
    return Date.now();
  };
  var originalDate = Date;
  var originalNow = originalDate.now;

  function advanceTimeTo(time) {
    var now = originalNow();
    if (timeOffset < time - now) {
      timeOffset = time - now;
    }
  }

  function installMockDate() {
    var NewDate = function Date(Y, M, D, h, m, s, ms) {
      if (this instanceof Date) {
        // Assume a construct call.
        switch (arguments.length) {
          case 0: return new originalDate(originalNow() + timeOffset);
          case 1: return new originalDate(Y);
          case 2: return new originalDate(Y, M);
          case 3: return new originalDate(Y, M, D);
          case 4: return new originalDate(Y, M, D, h);
          case 5: return new originalDate(Y, M, D, h, m);
          case 6: return new originalDate(Y, M, D, h, m, s);
          default: return new originalDate(Y, M, D, h, m, s, ms);
        }
      }
      return new originalDate(originalNow() + timeOffset).toString();
    };
    NewDate.UTC = originalDate.UTC;
    NewDate.parse = originalDate.parse;
    NewDate.now = function now() { return originalNow() + timeOffset; };
    NewDate.prototype = originalDate.prototype;
    originalDate.prototype.constructor = NewDate;
    Date = NewDate;
  }

  // Heap priority queue with key index.
  // Each entry is list of [timeout, callback1 ... callbackn].
  var timerHeap = [];
  var timerIndex = {};

  function addDelayedTimer(f, ms) {
    var timeout = now() + ms;
    var timerList = timerIndex[timeout];
    if (timerList == null) {
      timerList = [timeout, f];
      timerIndex[timeout] = timerList;
      var index = timerHeap.length;
      timerHeap.length += 1;
      bubbleUp(index, timeout, timerList);
    } else {
      timerList.push(f);
    }
  }

  function isNextTimerDue() {
    if (timerHeap.length == 0) return false;
    var head = timerHeap[0];
    return head[0] < originalNow() + timeOffset;
  }

  function nextDelayedTimerQueue() {
    if (timerHeap.length == 0) return null;
    var result = timerHeap[0];
    var last = timerHeap.pop();
    if (timerHeap.length > 0) {
      bubbleDown(0, last[0], last);
    }
    return result;
  }

  function bubbleUp(index, key, value) {
    while (index != 0) {
      var parentIndex = (index - 1) >> 1;
      var parent = timerHeap[parentIndex];
      var parentKey = parent[0];
      if (key > parentKey) break;
      timerHeap[index] = parent;
      index = parentIndex;
    }
    timerHeap[index] = value;
  }

  function bubbleDown(index, key, value) {
    while (true) {
      var leftChildIndex = index * 2 + 1;
      if (leftChildIndex >= timerHeap.length) break;
      var minChildIndex = leftChildIndex;
      var minChild = timerHeap[leftChildIndex];
      var minChildKey = minChild[0];
      var rightChildIndex = leftChildIndex + 1;
      if (rightChildIndex < timerHeap.length) {
        var rightChild = timerHeap[rightChildIndex];
        var rightKey = rightChild[0];
        if (rightKey < minChildKey) {
          minChildIndex = rightChildIndex;
          minChild = rightChild;
          minChildKey = rightKey;
        }
      }
      if (minChildKey > key) break;
      timerHeap[index] = minChild;
      index = minChildIndex;
    }
    timerHeap[index] = value;
  }

  function addInterval(f, ms) {
    ms = Math.max(0, ms);
    var id = timerIdCounter++;
    function repeat() {
      // Reactivate with the same id.
      repeat.$timerId = id;
      timerIds[id] = repeat;
      addDelayedTimer(repeat, ms);
      f();
    }
    repeat.$timerId = id;
    timerIds[id] = repeat;
    addDelayedTimer(repeat, ms);
    return id;
  }

  function cancelTimer(id) {
    var f = timerIds[id];
    if (f == null) return;
    clearTimerId(f, id);
  }

  function clearTimerId(f, id) {
    f.$timerId = undefined;
    delete timerIds[id];
  }

  async function eventLoop(action) {
    if (isJSC) asyncTestStart(1);
    isEventLoopRunning = true;
    while (action) {
      try {
        await action();
      } catch (e) {
        // JSC doesn't report/print uncaught async exceptions for some reason.
        if (isJSC) {
          print('Error: ' + e);
          print('Stack: ' + e.stack);
        }
        if (typeof onerror == "function") {
          onerror(e, null, -1);
        } else {
          throw e;
        }
      }
      action = nextEvent();
    }
    isEventLoopRunning = false;
    if (isJSC) asyncTestPassed();
  }

  // Global properties. "self" refers to the global object, so adding a
  // property to "self" defines a global variable.
  self.self = self;
  self.dartMainRunner = function (main, ignored_args) {
    // Initialize.
    var action = async function () { await main(scriptArguments, null); }
    eventLoop(action);
  };
  self.setTimeout = addTimer;
  self.clearTimeout = cancelTimer;
  self.setInterval = addInterval;
  self.clearInterval = cancelTimer;
  self.queueMicrotask = addTask;

  // Constructor function for JS `Response` objects, allows us to test for it
  // via `instanceof`.
  self.Response = function () { }

  self.location = {}
  if (args[wasmArg].startsWith('/')) {
    self.location.href = 'file://' + args[wasmArg];
  } else {
    self.location.href = args[wasmArg];
  }

  // Signals `Stopwatch._initTicker` to use `Date.now` to get ticks instead of
  // `performance.now`, as it's not available in d8.
  self.dartUseDateNowForTicks = true;
})(this, []);

// We would like this itself to be a ES module rather than a script, but
// unfortunately d8 does not return a failed error code if an unhandled
// exception occurs asynchronously in an ES module.
const main = async () => {
  const dart2wasm = await import(args[jsRuntimeArg]);

  function readBytes(filename) {
    if (isJSC) {
      return readFile(filename, "binary");
    } else if (isD8) {
      return readbuffer(filename);
    }
    return readRelativeToScript(filename, "binary");
  }

  globalThis.window ??= globalThis;

  let importObject = {};

  // Is an FFI module specified?
  if (args.length > 2) {
    // Instantiate FFI module.
    const ffiModule = await WebAssembly.compile(readBytes(args[ffiArg]));
    const ffiInstance = await WebAssembly.instantiate(ffiModule, {});

    // Make its exports available as imports under the 'ffi' module name.
    importObject.ffi = ffiInstance.exports;
  }

  // Instantiate the Dart module, importing from the global scope.
  const wasmFilename = args[wasmArg];
  const wasmDirectory = wasmFilename.slice(0, wasmFilename.lastIndexOf('/'));

  globalThis.loadData = async (relativeToWasmFileUri) => {
    return await readBytes(`${wasmDirectory}/${relativeToWasmFileUri}`);
  };

  const compiledApp = await dart2wasm.compile(readBytes(wasmFilename));
  const appInstance = await compiledApp.instantiate(importObject, {
    loadDeferredWasm: async (moduleName) => {
      let filename = wasmFilename.replace('.wasm', `_${moduleName}.wasm`);
      return readBytes(filename);
    },
    loadDynamicModule: async (wasmUri, mjsUri) => {
      return [await readBytes(wasmUri), await import(`${wasmDirectory}/${mjsUri}`)];
    }
  });

  // Call `main`. If tasks are placed into the event loop (by scheduling tasks
  // explicitly or awaiting Futures), these will automatically keep the script
  // alive even after `main` returns.
  await appInstance.invokeMain(...dartArgs);
};

dartMainRunner(main, []);
