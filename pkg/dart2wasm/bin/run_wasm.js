// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Runner V8 script for testing dart2wasm, takes ".wasm" files as arguments.
//
// Run as follows:
//
// $> d8 --experimental-wasm-gc \
//       --experimental-wasm-type-reflection run_wasm.js \
//       -- /abs/path/to/<dart_module>.mjs <dart_module>.wasm [<ffi_module>.wasm] \
//       [-- Dart commandline arguments...]
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

// d8's `setTimeout` doesn't work as expected (it doesn't wait before calling
// the callback), and d8 also doesn't have `setInterval` and `queueMicrotask`.
// So we define our own event loop with these functions.
//
// The code below is copied form dart2js, with some modifications:
// sdk/lib/_internal/js_runtime/lib/preambles/d8.js
(function(self, scriptArguments) {
  // Using strict mode to avoid accidentally defining global variables.
  "use strict"; // Should be first statement of this function.

  // Task queue as cyclic list queue.
  var taskQueue = new Array(8);  // Length is power of 2.
  var head = 0;
  var tail = 0;
  var mask = taskQueue.length - 1;

  function addTask(elem) {
    taskQueue[head] = elem;
    head = (head + 1) & mask;
    if (head == tail) _growTaskQueue();
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
    var id = timerIdCounter++;
    // A callback can be scheduled at most once.
    console.assert(f.$timerId === undefined);
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
  var now = function() {
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
          case 0:  return new originalDate(originalNow() + timeOffset);
          case 1:  return new originalDate(Y);
          case 2:  return new originalDate(Y, M);
          case 3:  return new originalDate(Y, M, D);
          case 4:  return new originalDate(Y, M, D, h);
          case 5:  return new originalDate(Y, M, D, h, m);
          case 6:  return new originalDate(Y, M, D, h, m, s);
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
    while (action) {
      try {
        await action();
      } catch (e) {
        if (typeof onerror == "function") {
          onerror(e, null, -1);
        } else {
          throw e;
        }
      }
      action = nextEvent();
    }
  }

  // Global properties. "self" refers to the global object, so adding a
  // property to "self" defines a global variable.
  self.self = self;
  self.dartMainRunner = function(main, ignored_args) {
    // Initialize.
    var action = async function() { await main(scriptArguments, null); }
    eventLoop(action);
  };
  self.setTimeout = addTimer;
  self.clearTimeout = cancelTimer;
  self.setInterval = addInterval;
  self.clearInterval = cancelTimer;
  self.queueMicrotask = addTask;

  // Signals `Stopwatch._initTicker` to use `Date.now` to get ticks instead of
  // `performance.now`, as it's not available in d8.
  self.dartUseDateNowForTicks = true;
})(this, []);

// We would like this itself to be a ES module rather than a script, but
// unfortunately d8 does not return a failed error code if an unhandled
// exception occurs asynchronously in an ES module.
const main = async () => {
    var args = arguments;
    var dartArgs = [];
    const argsSplit = args.indexOf("--");
    if (argsSplit != -1) {
        dartArgs = args.slice(argsSplit + 1);
        args = args.slice(0, argsSplit);
    }

    const dart2wasm = await import(args[jsRuntimeArg]);
    function compile(filename) {
        // Create a Wasm module from the binary wasm file.
        var bytes = readbuffer(filename);
        return new WebAssembly.Module(bytes);
    }

    function instantiate(filename, imports) {
        return new WebAssembly.Instance(compile(filename), imports);
    }

    globalThis.window ??= globalThis;

    let importObject = {};

    // Is an FFI module specified?
    if (args.length > 2) {
        // instantiate FFI module
        var ffiInstance = instantiate(args[ffiArg], {});
        // Make its exports available as imports under the 'ffi' module name
        importObject.ffi = ffiInstance.exports;
    }

    // Instantiate the Dart module, importing from the global scope.
    var dartInstance = await dart2wasm.instantiate(Promise.resolve(compile(args[wasmArg])), Promise.resolve(importObject));

    // Call `main`. If tasks are placed into the event loop (by scheduling tasks
    // explicitly or awaiting Futures), these will automatically keep the script
    // alive even after `main` returns.
    await dart2wasm.invoke(dartInstance, ...dartArgs);
};

dartMainRunner(main, []);
