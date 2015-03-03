var _isolate_helper;
(function(exports) {
  'use strict';
  // Function _callInIsolate: (_IsolateContext, Function) → dynamic
  function _callInIsolate(isolate, function) {
    let result = isolate.eval(function);
    exports._globalState.topEventLoop.run();
    return result;
  }
  // Function enterJsAsync: () → dynamic
  function enterJsAsync() {
    exports._globalState.topEventLoop._activeJsAsyncCount++;
  }
  // Function leaveJsAsync: () → dynamic
  function leaveJsAsync() {
    exports._globalState.topEventLoop._activeJsAsyncCount--;
    dart.assert(exports._globalState.topEventLoop._activeJsAsyncCount >= 0);
  }
  // Function isWorker: () → bool
  function isWorker() {
    return exports._globalState.isWorker;
  }
  // Function _currentIsolate: () → _IsolateContext
  function _currentIsolate() {
    return exports._globalState.currentContext;
  }
  // Function startRootIsolate: (dynamic, dynamic) → void
  function startRootIsolate(entry, args) {
    args = args;
    if (args === null)
      args = new List.from([]);
    if (!dart.is(args, core.List)) {
      throw new core.ArgumentError(`Arguments to main must be a List: ${args}`);
    }
    exports._globalState = new _Manager(dart.as(entry, core.Function));
    if (exports._globalState.isWorker)
      return;
    let rootContext = new _IsolateContext();
    exports._globalState.rootContext = rootContext;
    exports._globalState.currentContext = rootContext;
    if (dart.is(entry, _MainFunctionArgs)) {
      rootContext.eval(() => {
        dart.dinvokef(entry, args);
      });
    } else if (dart.is(entry, _MainFunctionArgsMessage)) {
      rootContext.eval(() => {
        dart.dinvokef(entry, args, null);
      });
    } else {
      rootContext.eval(dart.as(entry, core.Function));
    }
    exports._globalState.topEventLoop.run();
  }
  dart.copyProperties(exports, {
    get _globalState() {
      return dart.as(init.globalState, _Manager);
    },
    set _globalState(val) {
      init.globalState = val;
    }
  });
  class _Manager extends dart.Object {
    get useWorkers() {
      return this.supportsWorkers;
    }
    _Manager(entry) {
      this.entry = entry;
      this.nextIsolateId = 0;
      this.currentManagerId = 0;
      this.nextManagerId = 1;
      this.currentContext = null;
      this.rootContext = null;
      this.topEventLoop = null;
      this.fromCommandLine = null;
      this.isWorker = null;
      this.supportsWorkers = null;
      this.isolates = null;
      this.mainManager = null;
      this.managers = null;
      this._nativeDetectEnvironment();
      this.topEventLoop = new _EventLoop();
      this.isolates = new core.Map();
      this.managers = new core.Map();
      if (this.isWorker) {
        this.mainManager = new _MainManagerStub();
        this._nativeInitWorkerMessageHandler();
      }
    }
    _nativeDetectEnvironment() {
      let isWindowDefined = exports.globalWindow !== null;
      let isWorkerDefined = exports.globalWorker !== null;
      this.isWorker = dart.notNull(!dart.notNull(isWindowDefined)) && dart.notNull(exports.globalPostMessageDefined);
      this.supportsWorkers = dart.notNull(this.isWorker) || dart.notNull(dart.notNull(isWorkerDefined) && dart.notNull(IsolateNatives.thisScript !== null));
      this.fromCommandLine = dart.notNull(!dart.notNull(isWindowDefined)) && dart.notNull(!dart.notNull(this.isWorker));
    }
    _nativeInitWorkerMessageHandler() {
      let function = function(f, a) {
        return function(e) {
          f(a, e);
        };
      }(_foreign_helper.DART_CLOSURE_TO_JS(IsolateNatives._processWorkerMessage), this.mainManager);
      self.onmessage = function;
      self.dartPrint = self.dartPrint || function(serialize) {
        return function(object) {
          if (self.console && self.console.log) {
            self.console.log(object);
          } else {
            self.postMessage(serialize(object));
          }
        };
      }(_foreign_helper.DART_CLOSURE_TO_JS(_serializePrintMessage));
    }
    static _serializePrintMessage(object) {
      return _serializeMessage(dart.map({command: "print", msg: object}));
    }
    maybeCloseWorker() {
      if (dart.notNull(dart.notNull(this.isWorker) && dart.notNull(this.isolates.isEmpty)) && dart.notNull(this.topEventLoop._activeJsAsyncCount === 0)) {
        this.mainManager.postMessage(_serializeMessage(dart.map({command: 'close'})));
      }
    }
  }
  class _IsolateContext extends dart.Object {
    _IsolateContext() {
      this.id = exports._globalState.nextIsolateId++;
      this.ports = new core.Map();
      this.weakPorts = new core.Set();
      this.isolateStatics = _foreign_helper.JS_CREATE_ISOLATE();
      this.controlPort = new RawReceivePortImpl._controlPort();
      this.pauseCapability = new isolate.Capability();
      this.terminateCapability = new isolate.Capability();
      this.delayedEvents = dart.as(new List.from([]), core.List$(_IsolateEvent));
      this.pauseTokens = dart.as(new core.Set(), core.Set$(isolate.Capability));
      this.errorPorts = dart.as(new core.Set(), core.Set$(isolate.SendPort));
      this.initialized = false;
      this.isPaused = false;
      this.doneHandlers = null;
      this._scheduledControlEvents = null;
      this._isExecutingEvent = false;
      this.errorsAreFatal = true;
      this.registerWeak(this.controlPort._id, this.controlPort);
    }
    addPause(authentification, resume) {
      if (!dart.equals(this.pauseCapability, authentification))
        return;
      if (dart.notNull(this.pauseTokens.add(resume)) && dart.notNull(!dart.notNull(this.isPaused))) {
        this.isPaused = true;
      }
      this._updateGlobalState();
    }
    removePause(resume) {
      if (!dart.notNull(this.isPaused))
        return;
      this.pauseTokens.remove(resume);
      if (this.pauseTokens.isEmpty) {
        while (this.delayedEvents.isNotEmpty) {
          let event = this.delayedEvents.removeLast();
          exports._globalState.topEventLoop.prequeue(event);
        }
        this.isPaused = false;
      }
      this._updateGlobalState();
    }
    addDoneListener(responsePort) {
      if (this.doneHandlers === null) {
        this.doneHandlers = new List.from([]);
      }
      if (dart.dinvoke(this.doneHandlers, 'contains', responsePort))
        return;
      dart.dinvoke(this.doneHandlers, 'add', responsePort);
    }
    removeDoneListener(responsePort) {
      if (this.doneHandlers === null)
        return;
      dart.dinvoke(this.doneHandlers, 'remove', responsePort);
    }
    setErrorsFatal(authentification, errorsAreFatal) {
      if (!dart.equals(this.terminateCapability, authentification))
        return;
      this.errorsAreFatal = errorsAreFatal;
    }
    handlePing(responsePort, pingType) {
      if (dart.notNull(pingType === isolate.Isolate.IMMEDIATE) || dart.notNull(dart.notNull(pingType === isolate.Isolate.BEFORE_NEXT_EVENT) && dart.notNull(!dart.notNull(this._isExecutingEvent)))) {
        responsePort.send(null);
        return;
      }
      // Function respond: () → void
      function respond() {
        responsePort.send(null);
      }
      if (pingType === isolate.Isolate.AS_EVENT) {
        exports._globalState.topEventLoop.enqueue(this, respond, "ping");
        return;
      }
      dart.assert(pingType === isolate.Isolate.BEFORE_NEXT_EVENT);
      if (this._scheduledControlEvents === null) {
        this._scheduledControlEvents = new collection.Queue();
      }
      dart.dinvoke(this._scheduledControlEvents, 'addLast', respond);
    }
    handleKill(authentification, priority) {
      if (!dart.equals(this.terminateCapability, authentification))
        return;
      if (dart.notNull(priority === isolate.Isolate.IMMEDIATE) || dart.notNull(dart.notNull(priority === isolate.Isolate.BEFORE_NEXT_EVENT) && dart.notNull(!dart.notNull(this._isExecutingEvent)))) {
        this.kill();
        return;
      }
      if (priority === isolate.Isolate.AS_EVENT) {
        exports._globalState.topEventLoop.enqueue(this, this.kill, "kill");
        return;
      }
      dart.assert(priority === isolate.Isolate.BEFORE_NEXT_EVENT);
      if (this._scheduledControlEvents === null) {
        this._scheduledControlEvents = new collection.Queue();
      }
      dart.dinvoke(this._scheduledControlEvents, 'addLast', this.kill);
    }
    addErrorListener(port) {
      this.errorPorts.add(port);
    }
    removeErrorListener(port) {
      this.errorPorts.remove(port);
    }
    handleUncaughtError(error, stackTrace) {
      if (this.errorPorts.isEmpty) {
        if (dart.notNull(this.errorsAreFatal) && dart.notNull(core.identical(this, exports._globalState.rootContext))) {
          return;
        }
        if (self.console && self.console.error) {
          self.console.error(error, stackTrace);
        } else {
          core.print(error);
          if (stackTrace !== null)
            core.print(stackTrace);
        }
        return;
      }
      let message = new core.List(2);
      message.set(0, dart.dinvoke(error, 'toString'));
      message.set(1, stackTrace === null ? null : stackTrace.toString());
      for (let port of this.errorPorts)
        port.send(message);
    }
    eval(code) {
      let old = exports._globalState.currentContext;
      exports._globalState.currentContext = this;
      this._setGlobals();
      let result = null;
      this._isExecutingEvent = true;
      try {
        result = dart.dinvokef(code);
      } catch (e) {
        let s = dart.stackTrace(e);
        this.handleUncaughtError(e, s);
        if (this.errorsAreFatal) {
          this.kill();
          if (core.identical(this, exports._globalState.rootContext)) {
            throw e;
          }
        }
      }
 finally {
        this._isExecutingEvent = false;
        exports._globalState.currentContext = old;
        if (old !== null)
          old._setGlobals();
        if (this._scheduledControlEvents !== null) {
          while (dart.dload(this._scheduledControlEvents, 'isNotEmpty')) {
            dart.dinvokef(dart.dinvoke(this._scheduledControlEvents, 'removeFirst'));
          }
        }
      }
      return result;
    }
    _setGlobals() {
      _foreign_helper.JS_SET_CURRENT_ISOLATE(this.isolateStatics);
    }
    handleControlMessage(message) {
      switch (dart.dindex(message, 0)) {
        case "pause":
          this.addPause(dart.as(dart.dindex(message, 1), isolate.Capability), dart.as(dart.dindex(message, 2), isolate.Capability));
          break;
        case "resume":
          this.removePause(dart.as(dart.dindex(message, 1), isolate.Capability));
          break;
        case 'add-ondone':
          this.addDoneListener(dart.as(dart.dindex(message, 1), isolate.SendPort));
          break;
        case 'remove-ondone':
          this.removeDoneListener(dart.as(dart.dindex(message, 1), isolate.SendPort));
          break;
        case 'set-errors-fatal':
          this.setErrorsFatal(dart.as(dart.dindex(message, 1), isolate.Capability), dart.as(dart.dindex(message, 2), core.bool));
          break;
        case "ping":
          this.handlePing(dart.as(dart.dindex(message, 1), isolate.SendPort), dart.as(dart.dindex(message, 2), core.int));
          break;
        case "kill":
          this.handleKill(dart.as(dart.dindex(message, 1), isolate.Capability), dart.as(dart.dindex(message, 2), core.int));
          break;
        case "getErrors":
          this.addErrorListener(dart.as(dart.dindex(message, 1), isolate.SendPort));
          break;
        case "stopErrors":
          this.removeErrorListener(dart.as(dart.dindex(message, 1), isolate.SendPort));
          break;
        default:
      }
    }
    lookup(portId) {
      return this.ports.get(portId);
    }
    _addRegistration(portId, port) {
      if (this.ports.containsKey(portId)) {
        throw new core.Exception("Registry: ports must be registered only once.");
      }
      this.ports.set(portId, port);
    }
    register(portId, port) {
      this._addRegistration(portId, port);
      this._updateGlobalState();
    }
    registerWeak(portId, port) {
      this.weakPorts.add(portId);
      this._addRegistration(portId, port);
    }
    _updateGlobalState() {
      if (dart.notNull(dart.notNull(this.ports.length - this.weakPorts.length > 0) || dart.notNull(this.isPaused)) || dart.notNull(!dart.notNull(this.initialized))) {
        exports._globalState.isolates.set(this.id, this);
      } else {
        this.kill();
      }
    }
    kill() {
      if (this._scheduledControlEvents !== null) {
        dart.dinvoke(this._scheduledControlEvents, 'clear');
      }
      for (let port of this.ports.values) {
        dart.dinvoke(port, '_close');
      }
      this.ports.clear();
      this.weakPorts.clear();
      exports._globalState.isolates.remove(this.id);
      this.errorPorts.clear();
      if (this.doneHandlers !== null) {
        for (let port of this.doneHandlers) {
          port.send(null);
        }
        this.doneHandlers = null;
      }
    }
    unregister(portId) {
      this.ports.remove(portId);
      this.weakPorts.remove(portId);
      this._updateGlobalState();
    }
  }
  class _EventLoop extends dart.Object {
    _EventLoop() {
      this.events = new collection.Queue();
      this._activeJsAsyncCount = 0;
    }
    enqueue(isolate, fn, msg) {
      this.events.addLast(new _IsolateEvent(dart.as(isolate, _IsolateContext), dart.as(fn, core.Function), dart.as(msg, core.String)));
    }
    prequeue(event) {
      this.events.addFirst(event);
    }
    dequeue() {
      if (this.events.isEmpty)
        return null;
      return this.events.removeFirst();
    }
    checkOpenReceivePortsFromCommandLine() {
      if (dart.notNull(dart.notNull(dart.notNull(exports._globalState.rootContext !== null) && dart.notNull(exports._globalState.isolates.containsKey(exports._globalState.rootContext.id))) && dart.notNull(exports._globalState.fromCommandLine)) && dart.notNull(exports._globalState.rootContext.ports.isEmpty)) {
        throw new core.Exception("Program exited with open ReceivePorts.");
      }
    }
    runIteration() {
      let event = this.dequeue();
      if (event === null) {
        this.checkOpenReceivePortsFromCommandLine();
        exports._globalState.maybeCloseWorker();
        return false;
      }
      event.process();
      return true;
    }
    _runHelper() {
      if (exports.globalWindow !== null) {
        // Function next: () → void
        function next() {
          if (!dart.notNull(this.runIteration()))
            return;
          async.Timer.run(next);
        }
        next();
      } else {
        while (this.runIteration()) {
        }
      }
    }
    run() {
      if (!dart.notNull(exports._globalState.isWorker)) {
        this._runHelper();
      } else {
        try {
          this._runHelper();
        } catch (e) {
          let trace = dart.stackTrace(e);
          exports._globalState.mainManager.postMessage(_serializeMessage(dart.map({command: 'error', msg: `${e}\n${trace}`})));
        }

      }
    }
  }
  class _IsolateEvent extends dart.Object {
    _IsolateEvent(isolate, fn, message) {
      this.isolate = isolate;
      this.fn = fn;
      this.message = message;
    }
    process() {
      if (this.isolate.isPaused) {
        this.isolate.delayedEvents.add(this);
        return;
      }
      this.isolate.eval(this.fn);
    }
  }
  class _MainManagerStub extends dart.Object {
    postMessage(msg) {
      _js_helper.requiresPreamble();
      self.postMessage(msg);
    }
  }
  let _SPAWNED_SIGNAL = "spawned";
  let _SPAWN_FAILED_SIGNAL = "spawn failed";
  dart.copyProperties(exports, {
    get globalWindow() {
      _js_helper.requiresPreamble();
      return self.window;
    },
    get globalWorker() {
      _js_helper.requiresPreamble();
      return self.Worker;
    },
    get globalPostMessageDefined() {
      _js_helper.requiresPreamble();
      return !!self.postMessage;
    }
  });
  class IsolateNatives extends dart.Object {
    static computeThisScript() {
      let currentScript = _foreign_helper.JS_EMBEDDED_GLOBAL('', dart.as(_js_embedded_names.CURRENT_SCRIPT, core.String));
      if (currentScript !== null) {
        return String(currentScript.src);
      }
      if (_js_helper.Primitives.isD8)
        return computeThisScriptD8();
      if (_js_helper.Primitives.isJsshell)
        return computeThisScriptJsshell();
      if (exports._globalState.isWorker)
        return computeThisScriptFromTrace();
      return null;
    }
    static computeThisScriptJsshell() {
      return dart.as(thisFilename(), core.String);
    }
    static computeThisScriptD8() {
      return computeThisScriptFromTrace();
    }
    static computeThisScriptFromTrace() {
      let stack = new Error().stack;
      if (stack === null) {
        stack = function() {
          try {
            throw new Error();
          } catch (e) {
            return e.stack;
          }

        }();
        if (stack === null)
          throw new core.UnsupportedError('No stack trace');
      }
      let pattern = null, matches = null;
      pattern = new RegExp("^ *at [^(]*\\((.*):[0-9]*:[0-9]*\\)$", "m");
      matches = stack.match(pattern);
      if (matches !== null)
        return matches[1];
      pattern = new RegExp("^[^@]*@(.*):[0-9]*$", "m");
      matches = stack.match(pattern);
      if (matches !== null)
        return matches[1];
      throw new core.UnsupportedError(`Cannot extract URI from "${stack}"`);
    }
    static _getEventData(e) {
      return e.data;
    }
    static _processWorkerMessage(sender, e) {
      let msg = _deserializeMessage(_getEventData(e));
      switch (dart.dindex(msg, 'command')) {
        case 'start':
          exports._globalState.currentManagerId = dart.as(dart.dindex(msg, 'id'), core.int);
          let functionName = dart.as(dart.dindex(msg, 'functionName'), core.String);
          let entryPoint = dart.as(functionName === null ? exports._globalState.entry : _getJSFunctionFromName(functionName), core.Function);
          let args = dart.dindex(msg, 'args');
          let message = _deserializeMessage(dart.dindex(msg, 'msg'));
          let isSpawnUri = dart.dindex(msg, 'isSpawnUri');
          let startPaused = dart.dindex(msg, 'startPaused');
          let replyTo = _deserializeMessage(dart.dindex(msg, 'replyTo'));
          let context = new _IsolateContext();
          exports._globalState.topEventLoop.enqueue(context, () => {
            _startIsolate(entryPoint, dart.as(args, core.List$(core.String)), message, dart.as(isSpawnUri, core.bool), dart.as(startPaused, core.bool), dart.as(replyTo, isolate.SendPort));
          }, 'worker-start');
          exports._globalState.currentContext = context;
          exports._globalState.topEventLoop.run();
          break;
        case 'spawn-worker':
          if (enableSpawnWorker !== null)
            handleSpawnWorkerRequest(msg);
          break;
        case 'message':
          let port = dart.as(dart.dindex(msg, 'port'), isolate.SendPort);
          if (port !== null) {
            dart.dinvoke(dart.dindex(msg, 'port'), 'send', dart.dindex(msg, 'msg'));
          }
          exports._globalState.topEventLoop.run();
          break;
        case 'close':
          exports._globalState.managers.remove(workerIds.get(sender));
          sender.terminate();
          exports._globalState.topEventLoop.run();
          break;
        case 'log':
          _log(dart.dindex(msg, 'msg'));
          break;
        case 'print':
          if (exports._globalState.isWorker) {
            exports._globalState.mainManager.postMessage(_serializeMessage(dart.map({command: 'print', msg: msg})));
          } else {
            core.print(dart.dindex(msg, 'msg'));
          }
          break;
        case 'error':
          throw dart.dindex(msg, 'msg');
      }
    }
    static handleSpawnWorkerRequest(msg) {
      let replyPort = dart.dindex(msg, 'replyPort');
      spawn(dart.as(dart.dindex(msg, 'functionName'), core.String), dart.as(dart.dindex(msg, 'uri'), core.String), dart.as(dart.dindex(msg, 'args'), core.List$(core.String)), dart.dindex(msg, 'msg'), false, dart.as(dart.dindex(msg, 'isSpawnUri'), core.bool), dart.as(dart.dindex(msg, 'startPaused'), core.bool)).then((msg) => {
        dart.dinvoke(replyPort, 'send', msg);
      }, {
        onError: (errorMessage) => {
          dart.dinvoke(replyPort, 'send', new List.from([_SPAWN_FAILED_SIGNAL, errorMessage]));
        }
      });
    }
    static _log(msg) {
      if (exports._globalState.isWorker) {
        exports._globalState.mainManager.postMessage(_serializeMessage(dart.map({command: 'log', msg: msg})));
      } else {
        try {
          _consoleLog(msg);
        } catch (e) {
          let trace = dart.stackTrace(e);
          throw new core.Exception(trace);
        }

      }
    }
    static _consoleLog(msg) {
      _js_helper.requiresPreamble();
      self.console.log(msg);
    }
    static _getJSFunctionFromName(functionName) {
      let globalFunctionsContainer = _foreign_helper.JS_EMBEDDED_GLOBAL("", dart.as(_js_embedded_names.GLOBAL_FUNCTIONS, core.String));
      return globalFunctionsContainer[functionName]();
    }
    static _getJSFunctionName(f) {
      return dart.as(dart.is(f, _js_helper.Closure) ? f.$name : null, core.String);
    }
    static _allocate(ctor) {
      return new ctor();
    }
    static spawnFunction(topLevelFunction, message, startPaused) {
      IsolateNatives.enableSpawnWorker = true;
      let name = _getJSFunctionName(topLevelFunction);
      if (name === null) {
        throw new core.UnsupportedError("only top-level functions can be spawned.");
      }
      let isLight = false;
      let isSpawnUri = false;
      return spawn(name, null, null, message, isLight, isSpawnUri, startPaused);
    }
    static spawnUri(uri, args, message, startPaused) {
      IsolateNatives.enableSpawnWorker = true;
      let isLight = false;
      let isSpawnUri = true;
      return spawn(null, uri.toString(), args, message, isLight, isSpawnUri, startPaused);
    }
    static spawn(functionName, uri, args, message, isLight, isSpawnUri, startPaused) {
      if (dart.notNull(uri !== null) && dart.notNull(uri.endsWith(".dart")))
        uri = ".js";
      let port = new isolate.ReceivePort();
      let completer = dart.as(new async.Completer(), async.Completer$(core.List));
      port.first.then(((msg) => {
        if (dart.equals(dart.dindex(msg, 0), _SPAWNED_SIGNAL)) {
          completer.complete(msg);
        } else {
          dart.assert(dart.equals(dart.dindex(msg, 0), _SPAWN_FAILED_SIGNAL));
          completer.completeError(dart.dindex(msg, 1));
        }
      }).bind(this));
      let signalReply = port.sendPort;
      if (dart.notNull(exports._globalState.useWorkers) && dart.notNull(!dart.notNull(isLight))) {
        _startWorker(functionName, uri, args, message, isSpawnUri, startPaused, signalReply, ((message) => completer.completeError(message)).bind(this));
      } else {
        _startNonWorker(functionName, uri, args, message, isSpawnUri, startPaused, signalReply);
      }
      return completer.future;
    }
    static _startWorker(functionName, uri, args, message, isSpawnUri, startPaused, replyPort, onError) {
      if (args !== null)
        args = new core.List.from(args);
      if (exports._globalState.isWorker) {
        exports._globalState.mainManager.postMessage(_serializeMessage(dart.map({command: 'spawn-worker', functionName: functionName, args: args, msg: message, uri: uri, isSpawnUri: isSpawnUri, startPaused: startPaused, replyPort: replyPort})));
      } else {
        _spawnWorker(functionName, uri, args, message, isSpawnUri, startPaused, replyPort, onError);
      }
    }
    static _startNonWorker(functionName, uri, args, message, isSpawnUri, startPaused, replyPort) {
      if (uri !== null) {
        throw new core.UnsupportedError("Currently spawnUri is not supported without web workers.");
      }
      message = _clone(message);
      if (args !== null)
        args = new core.List.from(args);
      exports._globalState.topEventLoop.enqueue(new _IsolateContext(), () => {
        let func = _getJSFunctionFromName(functionName);
        _startIsolate(dart.as(func, core.Function), args, message, isSpawnUri, startPaused, replyPort);
      }, 'nonworker start');
    }
    static get currentIsolate() {
      let context = dart.as(_foreign_helper.JS_CURRENT_ISOLATE_CONTEXT(), _IsolateContext);
      return new isolate.Isolate(context.controlPort.sendPort, {pauseCapability: context.pauseCapability, terminateCapability: context.terminateCapability});
    }
    static _startIsolate(topLevel, args, message, isSpawnUri, startPaused, replyTo) {
      let context = dart.as(_foreign_helper.JS_CURRENT_ISOLATE_CONTEXT(), _IsolateContext);
      _js_helper.Primitives.initializeStatics(context.id);
      replyTo.send(new List.from([_SPAWNED_SIGNAL, context.controlPort.sendPort, context.pauseCapability, context.terminateCapability]));
      // Function runStartFunction: () → void
      function runStartFunction() {
        context.initialized = true;
        if (!dart.notNull(isSpawnUri)) {
          dart.dinvokef(topLevel, message);
        } else if (dart.is(topLevel, _MainFunctionArgsMessage)) {
          dart.dinvokef(topLevel, args, message);
        } else if (dart.is(topLevel, _MainFunctionArgs)) {
          dart.dinvokef(topLevel, args);
        } else {
          dart.dinvokef(topLevel);
        }
      }
      if (startPaused) {
        context.addPause(context.pauseCapability, context.pauseCapability);
        exports._globalState.topEventLoop.enqueue(context, runStartFunction, 'start isolate');
      } else {
        runStartFunction();
      }
    }
    static _spawnWorker(functionName, uri, args, message, isSpawnUri, startPaused, replyPort, onError) {
      if (uri === null)
        uri = thisScript;
      let worker = new Worker(uri);
      let onerrorTrampoline = function(f, u, c) {
        return function(e) {
          return f(e, u, c);
        };
      }(_foreign_helper.DART_CLOSURE_TO_JS(workerOnError), uri, onError);
      worker.onerror = onerrorTrampoline;
      let processWorkerMessageTrampoline = function(f, a) {
        return function(e) {
          e.onerror = null;
          return f(a, e);
        };
      }(_foreign_helper.DART_CLOSURE_TO_JS(_processWorkerMessage), worker);
      worker.onmessage = processWorkerMessageTrampoline;
      let workerId = exports._globalState.nextManagerId++;
      workerIds.set(worker, workerId);
      exports._globalState.managers.set(workerId, worker);
      worker.postMessage(_serializeMessage(dart.map({command: 'start', id: workerId, replyTo: _serializeMessage(replyPort), args: args, msg: _serializeMessage(message), isSpawnUri: isSpawnUri, startPaused: startPaused, functionName: functionName})));
    }
    static workerOnError(event, uri, onError) {
      event.preventDefault();
      let message = dart.as(event.message, core.String);
      if (message === null) {
        message = `Error spawning worker for ${uri}`;
      } else {
        message = `Error spawning worker for ${uri} (${message})`;
      }
      onError(message);
      return true;
    }
  }
  IsolateNatives.enableSpawnWorker = null;
  dart.defineLazyProperties(IsolateNatives, {
    get thisScript() {
      return computeThisScript();
    },
    set thisScript(_) {},
    get workerIds() {
      return new core.Expando();
    }
  });
  class _BaseSendPort extends dart.Object {
    _BaseSendPort(_isolateId) {
      this._isolateId = _isolateId;
    }
    _checkReplyTo(replyTo) {
      if (dart.notNull(dart.notNull(replyTo !== null) && dart.notNull(!dart.is(replyTo, _NativeJsSendPort))) && dart.notNull(!dart.is(replyTo, _WorkerSendPort))) {
        throw new core.Exception("SendPort.send: Illegal replyTo port type");
      }
    }
  }
  class _NativeJsSendPort extends _BaseSendPort {
    _NativeJsSendPort(_receivePort, isolateId) {
      this._receivePort = _receivePort;
      super._BaseSendPort(isolateId);
    }
    send(message) {
      let isolate = exports._globalState.isolates.get(this._isolateId);
      if (isolate === null)
        return;
      if (this._receivePort._isClosed)
        return;
      let msg = _clone(message);
      if (dart.equals(isolate.controlPort, this._receivePort)) {
        isolate.handleControlMessage(msg);
        return;
      }
      exports._globalState.topEventLoop.enqueue(isolate, (() => {
        if (!dart.notNull(this._receivePort._isClosed)) {
          this._receivePort._add(msg);
        }
      }).bind(this), `receive ${message}`);
    }
    ['=='](other) {
      return dart.notNull(dart.is(other, _NativeJsSendPort)) && dart.notNull(dart.equals(this._receivePort, dart.dload(other, '_receivePort')));
    }
    get hashCode() {
      return this._receivePort._id;
    }
  }
  class _WorkerSendPort extends _BaseSendPort {
    _WorkerSendPort(_workerId, isolateId, _receivePortId) {
      this._workerId = _workerId;
      this._receivePortId = _receivePortId;
      super._BaseSendPort(isolateId);
    }
    send(message) {
      let workerMessage = _serializeMessage(dart.map({command: 'message', port: this, msg: message}));
      if (exports._globalState.isWorker) {
        exports._globalState.mainManager.postMessage(workerMessage);
      } else {
        let manager = exports._globalState.managers.get(this._workerId);
        if (manager !== null) {
          manager.postMessage(workerMessage);
        }
      }
    }
    ['=='](other) {
      return dart.notNull(dart.notNull(dart.notNull(dart.is(other, _WorkerSendPort)) && dart.notNull(this._workerId === dart.dload(other, '_workerId'))) && dart.notNull(this._isolateId === dart.dload(other, '_isolateId'))) && dart.notNull(this._receivePortId === dart.dload(other, '_receivePortId'));
    }
    get hashCode() {
      return this._workerId << 16 ^ this._isolateId << 8 ^ this._receivePortId;
    }
  }
  class RawReceivePortImpl extends dart.Object {
    RawReceivePortImpl(_handler) {
      this._handler = _handler;
      this._id = _nextFreeId++;
      this._isClosed = false;
      exports._globalState.currentContext.register(this._id, this);
    }
    RawReceivePortImpl$weak(_handler) {
      this._handler = _handler;
      this._id = _nextFreeId++;
      this._isClosed = false;
      exports._globalState.currentContext.registerWeak(this._id, this);
    }
    RawReceivePortImpl$_controlPort() {
      this._handler = null;
      this._id = 0;
      this._isClosed = false;
    }
    set handler(newHandler) {
      this._handler = newHandler;
    }
    _close() {
      this._isClosed = true;
      this._handler = null;
    }
    close() {
      if (this._isClosed)
        return;
      this._isClosed = true;
      this._handler = null;
      exports._globalState.currentContext.unregister(this._id);
    }
    _add(dataEvent) {
      if (this._isClosed)
        return;
      dart.dinvokef(this._handler, dataEvent);
    }
    get sendPort() {
      return new _NativeJsSendPort(this, exports._globalState.currentContext.id);
    }
  }
  dart.defineNamedConstructor(RawReceivePortImpl, 'weak');
  dart.defineNamedConstructor(RawReceivePortImpl, '_controlPort');
  RawReceivePortImpl._nextFreeId = 1;
  class ReceivePortImpl extends async.Stream {
    ReceivePortImpl() {
      this.ReceivePortImpl$fromRawReceivePort(new RawReceivePortImpl(null));
    }
    ReceivePortImpl$weak() {
      this.ReceivePortImpl$fromRawReceivePort(new RawReceivePortImpl.weak(null));
    }
    ReceivePortImpl$fromRawReceivePort(_rawPort) {
      this._rawPort = _rawPort;
      this._controller = null;
      super.Stream();
      this._controller = new async.StreamController({onCancel: this.close, sync: true});
      this._rawPort.handler = this._controller.add;
    }
    listen(onData, opt$) {
      let onError = opt$.onError === void 0 ? null : opt$.onError;
      let onDone = opt$.onDone === void 0 ? null : opt$.onDone;
      let cancelOnError = opt$.cancelOnError === void 0 ? null : opt$.cancelOnError;
      return this._controller.stream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
    }
    close() {
      this._rawPort.close();
      this._controller.close();
    }
    get sendPort() {
      return this._rawPort.sendPort;
    }
  }
  dart.defineNamedConstructor(ReceivePortImpl, 'weak');
  dart.defineNamedConstructor(ReceivePortImpl, 'fromRawReceivePort');
  class TimerImpl extends dart.Object {
    TimerImpl(milliseconds, callback) {
      this._once = true;
      this._inEventLoop = false;
      this._handle = dart.as(null, core.int);
      if (dart.notNull(milliseconds === 0) && dart.notNull(dart.notNull(!dart.notNull(hasTimer())) || dart.notNull(exports._globalState.isWorker))) {
        // Function internalCallback: () → void
        function internalCallback() {
          this._handle = dart.as(null, core.int);
          callback();
        }
        this._handle = 1;
        exports._globalState.topEventLoop.enqueue(exports._globalState.currentContext, internalCallback, 'timer');
        this._inEventLoop = true;
      } else if (hasTimer()) {
        // Function internalCallback: () → void
        function internalCallback() {
          this._handle = dart.as(null, core.int);
          leaveJsAsync();
          callback();
        }
        enterJsAsync();
        this._handle = self.setTimeout(_js_helper.convertDartClosureToJS(internalCallback, 0), milliseconds);
      } else {
        dart.assert(milliseconds > 0);
        throw new core.UnsupportedError("Timer greater than 0.");
      }
    }
    TimerImpl$periodic(milliseconds, callback) {
      this._once = false;
      this._inEventLoop = false;
      this._handle = dart.as(null, core.int);
      if (hasTimer()) {
        enterJsAsync();
        this._handle = self.setInterval(_js_helper.convertDartClosureToJS((() => {
          callback(this);
        }).bind(this), 0), milliseconds);
      } else {
        throw new core.UnsupportedError("Periodic timer.");
      }
    }
    cancel() {
      if (hasTimer()) {
        if (this._inEventLoop) {
          throw new core.UnsupportedError("Timer in event loop cannot be canceled.");
        }
        if (this._handle === null)
          return;
        leaveJsAsync();
        if (this._once) {
          self.clearTimeout(this._handle);
        } else {
          self.clearInterval(this._handle);
        }
        this._handle = dart.as(null, core.int);
      } else {
        throw new core.UnsupportedError("Canceling a timer.");
      }
    }
    get isActive() {
      return this._handle !== null;
    }
  }
  dart.defineNamedConstructor(TimerImpl, 'periodic');
  // Function hasTimer: () → bool
  function hasTimer() {
    _js_helper.requiresPreamble();
    return self.setTimeout !== null;
  }
  class CapabilityImpl extends dart.Object {
    CapabilityImpl() {
      this.CapabilityImpl$_internal(_js_helper.random64());
    }
    CapabilityImpl$_internal(_id) {
      this._id = _id;
    }
    get hashCode() {
      let hash = this._id;
      hash = hash >> 0 ^ (hash / 4294967296).truncate();
      hash = ~hash + (hash << 15) & 4294967295;
      hash = hash >> 12;
      hash = hash * 5 & 4294967295;
      hash = hash >> 4;
      hash = hash * 2057 & 4294967295;
      hash = hash >> 16;
      return hash;
    }
    ['=='](other) {
      if (core.identical(other, this))
        return true;
      if (dart.is(other, CapabilityImpl)) {
        return core.identical(this._id, other._id);
      }
      return false;
    }
  }
  dart.defineNamedConstructor(CapabilityImpl, '_internal');
  // Function _serializeMessage: (dynamic) → dynamic
  function _serializeMessage(message) {
    return new _Serializer().serialize(message);
  }
  // Function _deserializeMessage: (dynamic) → dynamic
  function _deserializeMessage(message) {
    return new _Deserializer().deserialize(message);
  }
  // Function _clone: (dynamic) → dynamic
  function _clone(message) {
    let serializer = new _Serializer({serializeSendPorts: false});
    let deserializer = new _Deserializer();
    return deserializer.deserialize(serializer.serialize(message));
  }
  class _Serializer extends dart.Object {
    _Serializer(opt$) {
      let serializeSendPorts = opt$.serializeSendPorts === void 0 ? true : opt$.serializeSendPorts;
      this.serializedObjectIds = new core.Map.identity();
      this._serializeSendPorts = dart.as(serializeSendPorts, core.bool);
    }
    serialize(x) {
      if (this.isPrimitive(x))
        return this.serializePrimitive(x);
      let serializationId = this.serializedObjectIds.get(x);
      if (serializationId !== null)
        return this.makeRef(serializationId);
      serializationId = this.serializedObjectIds.length;
      this.serializedObjectIds.set(x, serializationId);
      if (dart.is(x, _native_typed_data.NativeByteBuffer))
        return this.serializeByteBuffer(dart.as(x, _native_typed_data.NativeByteBuffer));
      if (dart.is(x, _native_typed_data.NativeTypedData))
        return this.serializeTypedData(dart.as(x, _native_typed_data.NativeTypedData));
      if (dart.is(x, _interceptors.JSIndexable))
        return this.serializeJSIndexable(dart.as(x, _interceptors.JSIndexable));
      if (dart.is(x, _js_helper.InternalMap))
        return this.serializeMap(dart.as(x, core.Map));
      if (dart.is(x, _interceptors.JSObject))
        return this.serializeJSObject(dart.as(x, _interceptors.JSObject));
      if (dart.is(x, _interceptors.Interceptor))
        this.unsupported(x);
      if (dart.is(x, isolate.RawReceivePort)) {
        this.unsupported(x, "RawReceivePorts can't be transmitted:");
      }
      if (dart.is(x, _NativeJsSendPort))
        return this.serializeJsSendPort(dart.as(x, _NativeJsSendPort));
      if (dart.is(x, _WorkerSendPort))
        return this.serializeWorkerSendPort(dart.as(x, _WorkerSendPort));
      if (dart.is(x, _js_helper.Closure))
        return this.serializeClosure(dart.as(x, _js_helper.Closure));
      return this.serializeDartObject(x);
    }
    unsupported(x, message) {
      if (message === void 0)
        message = null;
      if (message === null)
        message = "Can't transmit:";
      throw new core.UnsupportedError(`${message} ${x}`);
    }
    makeRef(serializationId) {
      return new List.from(["ref", serializationId]);
    }
    isPrimitive(x) {
      return dart.notNull(dart.notNull(dart.notNull(x === null) || dart.notNull(typeof x == string)) || dart.notNull(dart.is(x, core.num))) || dart.notNull(typeof x == boolean);
    }
    serializePrimitive(primitive) {
      return primitive;
    }
    serializeByteBuffer(buffer) {
      return new List.from(["buffer", buffer]);
    }
    serializeTypedData(data) {
      return new List.from(["typed", data]);
    }
    serializeJSIndexable(indexable) {
      dart.assert(!(typeof indexable == string));
      let serialized = dart.as(this.serializeArray(dart.as(indexable, _interceptors.JSArray)), core.List);
      if (dart.is(indexable, _interceptors.JSFixedArray))
        return new List.from(["fixed", serialized]);
      if (dart.is(indexable, _interceptors.JSExtendableArray))
        return new List.from(["extendable", serialized]);
      if (dart.is(indexable, _interceptors.JSMutableArray))
        return new List.from(["mutable", serialized]);
      if (dart.is(indexable, _interceptors.JSArray))
        return new List.from(["const", serialized]);
      this.unsupported(indexable, "Can't serialize indexable: ");
      return null;
    }
    serializeArray(x) {
      let serialized = new List.from([]);
      serialized.length = x.length;
      for (let i = 0; i < x.length; i++) {
        serialized.set(i, this.serialize(x.get(i)));
      }
      return serialized;
    }
    serializeArrayInPlace(x) {
      for (let i = 0; i < x.length; i++) {
        x.set(i, this.serialize(x.get(i)));
      }
      return x;
    }
    serializeMap(x) {
      let serializeTearOff = this.serialize;
      return new List.from(['map', x.keys.map(dart.as(serializeTearOff, dart.throw_("Unimplemented type (dynamic) → dynamic"))).toList(), x.values.map(dart.as(serializeTearOff, dart.throw_("Unimplemented type (dynamic) → dynamic"))).toList()]);
    }
    serializeJSObject(x) {
      if (dart.notNull(!!x.constructor) && dart.notNull(x.constructor !== Object)) {
        this.unsupported(x, "Only plain JS Objects are supported:");
      }
      let keys = dart.as(Object.keys(x), core.List);
      let values = new List.from([]);
      values.length = keys.length;
      for (let i = 0; i < keys.length; i++) {
        values.set(i, this.serialize(x[keys.get(i)]));
      }
      return new List.from(['js-object', keys, values]);
    }
    serializeWorkerSendPort(x) {
      if (this._serializeSendPorts) {
        return new List.from(['sendport', x._workerId, x._isolateId, x._receivePortId]);
      }
      return new List.from(['raw sendport', x]);
    }
    serializeJsSendPort(x) {
      if (this._serializeSendPorts) {
        let workerId = exports._globalState.currentManagerId;
        return new List.from(['sendport', workerId, x._isolateId, x._receivePort._id]);
      }
      return new List.from(['raw sendport', x]);
    }
    serializeCapability(x) {
      return new List.from(['capability', x._id]);
    }
    serializeClosure(x) {
      let name = IsolateNatives._getJSFunctionName(x);
      if (name === null) {
        this.unsupported(x, "Closures can't be transmitted:");
      }
      return new List.from(['function', name]);
    }
    serializeDartObject(x) {
      let classExtractor = _foreign_helper.JS_EMBEDDED_GLOBAL('', dart.as(_js_embedded_names.CLASS_ID_EXTRACTOR, core.String));
      let fieldsExtractor = _foreign_helper.JS_EMBEDDED_GLOBAL('', dart.as(_js_embedded_names.CLASS_FIELDS_EXTRACTOR, core.String));
      let classId = classExtractor(x);
      let fields = dart.as(fieldsExtractor(x), core.List);
      return new List.from(['dart', classId, this.serializeArrayInPlace(dart.as(fields, _interceptors.JSArray))]);
    }
  }
  class _Deserializer extends dart.Object {
    _Deserializer(opt$) {
      let adjustSendPorts = opt$.adjustSendPorts === void 0 ? true : opt$.adjustSendPorts;
      this.deserializedObjects = new core.List();
      this._adjustSendPorts = dart.as(adjustSendPorts, core.bool);
    }
    deserialize(x) {
      if (this.isPrimitive(x))
        return this.deserializePrimitive(x);
      if (!dart.is(x, _interceptors.JSArray))
        throw new core.ArgumentError(`Bad serialized message: ${x}`);
      switch (dart.dload(x, 'first')) {
        case "ref":
          return this.deserializeRef(x);
        case "buffer":
          return this.deserializeByteBuffer(x);
        case "typed":
          return this.deserializeTypedData(x);
        case "fixed":
          return this.deserializeFixed(x);
        case "extendable":
          return this.deserializeExtendable(x);
        case "mutable":
          return this.deserializeMutable(x);
        case "const":
          return this.deserializeConst(x);
        case "map":
          return this.deserializeMap(x);
        case "sendport":
          return this.deserializeSendPort(x);
        case "raw sendport":
          return this.deserializeRawSendPort(x);
        case "js-object":
          return this.deserializeJSObject(x);
        case "function":
          return this.deserializeClosure(x);
        case "dart":
          return this.deserializeDartObject(x);
        default:
          throw `couldn't deserialize: ${x}`;
      }
    }
    isPrimitive(x) {
      return dart.notNull(dart.notNull(dart.notNull(x === null) || dart.notNull(typeof x == string)) || dart.notNull(dart.is(x, core.num))) || dart.notNull(typeof x == boolean);
    }
    deserializePrimitive(x) {
      return x;
    }
    deserializeRef(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'ref'));
      let serializationId = dart.as(dart.dindex(x, 1), core.int);
      return this.deserializedObjects.get(serializationId);
    }
    deserializeByteBuffer(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'buffer'));
      let result = dart.as(dart.dindex(x, 1), _native_typed_data.NativeByteBuffer);
      this.deserializedObjects.add(result);
      return result;
    }
    deserializeTypedData(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'typed'));
      let result = dart.as(dart.dindex(x, 1), _native_typed_data.NativeTypedData);
      this.deserializedObjects.add(result);
      return result;
    }
    deserializeArrayInPlace(x) {
      for (let i = 0; i < x.length; i++) {
        x.set(i, this.deserialize(x.get(i)));
      }
      return x;
    }
    deserializeFixed(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'fixed'));
      let result = dart.as(dart.dindex(x, 1), core.List);
      this.deserializedObjects.add(result);
      return new _interceptors.JSArray.markFixed(this.deserializeArrayInPlace(dart.as(result, _interceptors.JSArray)));
    }
    deserializeExtendable(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'extendable'));
      let result = dart.as(dart.dindex(x, 1), core.List);
      this.deserializedObjects.add(result);
      return new _interceptors.JSArray.markGrowable(this.deserializeArrayInPlace(dart.as(result, _interceptors.JSArray)));
    }
    deserializeMutable(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'mutable'));
      let result = dart.as(dart.dindex(x, 1), core.List);
      this.deserializedObjects.add(result);
      return this.deserializeArrayInPlace(dart.as(result, _interceptors.JSArray));
    }
    deserializeConst(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'const'));
      let result = dart.as(dart.dindex(x, 1), core.List);
      this.deserializedObjects.add(result);
      return new _interceptors.JSArray.markFixed(this.deserializeArrayInPlace(dart.as(result, _interceptors.JSArray)));
    }
    deserializeMap(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'map'));
      let keys = dart.as(dart.dindex(x, 1), core.List);
      let values = dart.as(dart.dindex(x, 2), core.List);
      let result = dart.map();
      this.deserializedObjects.add(result);
      keys = keys.map(this.deserialize).toList();
      for (let i = 0; i < keys.length; i++) {
        result.set(keys.get(i), this.deserialize(values.get(i)));
      }
      return result;
    }
    deserializeSendPort(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'sendport'));
      let managerId = dart.as(dart.dindex(x, 1), core.int);
      let isolateId = dart.as(dart.dindex(x, 2), core.int);
      let receivePortId = dart.as(dart.dindex(x, 3), core.int);
      let result = null;
      if (managerId === exports._globalState.currentManagerId) {
        let isolate = exports._globalState.isolates.get(isolateId);
        if (isolate === null)
          return null;
        let receivePort = isolate.lookup(receivePortId);
        if (receivePort === null)
          return null;
        result = new _NativeJsSendPort(receivePort, isolateId);
      } else {
        result = new _WorkerSendPort(managerId, isolateId, receivePortId);
      }
      this.deserializedObjects.add(result);
      return result;
    }
    deserializeRawSendPort(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'raw sendport'));
      let result = dart.as(dart.dindex(x, 1), isolate.SendPort);
      this.deserializedObjects.add(result);
      return result;
    }
    deserializeJSObject(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'js-object'));
      let keys = dart.as(dart.dindex(x, 1), core.List);
      let values = dart.as(dart.dindex(x, 2), core.List);
      let o = {};
      this.deserializedObjects.add(o);
      for (let i = 0; i < keys.length; i++) {
        o[keys.get(i)] = this.deserialize(values.get(i));
      }
      return o;
    }
    deserializeClosure(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'function'));
      let name = dart.as(dart.dindex(x, 1), core.String);
      let result = dart.as(IsolateNatives._getJSFunctionFromName(name), core.Function);
      this.deserializedObjects.add(result);
      return result;
    }
    deserializeDartObject(x) {
      dart.assert(dart.equals(dart.dindex(x, 0), 'dart'));
      let classId = dart.as(dart.dindex(x, 1), core.String);
      let fields = dart.as(dart.dindex(x, 2), core.List);
      let instanceFromClassId = _foreign_helper.JS_EMBEDDED_GLOBAL('', dart.as(_js_embedded_names.INSTANCE_FROM_CLASS_ID, core.String));
      let initializeObject = _foreign_helper.JS_EMBEDDED_GLOBAL('', dart.as(_js_embedded_names.INITIALIZE_EMPTY_INSTANCE, core.String));
      let emptyInstance = instanceFromClassId(classId);
      this.deserializedObjects.add(emptyInstance);
      this.deserializeArrayInPlace(dart.as(fields, _interceptors.JSArray));
      return initializeObject(classId, emptyInstance, fields);
    }
  }
  // Exports:
  exports.enterJsAsync = enterJsAsync;
  exports.leaveJsAsync = leaveJsAsync;
  exports.isWorker = isWorker;
  exports.startRootIsolate = startRootIsolate;
  exports.globalWindow = globalWindow;
  exports.globalWorker = globalWorker;
  exports.globalPostMessageDefined = globalPostMessageDefined;
  exports.IsolateNatives = IsolateNatives;
  exports.RawReceivePortImpl = RawReceivePortImpl;
  exports.ReceivePortImpl = ReceivePortImpl;
  exports.TimerImpl = TimerImpl;
  exports.hasTimer = hasTimer;
  exports.CapabilityImpl = CapabilityImpl;
})(_isolate_helper || (_isolate_helper = {}));
