// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Concepts used here:
 *
 * "manager" - A manager contains one or more isolates, schedules their
 * execution, and performs other plumbing on their behalf.  The isolate
 * present at the creation of the manager is designated as its "root isolate".
 * A manager may, for example, be implemented on a web Worker.
 *
 * [_Manager] - State present within a manager (exactly once, as a global).
 *
 * [_ManagerStub] - A handle held within one manager that allows interaction
 * with another manager.  A target manager may be addressed by zero or more
 * [_ManagerStub]s.
 *
 */

/**
 * A native object that is shared across isolates. This object is visible to all
 * isolates running under the same manager (either UI or background web worker).
 *
 * This is code that is intended to 'escape' the isolate boundaries in order to
 * implement the semantics of isolates in JavaScript. Without this we would have
 * been forced to implement more code (including the top-level event loop) in
 * JavaScript itself.
 */
// TODO(eub, sigmund): move the "manager" to be entirely in JS.
// Running any Dart code outside the context of an isolate gives it
// the change to break the isolate abstraction.
_Manager get _globalState() native "return \$globalState;";
set _globalState(_Manager val) native "\$globalState = val;";

void _fillStatics(context) native @"""
  $globals = context.isolateStatics;
  $static_init();
""";

ReceivePort _port;

SendPort _spawnFunction(void topLevelFunction()) {
  final name = _IsolateNatives._getJSFunctionName(topLevelFunction);
  if (name == null) {
    throw new UnsupportedOperationException(
        "only top-level functions can be spawned.");
  }
  return _IsolateNatives._spawn2(name, null, false);
}

SendPort _spawnUri(String uri) {
  return _IsolateNatives._spawn2(null, uri, false);
}

/** State associated with the current manager. See [globalState]. */
// TODO(sigmund): split in multiple classes: global, thread, main-worker states?
class _Manager {

  /** Next available isolate id within this [_Manager]. */
  int nextIsolateId = 0;

  /** id assigned to this [_Manager]. */
  int currentManagerId = 0;

  /**
   * Next available manager id. Only used by the main manager to assign a unique
   * id to each manager created by it.
   */
  int nextManagerId = 1;

  /** Context for the currently running [Isolate]. */
  _IsolateContext currentContext = null;

  /** Context for the root [Isolate] that first run in this [_Manager]. */
  _IsolateContext rootContext = null;

  /** The top-level event loop. */
  _EventLoop topEventLoop;

  /** Whether this program is running from the command line. */
  bool fromCommandLine;

  /** Whether this [_Manager] is running as a web worker. */
  bool isWorker;

  /** Whether we support spawning web workers. */
  bool supportsWorkers;

  /**
   * Whether to use web workers when implementing isolates. Set to false for
   * debugging/testing.
   */
  bool get useWorkers() => supportsWorkers;

  /**
   * Whether to use the web-worker JSON-based message serialization protocol. By
   * default this is only used with web workers. For debugging, you can force
   * using this protocol by changing this field value to [true].
   */
  bool get needSerialization() => useWorkers;

  /**
   * Registry of isolates. Isolates must be registered if, and only if, receive
   * ports are alive.  Normally no open receive-ports means that the isolate is
   * dead, but DOM callbacks could resurrect it.
   */
  Map<int, _IsolateContext> isolates;

  /** Reference to the main [_Manager].  Null in the main [_Manager] itself. */
  _ManagerStub mainManager;

  /** Registry of active [_ManagerStub]s.  Only used in the main [_Manager]. */
  Map<int, _ManagerStub> managers;

  _Manager() {
    _nativeDetectEnvironment();
    topEventLoop = new _EventLoop();
    isolates = new Map<int, _IsolateContext>();
    managers = new Map<int, _ManagerStub>();
    if (isWorker) {  // "if we are not the main manager ourself" is the intent.
      mainManager = new _MainManagerStub();
      _nativeInitWorkerMessageHandler();
    }
  }

  void _nativeDetectEnvironment() native @"""
    this.isWorker = typeof ($globalThis['importScripts']) != 'undefined';
    this.fromCommandLine = typeof(window) == 'undefined';
    this.supportsWorkers = this.isWorker ||
        ((typeof $globalThis['Worker']) != 'undefined');
  """;

  void _nativeInitWorkerMessageHandler() native @"""
    $globalThis.onmessage = function (e) {
      _IsolateNatives._processWorkerMessage(this.mainManager, e);
    }
  """ {
    _IsolateNatives._processWorkerMessage(null, null);
  }

  /** Close the worker running this code if all isolates are done. */
  void maybeCloseWorker() {
    if (isolates.isEmpty()) {
      mainManager.postMessage(_serializeMessage({'command': 'close'}));
    }
  }
}

/** Context information tracked for each isolate. */
class _IsolateContext {
  /** Current isolate id. */
  int id;

  /** Registry of receive ports currently active on this isolate. */
  Map<int, ReceivePort> ports;

  /** Holds isolate globals (statics and top-level properties). */
  var isolateStatics; // native object containing all globals of an isolate.

  _IsolateContext() {
    id = _globalState.nextIsolateId++;
    ports = new Map<int, ReceivePort>();
    initGlobals();
  }

  // these are filled lazily the first time the isolate starts running.
  void initGlobals() native @'$initGlobals(this);';

  /**
   * Run [code] in the context of the isolate represented by [this]. Note this
   * is called from JavaScript (see $wrap_call in corejs.dart).
   */
  Dynamic eval(Function code) {
    var old = _globalState.currentContext;
    _globalState.currentContext = this;
    this._setGlobals();
    var result = null;
    try {
      result = code();
    } finally {
      _globalState.currentContext = old;
      if (old != null) old._setGlobals();
    }
    return result;
  }

  void _setGlobals() native @'$setGlobals(this);';

  /** Lookup a port registered for this isolate. */
  ReceivePort lookup(int portId) => ports[portId];

  /** Register a port on this isolate. */
  void register(int portId, ReceivePort port)  {
    if (ports.containsKey(portId)) {
      throw new Exception("Registry: ports must be registered only once.");
    }
    ports[portId] = port;
    _globalState.isolates[id] = this; // indicate this isolate is active
  }

  /** Unregister a port on this isolate. */
  void unregister(int portId) {
    ports.remove(portId);
    if (ports.isEmpty()) {
      _globalState.isolates.remove(id); // indicate this isolate is not active
    }
  }
}

// We don't want to import the DOM library just because of window.setTimeout,
// so we reconstruct the Window class here. The only conflict that could happen
// with the other DOMWindow class would be because of subclasses.
// Currently, none of the two Dart classes have subclasses.
typedef void _TimeoutHandler();
class _Window native "@*DOMWindow" {
  int setTimeout(_TimeoutHandler handler, int timeout) native;
}
_Window get _window() native
    """return typeof window != 'undefined' ? window : (void 0);""";

/** Represent the event loop on a javascript thread (DOM or worker). */
class _EventLoop {
  Queue<_IsolateEvent> events;

  _EventLoop() : events = new Queue<_IsolateEvent>();

  void enqueue(isolate, fn, msg) {
    events.addLast(new _IsolateEvent(isolate, fn, msg));
  }

  _IsolateEvent dequeue() {
    if (events.isEmpty()) return null;
    return events.removeFirst();
  }

  /** Process a single event, if any. */
  bool runIteration() {
    final event = dequeue();
    if (event == null) {
      if (_globalState.isWorker) {
        _globalState.maybeCloseWorker();
      } else if (_globalState.rootContext != null &&
                 _globalState.isolates.containsKey(
                     _globalState.rootContext.id) &&
                 _globalState.fromCommandLine &&
                 _globalState.rootContext.ports.isEmpty()) {
        // We want to reach here only on the main [_Manager] and only
        // on the command-line.  In the browser the isolate might
        // still be alive due to DOM callbacks, but the presumption is
        // that on the command-line, no future events can be injected
        // into the event queue once it's empty.  Node has setTimeout
        // so this presumption is incorrect there.  We think(?) that
        // in d8 this assumption is valid.
        throw new Exception("Program exited with open ReceivePorts.");
      }
      return false;
    }
    event.process();
    return true;
  }

  /**
   * Runs multiple iterations of the run-loop. If possible, each iteration is
   * run asynchronously.
   */
  void _runHelper() {
    if (_window != null) {
      // Run each iteration from the browser's top event loop.
      void next() {
        if (!runIteration()) return;
        _window.setTimeout(next, 0);
      }
      next();
    } else {
      // Run synchronously until no more iterations are available.
      while (runIteration()) {}
    }
  }

  /**
   * Call [_runHelper] but ensure that worker exceptions are propragated. Note
   * this is called from JavaScript (see $wrap_call in corejs.dart).
   */
  void run() {
    if (!_globalState.isWorker) {
      _runHelper();
    } else {
      try {
        _runHelper();
      } catch(var e, var trace) {
        _globalState.mainManager.postMessage(_serializeMessage(
            {'command': 'error', 'msg': '$e\n$trace' }));
      }
    }
  }
}

/** An event in the top-level event queue. */
class _IsolateEvent {
  _IsolateContext isolate;
  Function fn;
  String message;

  _IsolateEvent(this.isolate, this.fn, this.message);

  void process() {
    isolate.eval(fn);
  }
}

/** An interface for a stub used to interact with a manager. */
interface _ManagerStub {
  get id();
  void set id(int i);
  void set onmessage(Function f);
  void postMessage(msg);
  void terminate();
}

/** A stub for interacting with the main manager. */
class _MainManagerStub implements _ManagerStub {
  get id() => 0;
  void set id(int i) { throw new NotImplementedException(); }
  void set onmessage(f) {
    throw new Exception("onmessage should not be set on MainManagerStub");
  }
  void postMessage(msg) native @"$globalThis.postMessage(msg);";
  void terminate() {}  // Nothing useful to do here.
}

/**
 * A stub for interacting with a manager built on a web worker. The type
 * Worker is also defined in 'dart:dom', but we define it here to avoid
 * introducing a dependency from corelib to dom. This definition uses a
 * 'hidden' type (* prefix on the native name) to enforce that the type is
 * defined dynamically only when web workers are actually available.
 */
class _WorkerStub implements _ManagerStub native "*Worker" {
  get id() native "return this.id;";
  void set id(i) native "this.id = i;";
  void set onmessage(f) native "this.onmessage = f;";
  void postMessage(msg) native "return this.postMessage(msg);";
  // terminate() is implemented by Worker.
  abstract void terminate();
}

final String _SPAWNED_SIGNAL = "spawned";

class _IsolateNatives {

  /** JavaScript-specific implementation to spawn an isolate. */
  static Future<SendPort> spawn(Isolate isolate, bool isLight) {
    Completer<SendPort> completer = new Completer<SendPort>();
    ReceivePort port = new ReceivePort();
    port.receive((msg, SendPort replyPort) {
      port.close();
      assert(msg == _SPAWNED_SIGNAL);
      completer.complete(replyPort);
    });

    // TODO(floitsch): throw exception if isolate's class doesn't have a
    // default constructor.
    if (_globalState.useWorkers && !isLight) {
      _startWorker(isolate, port.toSendPort());
    } else {
      _startNonWorker(isolate, port.toSendPort());
    }

    return completer.future;
  }

  static SendPort _startWorker(Isolate runnable, SendPort replyPort) {
    var factoryName = _getJSConstructorName(runnable);
    if (_globalState.isWorker) {
      _globalState.mainManager.postMessage(_serializeMessage({
          'command': 'spawn-worker',
          'factoryName': factoryName,
          'replyPort': _serializeMessage(replyPort)}));
    } else {
      _spawnWorker(factoryName, _serializeMessage(replyPort));
    }
  }

  /**
   * The src url for the script tag that loaded this code. Used to create
   * JavaScript workers.
   */
  static String get _thisScript() {
    if (_thisScriptCache == null) {
      _thisScriptCache = _computeThisScript();
    }
    return _thisScriptCache;
  }

  static String _thisScriptCache;

  // TODO(sigmund): fix - this code should be run synchronously when loading the
  // script. Running lazily on DOMContentLoaded will yield incorrect results.
  static String _computeThisScript() native @"""
    if (!$globalState.supportsWorkers || $globalState.isWorker) return (void 0);

    // TODO(5334778): Find a cross-platform non-brittle way of getting the
    // currently running script.
    var scripts = document.getElementsByTagName('script');
    // The scripts variable only contains the scripts that have already been
    // executed. The last one is the currently running script.
    var script = scripts[scripts.length - 1];
    var src = script && script.src;
    if (!src) {
      // TODO()
      src = "FIXME:5407062" + "_" + Math.random().toString();
      if (script) script.src = src;
    }
    return src;
  """;

  /** Starts a new worker with the given URL. */
  static _WorkerStub _newWorker(url) native "return new Worker(url);";

  /**
   * Spawns an isolate in a worker. [factoryName] is the Javascript constructor
   * name for the isolate entry point class.
   */
  static void _spawnWorker(factoryName, serializedReplyPort) {
    final worker = _newWorker(_thisScript);
    worker.onmessage = (e) { _processWorkerMessage(worker, e); };
    var workerId = _globalState.nextManagerId++;
    // We also store the id on the worker itself so that we can unregister it.
    worker.id = workerId;
    _globalState.managers[workerId] = worker;
    worker.postMessage(_serializeMessage({
      'command': 'start',
      'id': workerId,
      'replyTo': serializedReplyPort,
      'factoryName': factoryName }));
  }

  /**
   * Assume that [e] is a browser message event and extract its message data.
   * We don't import the dom explicitly so, when workers are disabled, this
   * library can also run on top of nodejs.
   */
  static _getEventData(e) native "return e.data";

  /**
   * Process messages on a worker, either to control the worker instance or to
   * pass messages along to the isolate running in the worker.
   */
  static void _processWorkerMessage(sender, e) {
    var msg = _deserializeMessage(_getEventData(e));
    switch (msg['command']) {
      // TODO(sigmund): delete after we migrate to the new API
      case 'start':
        _globalState.currentManagerId = msg['id'];
        var runnerObject =
            _allocate(_getJSConstructorFromName(msg['factoryName']));
        var serializedReplyTo = msg['replyTo'];
        _globalState.topEventLoop.enqueue(new _IsolateContext(), function() {
          var replyTo = _deserializeMessage(serializedReplyTo);
          _startIsolate(runnerObject, replyTo);
        }, 'worker-start');
        _globalState.topEventLoop.run();
        break;
      case 'start2':
        _globalState.currentManagerId = msg['id'];
        Function entryPoint = _getJSFunctionFromName(msg['functionName']);
        var replyTo = _deserializeMessage(msg['replyTo']);
        _globalState.topEventLoop.enqueue(new _IsolateContext(), function() {
          _startIsolate2(entryPoint, replyTo);
        }, 'worker-start');
        _globalState.topEventLoop.run();
        break;
      // TODO(sigmund): delete after we migrate to the new API
      case 'spawn-worker':
        _spawnWorker(msg['factoryName'], msg['replyPort']);
        break;
      case 'spawn-worker2':
        _spawnWorker2(msg['functionName'], msg['uri'], msg['replyPort']);
        break;
      case 'message':
        msg['port'].send(msg['msg'], msg['replyTo']);
        _globalState.topEventLoop.run();
        break;
      case 'close':
        _log("Closing Worker");
        _globalState.managers.remove(sender.id);
        sender.terminate();
        _globalState.topEventLoop.run();
        break;
      case 'log':
        _log(msg['msg']);
        break;
      case 'print':
        if (_globalState.isWorker) {
          _globalState.mainManager.postMessage(
              _serializeMessage({'command': 'print', 'msg': msg}));
        } else {
          print(msg['msg']);
        }
        break;
      case 'error':
        throw msg['msg'];
    }
  }

  /** Log a message, forwarding to the main [_Manager] if appropriate. */
  static _log(msg) {
    if (_globalState.isWorker) {
      _globalState.mainManager.postMessage(
          _serializeMessage({'command': 'log', 'msg': msg }));
    } else {
      try {
        _consoleLog(msg);
      } catch(var e, var trace) {
        throw new Exception(trace);
      }
    }
  }

  static void _consoleLog(msg) native "\$globalThis.console.log(msg);";


  /**
   * Extract the constructor of runnable, so it can be allocated in another
   * isolate.
   */
  static Dynamic _getJSConstructor(Isolate runnable) native """
    return runnable.constructor;
  """;

  /** Extract the constructor name of a runnable */
  // TODO(sigmund): find a browser-generic way to support this.
  static Dynamic _getJSConstructorName(Isolate runnable) native """
    return runnable.constructor.name;
  """;

  /** Find a constructor given its name. */
  static Dynamic _getJSConstructorFromName(String factoryName) native """
    return \$globalThis[factoryName];
  """;

  static Dynamic _getJSFunctionFromName(String functionName) native """
    return \$globalThis[functionName];
  """;

  /**
   * Get a string name for the function, if possible.  The result for
   * anonymous functions is browser-dependent -- it may be "" or "anonymous"
   * but you should probably not count on this.
   */
  static String _getJSFunctionName(Function f)
    // Comments on the code, outside of the string so they won't bulk up
    // the native output:
    //
    // Are we in a browser that implements the non-standard but
    // oh-so-convenient function .name property?  If not, parse the name
    // out of toString().
    //
    // When there is a match, our capture is element 1 of the results list.
    // If there is no match, match() returns null; we || this to a list
    // whose element 1 is null so everything lines up without error.
    //
    // TODO(eub): remove the toString workaround by attaching names to
    // functions where they could be needed.  For a simple
    // conservative approximation of "needed", see Siggi's option (c)
    // in discussion on the CL, 9416119.
    native @"""
    if (typeof(f.name) === 'undefined') {
      return (f.toString().match(/function (.+)\(/) || [, (void 0)])[1];
    } else {
      return f.name || (void 0);
    }
  """;

  /** Create a new JavaScript object instance given its constructor. */
  static Dynamic _allocate(var ctor) native "return new ctor();";

  /** Starts a non-worker isolate. */
  static SendPort _startNonWorker(Isolate runnable, SendPort replyTo) {
    // Spawn a new isolate and create the receive port in it.
    final spawned = new _IsolateContext();

    // Instead of just running the provided runnable, we create a
    // new cloned instance of it with a fresh state in the spawned
    // isolate. This way, we do not get cross-isolate references
    // through the runnable.
    final ctor = _getJSConstructor(runnable);
    _globalState.topEventLoop.enqueue(spawned, function() {
      _startIsolate(_allocate(ctor), replyTo);
    }, 'nonworker start');
  }

  /** Given a ready-to-start runnable, start running it. */
  static void _startIsolate(Isolate isolate, SendPort replyTo) {
    _fillStatics(_globalState.currentContext);
    ReceivePort port = new ReceivePort();
    replyTo.send(_SPAWNED_SIGNAL, port.toSendPort());
    isolate._run(port);
  }

  // TODO(sigmund): clean up above, after we make the new API the default:

  static _spawn2(String functionName, String uri, bool isLight) {
    Completer<SendPort> completer = new Completer<SendPort>();
    ReceivePort port = new ReceivePort();
    port.receive((msg, SendPort replyPort) {
      port.close();
      assert(msg == _SPAWNED_SIGNAL);
      completer.complete(replyPort);
    });

    SendPort signalReply = port.toSendPort();

    if (_globalState.useWorkers && !isLight) {
      _startWorker2(functionName, uri, signalReply);
    } else {
      _startNonWorker2(functionName, uri, signalReply);
    }
    return new _BufferingSendPort(
        _globalState.currentContext.id, completer.future);
  }

  static SendPort _startWorker2(
      String functionName, String uri, SendPort replyPort) {
    if (_globalState.isWorker) {
      _globalState.mainManager.postMessage(_serializeMessage({
          'command': 'spawn-worker2',
          'functionName': functionName,
          'uri': uri,
          'replyPort': replyPort}));
    } else {
      _spawnWorker2(functionName, uri, replyPort);
    }
  }

  static SendPort _startNonWorker2(
      String functionName, String uri, SendPort replyPort) {
    // TODO(eub): support IE9 using an iframe -- Dart issue 1702.
    if (uri != null) throw new UnsupportedOperationException(
            "Currently spawnUri is not supported without web workers.");
    _globalState.topEventLoop.enqueue(new _IsolateContext(), function() {
      final func = _getJSFunctionFromName(functionName);
      _startIsolate2(func, replyPort);
    }, 'nonworker start');
  }

  static void _startIsolate2(Function topLevel, SendPort replyTo) {
    _fillStatics(_globalState.currentContext);
    _port = new ReceivePort();
    replyTo.send(_SPAWNED_SIGNAL, port.toSendPort());
    topLevel();
  }

  /**
   * Spawns an isolate in a worker. [factoryName] is the Javascript constructor
   * name for the isolate entry point class.
   */
  static void _spawnWorker2(functionName, uri, replyPort) {
    if (functionName == null) functionName = 'main';
    if (uri == null) uri = _thisScript;
    if (!(new Uri.fromString(uri).isAbsolute())) {
      // The constructor of dom workers requires an absolute URL. If we use a
      // relative path we will get a DOM exception.
      String prefix = _thisScript.substring(0, _thisScript.lastIndexOf('/'));
      uri = "$prefix/$uri";
    }
    final worker = _newWorker(uri);
    worker.onmessage = (e) { _processWorkerMessage(worker, e); };
    var workerId = _globalState.nextManagerId++;
    // We also store the id on the worker itself so that we can unregister it.
    worker.id = workerId;
    _globalState.managers[workerId] = worker;
    worker.postMessage(_serializeMessage({
      'command': 'start2',
      'id': workerId,
      // Note: we serialize replyPort twice because the child worker needs to
      // first deserialize the worker id, before it can correctly deserialize
      // the port (port deserialization is sensitive to what is the current
      // workerId).
      'replyTo': _serializeMessage(replyPort),
      'functionName': functionName }));
  }
}
