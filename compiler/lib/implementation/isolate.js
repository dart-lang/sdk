// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): this file should be removed when the dart code generation
// backend is deleted.

var isolate$current = null;
var isolate$rootIsolate = null;  // Will only be set in the main worker.
var isolate$inits = [];
var isolate$globalThis = this;

// These declarations are needed to avoid errors from the Closure Compiler
// optimizer. They are defined in lib/dom/generated/dart_dom_wrapping.js.
var __dom_wrap;
var __dom_unwrap;

var isolate$inWorker =
    (typeof isolate$globalThis['importScripts']) != "undefined";
var isolate$supportsWorkers =
    isolate$inWorker || ((typeof isolate$globalThis['Worker']) != 'undefined');

var isolate$MAIN_WORKER_ID = 0;
// Non-main workers will update the id variable.
var isolate$thisWorkerId = isolate$MAIN_WORKER_ID;

// Whether to use web workers when implementing isolates.
var isolate$useWorkers = isolate$supportsWorkers;
// Uncomment this to not use web workers even if they're available.
//   isolate$useWorkers = false;

// Whether to use the web-worker JSON-based message serialization protocol,
// even if not using web workers.
var isolate$useWorkerSerializationProtocol = false;
// Uncomment this to always use the web-worker JSON-based message
// serialization protocol, e.g. for testing purposes.
//   isolate$useWorkerSerializationProtocol = true;


// ------- SendPort -------
function isolate$sendMessage(workerId, isolateId, receivePortId,
                             message, replyTo) {
  // Both, the message and the replyTo are already serialized.
  if (workerId == isolate$thisWorkerId) {
    var isolate = isolate$isolateRegistry.get(isolateId);
    if (!isolate) return;  // Isolate has been closed.
    var receivePort = isolate.getReceivePortForId(receivePortId);
    if (!receivePort) return;  // ReceivePort has been closed.
    isolate$receiveMessage(receivePort, isolate, message, replyTo);
  } else {
    var worker;
    if (isolate$inWorker) {
      worker = isolate$mainWorker;
    } else {
      worker = isolate$workerRegistry.get(workerId);
    }
    worker.postMessage({ command: 'message',
                         workerId: workerId,
                         isolateId: isolateId,
                         portId: receivePortId,
                         msg: message,
                         replyTo: replyTo });
  }
}

function isolate$receiveMessage(port, isolate,
                                serializedMessage, serializedReplyTo) {
  isolate$IsolateEvent.enqueue(isolate, function() {
    var message = isolate$deserializeMessage(serializedMessage);
    var replyTo = isolate$deserializeMessage(serializedReplyTo);
    native_ReceivePortImpl__invokeCallback(port, message, replyTo);
  });
}

// ------- ReceivePort -------

function native_ReceivePortImpl__register(id) {
  isolate$current.registerReceivePort(id, this);
}

function native_ReceivePortImpl__unregister(id) {
  isolate$current.unregisterReceivePort(id);
}

function native_ReceivePortImpl__currentWorkerId() {
  return isolate$thisWorkerId;
}

function native_ReceivePortImpl__currentIsolateId() {
  return isolate$current.id;
}

// -------- Registry ---------
function isolate$Registry() {
  this.map = {};
  this.count = 0;
}

isolate$Registry.prototype.register = function(id, val) {
  if (this.map[id]) {
    throw Error("Registry: Elements must be registered only once.");
  }
  this.map[id] = val;
  this.count++;
};

isolate$Registry.prototype.unregister = function(id) {
  if (id in this.map) {
    delete this.map[id];
    this.count--;
  }
};

isolate$Registry.prototype.get = function(id) {
  return this.map[id];
};

isolate$Registry.prototype.contains = function(id) {
  return this.map[id] !== void 0;
};

isolate$Registry.prototype.isEmpty = function() {
  return this.count === 0;
};


// ------- Worker registry -------
// Only used in the main worker.
var isolate$workerRegistry = new isolate$Registry();

// ------- Isolate registry -------
// Isolates must be registered if, and only if, receive ports are alive.
// Normally no open receive-ports means that the isolate is dead, but
// DOM callbacks could resurrect it.
var isolate$isolateRegistry = new isolate$Registry();

// ------- Debugging log function -------
function isolate$log(msg) {
  return;
  if (isolate$inWorker) {
    isolate$mainWorker.postMessage({ command: 'log', msg: msg });
  } else {
    try {
      isolate$globalThis.console.log(msg);
    } catch(e) {
      throw String(e.stack);
    }
  }
}

function isolate$initializeWorker(workerId) {
  isolate$thisWorkerId = workerId;
}

var isolate$workerPrint = false;
if (isolate$inWorker) {
  isolate$workerPrint = function(msg){
    isolate$mainWorker.postMessage({ command: 'print', msg: msg });
  }
}

// ------- Message handler -------
function isolate$processWorkerMessage(sender, e) {
  var msg = e.data;
  switch (msg.command) {
    case 'start':
      isolate$log("starting worker: " + msg.id + " " + msg.factoryName);
      isolate$initializeWorker(msg.id);
      var runnerObject = (isolate$globalThis[msg.factoryName])();
      var serializedReplyTo = msg.replyTo;
      isolate$IsolateEvent.enqueue(new isolate$Isolate(), function() {
        var replyTo = isolate$deserializeMessage(serializedReplyTo);
        native__IsolateJsUtil__startIsolate(runnerObject, replyTo);
      });
      isolate$runEventLoop();
      break;
    case 'spawn-worker':
      isolate$spawnWorker(msg.factoryName, msg.replyPort);
      break;
    case 'message':
      isolate$sendMessage(msg.workerId, msg.isolateId, msg.portId,
                          msg.msg, msg.replyTo);
      isolate$runEventLoop();
      break;
    case 'close':
      isolate$log("Closing Worker");
      isolate$workerRegistry.unregister(sender.id);
      sender.terminate();
      isolate$runEventLoop();
      break;
    case 'log':
      isolate$log(msg.msg);
      break;
    case 'print':
      native__IsolateJsUtil__print(msg.msg);
      break;
    case 'error':
      throw msg.msg;
      break;
  }
}

if (isolate$supportsWorkers) {
  isolate$globalThis.onmessage = function(e) {
    isolate$processWorkerMessage(isolate$mainWorker, e);
  };
}

// ------- Default Worker -------
function isolate$MainWorker() {
  this.id = isolate$MAIN_WORKER_ID;
}

var isolate$mainWorker = new isolate$MainWorker();
isolate$mainWorker.postMessage = function(msg) {
  isolate$globalThis.postMessage(msg);
};

var isolate$nextFreeIsolateId = 1;

// Native methods for isolate functionality.
/**
 * @constructor
 */
function isolate$Isolate() {
  // The isolate ids is only unique within the current worker and frame.
  this.id = isolate$nextFreeIsolateId++;
  // When storing information on DOM nodes the isolate's id is not enough.
  // We instead use a token with a hashcode. The token can be stored in the
  // DOM node (since it is small and will not keep much data alive).
  this.token = new Object();
  this.token.hashCode = (Math.random() * 0xFFFFFFF) >>> 0;
  this.receivePorts = new isolate$Registry();
  this.run(function() {
    // The Dart-to-JavaScript compiler builds a list of functions that
    // need to run for each isolate to setup the state of static
    // variables. Run through the list and execute each function.
    for (var i = 0, len = isolate$inits.length; i < len; i++) {
      isolate$inits[i]();
    }
  });
}

// It is allowed to stack 'run' calls. The stacked isolates can be different.
// That is Isolate1.run could call the DOM which then calls Isolate2.run.
isolate$Isolate.prototype.run = function(code) {
  var old = isolate$current;
  isolate$current = this;
  var result = null;
  try {
    result = code();
  } finally {
    isolate$current = old;
  }
  return result;
};

isolate$Isolate.prototype.registerReceivePort = function(id, port) {
  if (this.receivePorts.isEmpty()) {
    isolate$isolateRegistry.register(this.id, this);
  }
  this.receivePorts.register(id, port);
};

isolate$Isolate.prototype.unregisterReceivePort = function(id) {
  this.receivePorts.unregister(id);
  if (this.receivePorts.isEmpty()) {
    isolate$isolateRegistry.unregister(this.id);
  }
};

isolate$Isolate.prototype.getReceivePortForId = function(id) {
  return this.receivePorts.get(id);
};

var isolate$events = [];

/**
 * @constructor
 */
function isolate$IsolateEvent(isolate, fn) {
  this.isolate = isolate;
  this.fn = fn;
}

isolate$IsolateEvent.prototype.process = function() {
  this.isolate.run(this.fn);
};

isolate$IsolateEvent.enqueue = function(isolate, fn) {
  isolate$events.push(new isolate$IsolateEvent(isolate, fn));
};

isolate$IsolateEvent.dequeue = function() {
  if (isolate$events.length == 0) return $Dart$Null;
  var result = isolate$events[0];
  isolate$events.splice(0, 1);
  return result;
};

function native_IsolateNatives__spawn(runnable, light, replyPort) {
  // TODO(floitsch): throw exception if runnable's class doesn't have a
  // default constructor.
  if (isolate$useWorkers && !light) {
    isolate$startWorker(runnable, replyPort);
  } else {
    isolate$startNonWorker(runnable, replyPort);
  }
}

function isolate$startNonWorker(runnable, replyTo) {
  // Spawn a new isolate and create the receive port in it.
  var spawned = new isolate$Isolate();

  // Instead of just running the provided runnable, we create a
  // new cloned instance of it with a fresh state in the spawned
  // isolate. This way, we do not get cross-isolate references
  // through the runnable.
  var factory = runnable.getIsolateFactory();
  isolate$IsolateEvent.enqueue(spawned, function() {
    native__IsolateJsUtil__startIsolate(factory(), replyTo);
  });
}

// This field is only used by the main worker.
var isolate$nextFreeWorkerId = isolate$thisWorkerId + 1;

var isolate$thisScript = function() {
  if (!isolate$supportsWorkers || isolate$inWorker) return null;

  // TODO(5334778): Find a cross-platform non-brittle way of getting the
  // currently running script.
  var scripts = document.getElementsByTagName('script');
  // The scripts variable only contains the scripts that have already been
  // executed. The last one is the currently running script.
  var script = scripts[scripts.length - 1];
  var src = script.src;
  if (!src) {
    // TODO()
    src = "FIXME:5407062" + "_" + Math.random().toString();
    script.src = src;
  }
  return src;
}();

function isolate$startWorker(runnable, replyPort) {
  var factory = runnable.getIsolateFactory();
  var factoryName = factory.name;
  var serializedReplyPort = isolate$serializeMessage(replyPort);
  if (isolate$inWorker) {
    isolate$mainWorker.postMessage({ command: 'spawn-worker',
                                     factoryName: factoryName,
                                     replyPort: serializedReplyPort } );
  } else {
    isolate$spawnWorker(factoryName, serializedReplyPort);
  }
}

function isolate$spawnWorker(factoryName, serializedReplyPort) {
  var worker = new Worker(isolate$thisScript);
  worker.onmessage = function(e) {
    isolate$processWorkerMessage(worker, e);
  };
  var workerId = isolate$nextFreeWorkerId++;
  // We also store the id on the worker itself so that we can unregister it.
  worker.id = workerId;
  isolate$workerRegistry.register(workerId, worker);
  worker.postMessage({ command: 'start',
                       id: workerId,
                       replyTo: serializedReplyPort,
                       factoryName: factoryName });
}

function native_SendPortImpl__sendNow(message, replyTo) {
  if (replyTo !== $Dart$Null && !(replyTo instanceof SendPortImpl$Dart)) {
    throw "SendPort::send: Illegal replyTo type.";
  }
  message = isolate$serializeMessage(message);
  replyTo = isolate$serializeMessage(replyTo);
  var workerId = native_SendPortImpl__getWorkerId(this);
  var isolateId = native_SendPortImpl__getIsolateId(this);
  var receivePortId = native_SendPortImpl__getReceivePortId(this);
  isolate$sendMessage(workerId, isolateId, receivePortId, message, replyTo);
}

function isolate$closeWorkerIfNecessary() {
  if (!isolate$isolateRegistry.isEmpty()) return;
  isolate$mainWorker.postMessage( { command: 'close' } );
}

function isolate$doOneEventLoopIteration() {
  var CONTINUE_LOOP = true;
  var STOP_LOOP = false;
  var event = isolate$IsolateEvent.dequeue();
  if (!event) {
    if (isolate$inWorker) {
      isolate$closeWorkerIfNecessary();
    } else if (isolate$isolateRegistry.contains(isolate$rootIsolate.id) &&
               isolate$workerRegistry.isEmpty() &&
               !isolate$supportsWorkers && (typeof(window) == 'undefined')) {
      // No events anymore, but the main-worker still has open receive-ports.
      // This simulates the VM's behavior (which instead times out).
      // We only trigger this message when we run on the console (where we
      // don't have workers). We don't want this check to execute in the browser
      // where the isolate might still be alive due to DOM callbacks.
      throw Error("Program exited with open ReceivePorts.");
    }
    return STOP_LOOP;
  } else {
    event.process();
    return CONTINUE_LOOP;
  }
}

function isolate$doRunEventLoop() {
  if (typeof window != 'undefined' && window.setTimeout) {
    (function next() {
      var continueLoop = isolate$doOneEventLoopIteration();
      if (!continueLoop) return;
      // TODO(kasperl): It might turn out to be too expensive to call
      // setTimeout for every single event. This needs more investigation.
      window.setTimeout(next, 0);
    })();
  } else {
    while (true) {
      var continueLoop = isolate$doOneEventLoopIteration();
      if (!continueLoop) break;
    }
  }
}

function isolate$runEventLoop() {
  if (!isolate$inWorker) {
    isolate$doRunEventLoop();
  } else {
    try {
      isolate$doRunEventLoop();
    } catch(e) {
      // TODO(floitsch): try to send stack-trace to the other side.
      isolate$mainWorker.postMessage({ command: 'error', msg: "" + e });
    }
  }
}

function RunEntry(entry, args) {
  // Don't start the main loop again, if we are in a worker.
  if (isolate$inWorker) return;
  var isolate = new isolate$Isolate();
  isolate$rootIsolate = isolate;
  isolate$IsolateEvent.enqueue(isolate, function() {
    entry(args);
  });
  isolate$runEventLoop();

  // BUG(5151491): This should not be necessary, but because closures
  // passed to the DOM as event handlers do not bind their isolate
  // automatically we try to give them a reasonable context to live in
  // by having a "default" isolate (the first one created).
  isolate$current = isolate;
}

// ------- Message Serializing and Deserializing -------

function native_MessageTraverser__clearAttachedInfo(o) {
  o['__MessageTraverser__attached_info__'] = (void 0);
}

function native_MessageTraverser__setAttachedInfo(o, info) {
  o['__MessageTraverser__attached_info__'] = info;
}

function native_MessageTraverser__getAttachedInfo(o) {
  return o['__MessageTraverser__attached_info__'];
}

function native_Serializer__newJsArray(len) {
  return new Array(len);
}

function native_Serializer__jsArrayIndexSet(jsArray, index, val) {
  jsArray[index] = val;
}

function native_Serializer__dartListToJsArrayNoCopy(list) {
  if (list instanceof Array) {
    RTT.removeTypeInfo(list);
    return list;
  } else {
    var len = native__ListJsUtil__listLength(list);
    var array = new Array(len);
    for (var i = 0; i < len; i++) {
      array[i] = INDEX$operator(list, i);
    }
    return array;
  }
}

function native_Deserializer__isJsArray(x) {
  return x instanceof Array;
}

function native_Deserializer__jsArrayIndex(x, index) {
  return x[index];
}

function native_Deserializer__jsArrayLength(x) {
  return x.length;
}

function isolate$serializeMessage(message) {
  if (isolate$useWorkers || isolate$useWorkerSerializationProtocol) {
    return native__IsolateJsUtil__serializeObject(message);
  } else {
    return native__IsolateJsUtil__copyObject(message);
  }
}

function isolate$deserializeMessage(message) {
  if (isolate$useWorkers || isolate$useWorkerSerializationProtocol) {
    return native__IsolateJsUtil__deserializeMessage(message);
  } else {
    // Nothing more to do.
    return message;
  }
}
