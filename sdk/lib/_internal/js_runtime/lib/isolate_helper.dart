// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _isolate_helper;

import 'dart:_js_embedded_names'
    show
        CLASS_ID_EXTRACTOR,
        CLASS_FIELDS_EXTRACTOR,
        CREATE_NEW_ISOLATE,
        CURRENT_SCRIPT,
        INITIALIZE_EMPTY_INSTANCE,
        INSTANCE_FROM_CLASS_ID,
        STATIC_FUNCTION_NAME_PROPERTY_NAME;

import 'dart:async';
import 'dart:collection' show Queue;
import 'dart:isolate';
import 'dart:_native_typed_data' show NativeByteBuffer, NativeTypedData;

import 'dart:_js_helper'
    show
        Closure,
        InternalMap,
        Primitives,
        convertDartClosureToJS,
        createDartClosureFromNameOfStaticFunction,
        isDartObject,
        random64,
        requiresPreamble;

import 'dart:_foreign_helper'
    show
        DART_CLOSURE_TO_JS,
        JS,
        JS_CURRENT_ISOLATE_CONTEXT,
        JS_EMBEDDED_GLOBAL,
        JS_SET_STATIC_STATE,
        IsolateContext;

import 'dart:_interceptors'
    show
        Interceptor,
        JSArray,
        JSExtendableArray,
        JSFixedArray,
        JSIndexable,
        JSMutableArray,
        JSObject;

part 'isolate_serialization.dart';

/**
 * Called by the compiler to support switching
 * between isolates when we get a callback from the DOM.
 */
_callInIsolate(_IsolateContext isolate, Function function) {
  var result = isolate.eval(function);
  // If we are not already running the event-loop start it now.
  if (!_currentIsolate()._isExecutingEvent) _globalState.topEventLoop.run();
  return result;
}

/// Marks entering a JavaScript async operation to keep the worker alive.
///
/// To be called by library code before starting an async operation controlled
/// by the JavaScript event handler.
///
/// Also call [leaveJsAsync] in all callback handlers marking the end of that
/// async operation (also error handlers) so the worker can be released.
///
/// These functions only has to be called for code that can be run from a
/// worker-isolate (so not for general dom operations).
enterJsAsync() {
  _globalState.topEventLoop._activeJsAsyncCount++;
}

/// Marks leaving a javascript async operation.
///
/// See [enterJsAsync].
leaveJsAsync() {
  _globalState.topEventLoop._activeJsAsyncCount--;
  assert(_globalState.topEventLoop._activeJsAsyncCount >= 0);
}

/// Returns true if we are currently in a worker context.
bool isWorker() => _globalState.isWorker;

/**
 * Called by the compiler to fetch the current isolate context.
 */
_IsolateContext _currentIsolate() => _globalState.currentContext;

/**
 * Wrapper that takes the dart entry point and runs it within an isolate. The
 * dart2js compiler will inject a call of the form
 * [: startRootIsolate(main); :] when it determines that this wrapping
 * is needed. For single-isolate applications (e.g. hello world), this
 * call is not emitted.
 */
void startRootIsolate(entry, args) {
  if (args == null) args = [];
  if (args is! List) {
    throw new ArgumentError("Arguments to main must be a List: $args");
  }
  _globalState = new _Manager(entry);
  _globalState._initialize();

  // Don't start the main loop again, if we are in a worker.
  if (_globalState.isWorker) return;
  final rootContext = new _IsolateContext();
  _globalState.rootContext = rootContext;
  _globalState.isolates[rootContext.id] = rootContext;

  // BUG(5151491): Setting currentContext should not be necessary, but
  // because closures passed to the DOM as event handlers do not bind their
  // isolate automatically we try to give them a reasonable context to live in
  // by having a "default" isolate (the first one created).
  _globalState.currentContext = rootContext;
  if (entry is _MainFunctionArgs) {
    rootContext.eval(() {
      entry(args);
    });
  } else if (entry is _MainFunctionArgsMessage) {
    rootContext.eval(() {
      entry(args, null);
    });
  } else {
    rootContext.eval(entry);
  }
  _globalState.topEventLoop.run();
}

/********************************************************
  Inserted from lib/isolate/dart2js/isolateimpl.dart
 ********************************************************/

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
 * TODO(ahe): The _ManagerStub concept is broken.  It was an attempt
 * to create a common interface between the native Worker class and
 * _MainManagerStub.
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
// the chance to break the isolate abstraction.
_Manager get _globalState => JS('_Manager', 'init.globalState');

set _globalState(_Manager val) {
  JS('void', 'init.globalState = #', val);
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
  bool get useWorkers => supportsWorkers;

  /**
   * Registry of isolates. Isolates must be registered if, and only if, receive
   * ports are alive.  Normally no open receive-ports means that the isolate is
   * dead, but DOM callbacks could resurrect it.
   */
  Map<int, _IsolateContext> isolates;

  /** Reference to the main [_Manager].  Null in the main [_Manager] itself. */
  _MainManagerStub mainManager;

  /// Registry of active Web Workers.  Only used in the main [_Manager].
  Map<int, dynamic /* Worker */ > managers;

  /** The entry point given by [startRootIsolate]. */
  final Function entry;

  _Manager(this.entry);

  _initialize() {
    _nativeDetectEnvironment();
    topEventLoop = new _EventLoop();
    isolates = new Map<int, _IsolateContext>();
    managers = new Map<int, dynamic>();
    if (isWorker) {
      // "if we are not the main manager ourself" is the intent.
      mainManager = new _MainManagerStub();
      _nativeInitWorkerMessageHandler();
    }
  }

  void _nativeDetectEnvironment() {
    bool isWindowDefined = globalWindow != null;
    bool isWorkerDefined = globalWorker != null;

    // `isWorker` must be initialized now, since `IsolateNatives.thisScript`
    // may access it.
    isWorker = !isWindowDefined && globalPostMessageDefined;
    supportsWorkers =
        isWorker || (isWorkerDefined && IsolateNatives.thisScript != null);
    fromCommandLine = !isWindowDefined && !isWorker;
  }

  void _nativeInitWorkerMessageHandler() {
    var function = JS(
        '',
        '(function (f, a) { return function (e) { f(a, e); }})(#, #)',
        DART_CLOSURE_TO_JS(IsolateNatives._processWorkerMessage),
        mainManager);
    JS('void', r'self.onmessage = #', function);
    // We ensure dartPrint is defined so that the implementation of the Dart
    // print method knows what to call.
    JS(
        '',
        '''self.dartPrint = self.dartPrint || (function(serialize) {
  return function (object) {
    if (self.console && self.console.log) {
      self.console.log(object)
    } else {
      self.postMessage(serialize(object));
    }
  }
})(#)''',
        DART_CLOSURE_TO_JS(_serializePrintMessage));
  }

  static _serializePrintMessage(object) {
    return _serializeMessage({'command': 'print', 'msg': object});
  }

  /**
   * Close the worker running this code if all isolates are done and
   * there are no active async JavaScript tasks still running.
   */
  void maybeCloseWorker() {
    if (isWorker && isolates.isEmpty && topEventLoop._activeJsAsyncCount == 0) {
      mainManager.postMessage(_serializeMessage({'command': 'close'}));
    }
  }
}

/** Context information tracked for each isolate. */
class _IsolateContext implements IsolateContext {
  /** Current isolate id. */
  final int id = _globalState.nextIsolateId++;

  /** Registry of receive ports currently active on this isolate. */
  final Map<int, RawReceivePortImpl> ports = new Map<int, RawReceivePortImpl>();

  /** Registry of weak receive ports currently active on this isolate. */
  final Set<int> weakPorts = new Set<int>();

  /** Holds isolate globals (statics and top-level properties). */
  // native object containing all globals of an isolate.
  final isolateStatics =
      JS('', '#()', JS_EMBEDDED_GLOBAL('', CREATE_NEW_ISOLATE));

  final RawReceivePortImpl controlPort = new RawReceivePortImpl._controlPort();

  final Capability pauseCapability = new Capability();
  final Capability terminateCapability = new Capability(); // License to kill.

  /// Boolean flag set when the initial method of the isolate has been executed.
  ///
  /// Used to avoid considering the isolate dead when it has no open
  /// receive ports and no scheduled timers, because it hasn't had time to
  /// create them yet.
  bool initialized = false;

  // TODO(lrn): Store these in single "PauseState" object, so they don't take
  // up as much room when not pausing.
  bool isPaused = false;
  List<_IsolateEvent> delayedEvents = [];
  Set<Capability> pauseTokens = new Set();

  // Container with the "on exit" handler send-ports and responses.
  var doneHandlers;

  /**
   * Queue of functions to call when the current event is complete.
   *
   * These events are not just put at the front of the event queue, because
   * they represent control messages, and should be handled even if the
   * event queue is paused.
   */
  var _scheduledControlEvents;
  bool _isExecutingEvent = false;

  /** Whether uncaught errors are considered fatal. */
  bool errorsAreFatal = true;

  // Set of ports that listen to uncaught errors.
  Set<SendPort> errorPorts = new Set();

  _IsolateContext() {
    this.registerWeak(controlPort._id, controlPort);
  }

  void addPause(Capability authentification, Capability resume) {
    if (pauseCapability != authentification) return;
    if (pauseTokens.add(resume) && !isPaused) {
      isPaused = true;
    }
    _updateGlobalState();
  }

  void removePause(Capability resume) {
    if (!isPaused) return;
    pauseTokens.remove(resume);
    if (pauseTokens.isEmpty) {
      while (delayedEvents.isNotEmpty) {
        _IsolateEvent event = delayedEvents.removeLast();
        _globalState.topEventLoop.prequeue(event);
      }
      isPaused = false;
    }
    _updateGlobalState();
  }

  void addDoneListener(SendPort responsePort, Object response) {
    if (doneHandlers == null) {
      doneHandlers = [];
    }
    for (int i = 0; i < doneHandlers.length; i += 2) {
      if (responsePort == doneHandlers[i]) {
        doneHandlers[i + 1] = response;
        return;
      }
    }
    doneHandlers.add(responsePort);
    doneHandlers.add(response);
  }

  void removeDoneListener(SendPort responsePort) {
    if (doneHandlers == null) return;
    for (int i = 0; i < doneHandlers.length; i += 2) {
      if (responsePort == doneHandlers[i]) {
        doneHandlers.removeRange(i, i + 2);
        return;
      }
    }
  }

  void setErrorsFatal(Capability authentification, bool errorsAreFatal) {
    if (terminateCapability != authentification) return;
    this.errorsAreFatal = errorsAreFatal;
  }

  void handlePing(SendPort responsePort, int pingType, Object response) {
    if (pingType == Isolate.IMMEDIATE ||
        (pingType == Isolate.BEFORE_NEXT_EVENT && !_isExecutingEvent)) {
      responsePort.send(response);
      return;
    }
    void respond() {
      responsePort.send(response);
    }

    assert(pingType == Isolate.BEFORE_NEXT_EVENT);
    if (_scheduledControlEvents == null) {
      _scheduledControlEvents = new Queue();
    }
    _scheduledControlEvents.addLast(respond);
  }

  void handleKill(Capability authentification, int priority) {
    if (this.terminateCapability != authentification) return;
    if (priority == Isolate.IMMEDIATE ||
        (priority == Isolate.BEFORE_NEXT_EVENT && !_isExecutingEvent)) {
      kill();
      return;
    }
    assert(priority == Isolate.BEFORE_NEXT_EVENT);
    if (_scheduledControlEvents == null) {
      _scheduledControlEvents = new Queue();
    }
    _scheduledControlEvents.addLast(kill);
  }

  void addErrorListener(SendPort port) {
    errorPorts.add(port);
  }

  void removeErrorListener(SendPort port) {
    errorPorts.remove(port);
  }

  /** Function called with an uncaught error. */
  void handleUncaughtError(error, StackTrace stackTrace) {
    // Just print the error if there is no error listener registered.
    if (errorPorts.isEmpty) {
      // An uncaught error in the root isolate will terminate the program?
      if (errorsAreFatal && identical(this, _globalState.rootContext)) {
        // The error will be rethrown to reach the global scope, so
        // don't print it.
        return;
      }
      if (JS('bool', 'self.console && self.console.error')) {
        JS('void', 'self.console.error(#, #)', error, stackTrace);
      } else {
        print(error);
        if (stackTrace != null) print(stackTrace);
      }
      return;
    }
    List message = new List(2)
      ..[0] = error.toString()
      ..[1] = (stackTrace == null) ? null : stackTrace.toString();
    for (SendPort port in errorPorts) port.send(message);
  }

  /**
   * Run [code] in the context of the isolate represented by [this].
   */
  dynamic eval(Function code) {
    var old = _globalState.currentContext;
    _globalState.currentContext = this;
    this._setGlobals();
    var result = null;
    var oldIsExecutingEvent = _isExecutingEvent;
    _isExecutingEvent = true;
    try {
      result = code();
    } catch (e, s) {
      handleUncaughtError(e, s);
      if (errorsAreFatal) {
        kill();
        // An uncaught error in the root context terminates all isolates.
        if (identical(this, _globalState.rootContext)) {
          rethrow;
        }
      }
    } finally {
      _isExecutingEvent = oldIsExecutingEvent;
      _globalState.currentContext = old;
      if (old != null) old._setGlobals();
      if (_scheduledControlEvents != null) {
        while (_scheduledControlEvents.isNotEmpty) {
          (_scheduledControlEvents.removeFirst())();
        }
      }
    }
    return result;
  }

  void _setGlobals() {
    JS_SET_STATIC_STATE(isolateStatics);
  }

  /**
   * Handle messages coming in on the control port.
   *
   * These events do not go through the event queue.
   * The `_globalState.currentContext` context is not set to this context
   * during the handling.
   */
  void handleControlMessage(message) {
    switch (message[0]) {
      case 'pause':
        addPause(message[1], message[2]);
        break;
      case 'resume':
        removePause(message[1]);
        break;
      case 'add-ondone':
        addDoneListener(message[1], message[2]);
        break;
      case 'remove-ondone':
        removeDoneListener(message[1]);
        break;
      case 'set-errors-fatal':
        setErrorsFatal(message[1], message[2]);
        break;
      case 'ping':
        handlePing(message[1], message[2], message[3]);
        break;
      case 'kill':
        handleKill(message[1], message[2]);
        break;
      case 'getErrors':
        addErrorListener(message[1]);
        break;
      case 'stopErrors':
        removeErrorListener(message[1]);
        break;
      default:
    }
  }

  /** Looks up a port registered for this isolate. */
  RawReceivePortImpl lookup(int portId) => ports[portId];

  void _addRegistration(int portId, RawReceivePortImpl port) {
    if (ports.containsKey(portId)) {
      throw new Exception('Registry: ports must be registered only once.');
    }
    ports[portId] = port;
  }

  /** Registers a port on this isolate. */
  void register(int portId, RawReceivePortImpl port) {
    _addRegistration(portId, port);
    _updateGlobalState();
  }

  /**
   * Registers a weak port on this isolate.
   *
   * The port does not keep the isolate active.
   */
  void registerWeak(int portId, RawReceivePortImpl port) {
    weakPorts.add(portId);
    _addRegistration(portId, port);
  }

  void _updateGlobalState() {
    if (ports.length - weakPorts.length > 0 || isPaused || !initialized) {
      _globalState.isolates[id] = this; // indicate this isolate is active
    } else {
      kill();
    }
  }

  void kill() {
    if (_scheduledControlEvents != null) {
      // Kill all pending events.
      _scheduledControlEvents.clear();
    }
    // Stop listening on all ports.
    // This should happen before sending events to done handlers, in case
    // we are listening on ourselves.
    // Closes all ports, including control port.
    for (var port in ports.values) {
      port._close();
    }
    ports.clear();
    weakPorts.clear();
    _globalState.isolates.remove(id); // indicate this isolate is not active
    errorPorts.clear();
    if (doneHandlers != null) {
      for (int i = 0; i < doneHandlers.length; i += 2) {
        SendPort responsePort = doneHandlers[i];
        Object response = doneHandlers[i + 1];
        responsePort.send(response);
      }
      doneHandlers = null;
    }
  }

  /** Unregister a port on this isolate. */
  void unregister(int portId) {
    ports.remove(portId);
    weakPorts.remove(portId);
    _updateGlobalState();
  }
}

/** Represent the event loop on a javascript thread (DOM or worker). */
class _EventLoop {
  final Queue<_IsolateEvent> events = new Queue<_IsolateEvent>();

  /// The number of waiting callbacks not controlled by the dart event loop.
  ///
  /// This could be timers or http requests. The worker will only be killed if
  /// this count reaches 0.
  /// Access this by using [enterJsAsync] before starting a JavaScript async
  /// operation and [leaveJsAsync] when the callback has fired.
  int _activeJsAsyncCount = 0;

  _EventLoop();

  void enqueue(isolate, fn, msg) {
    events.addLast(new _IsolateEvent(isolate, fn, msg));
  }

  void prequeue(_IsolateEvent event) {
    events.addFirst(event);
  }

  _IsolateEvent dequeue() {
    if (events.isEmpty) return null;
    return events.removeFirst();
  }

  void checkOpenReceivePortsFromCommandLine() {
    if (_globalState.rootContext != null &&
        _globalState.isolates.containsKey(_globalState.rootContext.id) &&
        _globalState.fromCommandLine &&
        _globalState.rootContext.ports.isEmpty) {
      // We want to reach here only on the main [_Manager] and only
      // on the command-line.  In the browser the isolate might
      // still be alive due to DOM callbacks, but the presumption is
      // that on the command-line, no future events can be injected
      // into the event queue once it's empty.  Node has setTimeout
      // so this presumption is incorrect there.  We think(?) that
      // in d8 this assumption is valid.
      throw new Exception('Program exited with open ReceivePorts.');
    }
  }

  /** Process a single event, if any. */
  bool runIteration() {
    final event = dequeue();
    if (event == null) {
      checkOpenReceivePortsFromCommandLine();
      _globalState.maybeCloseWorker();
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
    if (globalWindow != null) {
      // Run each iteration from the browser's top event loop.
      void next() {
        if (!runIteration()) return;
        Timer.run(next);
      }

      next();
    } else {
      // Run synchronously until no more iterations are available.
      while (runIteration()) {}
    }
  }

  /**
   * Call [_runHelper] but ensure that worker exceptions are propagated.
   */
  void run() {
    if (!_globalState.isWorker) {
      _runHelper();
    } else {
      try {
        _runHelper();
      } catch (e, trace) {
        _globalState.mainManager.postMessage(
            _serializeMessage({'command': 'error', 'msg': '$e\n$trace'}));
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
    if (isolate.isPaused) {
      isolate.delayedEvents.add(this);
      return;
    }
    isolate.eval(fn);
  }
}

/** A stub for interacting with the main manager. */
class _MainManagerStub {
  void postMessage(msg) {
    // "self" is a way to refer to the global context object that
    // works in HTML pages and in Web Workers.  It does not work in d8
    // and Firefox jsshell, because that would have been too easy.
    //
    // See: http://www.w3.org/TR/workers/#the-global-scope
    // and: http://www.w3.org/TR/Window/#dfn-self-attribute
    requiresPreamble();
    JS('void', r'self.postMessage(#)', msg);
  }
}

const String _SPAWNED_SIGNAL = 'spawned';
const String _SPAWN_FAILED_SIGNAL = 'spawn failed';

get globalWindow {
  requiresPreamble();
  return JS('', 'self.window');
}

get globalWorker {
  requiresPreamble();
  return JS('', 'self.Worker');
}

bool get globalPostMessageDefined {
  requiresPreamble();
  return JS('bool', '!!self.postMessage');
}

typedef _MainFunction();
typedef _MainFunctionArgs(args);
typedef _MainFunctionArgsMessage(args, message);

/// Note: IsolateNatives depends on _globalState which is only set up correctly
/// when 'dart:isolate' has been imported.
class IsolateNatives {
  // We set [enableSpawnWorker] to true (not null) when calling isolate
  // primitives that require support for spawning workers. The field starts out
  // by being null, and dart2js' type inference will track if it can have a
  // non-null value. So by testing if this value is not null, we generate code
  // that dart2js knows is dead when worker support isn't needed.
  // TODO(herhut): Initialize this to false when able to track compile-time
  // constants.
  static var enableSpawnWorker;

  static String thisScript = computeThisScript();

  /// Returns the base path added to Uri.base to resolve `package:` Uris.
  ///
  /// This is used by `Isolate.resolvePackageUri` to load resources. The default
  /// value is `packages/` but users can override this by using the
  /// `defaultPackagesBase` hook.
  static String get packagesBase =>
      JS('String', r'self.defaultPackagesBase || "packages/"');

  /// Associates an ID with a native worker object.
  static final Expando<int> workerIds = new Expando<int>();

  /**
   * The src url for the script tag that loaded this function.
   *
   * Used to create JavaScript workers and load deferred libraries.
   */
  static String computeThisScript() {
    var currentScript = JS_EMBEDDED_GLOBAL('', CURRENT_SCRIPT);
    if (currentScript != null) {
      return JS('String', 'String(#.src)', currentScript);
    }
    // A worker has no script tag - so get an url from a stack-trace.
    if (_globalState.isWorker) return computeThisScriptFromTrace();
    // An isolate that doesn't support workers, but doesn't have a
    // currentScript either. This is most likely a Chrome extension.
    return null;
  }

  static String computeThisScriptFromTrace() {
    var stack = JS('String|Null', 'new Error().stack');
    if (stack == null) {
      // According to Internet Explorer documentation, the stack
      // property is not set until the exception is thrown. The stack
      // property was not provided until IE10.
      stack = JS(
          'String|Null',
          '(function() {'
          'try { throw new Error() } catch(e) { return e.stack }'
          '})()');
      if (stack == null) throw new UnsupportedError('No stack trace');
    }
    var pattern, matches;

    // This pattern matches V8, Chrome, and Internet Explorer stack
    // traces that look like this:
    // Error
    //     at methodName (URI:LINE:COLUMN)
    pattern =
        JS('', r'new RegExp("^ *at [^(]*\\((.*):[0-9]*:[0-9]*\\)$", "m")');

    matches = JS('JSExtendableArray|Null', '#.match(#)', stack, pattern);
    if (matches != null) return JS('String', '#[1]', matches);

    // This pattern matches Firefox stack traces that look like this:
    // methodName@URI:LINE
    pattern = JS('', r'new RegExp("^[^@]*@(.*):[0-9]*$", "m")');

    matches = JS('JSExtendableArray|Null', '#.match(#)', stack, pattern);
    if (matches != null) return JS('String', '#[1]', matches);

    throw new UnsupportedError('Cannot extract URI from "$stack"');
  }

  /**
   * Assume that [e] is a browser message event and extract its message data.
   * We don't import the dom explicitly so, when workers are disabled, this
   * library can also run on top of nodejs.
   */
  static _getEventData(e) => JS('', '#.data', e);

  /**
   * Process messages on a worker, either to control the worker instance or to
   * pass messages along to the isolate running in the worker.
   */
  static void _processWorkerMessage(/* Worker */ sender, e) {
    var msg = _deserializeMessage(_getEventData(e));
    switch (msg['command']) {
      case 'start':
        _globalState.currentManagerId = msg['id'];
        String functionName = msg['functionName'];
        Function entryPoint = (functionName == null)
            ? _globalState.entry
            : _getJSFunctionFromName(functionName);
        var args = msg['args'];
        var message = _deserializeMessage(msg['msg']);
        var isSpawnUri = msg['isSpawnUri'];
        var startPaused = msg['startPaused'];
        var replyTo = _deserializeMessage(msg['replyTo']);
        var context = new _IsolateContext();
        _globalState.topEventLoop.enqueue(context, () {
          _startIsolate(
              entryPoint, args, message, isSpawnUri, startPaused, replyTo);
        }, 'worker-start');
        // Make sure we always have a current context in this worker.
        // TODO(7907): This is currently needed because we're using
        // Timers to implement Futures, and this isolate library
        // implementation uses Futures. We should either stop using
        // Futures in this library, or re-adapt if Futures get a
        // different implementation.
        _globalState.currentContext = context;
        _globalState.topEventLoop.run();
        break;
      case 'spawn-worker':
        if (enableSpawnWorker != null) handleSpawnWorkerRequest(msg);
        break;
      case 'message':
        SendPort port = msg['port'];
        // If the port has been closed, we ignore the message.
        if (port != null) {
          msg['port'].send(msg['msg']);
        }
        _globalState.topEventLoop.run();
        break;
      case 'close':
        _globalState.managers.remove(workerIds[sender]);
        JS('void', '#.terminate()', sender);
        _globalState.topEventLoop.run();
        break;
      case 'log':
        _log(msg['msg']);
        break;
      case 'print':
        if (_globalState.isWorker) {
          _globalState.mainManager
              .postMessage(_serializeMessage({'command': 'print', 'msg': msg}));
        } else {
          print(msg['msg']);
        }
        break;
      case 'error':
        throw msg['msg'];
    }
  }

  static handleSpawnWorkerRequest(msg) {
    var replyPort = msg['replyPort'];
    spawn(msg['functionName'], msg['uri'], msg['args'], msg['msg'], false,
        msg['isSpawnUri'], msg['startPaused']).then((msg) {
      replyPort.send(msg);
    }, onError: (String errorMessage) {
      replyPort.send([_SPAWN_FAILED_SIGNAL, errorMessage]);
    });
  }

  /** Log a message, forwarding to the main [_Manager] if appropriate. */
  static _log(msg) {
    if (_globalState.isWorker) {
      _globalState.mainManager
          .postMessage(_serializeMessage({'command': 'log', 'msg': msg}));
    } else {
      try {
        _consoleLog(msg);
      } catch (e, trace) {
        throw new Exception(trace);
      }
    }
  }

  static void _consoleLog(msg) {
    requiresPreamble();
    JS('void', r'self.console.log(#)', msg);
  }

  static _getJSFunctionFromName(String functionName) {
    return createDartClosureFromNameOfStaticFunction(functionName);
  }

  /**
   * Get a string name for the function, if possible.  The result for
   * anonymous functions is browser-dependent -- it may be "" or "anonymous"
   * but you should probably not count on this.
   */
  static String _getJSFunctionName(Function f) {
    return (f is Closure)
        ? JS('String|Null', r'#[#]', f, STATIC_FUNCTION_NAME_PROPERTY_NAME)
        : null;
  }

  /** Create a new JavaScript object instance given its constructor. */
  static dynamic _allocate(var ctor) {
    return JS('', 'new #()', ctor);
  }

  static Future<List> spawnFunction(
      void topLevelFunction(message), var message, bool startPaused) {
    IsolateNatives.enableSpawnWorker = true;
    final name = _getJSFunctionName(topLevelFunction);
    if (name == null) {
      throw new UnsupportedError('only top-level functions can be spawned.');
    }
    bool isLight = false;
    bool isSpawnUri = false;
    return spawn(name, null, null, message, isLight, isSpawnUri, startPaused);
  }

  static Future<List> spawnUri(
      Uri uri, List<String> args, var message, bool startPaused) {
    IsolateNatives.enableSpawnWorker = true;
    bool isLight = false;
    bool isSpawnUri = true;
    return spawn(
        null, uri.toString(), args, message, isLight, isSpawnUri, startPaused);
  }

  // TODO(sigmund): clean up above, after we make the new API the default:

  /// If [uri] is `null` it is replaced with the current script.
  static Future<List> spawn(String functionName, String uri, List<String> args,
      message, bool isLight, bool isSpawnUri, bool startPaused) {
    // Assume that the compiled version of the Dart file lives just next to the
    // dart file.
    // TODO(floitsch): support precompiled version of dart2js output.
    if (uri != null && uri.endsWith('.dart')) uri += '.js';

    ReceivePort port = new ReceivePort();
    Completer<List> completer = new Completer();
    port.first.then((msg) {
      if (msg[0] == _SPAWNED_SIGNAL) {
        completer.complete(msg);
      } else {
        assert(msg[0] == _SPAWN_FAILED_SIGNAL);
        completer.completeError(msg[1]);
      }
    });

    SendPort signalReply = port.sendPort;

    if (_globalState.useWorkers && !isLight) {
      _startWorker(functionName, uri, args, message, isSpawnUri, startPaused,
          signalReply, (String message) => completer.completeError(message));
    } else {
      _startNonWorker(functionName, uri, args, message, isSpawnUri, startPaused,
          signalReply);
    }
    return completer.future;
  }

  static void _startWorker(
      String functionName,
      String uri,
      List<String> args,
      message,
      bool isSpawnUri,
      bool startPaused,
      SendPort replyPort,
      void onError(String message)) {
    // Make sure that the args list is a fresh generic list. A newly spawned
    // isolate should be able to assume that the arguments list is an
    // extendable list.
    if (args != null) args = new List<String>.from(args);
    if (_globalState.isWorker) {
      _globalState.mainManager.postMessage(_serializeMessage({
        'command': 'spawn-worker',
        'functionName': functionName,
        'args': args,
        'msg': message,
        'uri': uri,
        'isSpawnUri': isSpawnUri,
        'startPaused': startPaused,
        'replyPort': replyPort
      }));
    } else {
      _spawnWorker(functionName, uri, args, message, isSpawnUri, startPaused,
          replyPort, onError);
    }
  }

  static void _startNonWorker(
      String functionName,
      String uri,
      List<String> args,
      var message,
      bool isSpawnUri,
      bool startPaused,
      SendPort replyPort) {
    // TODO(eub): support IE9 using an iframe -- Dart issue 1702.
    if (uri != null) {
      throw new UnsupportedError(
          'Currently spawnUri is not supported without web workers.');
    }
    // Clone the message to enforce the restrictions we have on isolate
    // messages.
    message = _clone(message);
    // Make sure that the args list is a fresh generic list. A newly spawned
    // isolate should be able to assume that the arguments list is an
    // extendable list.
    if (args != null) args = new List<String>.from(args);
    _globalState.topEventLoop.enqueue(new _IsolateContext(), () {
      final func = _getJSFunctionFromName(functionName);
      _startIsolate(func, args, message, isSpawnUri, startPaused, replyPort);
    }, 'nonworker start');
  }

  static Isolate get currentIsolate {
    _IsolateContext context = JS_CURRENT_ISOLATE_CONTEXT();
    return new Isolate(context.controlPort.sendPort,
        pauseCapability: context.pauseCapability,
        terminateCapability: context.terminateCapability);
  }

  static void _startIsolate(Function topLevel, List<String> args, message,
      bool isSpawnUri, bool startPaused, SendPort replyTo) {
    _IsolateContext context = JS_CURRENT_ISOLATE_CONTEXT();
    Primitives.initializeStatics(context.id);
    // The isolate's port does not keep the isolate open.
    replyTo.send([
      _SPAWNED_SIGNAL,
      context.controlPort.sendPort,
      context.pauseCapability,
      context.terminateCapability
    ]);

    void runStartFunction() {
      context.initialized = true;
      if (!isSpawnUri) {
        topLevel(message);
      } else if (topLevel is _MainFunctionArgsMessage) {
        topLevel(args, message);
      } else if (topLevel is _MainFunctionArgs) {
        topLevel(args);
      } else {
        topLevel();
      }
      context._updateGlobalState();
    }

    if (startPaused) {
      context.addPause(context.pauseCapability, context.pauseCapability);
      _globalState.topEventLoop
          .enqueue(context, runStartFunction, 'start isolate');
    } else {
      runStartFunction();
    }
  }

  /**
   * Spawns an isolate in a worker. [factoryName] is the Javascript constructor
   * name for the isolate entry point class.
   */
  static void _spawnWorker(
      functionName,
      String uri,
      List<String> args,
      message,
      bool isSpawnUri,
      bool startPaused,
      SendPort replyPort,
      void onError(String message)) {
    if (uri == null) uri = thisScript;
    final worker = JS('var', 'new Worker(#)', uri);
    // Trampolines are used when wanting to call a Dart closure from
    // JavaScript.  The helper function DART_CLOSURE_TO_JS only accepts
    // top-level or static methods, and the trampoline allows us to capture
    // arguments and values which can be passed to a static method.
    final onerrorTrampoline = JS(
        '',
        '''
(function (f, u, c) {
  return function(e) {
    return f(e, u, c)
  }
})(#, #, #)''',
        DART_CLOSURE_TO_JS(workerOnError),
        uri,
        onError);
    JS('void', '#.onerror = #', worker, onerrorTrampoline);

    var processWorkerMessageTrampoline = JS(
        '',
        """
(function (f, a) {
  return function (e) {
    // We can stop listening for errors when the first message is received as
    // we only listen for messages to determine if the uri was bad.
    e.onerror = null;
    return f(a, e);
  }
})(#, #)""",
        DART_CLOSURE_TO_JS(_processWorkerMessage),
        worker);
    JS('void', '#.onmessage = #', worker, processWorkerMessageTrampoline);
    var workerId = _globalState.nextManagerId++;
    // We also store the id on the worker itself so that we can unregister it.
    workerIds[worker] = workerId;
    _globalState.managers[workerId] = worker;
    JS(
        'void',
        '#.postMessage(#)',
        worker,
        _serializeMessage({
          'command': 'start',
          'id': workerId,
          // Note: we serialize replyPort twice because the child worker needs to
          // first deserialize the worker id, before it can correctly deserialize
          // the port (port deserialization is sensitive to what is the current
          // workerId).
          'replyTo': _serializeMessage(replyPort),
          'args': args,
          'msg': _serializeMessage(message),
          'isSpawnUri': isSpawnUri,
          'startPaused': startPaused,
          'functionName': functionName
        }));
  }

  static bool workerOnError(
      /* Event */ event,
      String uri,
      void onError(String message)) {
    // Attempt to shut up the browser, as the error has been handled.  Chrome
    // ignores this :-(
    JS('void', '#.preventDefault()', event);
    String message = JS('String|Null', '#.message', event);
    if (message == null) {
      // Some browsers, including Chrome, fail to provide a proper error
      // event.
      message = 'Error spawning worker for $uri';
    } else {
      message = 'Error spawning worker for $uri ($message)';
    }
    onError(message);
    return true;
  }
}

/********************************************************
  Inserted from lib/isolate/dart2js/ports.dart
 ********************************************************/

/** Common functionality to all send ports. */
abstract class _BaseSendPort implements SendPort {
  /** Id for the destination isolate. */
  final int _isolateId;

  const _BaseSendPort(this._isolateId);

  void _checkReplyTo(SendPort replyTo) {
    if (replyTo != null &&
        replyTo is! _NativeJsSendPort &&
        replyTo is! _WorkerSendPort) {
      throw new Exception('SendPort.send: Illegal replyTo port type');
    }
  }

  void send(var message);
  bool operator ==(var other);
  int get hashCode;
}

/** A send port that delivers messages in-memory via native JavaScript calls. */
class _NativeJsSendPort extends _BaseSendPort implements SendPort {
  final RawReceivePortImpl _receivePort;

  const _NativeJsSendPort(this._receivePort, int isolateId) : super(isolateId);

  void send(var message) {
    // Check that the isolate still runs and the port is still open
    final isolate = _globalState.isolates[_isolateId];
    if (isolate == null) return;
    if (_receivePort._isClosed) return;
    // Clone the message to enforce the restrictions we have on isolate
    // messages.
    var msg = _clone(message);
    if (isolate.controlPort == _receivePort) {
      isolate.handleControlMessage(msg);
      return;
    }
    _globalState.topEventLoop.enqueue(isolate, () {
      if (!_receivePort._isClosed) {
        _receivePort._add(msg);
      }
    }, 'receive');
  }

  bool operator ==(var other) =>
      (other is _NativeJsSendPort) && (_receivePort == other._receivePort);

  int get hashCode => _receivePort._id;
}

/** A send port that delivers messages via worker.postMessage. */
// TODO(eub): abstract this for iframes.
class _WorkerSendPort extends _BaseSendPort implements SendPort {
  final int _workerId;
  final int _receivePortId;

  const _WorkerSendPort(this._workerId, int isolateId, this._receivePortId)
      : super(isolateId);

  void send(var message) {
    final workerMessage =
        _serializeMessage({'command': 'message', 'port': this, 'msg': message});

    if (_globalState.isWorker) {
      // Communication from one worker to another go through the
      // main worker.
      _globalState.mainManager.postMessage(workerMessage);
    } else {
      // Deliver the message only if the worker is still alive.
      /* Worker */ var manager = _globalState.managers[_workerId];
      if (manager != null) {
        JS('void', '#.postMessage(#)', manager, workerMessage);
      }
    }
  }

  bool operator ==(var other) {
    return (other is _WorkerSendPort) &&
        (_workerId == other._workerId) &&
        (_isolateId == other._isolateId) &&
        (_receivePortId == other._receivePortId);
  }

  int get hashCode {
    // TODO(sigmund): use a standard hash when we get one available in corelib.
    return (_workerId << 16) ^ (_isolateId << 8) ^ _receivePortId;
  }
}

class RawReceivePortImpl implements RawReceivePort {
  static int _nextFreeId = 1;

  final int _id;
  Function _handler;
  bool _isClosed = false;

  RawReceivePortImpl(this._handler) : _id = _nextFreeId++ {
    _globalState.currentContext.register(_id, this);
  }

  RawReceivePortImpl.weak(this._handler) : _id = _nextFreeId++ {
    _globalState.currentContext.registerWeak(_id, this);
  }

  // Creates the control port of an isolate.
  // This is created before the isolate context object itself,
  // so it cannot access the static _nextFreeId field.
  RawReceivePortImpl._controlPort()
      : _handler = null,
        _id = 0;

  void set handler(Function newHandler) {
    _handler = newHandler;
  }

  // Close the port without unregistering it.
  // Used by an isolate context to close all ports when shutting down.
  void _close() {
    _isClosed = true;
    _handler = null;
  }

  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _handler = null;
    _globalState.currentContext.unregister(_id);
  }

  void _add(dataEvent) {
    if (_isClosed) return;
    _handler(dataEvent);
  }

  SendPort get sendPort {
    return new _NativeJsSendPort(this, _globalState.currentContext.id);
  }
}

class ReceivePortImpl extends Stream implements ReceivePort {
  final RawReceivePort _rawPort;
  StreamController _controller;

  ReceivePortImpl() : this.fromRawReceivePort(new RawReceivePortImpl(null));

  ReceivePortImpl.weak()
      : this.fromRawReceivePort(new RawReceivePortImpl.weak(null));

  ReceivePortImpl.fromRawReceivePort(this._rawPort) {
    _controller = new StreamController(onCancel: close, sync: true);
    _rawPort.handler = _controller.add;
  }

  StreamSubscription listen(void onData(var event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void close() {
    _rawPort.close();
    _controller.close();
  }

  SendPort get sendPort => _rawPort.sendPort;
}

class TimerImpl implements Timer {
  final bool _once;
  bool _inEventLoop = false;
  int _handle;

  TimerImpl(int milliseconds, void callback()) : _once = true {
    if (milliseconds == 0 && (!hasTimer() || _globalState.isWorker)) {
      void internalCallback() {
        _handle = null;
        callback();
      }

      // Setting _handle to something different from null indicates that the
      // callback has not been run. Hence, the choice of 1 is arbitrary.
      _handle = 1;

      // This makes a dependency between the async library and the
      // event loop of the isolate library. The compiler makes sure
      // that the event loop is compiled if [Timer] is used.
      // TODO(7907): In case of web workers, we need to use the event
      // loop instead of setTimeout, to make sure the futures get executed in
      // order.
      _globalState.topEventLoop
          .enqueue(_globalState.currentContext, internalCallback, 'timer');
      _inEventLoop = true;
    } else if (hasTimer()) {
      void internalCallback() {
        _handle = null;
        leaveJsAsync();
        callback();
      }

      enterJsAsync();

      _handle = JS('int', 'self.setTimeout(#, #)',
          convertDartClosureToJS(internalCallback, 0), milliseconds);
    } else {
      assert(milliseconds > 0);
      throw new UnsupportedError('Timer greater than 0.');
    }
  }

  TimerImpl.periodic(int milliseconds, void callback(Timer timer))
      : _once = false {
    if (hasTimer()) {
      enterJsAsync();
      _handle = JS(
          'int',
          'self.setInterval(#, #)',
          convertDartClosureToJS(() {
            callback(this);
          }, 0),
          milliseconds);
    } else {
      throw new UnsupportedError('Periodic timer.');
    }
  }

  void cancel() {
    if (hasTimer()) {
      if (_inEventLoop) {
        throw new UnsupportedError('Timer in event loop cannot be canceled.');
      }
      if (_handle == null) return;
      leaveJsAsync();
      if (_once) {
        JS('void', 'self.clearTimeout(#)', _handle);
      } else {
        JS('void', 'self.clearInterval(#)', _handle);
      }
      _handle = null;
    } else {
      throw new UnsupportedError('Canceling a timer.');
    }
  }

  bool get isActive => _handle != null;
}

bool hasTimer() {
  requiresPreamble();
  return JS('', 'self.setTimeout') != null;
}

/**
 * Implementation class for [Capability].
 *
 * It has the same name to make it harder for users to distinguish.
 */
class CapabilityImpl implements Capability {
  /** Internal random secret identifying the capability. */
  final int _id;

  CapabilityImpl() : this._internal(random64());

  CapabilityImpl._internal(this._id);

  int get hashCode {
    // Thomas Wang 32 bit Mix.
    // http://www.concentric.net/~Ttwang/tech/inthash.htm
    // (via https://gist.github.com/badboy/6267743)
    int hash = _id;
    hash = (hash >> 0) ^ (hash ~/ 0x100000000); // To 32 bit from ~64.
    hash = (~hash + (hash << 15)) & 0xFFFFFFFF;
    hash ^= hash >> 12;
    hash = (hash * 5) & 0xFFFFFFFF;
    hash ^= hash >> 4;
    hash = (hash * 2057) & 0xFFFFFFFF;
    hash ^= hash >> 16;
    return hash;
  }

  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is CapabilityImpl) {
      return identical(_id, other._id);
    }
    return false;
  }
}
