var async;
(function (async) {
  'use strict';
  // Function _invokeErrorHandler: (Function, Object, StackTrace) → dynamic
  function _invokeErrorHandler(errorHandler, error, stackTrace) {
    if (dart.is(errorHandler, ZoneBinaryCallback)) {
      return dart.dinvokef(errorHandler, error, stackTrace);
    } else {
      return dart.dinvokef(errorHandler, error);
    }
  }

  // Function _registerErrorHandler: (Function, Zone) → Function
  function _registerErrorHandler(errorHandler, zone) {
    if (dart.is(errorHandler, ZoneBinaryCallback)) {
      return zone.registerBinaryCallback(dart.as(errorHandler, /* Unimplemented type (dynamic, dynamic) → dynamic */));
    } else {
      return zone.registerUnaryCallback(dart.as(errorHandler, /* Unimplemented type (dynamic) → dynamic */));
    }
  }

  class _UncaughtAsyncError extends AsyncError {
    constructor(error, stackTrace) {
      super(error, _getBestStackTrace(error, stackTrace));
    }
    static _getBestStackTrace(error, stackTrace) {
      if (stackTrace !== null) return stackTrace;
      if (dart.is(error, core.Error)) {
        return dart.as(dart.dload(error, "stackTrace"), core.StackTrace);
      }
      return null;
    }
    toString() {
      let result = `Uncaught Error: ${this.error}`;
      if (this.stackTrace !== null) {
        result = `\nStack Trace:\n${this.stackTrace}`;
      }
      return result;
    }
  }

  let _BroadcastStream$ = dart.generic(function(T) {
    class _BroadcastStream extends _ControllerStream$(T) {
      constructor(controller) {
        super(dart.as(controller, _StreamControllerLifecycle$(T)));
      }
      get isBroadcast() { return true; }
    }
    return _BroadcastStream;
  });
  let _BroadcastStream = _BroadcastStream$(dynamic);

  class _BroadcastSubscriptionLink {
    constructor() {
      this._next = null;
      this._previous = null;
      super();
    }
  }

  let _BroadcastSubscription$ = dart.generic(function(T) {
    class _BroadcastSubscription extends _ControllerSubscription$(T) {
      constructor(controller, onData, onError, onDone, cancelOnError) {
        this._eventState = dart.as(null, core.int);
        this._next = null;
        this._previous = null;
        super(dart.as(controller, _StreamControllerLifecycle$(T)), onData, onError, onDone, cancelOnError);
        this._next = this._previous = this;
      }
      get _controller() { return dart.as(super._controller, _BroadcastStreamController); }
      _expectsEvent(eventId) { return (this._eventState & _STATE_EVENT_ID) === eventId; }
      _toggleEventId() {
        this._eventState = _STATE_EVENT_ID;
      }
      get _isFiring() { return (this._eventState & _STATE_FIRING) !== 0; }
      _setRemoveAfterFiring() {
        dart.assert(this._isFiring);
        this._eventState = _STATE_REMOVE_AFTER_FIRING;
      }
      get _removeAfterFiring() { return (this._eventState & _STATE_REMOVE_AFTER_FIRING) !== 0; }
      _onPause() {
      }
      _onResume() {
      }
    }
    _BroadcastSubscription._STATE_EVENT_ID = 1;
    _BroadcastSubscription._STATE_FIRING = 2;
    _BroadcastSubscription._STATE_REMOVE_AFTER_FIRING = 4;
    return _BroadcastSubscription;
  });
  let _BroadcastSubscription = _BroadcastSubscription$(dynamic);

  let _BroadcastStreamController$ = dart.generic(function(T) {
    class _BroadcastStreamController {
      constructor(_onListen, _onCancel) {
        this._onListen = _onListen;
        this._onCancel = _onCancel;
        this._state = _STATE_INITIAL;
        this._next = null;
        this._previous = null;
        this._addStreamState = null;
        this._doneFuture = null;
        this._next = this._previous = this;
      }
      get stream() { return new _BroadcastStream(this); }
      get sink() { return new _StreamSinkWrapper(this); }
      get isClosed() { return (this._state & _STATE_CLOSED) !== 0; }
      get isPaused() { return false; }
      get hasListener() { return !this._isEmpty; }
      get _hasOneListener() {
        dart.assert(!this._isEmpty);
        return core.identical(this._next._next, this);
      }
      get _isFiring() { return (this._state & _STATE_FIRING) !== 0; }
      get _isAddingStream() { return (this._state & _STATE_ADDSTREAM) !== 0; }
      get _mayAddEvent() { return (this._state < _STATE_CLOSED); }
      _ensureDoneFuture() {
        if (this._doneFuture !== null) return this._doneFuture;
        return this._doneFuture = new _Future();
      }
      get _isEmpty() { return core.identical(this._next, this); }
      _addListener(subscription) {
        dart.assert(core.identical(subscription._next, subscription));
        subscription._previous = this._previous;
        subscription._next = this;
        this._previous._next = subscription;
        this._previous = subscription;
        subscription._eventState = (this._state & _STATE_EVENT_ID);
      }
      _removeListener(subscription) {
        dart.assert(core.identical(subscription._controller, this));
        dart.assert(!core.identical(subscription._next, subscription));
        let previous = subscription._previous;
        let next = subscription._next;
        previous._next = next;
        next._previous = previous;
        subscription._next = subscription._previous = subscription;
      }
      _subscribe(onData, onError, onDone, cancelOnError) {
        if (this.isClosed) {
          if (onDone === null) onDone = _nullDoneHandler;
          return new _DoneStreamSubscription(onDone);
        }
        let subscription = new _BroadcastSubscription(this, onData, onError, onDone, cancelOnError);
        this._addListener(dart.as(subscription, _BroadcastSubscription$(T)));
        if (core.identical(this._next, this._previous)) {
          _runGuarded(this._onListen);
        }
        return dart.as(subscription, StreamSubscription$(T));
      }
      _recordCancel(subscription) {
        if (core.identical(subscription._next, subscription)) return null;
        dart.assert(!core.identical(subscription._next, subscription));
        if (subscription._isFiring) {
          subscription._setRemoveAfterFiring();
        } else {
          dart.assert(!core.identical(subscription._next, subscription));
          this._removeListener(subscription);
          if (!this._isFiring && this._isEmpty) {
            this._callOnCancel();
          }
        }
        return null;
      }
      _recordPause(subscription) {
      }
      _recordResume(subscription) {
      }
      _addEventError() {
        if (this.isClosed) {
          return new core.StateError("Cannot add new events after calling close");
        }
        dart.assert(this._isAddingStream);
        return new core.StateError("Cannot add new events while doing an addStream");
      }
      add(data) {
        if (!this._mayAddEvent) throw this._addEventError();
        this._sendData(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        error = _nonNullError(error);
        if (!this._mayAddEvent) throw this._addEventError();
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement !== null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this._sendError(error, stackTrace);
      }
      close() {
        if (this.isClosed) {
          dart.assert(this._doneFuture !== null);
          return this._doneFuture;
        }
        if (!this._mayAddEvent) throw this._addEventError();
        this._state = _STATE_CLOSED;
        let doneFuture = this._ensureDoneFuture();
        this._sendDone();
        return doneFuture;
      }
      get done() { return this._ensureDoneFuture(); }
      addStream(stream, opt$) {
        let cancelOnError = opt$.cancelOnError === undefined ? true : opt$.cancelOnError;
        if (!this._mayAddEvent) throw this._addEventError();
        this._state = _STATE_ADDSTREAM;
        this._addStreamState = dart.as(new _AddStreamState(this, stream, cancelOnError), _AddStreamState$(T));
        return this._addStreamState.addStreamFuture;
      }
      _add(data) {
        this._sendData(data);
      }
      _addError(error, stackTrace) {
        this._sendError(error, stackTrace);
      }
      _close() {
        dart.assert(this._isAddingStream);
        let addState = this._addStreamState;
        this._addStreamState = null;
        this._state = ~_STATE_ADDSTREAM;
        addState.complete();
      }
      _forEachListener(action) {
        if (this._isFiring) {
          throw new core.StateError("Cannot fire new event. Controller is already firing an event");
        }
        if (this._isEmpty) return;
        let id = (this._state & _STATE_EVENT_ID);
        this._state = _STATE_EVENT_ID | _STATE_FIRING;
        let link = this._next;
        while (!core.identical(link, this)) {
          let subscription = dart.as(link, _BroadcastSubscription$(T));
          if (subscription._expectsEvent(id)) {
            subscription._eventState = _BroadcastSubscription._STATE_FIRING;
            action(subscription);
            subscription._toggleEventId();
            link = subscription._next;
            if (subscription._removeAfterFiring) {
              this._removeListener(subscription);
            }
            subscription._eventState = ~_BroadcastSubscription._STATE_FIRING;
          } else {
            link = subscription._next;
          }
        }
        this._state = ~_STATE_FIRING;
        if (this._isEmpty) {
          this._callOnCancel();
        }
      }
      _callOnCancel() {
        dart.assert(this._isEmpty);
        if (this.isClosed && this._doneFuture._mayComplete) {
          this._doneFuture._asyncComplete(null);
        }
        _runGuarded(this._onCancel);
      }
    }
    _BroadcastStreamController._STATE_INITIAL = 0;
    _BroadcastStreamController._STATE_EVENT_ID = 1;
    _BroadcastStreamController._STATE_FIRING = 2;
    _BroadcastStreamController._STATE_CLOSED = 4;
    _BroadcastStreamController._STATE_ADDSTREAM = 8;
    return _BroadcastStreamController;
  });
  let _BroadcastStreamController = _BroadcastStreamController$(dynamic);

  let _SyncBroadcastStreamController$ = dart.generic(function(T) {
    class _SyncBroadcastStreamController extends _BroadcastStreamController$(T) {
      constructor(onListen, onCancel) {
        super(onListen, onCancel);
      }
      _sendData(data) {
        if (this._isEmpty) return;
        if (this._hasOneListener) {
          this._state = _BroadcastStreamController._STATE_FIRING;
          let subscription = dart.as(this._next, _BroadcastSubscription);
          subscription._add(data);
          this._state = ~_BroadcastStreamController._STATE_FIRING;
          if (this._isEmpty) {
            this._callOnCancel();
          }
          return;
        }
        this._forEachListener((subscription) => {
          subscription._add(data);
        });
      }
      _sendError(error, stackTrace) {
        if (this._isEmpty) return;
        this._forEachListener((subscription) => {
          subscription._addError(error, stackTrace);
        });
      }
      _sendDone() {
        if (!this._isEmpty) {
          this._forEachListener(dart.as((subscription) => {
            subscription._close();
          }, /* Unimplemented type (_BufferingStreamSubscription<T>) → void */));
        } else {
          dart.assert(this._doneFuture !== null);
          dart.assert(this._doneFuture._mayComplete);
          this._doneFuture._asyncComplete(null);
        }
      }
    }
    return _SyncBroadcastStreamController;
  });
  let _SyncBroadcastStreamController = _SyncBroadcastStreamController$(dynamic);

  let _AsyncBroadcastStreamController$ = dart.generic(function(T) {
    class _AsyncBroadcastStreamController extends _BroadcastStreamController$(T) {
      constructor(onListen, onCancel) {
        super(onListen, onCancel);
      }
      _sendData(data) {
        for (let link = this._next; !core.identical(link, this); link = link._next) {
          let subscription = dart.as(link, _BroadcastSubscription$(T));
          subscription._addPending(new _DelayedData(data));
        }
      }
      _sendError(error, stackTrace) {
        for (let link = this._next; !core.identical(link, this); link = link._next) {
          let subscription = dart.as(link, _BroadcastSubscription$(T));
          subscription._addPending(new _DelayedError(error, stackTrace));
        }
      }
      _sendDone() {
        if (!this._isEmpty) {
          for (let link = this._next; !core.identical(link, this); link = link._next) {
            let subscription = dart.as(link, _BroadcastSubscription$(T));
            subscription._addPending(new _DelayedDone());
          }
        } else {
          dart.assert(this._doneFuture !== null);
          dart.assert(this._doneFuture._mayComplete);
          this._doneFuture._asyncComplete(null);
        }
      }
    }
    return _AsyncBroadcastStreamController;
  });
  let _AsyncBroadcastStreamController = _AsyncBroadcastStreamController$(dynamic);

  let _AsBroadcastStreamController$ = dart.generic(function(T) {
    class _AsBroadcastStreamController extends _SyncBroadcastStreamController$(T) {
      constructor(onListen, onCancel) {
        this._pending = null;
        super(onListen, onCancel);
      }
      get _hasPending() { return this._pending !== null && !this._pending.isEmpty; }
      _addPendingEvent(event) {
        if (this._pending === null) {
          this._pending = new _StreamImplEvents();
        }
        this._pending.add(event);
      }
      add(data) {
        if (!this.isClosed && this._isFiring) {
          this._addPendingEvent(new _DelayedData(data));
          return;
        }
        super.add(data);
        while (this._hasPending) {
          this._pending.handleNext(this);
        }
      }
      addError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        if (!this.isClosed && this._isFiring) {
          this._addPendingEvent(new _DelayedError(error, stackTrace));
          return;
        }
        if (!this._mayAddEvent) throw this._addEventError();
        this._sendError(error, stackTrace);
        while (this._hasPending) {
          this._pending.handleNext(this);
        }
      }
      close() {
        if (!this.isClosed && this._isFiring) {
          this._addPendingEvent(new _DelayedDone());
          this._state = _BroadcastStreamController._STATE_CLOSED;
          return super.done;
        }
        let result = super.close();
        dart.assert(!this._hasPending);
        return result;
      }
      _callOnCancel() {
        if (this._hasPending) {
          this._pending.clear();
          this._pending = null;
        }
        super._callOnCancel();
      }
    }
    return _AsBroadcastStreamController;
  });
  let _AsBroadcastStreamController = _AsBroadcastStreamController$(dynamic);

  let _DoneSubscription$ = dart.generic(function(T) {
    class _DoneSubscription {
      constructor() {
        this._pauseCount = 0;
        super();
      }
      onData(handleData) {
      }
      onError(handleError) {
      }
      onDone(handleDone) {
      }
      pause(resumeSignal) {
        if (resumeSignal === undefined) resumeSignal = null;
        if (resumeSignal !== null) resumeSignal.then(this._resume);
        this._pauseCount++;
      }
      resume() {
        this._resume(null);
      }
      _resume(_) {
        if (this._pauseCount > 0) this._pauseCount--;
      }
      cancel() {
        return new _Future.immediate(null);
      }
      get isPaused() { return this._pauseCount > 0; }
      asFuture(value) {
        if (value === undefined) value = null;
        return new _Future()
      }
    }
    return _DoneSubscription;
  });
  let _DoneSubscription = _DoneSubscription$(dynamic);

  class DeferredLibrary {
    constructor(libraryName, opt$) {
      let uri = opt$.uri === undefined ? null : opt$.uri;
      this.libraryName = libraryName;
      this.uri = uri;
    }
    /* Unimplemented external Future<Null> load(); */
  }

  class DeferredLoadException {
    constructor(_s) {
      this._s = _s;
    }
    toString() { return `DeferredLoadException: '${this._s}'`; }
  }

  let Future$ = dart.generic(function(T) {
    class Future {
      constructor(computation) {
        let result = new _Future();
        Timer.run(() => {
          try {
            result._complete(computation());
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }
        });
        return dart.as(result, Future$(T));
      }
      /*constructor*/ microtask(computation) {
        let result = new _Future();
        scheduleMicrotask(() => {
          try {
            result._complete(computation());
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }
        });
        return dart.as(result, Future$(T));
      }
      /*constructor*/ sync(computation) {
        try {
          let result = computation();
          return new Future.value(result);
        }
        catch (error) {
          let stackTrace = dart.stackTrace(error);
          return new Future.error(error, stackTrace);
        }
      }
      /*constructor*/ value(value) {
        if (value === undefined) value = null;
        return new _Future.immediate(value);
      }
      /*constructor*/ error(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        error = _nonNullError(error);
        if (!core.identical(Zone.current, _ROOT_ZONE)) {
          let replacement = Zone.current.errorCallback(error, stackTrace);
          if (replacement !== null) {
            error = _nonNullError(replacement.error);
            stackTrace = replacement.stackTrace;
          }
        }
        return new _Future.immediateError(error, stackTrace);
      }
      /*constructor*/ delayed(duration, computation) {
        if (computation === undefined) computation = null;
        let result = new _Future();
        new Timer(duration, () => {
          try {
            result._complete(computation === null ? null : computation());
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(result, e, s);
          }
        });
        return dart.as(result, Future$(T));
      }
      static wait(futures, opt$) {
        let eagerError = opt$.eagerError === undefined ? false : opt$.eagerError;
        let cleanUp = opt$.cleanUp === undefined ? null : opt$.cleanUp;
        let result = new _Future();
        let values = null;
        let remaining = 0;
        let error = null;
        let stackTrace = null;
        // Function handleError: (dynamic, dynamic) → void
        function handleError(theError, theStackTrace) {
          remaining--;
          if (values !== null) {
            if (cleanUp !== null) {
              for (let value of values) {
                if (value !== null) {
                  new Future.sync(() => {
                    cleanUp(value);
                  });
                }
              }
            }
            values = null;
            if (remaining === 0 || eagerError) {
              result._completeError(theError, dart.as(theStackTrace, core.StackTrace));
            } else {
              error = theError;
              stackTrace = dart.as(theStackTrace, core.StackTrace);
            }
          } else if (remaining === 0 && !eagerError) {
            result._completeError(error, stackTrace);
          }
        }
        for (let future of futures) {
          let pos = remaining++;
          future.then(dart.as((value) => {
            remaining--;
            if (values !== null) {
              values.set(pos, value);
              if (remaining === 0) {
                result._completeWithValue(values);
              }
            } else {
              if (cleanUp !== null && value !== null) {
                new Future.sync(() => {
                  cleanUp(value);
                });
              }
              if (remaining === 0 && !eagerError) {
                result._completeError(error, stackTrace);
              }
            }
          }, /* Unimplemented type (dynamic) → dynamic */), {onError: handleError});
        }
        if (remaining === 0) {
          return dart.as(new Future.value(/* Unimplemented const */new List.from([])), Future$(core.List));
        }
        values = new core.List(remaining);
        return result;
      }
      static forEach(input, f) {
        let iterator = input.iterator;
        return doWhile(() => {
          if (!iterator.moveNext()) return false;
          return new Future.sync(() => f(iterator.current)).then((_) => true);
        });
      }
      static doWhile(f) {
        let doneSignal = new _Future();
        let nextIteration = null;
        nextIteration = Zone.current.bindUnaryCallback(dart.as((keepGoing) => {
          if (keepGoing) {
            new Future.sync(f).then(dart.as(nextIteration, /* Unimplemented type (dynamic) → dynamic */), {onError: doneSignal._completeError});
          } else {
            doneSignal._complete(null);
          }
        }, /* Unimplemented type (dynamic) → dynamic */), {runGuarded: true});
        dart.dinvokef(nextIteration, true);
        return doneSignal;
      }
    }
    dart.defineNamedConstructor(Future, "microtask");
    dart.defineNamedConstructor(Future, "sync");
    dart.defineNamedConstructor(Future, "value");
    dart.defineNamedConstructor(Future, "error");
    dart.defineNamedConstructor(Future, "delayed");
    dart.defineLazyProperties(Future, {
      get _nullFuture() { return dart.as(new Future.value(null), _Future) },
    });
    return Future;
  });
  let Future = Future$(dynamic);

  class TimeoutException {
    constructor(message, duration) {
      if (duration === undefined) duration = null;
      this.message = message;
      this.duration = duration;
    }
    toString() {
      let result = "TimeoutException";
      if (this.duration !== null) result = `TimeoutException after ${this.duration}`;
      if (this.message !== null) result = `${result}: ${this.message}`;
      return result;
    }
  }

  let Completer$ = dart.generic(function(T) {
    class Completer {
      constructor() {
        return new _AsyncCompleter();
      }
      /*constructor*/ sync() {
        return new _SyncCompleter();
      }
    }
    dart.defineNamedConstructor(Completer, "sync");
    return Completer;
  });
  let Completer = Completer$(dynamic);

  // Function _completeWithErrorCallback: (_Future<dynamic>, dynamic, dynamic) → void
  function _completeWithErrorCallback(result, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, dart.as(stackTrace, core.StackTrace));
    if (replacement !== null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    result._completeError(error, dart.as(stackTrace, core.StackTrace));
  }

  // Function _nonNullError: (Object) → Object
  function _nonNullError(error) { return (error !== null) ? error : new core.NullThrownError(); }

  let _Completer$ = dart.generic(function(T) {
    class _Completer {
      constructor() {
        this.future = new _Future();
        super();
      }
      completeError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        error = _nonNullError(error);
        if (!this.future._mayComplete) throw new core.StateError("Future already completed");
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement !== null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this._completeError(error, stackTrace);
      }
      get isCompleted() { return !this.future._mayComplete; }
    }
    return _Completer;
  });
  let _Completer = _Completer$(dynamic);

  let _AsyncCompleter$ = dart.generic(function(T) {
    class _AsyncCompleter extends _Completer$(T) {
      complete(value) {
        if (value === undefined) value = null;
        if (!this.future._mayComplete) throw new core.StateError("Future already completed");
        this.future._asyncComplete(value);
      }
      _completeError(error, stackTrace) {
        this.future._asyncCompleteError(error, stackTrace);
      }
    }
    return _AsyncCompleter;
  });
  let _AsyncCompleter = _AsyncCompleter$(dynamic);

  let _SyncCompleter$ = dart.generic(function(T) {
    class _SyncCompleter extends _Completer$(T) {
      complete(value) {
        if (value === undefined) value = null;
        if (!this.future._mayComplete) throw new core.StateError("Future already completed");
        this.future._complete(value);
      }
      _completeError(error, stackTrace) {
        this.future._completeError(error, stackTrace);
      }
    }
    return _SyncCompleter;
  });
  let _SyncCompleter = _SyncCompleter$(dynamic);

  class _FutureListener {
    /*constructor*/ then(result, onValue, errorCallback) {
      this.result = result;
      this.callback = onValue;
      this.errorCallback = errorCallback;
      this.state = (errorCallback === null) ? STATE_THEN : STATE_THEN_ONERROR;
      this._nextListener = null;
    }
    /*constructor*/ catchError(result, errorCallback, test) {
      this.result = result;
      this.errorCallback = errorCallback;
      this.callback = test;
      this.state = (test === null) ? STATE_CATCHERROR : STATE_CATCHERROR_TEST;
      this._nextListener = null;
    }
    /*constructor*/ whenComplete(result, onComplete) {
      this.result = result;
      this.callback = onComplete;
      this.errorCallback = null;
      this.state = STATE_WHENCOMPLETE;
      this._nextListener = null;
    }
    /*constructor*/ chain(result) {
      this.result = result;
      this.callback = null;
      this.errorCallback = null;
      this.state = STATE_CHAIN;
      this._nextListener = null;
    }
    get _zone() { return this.result._zone; }
    get handlesValue() { return (this.state & MASK_VALUE !== 0); }
    get handlesError() { return (this.state & MASK_ERROR !== 0); }
    get hasErrorTest() { return (this.state === STATE_CATCHERROR_TEST); }
    get handlesComplete() { return (this.state === STATE_WHENCOMPLETE); }
    get _onValue() {
      dart.assert(this.handlesValue);
      return dart.as(this.callback, _FutureOnValue);
    }
    get _onError() { return this.errorCallback; }
    get _errorTest() {
      dart.assert(this.hasErrorTest);
      return dart.as(this.callback, _FutureErrorTest);
    }
    get _whenCompleteAction() {
      dart.assert(this.handlesComplete);
      return dart.as(this.callback, _FutureAction);
    }
  }
  dart.defineNamedConstructor(_FutureListener, "then");
  dart.defineNamedConstructor(_FutureListener, "catchError");
  dart.defineNamedConstructor(_FutureListener, "whenComplete");
  dart.defineNamedConstructor(_FutureListener, "chain");
  _FutureListener.MASK_VALUE = 1;
  _FutureListener.MASK_ERROR = 2;
  _FutureListener.MASK_TEST_ERROR = 4;
  _FutureListener.MASK_WHENCOMPLETE = 8;
  _FutureListener.STATE_CHAIN = 0;
  _FutureListener.STATE_THEN = MASK_VALUE;
  _FutureListener.STATE_THEN_ONERROR = MASK_VALUE | MASK_ERROR;
  _FutureListener.STATE_CATCHERROR = MASK_ERROR;
  _FutureListener.STATE_CATCHERROR_TEST = MASK_ERROR | MASK_TEST_ERROR;
  _FutureListener.STATE_WHENCOMPLETE = MASK_WHENCOMPLETE;

  let _Future$ = dart.generic(function(T) {
    class _Future {
      constructor() {
        this._zone = Zone.current;
        this._state = _INCOMPLETE;
        this._resultOrListeners = null;
      }
      /*constructor*/ immediate(value) {
        this._zone = Zone.current;
        this._state = _INCOMPLETE;
        this._resultOrListeners = null;
        this._asyncComplete(value);
      }
      /*constructor*/ immediateError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        this._zone = Zone.current;
        this._state = _INCOMPLETE;
        this._resultOrListeners = null;
        this._asyncCompleteError(error, stackTrace);
      }
      get _mayComplete() { return this._state === _INCOMPLETE; }
      get _isChained() { return this._state === _CHAINED; }
      get _isComplete() { return this._state >= _VALUE; }
      get _hasValue() { return this._state === _VALUE; }
      get _hasError() { return this._state === _ERROR; }
      set _isChained(value) {
        if (value) {
          dart.assert(!this._isComplete);
          this._state = _CHAINED;
        } else {
          dart.assert(this._isChained);
          this._state = _INCOMPLETE;
        }
      }
      then(f, opt$) {
        let onError = opt$.onError === undefined ? null : opt$.onError;
        let result = new _Future();
        if (!core.identical(result._zone, _ROOT_ZONE)) {
          f = result._zone.registerUnaryCallback(dart.as(f, /* Unimplemented type (dynamic) → dynamic */));
          if (onError !== null) {
            onError = _registerErrorHandler(onError, result._zone);
          }
        }
        this._addListener(new _FutureListener.then(result, f, onError));
        return result;
      }
      catchError(onError, opt$) {
        let test = opt$.test === undefined ? null : opt$.test;
        let result = new _Future();
        if (!core.identical(result._zone, _ROOT_ZONE)) {
          onError = _registerErrorHandler(onError, result._zone);
          if (test !== null) test = dart.as(result._zone.registerUnaryCallback(test), /* Unimplemented type (dynamic) → bool */);
        }
        this._addListener(new _FutureListener.catchError(result, onError, test));
        return result;
      }
      whenComplete(action) {
        let result = new _Future();
        if (!core.identical(result._zone, _ROOT_ZONE)) {
          action = result._zone.registerCallback(action);
        }
        this._addListener(new _FutureListener.whenComplete(result, action));
        return dart.as(result, Future$(T));
      }
      asStream() { return dart.as(new Stream.fromFuture(this), Stream$(T)); }
      _markPendingCompletion() {
        if (!this._mayComplete) throw new core.StateError("Future already completed");
        this._state = _PENDING_COMPLETE;
      }
      get _value() {
        dart.assert(this._isComplete && this._hasValue);
        return dart.as(this._resultOrListeners, T);
      }
      get _error() {
        dart.assert(this._isComplete && this._hasError);
        return dart.as(this._resultOrListeners, AsyncError);
      }
      _setValue(value) {
        dart.assert(!this._isComplete);
        this._state = _VALUE;
        this._resultOrListeners = value;
      }
      _setErrorObject(error) {
        dart.assert(!this._isComplete);
        this._state = _ERROR;
        this._resultOrListeners = error;
      }
      _setError(error, stackTrace) {
        this._setErrorObject(new AsyncError(error, stackTrace));
      }
      _addListener(listener) {
        dart.assert(listener._nextListener === null);
        if (this._isComplete) {
          this._zone.scheduleMicrotask(() => {
            _propagateToListeners(this, listener);
          });
        } else {
          listener._nextListener = dart.as(this._resultOrListeners, _FutureListener);
          this._resultOrListeners = listener;
        }
      }
      _removeListeners() {
        dart.assert(!this._isComplete);
        let current = dart.as(this._resultOrListeners, _FutureListener);
        this._resultOrListeners = null;
        let prev = null;
        while (current !== null) {
          let next = current._nextListener;
          current._nextListener = prev;
          prev = current;
          current = next;
        }
        return prev;
      }
      static _chainForeignFuture(source, target) {
        dart.assert(!target._isComplete);
        dart.assert(!dart.is(source, _Future));
        target._isChained = true;
        source.then((value) => {
          dart.assert(target._isChained);
          target._completeWithValue(value);
        }, {onError: (error, stackTrace) => {
          if (stackTrace === undefined) stackTrace = null;
          dart.assert(target._isChained);
          target._completeError(error, dart.as(stackTrace, core.StackTrace));
        }});
      }
      static _chainCoreFuture(source, target) {
        dart.assert(!target._isComplete);
        dart.assert(dart.is(source, _Future));
        target._isChained = true;
        let listener = new _FutureListener.chain(target);
        if (source._isComplete) {
          _propagateToListeners(source, listener);
        } else {
          source._addListener(listener);
        }
      }
      _complete(value) {
        dart.assert(!this._isComplete);
        if (dart.is(value, Future)) {
          if (dart.is(value, _Future)) {
            _chainCoreFuture(dart.as(value, _Future), this);
          } else {
            _chainForeignFuture(dart.as(value, Future), this);
          }
        } else {
          let listeners = this._removeListeners();
          this._setValue(dart.as(value, T));
          _propagateToListeners(this, listeners);
        }
      }
      _completeWithValue(value) {
        dart.assert(!this._isComplete);
        dart.assert(!dart.is(value, Future));
        let listeners = this._removeListeners();
        this._setValue(dart.as(value, T));
        _propagateToListeners(this, listeners);
      }
      _completeError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        dart.assert(!this._isComplete);
        let listeners = this._removeListeners();
        this._setError(error, stackTrace);
        _propagateToListeners(this, listeners);
      }
      _asyncComplete(value) {
        dart.assert(!this._isComplete);
        if (value === null) {
        } else if (dart.is(value, Future)) {
          let typedFuture = dart.as(value, Future$(T));
          if (dart.is(typedFuture, _Future)) {
            let coreFuture = dart.as(typedFuture, _Future$(T));
            if (coreFuture._isComplete && coreFuture._hasError) {
              this._markPendingCompletion();
              this._zone.scheduleMicrotask(() => {
                _chainCoreFuture(coreFuture, this);
              });
            } else {
              _chainCoreFuture(coreFuture, this);
            }
          } else {
            _chainForeignFuture(typedFuture, this);
          }
          return;
        } else {
          let typedValue = dart.as(value, T);
        }
        this._markPendingCompletion();
        this._zone.scheduleMicrotask(() => {
          this._completeWithValue(value);
        });
      }
      _asyncCompleteError(error, stackTrace) {
        dart.assert(!this._isComplete);
        this._markPendingCompletion();
        this._zone.scheduleMicrotask(() => {
          this._completeError(error, stackTrace);
        });
      }
      static _propagateToListeners(source, listeners) {
        while (true) {
          dart.assert(source._isComplete);
          let hasError = source._hasError;
          if (listeners === null) {
            if (hasError) {
              let asyncError = source._error;
              source._zone.handleUncaughtError(asyncError.error, asyncError.stackTrace);
            }
            return;
          }
          while (listeners._nextListener !== null) {
            let listener = listeners;
            listeners = listener._nextListener;
            listener._nextListener = null;
            _propagateToListeners(source, listener);
          }
          let listener = listeners;
          let listenerHasValue = true;
          let sourceValue = hasError ? null : source._value;
          let listenerValueOrError = sourceValue;
          let isPropagationAborted = false;
          if (hasError || (listener.handlesValue || listener.handlesComplete)) {
            let zone = listener._zone;
            if (hasError && !source._zone.inSameErrorZone(zone)) {
              let asyncError = source._error;
              source._zone.handleUncaughtError(asyncError.error, asyncError.stackTrace);
              return;
            }
            let oldZone = null;
            if (!core.identical(Zone.current, zone)) {
              oldZone = Zone._enter(zone);
            }
            // Function handleValueCallback: () → bool
            function handleValueCallback() {
              try {
                listenerValueOrError = zone.runUnary(listener._onValue, sourceValue);
                return true;
              }
              catch (e) {
                let s = dart.stackTrace(e);
                listenerValueOrError = new AsyncError(e, s);
                return false;
              }
            }
            // Function handleError: () → void
            function handleError() {
              let asyncError = source._error;
              let matchesTest = true;
              if (listener.hasErrorTest) {
                let test = listener._errorTest;
                try {
                  matchesTest = dart.as(zone.runUnary(test, asyncError.error), core.bool);
                }
                catch (e) {
                  let s = dart.stackTrace(e);
                  listenerValueOrError = core.identical(asyncError.error, e) ? asyncError : new AsyncError(e, s);
                  listenerHasValue = false;
                  return;
                }
              }
              let errorCallback = listener._onError;
              if (matchesTest && errorCallback !== null) {
                try {
                  if (dart.is(errorCallback, ZoneBinaryCallback)) {
                    listenerValueOrError = zone.runBinary(dart.as(errorCallback, /* Unimplemented type (dynamic, dynamic) → dynamic */), asyncError.error, asyncError.stackTrace);
                  } else {
                    listenerValueOrError = zone.runUnary(dart.as(errorCallback, /* Unimplemented type (dynamic) → dynamic */), asyncError.error);
                  }
                }
                catch (e) {
                  let s = dart.stackTrace(e);
                  listenerValueOrError = core.identical(asyncError.error, e) ? asyncError : new AsyncError(e, s);
                  listenerHasValue = false;
                  return;
                }
                listenerHasValue = true;
              } else {
                listenerValueOrError = asyncError;
                listenerHasValue = false;
              }
            }
            // Function handleWhenCompleteCallback: () → void
            function handleWhenCompleteCallback() {
              let completeResult = null;
              try {
                completeResult = zone.run(listener._whenCompleteAction);
              }
              catch (e) {
                let s = dart.stackTrace(e);
                if (hasError && core.identical(source._error.error, e)) {
                  listenerValueOrError = source._error;
                } else {
                  listenerValueOrError = new AsyncError(e, s);
                }
                listenerHasValue = false;
                return;
              }
              if (dart.is(completeResult, Future)) {
                let result = listener.result;
                result._isChained = true;
                isPropagationAborted = true;
                dart.dinvoke(completeResult, "then", (ignored) => {
                  _propagateToListeners(source, new _FutureListener.chain(result));
                }, {onError: (error, stackTrace) => {
                  if (stackTrace === undefined) stackTrace = null;
                  if (!dart.is(completeResult, _Future)) {
                    completeResult = new _Future();
                    dart.dinvoke(completeResult, "_setError", error, stackTrace);
                  }
                  _propagateToListeners(dart.as(completeResult, _Future), new _FutureListener.chain(result));
                }});
              }
            }
            if (!hasError) {
              if (listener.handlesValue) {
                listenerHasValue = handleValueCallback();
              }
            } else {
              handleError();
            }
            if (listener.handlesComplete) {
              handleWhenCompleteCallback();
            }
            if (oldZone !== null) Zone._leave(oldZone);
            if (isPropagationAborted) return;
            if (listenerHasValue && !core.identical(sourceValue, listenerValueOrError) && dart.is(listenerValueOrError, Future)) {
              let chainSource = dart.as(listenerValueOrError, Future);
              let result = listener.result;
              if (dart.is(chainSource, _Future)) {
                if (chainSource._isComplete) {
                  result._isChained = true;
                  source = dart.as(chainSource, _Future);
                  listeners = new _FutureListener.chain(result);
                  continue;
                } else {
                  _chainCoreFuture(dart.as(chainSource, _Future), result);
                }
              } else {
                _chainForeignFuture(chainSource, result);
              }
              return;
            }
          }
          let result = listener.result;
          listeners = result._removeListeners();
          if (listenerHasValue) {
            result._setValue(listenerValueOrError);
          } else {
            let asyncError = dart.as(listenerValueOrError, AsyncError);
            result._setErrorObject(asyncError);
          }
          source = result;
        }
      }
      timeout(timeLimit, opt$) {
        let onTimeout = opt$.onTimeout === undefined ? null : opt$.onTimeout;
        if (this._isComplete) return new _Future.immediate(this);
        let result = new _Future();
        let timer = null;
        if (onTimeout === null) {
          timer = new Timer(timeLimit, () => {
            result._completeError(new TimeoutException("Future not completed", timeLimit));
          });
        } else {
          let zone = Zone.current;
          onTimeout = zone.registerCallback(onTimeout);
          timer = new Timer(timeLimit, () => {
            try {
              result._complete(zone.run(onTimeout));
            }
            catch (e) {
              let s = dart.stackTrace(e);
              result._completeError(e, s);
            }
          });
        }
        this.then((v) => {
          if (timer.isActive) {
            timer.cancel();
            result._completeWithValue(v);
          }
        }, {onError: (e, s) => {
          if (timer.isActive) {
            timer.cancel();
            result._completeError(e, dart.as(s, core.StackTrace));
          }
        }});
        return result;
      }
    }
    dart.defineNamedConstructor(_Future, "immediate");
    dart.defineNamedConstructor(_Future, "immediateError");
    _Future._INCOMPLETE = 0;
    _Future._PENDING_COMPLETE = 1;
    _Future._CHAINED = 2;
    _Future._VALUE = 4;
    _Future._ERROR = 8;
    return _Future;
  });
  let _Future = _Future$(dynamic);

  class _AsyncCallbackEntry {
    constructor(callback) {
      this.callback = callback;
      this.next = null;
    }
  }

  async._nextCallback = null;
  async._lastCallback = null;
  async._lastPriorityCallback = null;
  async._isInCallbackLoop = false;
  // Function _asyncRunCallbackLoop: () → void
  function _asyncRunCallbackLoop() {
    while (async._nextCallback !== null) {
      async._lastPriorityCallback = null;
      let entry = async._nextCallback;
      async._nextCallback = entry.next;
      if (async._nextCallback === null) async._lastCallback = null;
      entry.callback();
    }
  }

  // Function _asyncRunCallback: () → void
  function _asyncRunCallback() {
    async._isInCallbackLoop = true;
    try {
      _asyncRunCallbackLoop();
    }
    finally {
      async._lastPriorityCallback = null;
      async._isInCallbackLoop = false;
      if (async._nextCallback !== null) _AsyncRun._scheduleImmediate(_asyncRunCallback);
    }
  }

  // Function _scheduleAsyncCallback: (dynamic) → void
  function _scheduleAsyncCallback(callback) {
    if (async._nextCallback === null) {
      async._nextCallback = async._lastCallback = new _AsyncCallbackEntry(callback);
      if (!async._isInCallbackLoop) {
        _AsyncRun._scheduleImmediate(_asyncRunCallback);
      }
    } else {
      let newEntry = new _AsyncCallbackEntry(callback);
      async._lastCallback.next = newEntry;
      async._lastCallback = newEntry;
    }
  }

  // Function _schedulePriorityAsyncCallback: (dynamic) → void
  function _schedulePriorityAsyncCallback(callback) {
    let entry = new _AsyncCallbackEntry(callback);
    if (async._nextCallback === null) {
      _scheduleAsyncCallback(callback);
      async._lastPriorityCallback = async._lastCallback;
    } else if (async._lastPriorityCallback === null) {
      entry.next = async._nextCallback;
      async._nextCallback = async._lastPriorityCallback = entry;
    } else {
      entry.next = async._lastPriorityCallback.next;
      async._lastPriorityCallback.next = entry;
      async._lastPriorityCallback = entry;
      if (entry.next === null) {
        async._lastCallback = entry;
      }
    }
  }

  // Function scheduleMicrotask: (() → void) → void
  function scheduleMicrotask(callback) {
    if (core.identical(_ROOT_ZONE, Zone.current)) {
      _rootScheduleMicrotask(null, null, dart.as(_ROOT_ZONE, Zone), callback);
      return;
    }
    Zone.current.scheduleMicrotask(Zone.current.bindCallback(callback, {runGuarded: true}));
  }

  class _AsyncRun {
    /* Unimplemented external static void _scheduleImmediate(void callback()); */
  }

  let Stream$ = dart.generic(function(T) {
    class Stream {
      constructor() {
      }
      /*constructor*/ fromFuture(future) {
        let controller = dart.as(new StreamController({sync: true}), _StreamController$(T));
        future.then((value) => {
          controller._add(dart.as(value, T));
          controller._closeUnchecked();
        }, {onError: (error, stackTrace) => {
          controller._addError(error, dart.as(stackTrace, core.StackTrace));
          controller._closeUnchecked();
        }});
        return controller.stream;
      }
      /*constructor*/ fromIterable(data) {
        return new _GeneratedStreamImpl(() => new _IterablePendingEvents(data));
      }
      /*constructor*/ periodic(period, computation) {
        if (computation === undefined) computation = null;
        if (computation === null) computation = dart.as(((i) => null), /* Unimplemented type (int) → T */);
        let timer = null;
        let computationCount = 0;
        let controller = null;
        let watch = new core.Stopwatch();
        // Function sendEvent: () → void
        function sendEvent() {
          watch.reset();
          let data = computation(computationCount++);
          controller.add(data);
        }
        // Function startPeriodicTimer: () → void
        function startPeriodicTimer() {
          dart.assert(timer === null);
          timer = new Timer.periodic(period, (timer) => {
            sendEvent();
          });
        }
        controller = new StreamController({sync: true, onListen: () => {
          watch.start();
          startPeriodicTimer();
        }, onPause: () => {
          timer.cancel();
          timer = null;
          watch.stop();
        }, onResume: () => {
          dart.assert(timer === null);
          let elapsed = watch.elapsed;
          watch.start();
          timer = new Timer(period['-'](elapsed), () => {
            timer = null;
            startPeriodicTimer();
            sendEvent();
          });
        }, onCancel: () => {
          if (timer !== null) timer.cancel();
          timer = null;
        }});
        return controller.stream;
      }
      /*constructor*/ eventTransformed(source, mapSink) {
        return dart.as(new _BoundSinkStream(source, mapSink), Stream$(T));
      }
      get isBroadcast() { return false; }
      asBroadcastStream(opt$) {
        let onListen = opt$.onListen === undefined ? null : opt$.onListen;
        let onCancel = opt$.onCancel === undefined ? null : opt$.onCancel;
        return new _AsBroadcastStream(this, onListen, onCancel);
      }
      where(test) {
        return new _WhereStream(this, test);
      }
      map(convert) {
        return new _MapStream(this, convert);
      }
      asyncMap(convert) {
        let controller = null;
        let subscription = null;
        // Function onListen: () → void
        function onListen() {
          let add = controller.add;
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = controller;
          let addError = eventSink._addError;
          subscription = this.listen((event) => {
            let newValue = null;
            try {
              newValue = convert(event);
            }
            catch (e) {
              let s = dart.stackTrace(e);
              controller.addError(e, s);
              return;
            }
            if (dart.is(newValue, Future)) {
              subscription.pause();
              dart.dinvoke(dart.dinvoke(newValue, "then", add, {onError: addError}), "whenComplete", subscription.resume);
            } else {
              controller.add(newValue);
            }
          }, dart.as(onError: addError, core.Function), {onDone: controller.close});
        }
        if (this.isBroadcast) {
          controller = new StreamController.broadcast({onListen: onListen, onCancel: () => {
            subscription.cancel();
          }, sync: true});
        } else {
          controller = new StreamController({onListen: onListen, onPause: () => {
            subscription.pause();
          }, onResume: () => {
            subscription.resume();
          }, onCancel: () => {
            subscription.cancel();
          }, sync: true});
        }
        return controller.stream;
      }
      asyncExpand(convert) {
        let controller = null;
        let subscription = null;
        // Function onListen: () → void
        function onListen() {
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = controller;
          subscription = this.listen((event) => {
            let newStream = null;
            try {
              newStream = convert(event);
            }
            catch (e) {
              let s = dart.stackTrace(e);
              controller.addError(e, s);
              return;
            }
            if (newStream !== null) {
              subscription.pause();
              controller.addStream(newStream).whenComplete(subscription.resume);
            }
          }, dart.as(onError: eventSink._addError, core.Function), {onDone: controller.close});
        }
        if (this.isBroadcast) {
          controller = new StreamController.broadcast({onListen: onListen, onCancel: () => {
            subscription.cancel();
          }, sync: true});
        } else {
          controller = new StreamController({onListen: onListen, onPause: () => {
            subscription.pause();
          }, onResume: () => {
            subscription.resume();
          }, onCancel: () => {
            subscription.cancel();
          }, sync: true});
        }
        return controller.stream;
      }
      handleError(onError, opt$) {
        let test = opt$.test === undefined ? null : opt$.test;
        return new _HandleErrorStream(this, onError, test);
      }
      expand(convert) {
        return new _ExpandStream(this, convert);
      }
      pipe(streamConsumer) {
        return streamConsumer.addStream(this).then((_) => streamConsumer.close());
      }
      transform(streamTransformer) {
        return streamTransformer.bind(this);
      }
      reduce(combine) {
        let result = new _Future();
        let seenFirst = false;
        let value = null;
        let subscription = null;
        subscription = this.listen((element) => {
          if (seenFirst) {
            _runUserCode(() => combine(value, element), dart.as((newValue) => {
              value = newValue;
            }, /* Unimplemented type (dynamic) → dynamic */), dart.as(_cancelAndErrorClosure(subscription, result), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
          } else {
            value = element;
            seenFirst = true;
          }
        }, {onError: result._completeError, onDone: () => {
          if (!seenFirst) {
            try {
              throw _internal.IterableElementError.noElement();
            }
            catch (e) {
              let s = dart.stackTrace(e);
              _completeWithErrorCallback(result, e, s);
            }
          } else {
            result._complete(value);
          }
        }, cancelOnError: true});
        return result;
      }
      fold(initialValue, combine) {
        let result = new _Future();
        let value = initialValue;
        let subscription = null;
        subscription = this.listen((element) => {
          _runUserCode(() => combine(value, element), (newValue) => {
            value = newValue;
          }, dart.as(_cancelAndErrorClosure(subscription, result), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: (e, st) => {
          result._completeError(e, dart.as(st, core.StackTrace));
        }, onDone: () => {
          result._complete(value);
        }, cancelOnError: true});
        return result;
      }
      join(separator) {
        if (separator === undefined) separator = "";
        let result = new _Future();
        let buffer = new core.StringBuffer();
        let subscription = null;
        let first = true;
        subscription = this.listen((element) => {
          if (!first) {
            buffer.write(separator);
          }
          first = false;
          try {
            buffer.write(element);
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _cancelAndErrorWithReplacement(subscription, result, e, s);
          }
        }, {onError: (e) => {
          result._completeError(e);
        }, onDone: () => {
          result._complete(buffer.toString());
        }, cancelOnError: true});
        return result;
      }
      contains(needle) {
        let future = new _Future();
        let subscription = null;
        subscription = this.listen((element) => {
          _runUserCode(() => (dart.equals(element, needle)), dart.as((isMatch) => {
            if (isMatch) {
              _cancelAndValue(subscription, future, true);
            }
          }, /* Unimplemented type (dynamic) → dynamic */), dart.as(_cancelAndErrorClosure(subscription, future), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: future._completeError, onDone: () => {
          future._complete(false);
        }, cancelOnError: true});
        return future;
      }
      forEach(action) {
        let future = new _Future();
        let subscription = null;
        subscription = this.listen((element) => {
          _runUserCode(() => action(element), (_) => {
          }, dart.as(_cancelAndErrorClosure(subscription, future), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: future._completeError, onDone: () => {
          future._complete(null);
        }, cancelOnError: true});
        return future;
      }
      every(test) {
        let future = new _Future();
        let subscription = null;
        subscription = this.listen((element) => {
          _runUserCode(() => test(element), dart.as((isMatch) => {
            if (!isMatch) {
              _cancelAndValue(subscription, future, false);
            }
          }, /* Unimplemented type (dynamic) → dynamic */), dart.as(_cancelAndErrorClosure(subscription, future), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: future._completeError, onDone: () => {
          future._complete(true);
        }, cancelOnError: true});
        return future;
      }
      any(test) {
        let future = new _Future();
        let subscription = null;
        subscription = this.listen((element) => {
          _runUserCode(() => test(element), dart.as((isMatch) => {
            if (isMatch) {
              _cancelAndValue(subscription, future, true);
            }
          }, /* Unimplemented type (dynamic) → dynamic */), dart.as(_cancelAndErrorClosure(subscription, future), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: future._completeError, onDone: () => {
          future._complete(false);
        }, cancelOnError: true});
        return future;
      }
      get length() {
        let future = new _Future();
        let count = 0;
        this.listen((_) => {
          count++;
        }, {onError: future._completeError, onDone: () => {
          future._complete(count);
        }, cancelOnError: true});
        return future;
      }
      get isEmpty() {
        let future = new _Future();
        let subscription = null;
        subscription = this.listen((_) => {
          _cancelAndValue(subscription, future, false);
        }, {onError: future._completeError, onDone: () => {
          future._complete(true);
        }, cancelOnError: true});
        return future;
      }
      toList() {
        let result = new List.from([]);
        let future = new _Future();
        this.listen((data) => {
          result.add(data);
        }, {onError: future._completeError, onDone: () => {
          future._complete(result);
        }, cancelOnError: true});
        return future;
      }
      toSet() {
        let result = new core.Set();
        let future = new _Future();
        this.listen((data) => {
          result.add(data);
        }, {onError: future._completeError, onDone: () => {
          future._complete(result);
        }, cancelOnError: true});
        return future;
      }
      drain(futureValue) {
        if (futureValue === undefined) futureValue = null;
        return this.listen(null, {cancelOnError: true}).asFuture(futureValue)
      }
      take(count) {
        return dart.as(new _TakeStream(this, count), Stream$(T));
      }
      takeWhile(test) {
        return dart.as(new _TakeWhileStream(this, test), Stream$(T));
      }
      skip(count) {
        return dart.as(new _SkipStream(this, count), Stream$(T));
      }
      skipWhile(test) {
        return dart.as(new _SkipWhileStream(this, test), Stream$(T));
      }
      distinct(equals) {
        if (equals === undefined) equals = null;
        return dart.as(new _DistinctStream(this, equals), Stream$(T));
      }
      get first() {
        let future = new _Future();
        let subscription = null;
        subscription = this.listen((value) => {
          _cancelAndValue(subscription, future, value);
        }, {onError: future._completeError, onDone: () => {
          try {
            throw _internal.IterableElementError.noElement();
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(future, e, s);
          }
        }, cancelOnError: true});
        return future;
      }
      get last() {
        let future = new _Future();
        let result = dart.as(null, T);
        let foundResult = false;
        let subscription = null;
        subscription = this.listen((value) => {
          foundResult = true;
          result = value;
        }, {onError: future._completeError, onDone: () => {
          if (foundResult) {
            future._complete(result);
            return;
          }
          try {
            throw _internal.IterableElementError.noElement();
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(future, e, s);
          }
        }, cancelOnError: true});
        return future;
      }
      get single() {
        let future = new _Future();
        let result = dart.as(null, T);
        let foundResult = false;
        let subscription = null;
        subscription = this.listen((value) => {
          if (foundResult) {
            try {
              throw _internal.IterableElementError.tooMany();
            }
            catch (e) {
              let s = dart.stackTrace(e);
              _cancelAndErrorWithReplacement(subscription, future, e, s);
            }
            return;
          }
          foundResult = true;
          result = value;
        }, {onError: future._completeError, onDone: () => {
          if (foundResult) {
            future._complete(result);
            return;
          }
          try {
            throw _internal.IterableElementError.noElement();
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(future, e, s);
          }
        }, cancelOnError: true});
        return future;
      }
      firstWhere(test, opt$) {
        let defaultValue = opt$.defaultValue === undefined ? null : opt$.defaultValue;
        let future = new _Future();
        let subscription = null;
        subscription = this.listen((value) => {
          _runUserCode(() => test(value), dart.as((isMatch) => {
            if (isMatch) {
              _cancelAndValue(subscription, future, value);
            }
          }, /* Unimplemented type (dynamic) → dynamic */), dart.as(_cancelAndErrorClosure(subscription, future), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: future._completeError, onDone: () => {
          if (defaultValue !== null) {
            _runUserCode(defaultValue, future._complete, future._completeError);
            return;
          }
          try {
            throw _internal.IterableElementError.noElement();
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(future, e, s);
          }
        }, cancelOnError: true});
        return future;
      }
      lastWhere(test, opt$) {
        let defaultValue = opt$.defaultValue === undefined ? null : opt$.defaultValue;
        let future = new _Future();
        let result = dart.as(null, T);
        let foundResult = false;
        let subscription = null;
        subscription = this.listen((value) => {
          _runUserCode(() => true === test(value), dart.as((isMatch) => {
            if (isMatch) {
              foundResult = true;
              result = value;
            }
          }, /* Unimplemented type (dynamic) → dynamic */), dart.as(_cancelAndErrorClosure(subscription, future), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: future._completeError, onDone: () => {
          if (foundResult) {
            future._complete(result);
            return;
          }
          if (defaultValue !== null) {
            _runUserCode(defaultValue, future._complete, future._completeError);
            return;
          }
          try {
            throw _internal.IterableElementError.noElement();
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(future, e, s);
          }
        }, cancelOnError: true});
        return future;
      }
      singleWhere(test) {
        let future = new _Future();
        let result = dart.as(null, T);
        let foundResult = false;
        let subscription = null;
        subscription = this.listen((value) => {
          _runUserCode(() => true === test(value), dart.as((isMatch) => {
            if (isMatch) {
              if (foundResult) {
                try {
                  throw _internal.IterableElementError.tooMany();
                }
                catch (e) {
                  let s = dart.stackTrace(e);
                  _cancelAndErrorWithReplacement(subscription, future, e, s);
                }
                return;
              }
              foundResult = true;
              result = value;
            }
          }, /* Unimplemented type (dynamic) → dynamic */), dart.as(_cancelAndErrorClosure(subscription, future), /* Unimplemented type (dynamic, StackTrace) → dynamic */));
        }, {onError: future._completeError, onDone: () => {
          if (foundResult) {
            future._complete(result);
            return;
          }
          try {
            throw _internal.IterableElementError.noElement();
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _completeWithErrorCallback(future, e, s);
          }
        }, cancelOnError: true});
        return future;
      }
      elementAt(index) {
        if (!(typeof index == "number") || index < 0) throw new core.ArgumentError(index);
        let future = new _Future();
        let subscription = null;
        let elementIndex = 0;
        subscription = this.listen((value) => {
          if (index === elementIndex) {
            _cancelAndValue(subscription, future, value);
            return;
          }
          elementIndex = 1;
        }, {onError: future._completeError, onDone: () => {
          future._completeError(new core.RangeError.index(index, this, "index", null, elementIndex));
        }, cancelOnError: true});
        return future;
      }
      timeout(timeLimit, opt$) {
        let onTimeout = opt$.onTimeout === undefined ? null : opt$.onTimeout;
        let controller = null;
        let subscription = null;
        let timer = null;
        let zone = null;
        let timeout = null;
        // Function onData: (T) → void
        function onData(event) {
          timer.cancel();
          controller.add(event);
          timer = zone.createTimer(timeLimit, dart.as(timeout, /* Unimplemented type () → void */));
        }
        // Function onError: (dynamic, StackTrace) → void
        function onError(error, stackTrace) {
          timer.cancel();
          dart.assert(dart.is(controller, _StreamController) || dart.is(controller, _BroadcastStreamController));
          let eventSink = controller;
          dart.dinvoke(eventSink, "_addError", error, stackTrace);
          timer = zone.createTimer(timeLimit, dart.as(timeout, /* Unimplemented type () → void */));
        }
        // Function onDone: () → void
        function onDone() {
          timer.cancel();
          controller.close();
        }
        // Function onListen: () → void
        function onListen() {
          zone = Zone.current;
          if (onTimeout === null) {
            timeout = () => {
              controller.addError(new TimeoutException("No stream event", timeLimit), null);
            };
          } else {
            onTimeout = zone.registerUnaryCallback(dart.as(onTimeout, /* Unimplemented type (dynamic) → dynamic */));
            let wrapper = new _ControllerEventSinkWrapper(null);
            timeout = () => {
              wrapper._sink = controller;
              zone.runUnaryGuarded(dart.as(onTimeout, /* Unimplemented type (dynamic) → dynamic */), wrapper);
              wrapper._sink = null;
            };
          }
          subscription = this.listen(onData, {onError: onError, onDone: onDone});
          timer = zone.createTimer(timeLimit, dart.as(timeout, /* Unimplemented type () → void */));
        }
        // Function onCancel: () → Future<dynamic>
        function onCancel() {
          timer.cancel();
          let result = subscription.cancel();
          subscription = null;
          return result;
        }
        controller = this.isBroadcast ? new _SyncBroadcastStreamController(onListen, onCancel) : new _SyncStreamController(onListen, () => {
          timer.cancel();
          subscription.pause();
        }, () => {
          subscription.resume();
          timer = zone.createTimer(timeLimit, dart.as(timeout, /* Unimplemented type () → void */));
        }, onCancel);
        return controller.stream;
      }
    }
    dart.defineNamedConstructor(Stream, "fromFuture");
    dart.defineNamedConstructor(Stream, "fromIterable");
    dart.defineNamedConstructor(Stream, "periodic");
    dart.defineNamedConstructor(Stream, "eventTransformed");
    return Stream;
  });
  let Stream = Stream$(dynamic);

  let StreamSubscription$ = dart.generic(function(T) {
    class StreamSubscription {
    }
    return StreamSubscription;
  });
  let StreamSubscription = StreamSubscription$(dynamic);

  let EventSink$ = dart.generic(function(T) {
    class EventSink {
    }
    return EventSink;
  });
  let EventSink = EventSink$(dynamic);

  let StreamView$ = dart.generic(function(T) {
    class StreamView extends Stream$(T) {
      constructor(_stream) {
        this._stream = _stream;
        super();
      }
      get isBroadcast() { return this._stream.isBroadcast; }
      asBroadcastStream(opt$) {
        let onListen = opt$.onListen === undefined ? null : opt$.onListen;
        let onCancel = opt$.onCancel === undefined ? null : opt$.onCancel;
        return this._stream.asBroadcastStream({onListen: onListen, onCancel: onCancel})
      }
      listen(onData, opt$) {
        let onError = opt$.onError === undefined ? null : opt$.onError;
        let onDone = opt$.onDone === undefined ? null : opt$.onDone;
        let cancelOnError = opt$.cancelOnError === undefined ? null : opt$.cancelOnError;
        return this._stream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
      }
    }
    return StreamView;
  });
  let StreamView = StreamView$(dynamic);

  let StreamConsumer$ = dart.generic(function(S) {
    class StreamConsumer {
    }
    return StreamConsumer;
  });
  let StreamConsumer = StreamConsumer$(dynamic);

  let StreamSink$ = dart.generic(function(S) {
    class StreamSink {
    }
    return StreamSink;
  });
  let StreamSink = StreamSink$(dynamic);

  let StreamTransformer$ = dart.generic(function(S, T) {
    class StreamTransformer {
      constructor(transformer) {
        return new _StreamSubscriptionTransformer(transformer);
      }
      /*constructor*/ fromHandlers(opt$) {
        return new _StreamHandlerTransformer(opt$);
      }
    }
    dart.defineNamedConstructor(StreamTransformer, "fromHandlers");
    return StreamTransformer;
  });
  let StreamTransformer = StreamTransformer$(dynamic, dynamic);

  let StreamIterator$ = dart.generic(function(T) {
    class StreamIterator {
      constructor(stream) {
        return new _StreamIteratorImpl(stream);
      }
    }
    return StreamIterator;
  });
  let StreamIterator = StreamIterator$(dynamic);

  let _ControllerEventSinkWrapper$ = dart.generic(function(T) {
    class _ControllerEventSinkWrapper {
      constructor(_sink) {
        this._sink = _sink;
      }
      add(data) {
        this._sink.add(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        this._sink.addError(error, stackTrace);
      }
      close() {
        this._sink.close();
      }
    }
    return _ControllerEventSinkWrapper;
  });
  let _ControllerEventSinkWrapper = _ControllerEventSinkWrapper$(dynamic);

  let StreamController$ = dart.generic(function(T) {
    class StreamController {
      constructor(opt$) {
        let onListen = opt$.onListen === undefined ? null : opt$.onListen;
        let onPause = opt$.onPause === undefined ? null : opt$.onPause;
        let onResume = opt$.onResume === undefined ? null : opt$.onResume;
        let onCancel = opt$.onCancel === undefined ? null : opt$.onCancel;
        let sync = opt$.sync === undefined ? false : opt$.sync;
        if (onListen === null && onPause === null && onResume === null && onCancel === null) {
          return dart.as(sync ? new _NoCallbackSyncStreamController() : new _NoCallbackAsyncStreamController(), StreamController$(T));
        }
        return sync ? new _SyncStreamController(onListen, onPause, onResume, onCancel) : new _AsyncStreamController(onListen, onPause, onResume, onCancel);
      }
      /*constructor*/ broadcast(opt$) {
        let onListen = opt$.onListen === undefined ? null : opt$.onListen;
        let onCancel = opt$.onCancel === undefined ? null : opt$.onCancel;
        let sync = opt$.sync === undefined ? false : opt$.sync;
        return sync ? new _SyncBroadcastStreamController(onListen, onCancel) : new _AsyncBroadcastStreamController(onListen, onCancel);
      }
    }
    dart.defineNamedConstructor(StreamController, "broadcast");
    return StreamController;
  });
  let StreamController = StreamController$(dynamic);

  let _StreamControllerLifecycle$ = dart.generic(function(T) {
    class _StreamControllerLifecycle {
      _recordPause(subscription) {
      }
      _recordResume(subscription) {
      }
      _recordCancel(subscription) { return null; }
    }
    return _StreamControllerLifecycle;
  });
  let _StreamControllerLifecycle = _StreamControllerLifecycle$(dynamic);

  let _StreamController$ = dart.generic(function(T) {
    class _StreamController {
      constructor() {
        this._varData = null;
        this._state = _STATE_INITIAL;
        this._doneFuture = null;
      }
      get stream() { return dart.as(new _ControllerStream(this), Stream$(T)); }
      get sink() { return new _StreamSinkWrapper(this); }
      get _isCanceled() { return (this._state & _STATE_CANCELED) !== 0; }
      get hasListener() { return (this._state & _STATE_SUBSCRIBED) !== 0; }
      get _isInitialState() { return (this._state & _STATE_SUBSCRIPTION_MASK) === _STATE_INITIAL; }
      get isClosed() { return (this._state & _STATE_CLOSED) !== 0; }
      get isPaused() { return this.hasListener ? this._subscription._isInputPaused : !this._isCanceled; }
      get _isAddingStream() { return (this._state & _STATE_ADDSTREAM) !== 0; }
      get _mayAddEvent() { return (this._state < _STATE_CLOSED); }
      get _pendingEvents() {
        dart.assert(this._isInitialState);
        if (!this._isAddingStream) {
          return dart.as(this._varData, _PendingEvents);
        }
        let state = dart.as(this._varData, _StreamControllerAddStreamState);
        return dart.as(state.varData, _PendingEvents);
      }
      _ensurePendingEvents() {
        dart.assert(this._isInitialState);
        if (!this._isAddingStream) {
          if (this._varData === null) this._varData = new _StreamImplEvents();
          return dart.as(this._varData, _StreamImplEvents);
        }
        let state = dart.as(this._varData, _StreamControllerAddStreamState);
        if (state.varData === null) state.varData = new _StreamImplEvents();
        return dart.as(state.varData, _StreamImplEvents);
      }
      get _subscription() {
        dart.assert(this.hasListener);
        if (this._isAddingStream) {
          let addState = dart.as(this._varData, _StreamControllerAddStreamState);
          return dart.as(addState.varData, _ControllerSubscription);
        }
        return dart.as(this._varData, _ControllerSubscription);
      }
      _badEventState() {
        if (this.isClosed) {
          return new core.StateError("Cannot add event after closing");
        }
        dart.assert(this._isAddingStream);
        return new core.StateError("Cannot add event while adding a stream");
      }
      addStream(source, opt$) {
        let cancelOnError = opt$.cancelOnError === undefined ? true : opt$.cancelOnError;
        if (!this._mayAddEvent) throw this._badEventState();
        if (this._isCanceled) return new _Future.immediate(null);
        let addState = new _StreamControllerAddStreamState(this, this._varData, source, cancelOnError);
        this._varData = addState;
        this._state = _STATE_ADDSTREAM;
        return addState.addStreamFuture;
      }
      get done() { return this._ensureDoneFuture(); }
      _ensureDoneFuture() {
        if (this._doneFuture === null) {
          this._doneFuture = this._isCanceled ? Future._nullFuture : new _Future();
        }
        return this._doneFuture;
      }
      add(value) {
        if (!this._mayAddEvent) throw this._badEventState();
        this._add(value);
      }
      addError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        error = _nonNullError(error);
        if (!this._mayAddEvent) throw this._badEventState();
        let replacement = Zone.current.errorCallback(error, stackTrace);
        if (replacement !== null) {
          error = _nonNullError(replacement.error);
          stackTrace = replacement.stackTrace;
        }
        this._addError(error, stackTrace);
      }
      close() {
        if (this.isClosed) {
          return this._ensureDoneFuture();
        }
        if (!this._mayAddEvent) throw this._badEventState();
        this._closeUnchecked();
        return this._ensureDoneFuture();
      }
      _closeUnchecked() {
        this._state = _STATE_CLOSED;
        if (this.hasListener) {
          this._sendDone();
        } else if (this._isInitialState) {
          this._ensurePendingEvents().add(new _DelayedDone());
        }
      }
      _add(value) {
        if (this.hasListener) {
          this._sendData(value);
        } else if (this._isInitialState) {
          this._ensurePendingEvents().add(new _DelayedData(value));
        }
      }
      _addError(error, stackTrace) {
        if (this.hasListener) {
          this._sendError(error, stackTrace);
        } else if (this._isInitialState) {
          this._ensurePendingEvents().add(new _DelayedError(error, stackTrace));
        }
      }
      _close() {
        dart.assert(this._isAddingStream);
        let addState = dart.as(this._varData, _StreamControllerAddStreamState);
        this._varData = addState.varData;
        this._state = ~_STATE_ADDSTREAM;
        addState.complete();
      }
      _subscribe(onData, onError, onDone, cancelOnError) {
        if (!this._isInitialState) {
          throw new core.StateError("Stream has already been listened to.");
        }
        let subscription = new _ControllerSubscription(this, onData, onError, onDone, cancelOnError);
        let pendingEvents = this._pendingEvents;
        this._state = _STATE_SUBSCRIBED;
        if (this._isAddingStream) {
          let addState = dart.as(this._varData, _StreamControllerAddStreamState);
          addState.varData = subscription;
          addState.resume();
        } else {
          this._varData = subscription;
        }
        subscription._setPendingEvents(pendingEvents);
        subscription._guardCallback(() => {
          _runGuarded(this._onListen);
        });
        return dart.as(subscription, StreamSubscription$(T));
      }
      _recordCancel(subscription) {
        let result = null;
        if (this._isAddingStream) {
          let addState = dart.as(this._varData, _StreamControllerAddStreamState);
          result = addState.cancel();
        }
        this._varData = null;
        this._state = (this._state & ~(_STATE_SUBSCRIBED | _STATE_ADDSTREAM)) | _STATE_CANCELED;
        if (this._onCancel !== null) {
          if (result === null) {
            try {
              result = dart.as(this._onCancel(), Future);
            }
            catch (e) {
              let s = dart.stackTrace(e);
              result = ((_) => {
                _._asyncCompleteError(e, s);
                return _;
              })(new _Future());
            }
          } else {
            result = result.whenComplete(this._onCancel);
          }
        }
        // Function complete: () → void
        function complete() {
          if (this._doneFuture !== null && this._doneFuture._mayComplete) {
            this._doneFuture._asyncComplete(null);
          }
        }
        if (result !== null) {
          result = result.whenComplete(complete);
        } else {
          complete();
        }
        return result;
      }
      _recordPause(subscription) {
        if (this._isAddingStream) {
          let addState = dart.as(this._varData, _StreamControllerAddStreamState);
          addState.pause();
        }
        _runGuarded(this._onPause);
      }
      _recordResume(subscription) {
        if (this._isAddingStream) {
          let addState = dart.as(this._varData, _StreamControllerAddStreamState);
          addState.resume();
        }
        _runGuarded(this._onResume);
      }
    }
    _StreamController._STATE_INITIAL = 0;
    _StreamController._STATE_SUBSCRIBED = 1;
    _StreamController._STATE_CANCELED = 2;
    _StreamController._STATE_SUBSCRIPTION_MASK = 3;
    _StreamController._STATE_CLOSED = 4;
    _StreamController._STATE_ADDSTREAM = 8;
    return _StreamController;
  });
  let _StreamController = _StreamController$(dynamic);

  let _SyncStreamControllerDispatch$ = dart.generic(function(T) {
    class _SyncStreamControllerDispatch {
      _sendData(data) {
        this._subscription._add(data);
      }
      _sendError(error, stackTrace) {
        this._subscription._addError(error, stackTrace);
      }
      _sendDone() {
        this._subscription._close();
      }
    }
    return _SyncStreamControllerDispatch;
  });
  let _SyncStreamControllerDispatch = _SyncStreamControllerDispatch$(dynamic);

  let _AsyncStreamControllerDispatch$ = dart.generic(function(T) {
    class _AsyncStreamControllerDispatch {
      _sendData(data) {
        this._subscription._addPending(new _DelayedData(data));
      }
      _sendError(error, stackTrace) {
        this._subscription._addPending(new _DelayedError(error, stackTrace));
      }
      _sendDone() {
        this._subscription._addPending(new _DelayedDone());
      }
    }
    return _AsyncStreamControllerDispatch;
  });
  let _AsyncStreamControllerDispatch = _AsyncStreamControllerDispatch$(dynamic);

  let _AsyncStreamController$ = dart.generic(function(T) {
    class _AsyncStreamController extends dart.mixin(_StreamController$(T), _AsyncStreamControllerDispatch$(T)) {
      constructor(_onListen, _onPause, _onResume, _onCancel) {
        this._onListen = _onListen;
        this._onPause = _onPause;
        this._onResume = _onResume;
        this._onCancel = _onCancel;
        super();
      }
    }
    return _AsyncStreamController;
  });
  let _AsyncStreamController = _AsyncStreamController$(dynamic);

  let _SyncStreamController$ = dart.generic(function(T) {
    class _SyncStreamController extends dart.mixin(_StreamController$(T), _SyncStreamControllerDispatch$(T)) {
      constructor(_onListen, _onPause, _onResume, _onCancel) {
        this._onListen = _onListen;
        this._onPause = _onPause;
        this._onResume = _onResume;
        this._onCancel = _onCancel;
        super();
      }
    }
    return _SyncStreamController;
  });
  let _SyncStreamController = _SyncStreamController$(dynamic);

  class _NoCallbacks {
    get _onListen() { return null; }
    get _onPause() { return null; }
    get _onResume() { return null; }
    get _onCancel() { return null; }
  }

  class _NoCallbackAsyncStreamController extends dart.mixin(_AsyncStreamControllerDispatch, _NoCallbacks) {}

  class _NoCallbackSyncStreamController extends dart.mixin(_SyncStreamControllerDispatch, _NoCallbacks) {}

  // Function _runGuarded: (() → dynamic) → Future<dynamic>
  function _runGuarded(notificationHandler) {
    if (notificationHandler === null) return null;
    try {
      let result = notificationHandler();
      if (dart.is(result, Future)) return dart.as(result, Future);
      return null;
    }
    catch (e) {
      let s = dart.stackTrace(e);
      Zone.current.handleUncaughtError(e, s);
    }
  }

  let _ControllerStream$ = dart.generic(function(T) {
    class _ControllerStream extends _StreamImpl$(T) {
      constructor(_controller) {
        this._controller = _controller;
        super();
      }
      _createSubscription(onData, onError, onDone, cancelOnError) { return this._controller._subscribe(onData, onError, onDone, cancelOnError); }
      get hashCode() { return this._controller.hashCode ^ 892482866; }
      ['=='](other) {
        if (core.identical(this, other)) return true;
        if (!dart.is(other, _ControllerStream)) return false;
        let otherStream = dart.as(other, _ControllerStream);
        return core.identical(otherStream._controller, this._controller);
      }
    }
    return _ControllerStream;
  });
  let _ControllerStream = _ControllerStream$(dynamic);

  let _ControllerSubscription$ = dart.generic(function(T) {
    class _ControllerSubscription extends _BufferingStreamSubscription$(T) {
      constructor(_controller, onData, onError, onDone, cancelOnError) {
        this._controller = _controller;
        super(onData, onError, onDone, cancelOnError);
      }
      _onCancel() {
        return this._controller._recordCancel(this);
      }
      _onPause() {
        this._controller._recordPause(this);
      }
      _onResume() {
        this._controller._recordResume(this);
      }
    }
    return _ControllerSubscription;
  });
  let _ControllerSubscription = _ControllerSubscription$(dynamic);

  let _StreamSinkWrapper$ = dart.generic(function(T) {
    class _StreamSinkWrapper {
      constructor(_target) {
        this._target = _target;
      }
      add(data) {
        this._target.add(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        this._target.addError(error, stackTrace);
      }
      close() { return this._target.close(); }
      addStream(source, opt$) {
        let cancelOnError = opt$.cancelOnError === undefined ? true : opt$.cancelOnError;
        return this._target.addStream(source, {cancelOnError: cancelOnError})
      }
      get done() { return this._target.done; }
    }
    return _StreamSinkWrapper;
  });
  let _StreamSinkWrapper = _StreamSinkWrapper$(dynamic);

  let _AddStreamState$ = dart.generic(function(T) {
    class _AddStreamState {
      constructor(controller, source, cancelOnError) {
        this.addStreamFuture = new _Future();
        this.addSubscription = source.listen(dart.as(controller._add, /* Unimplemented type (dynamic) → void */), dart.as(onError: cancelOnError ? makeErrorHandler(controller) : controller._addError, core.Function), {onDone: controller._close, cancelOnError: cancelOnError});
      }
      static makeErrorHandler(controller) { return (e, s) => {
        controller._addError(e, s);
        controller._close();
      }; }
      pause() {
        this.addSubscription.pause();
      }
      resume() {
        this.addSubscription.resume();
      }
      cancel() {
        let cancel = this.addSubscription.cancel();
        if (cancel === null) {
          this.addStreamFuture._asyncComplete(null);
          return null;
        }
        return cancel.whenComplete(() => {
          this.addStreamFuture._asyncComplete(null);
        });
      }
      complete() {
        this.addStreamFuture._asyncComplete(null);
      }
    }
    return _AddStreamState;
  });
  let _AddStreamState = _AddStreamState$(dynamic);

  let _StreamControllerAddStreamState$ = dart.generic(function(T) {
    class _StreamControllerAddStreamState extends _AddStreamState$(T) {
      constructor(controller, varData, source, cancelOnError) {
        this.varData = varData;
        super(dart.as(controller, _EventSink$(T)), source, cancelOnError);
        if (controller.isPaused) {
          this.addSubscription.pause();
        }
      }
    }
    return _StreamControllerAddStreamState;
  });
  let _StreamControllerAddStreamState = _StreamControllerAddStreamState$(dynamic);

  let _EventSink$ = dart.generic(function(T) {
    class _EventSink {
    }
    return _EventSink;
  });
  let _EventSink = _EventSink$(dynamic);

  let _EventDispatch$ = dart.generic(function(T) {
    class _EventDispatch {
    }
    return _EventDispatch;
  });
  let _EventDispatch = _EventDispatch$(dynamic);

  let _BufferingStreamSubscription$ = dart.generic(function(T) {
    class _BufferingStreamSubscription {
      constructor(onData, onError, onDone, cancelOnError) {
        this._zone = Zone.current;
        this._state = (cancelOnError ? _STATE_CANCEL_ON_ERROR : 0);
        this._onData = null;
        this._onError = null;
        this._onDone = null;
        this._cancelFuture = null;
        this._pending = null;
        this.onData(onData);
        this.onError(onError);
        this.onDone(onDone);
      }
      _setPendingEvents(pendingEvents) {
        dart.assert(this._pending === null);
        if (pendingEvents === null) return;
        this._pending = pendingEvents;
        if (!pendingEvents.isEmpty) {
          this._state = _STATE_HAS_PENDING;
          this._pending.schedule(this);
        }
      }
      _extractPending() {
        dart.assert(this._isCanceled);
        let events = this._pending;
        this._pending = null;
        return events;
      }
      onData(handleData) {
        if (handleData === null) handleData = _nullDataHandler;
        this._onData = this._zone.registerUnaryCallback(dart.as(handleData, /* Unimplemented type (dynamic) → dynamic */));
      }
      onError(handleError) {
        if (handleError === null) handleError = _nullErrorHandler;
        this._onError = _registerErrorHandler(handleError, this._zone);
      }
      onDone(handleDone) {
        if (handleDone === null) handleDone = _nullDoneHandler;
        this._onDone = this._zone.registerCallback(handleDone);
      }
      pause(resumeSignal) {
        if (resumeSignal === undefined) resumeSignal = null;
        if (this._isCanceled) return;
        let wasPaused = this._isPaused;
        let wasInputPaused = this._isInputPaused;
        this._state = (this._state + _STATE_PAUSE_COUNT) | _STATE_INPUT_PAUSED;
        if (resumeSignal !== null) resumeSignal.whenComplete(this.resume);
        if (!wasPaused && this._pending !== null) this._pending.cancelSchedule();
        if (!wasInputPaused && !this._inCallback) this._guardCallback(this._onPause);
      }
      resume() {
        if (this._isCanceled) return;
        if (this._isPaused) {
          this._decrementPauseCount();
          if (!this._isPaused) {
            if (this._hasPending && !this._pending.isEmpty) {
              this._pending.schedule(this);
            } else {
              dart.assert(this._mayResumeInput);
              this._state = ~_STATE_INPUT_PAUSED;
              if (!this._inCallback) this._guardCallback(this._onResume);
            }
          }
        }
      }
      cancel() {
        this._state = ~_STATE_WAIT_FOR_CANCEL;
        if (this._isCanceled) return this._cancelFuture;
        this._cancel();
        return this._cancelFuture;
      }
      asFuture(futureValue) {
        if (futureValue === undefined) futureValue = null;
        let result = new _Future();
        this._onDone = () => {
          result._complete(futureValue);
        };
        this._onError = (error, stackTrace) => {
          this.cancel();
          result._completeError(error, dart.as(stackTrace, core.StackTrace));
        };
        return result;
      }
      get _isInputPaused() { return (this._state & _STATE_INPUT_PAUSED) !== 0; }
      get _isClosed() { return (this._state & _STATE_CLOSED) !== 0; }
      get _isCanceled() { return (this._state & _STATE_CANCELED) !== 0; }
      get _waitsForCancel() { return (this._state & _STATE_WAIT_FOR_CANCEL) !== 0; }
      get _inCallback() { return (this._state & _STATE_IN_CALLBACK) !== 0; }
      get _hasPending() { return (this._state & _STATE_HAS_PENDING) !== 0; }
      get _isPaused() { return this._state >= _STATE_PAUSE_COUNT; }
      get _canFire() { return this._state < _STATE_IN_CALLBACK; }
      get _mayResumeInput() { return !this._isPaused && (this._pending === null || this._pending.isEmpty); }
      get _cancelOnError() { return (this._state & _STATE_CANCEL_ON_ERROR) !== 0; }
      get isPaused() { return this._isPaused; }
      _cancel() {
        this._state = _STATE_CANCELED;
        if (this._hasPending) {
          this._pending.cancelSchedule();
        }
        if (!this._inCallback) this._pending = null;
        this._cancelFuture = this._onCancel();
      }
      _incrementPauseCount() {
        this._state = (this._state + _STATE_PAUSE_COUNT) | _STATE_INPUT_PAUSED;
      }
      _decrementPauseCount() {
        dart.assert(this._isPaused);
        this._state = _STATE_PAUSE_COUNT;
      }
      _add(data) {
        dart.assert(!this._isClosed);
        if (this._isCanceled) return;
        if (this._canFire) {
          this._sendData(data);
        } else {
          this._addPending(new _DelayedData(data));
        }
      }
      _addError(error, stackTrace) {
        if (this._isCanceled) return;
        if (this._canFire) {
          this._sendError(error, stackTrace);
        } else {
          this._addPending(new _DelayedError(error, stackTrace));
        }
      }
      _close() {
        dart.assert(!this._isClosed);
        if (this._isCanceled) return;
        this._state = _STATE_CLOSED;
        if (this._canFire) {
          this._sendDone();
        } else {
          this._addPending(new _DelayedDone());
        }
      }
      _onPause() {
        dart.assert(this._isInputPaused);
      }
      _onResume() {
        dart.assert(!this._isInputPaused);
      }
      _onCancel() {
        dart.assert(this._isCanceled);
        return null;
      }
      _addPending(event) {
        let pending = dart.as(this._pending, _StreamImplEvents);
        if (this._pending === null) pending = this._pending = new _StreamImplEvents();
        pending.add(event);
        if (!this._hasPending) {
          this._state = _STATE_HAS_PENDING;
          if (!this._isPaused) {
            this._pending.schedule(this);
          }
        }
      }
      _sendData(data) {
        dart.assert(!this._isCanceled);
        dart.assert(!this._isPaused);
        dart.assert(!this._inCallback);
        let wasInputPaused = this._isInputPaused;
        this._state = _STATE_IN_CALLBACK;
        this._zone.runUnaryGuarded(dart.as(this._onData, /* Unimplemented type (dynamic) → dynamic */), data);
        this._state = ~_STATE_IN_CALLBACK;
        this._checkState(wasInputPaused);
      }
      _sendError(error, stackTrace) {
        dart.assert(!this._isCanceled);
        dart.assert(!this._isPaused);
        dart.assert(!this._inCallback);
        let wasInputPaused = this._isInputPaused;
        // Function sendError: () → void
        function sendError() {
          if (this._isCanceled && !this._waitsForCancel) return;
          this._state = _STATE_IN_CALLBACK;
          if (dart.is(this._onError, ZoneBinaryCallback)) {
            this._zone.runBinaryGuarded(dart.as(this._onError, /* Unimplemented type (dynamic, dynamic) → dynamic */), error, stackTrace);
          } else {
            this._zone.runUnaryGuarded(dart.as(this._onError, /* Unimplemented type (dynamic) → dynamic */), error);
          }
          this._state = ~_STATE_IN_CALLBACK;
        }
        if (this._cancelOnError) {
          this._state = _STATE_WAIT_FOR_CANCEL;
          this._cancel();
          if (dart.is(this._cancelFuture, Future)) {
            this._cancelFuture.whenComplete(sendError);
          } else {
            sendError();
          }
        } else {
          sendError();
          this._checkState(wasInputPaused);
        }
      }
      _sendDone() {
        dart.assert(!this._isCanceled);
        dart.assert(!this._isPaused);
        dart.assert(!this._inCallback);
        // Function sendDone: () → void
        function sendDone() {
          if (!this._waitsForCancel) return;
          this._state = (_STATE_CANCELED | _STATE_CLOSED | _STATE_IN_CALLBACK);
          this._zone.runGuarded(this._onDone);
          this._state = ~_STATE_IN_CALLBACK;
        }
        this._cancel();
        this._state = _STATE_WAIT_FOR_CANCEL;
        if (dart.is(this._cancelFuture, Future)) {
          this._cancelFuture.whenComplete(sendDone);
        } else {
          sendDone();
        }
      }
      _guardCallback(callback) {
        dart.assert(!this._inCallback);
        let wasInputPaused = this._isInputPaused;
        this._state = _STATE_IN_CALLBACK;
        dart.dinvokef(callback);
        this._state = ~_STATE_IN_CALLBACK;
        this._checkState(wasInputPaused);
      }
      _checkState(wasInputPaused) {
        dart.assert(!this._inCallback);
        if (this._hasPending && this._pending.isEmpty) {
          this._state = ~_STATE_HAS_PENDING;
          if (this._isInputPaused && this._mayResumeInput) {
            this._state = ~_STATE_INPUT_PAUSED;
          }
        }
        while (true) {
          if (this._isCanceled) {
            this._pending = null;
            return;
          }
          let isInputPaused = this._isInputPaused;
          if (wasInputPaused === isInputPaused) break;
          this._state = _STATE_IN_CALLBACK;
          if (isInputPaused) {
            this._onPause();
          } else {
            this._onResume();
          }
          this._state = ~_STATE_IN_CALLBACK;
          wasInputPaused = isInputPaused;
        }
        if (this._hasPending && !this._isPaused) {
          this._pending.schedule(this);
        }
      }
    }
    _BufferingStreamSubscription._STATE_CANCEL_ON_ERROR = 1;
    _BufferingStreamSubscription._STATE_CLOSED = 2;
    _BufferingStreamSubscription._STATE_INPUT_PAUSED = 4;
    _BufferingStreamSubscription._STATE_CANCELED = 8;
    _BufferingStreamSubscription._STATE_WAIT_FOR_CANCEL = 16;
    _BufferingStreamSubscription._STATE_IN_CALLBACK = 32;
    _BufferingStreamSubscription._STATE_HAS_PENDING = 64;
    _BufferingStreamSubscription._STATE_PAUSE_COUNT = 128;
    _BufferingStreamSubscription._STATE_PAUSE_COUNT_SHIFT = 7;
    return _BufferingStreamSubscription;
  });
  let _BufferingStreamSubscription = _BufferingStreamSubscription$(dynamic);

  let _StreamImpl$ = dart.generic(function(T) {
    class _StreamImpl extends Stream$(T) {
      listen(onData, opt$) {
        let onError = opt$.onError === undefined ? null : opt$.onError;
        let onDone = opt$.onDone === undefined ? null : opt$.onDone;
        let cancelOnError = opt$.cancelOnError === undefined ? null : opt$.cancelOnError;
        cancelOnError = core.identical(true, cancelOnError);
        let subscription = this._createSubscription(onData, onError, onDone, cancelOnError);
        this._onListen(subscription);
        return dart.as(subscription, StreamSubscription$(T));
      }
      _createSubscription(onData, onError, onDone, cancelOnError) {
        return new _BufferingStreamSubscription(onData, onError, onDone, cancelOnError);
      }
      _onListen(subscription) {
      }
    }
    return _StreamImpl;
  });
  let _StreamImpl = _StreamImpl$(dynamic);

  let _GeneratedStreamImpl$ = dart.generic(function(T) {
    class _GeneratedStreamImpl extends _StreamImpl$(T) {
      constructor(_pending) {
        this._pending = _pending;
        this._isUsed = false;
        super();
      }
      _createSubscription(onData, onError, onDone, cancelOnError) {
        if (this._isUsed) throw new core.StateError("Stream has already been listened to.");
        this._isUsed = true;
        return ((_) => {
          _._setPendingEvents(this._pending());
          return _;
        })(new _BufferingStreamSubscription(onData, onError, onDone, cancelOnError));
      }
    }
    return _GeneratedStreamImpl;
  });
  let _GeneratedStreamImpl = _GeneratedStreamImpl$(dynamic);

  let _IterablePendingEvents$ = dart.generic(function(T) {
    class _IterablePendingEvents extends _PendingEvents {
      constructor(data) {
        this._iterator = data.iterator;
        super();
      }
      get isEmpty() { return this._iterator === null; }
      handleNext(dispatch) {
        if (this._iterator === null) {
          throw new core.StateError("No events pending.");
        }
        let isDone = null;
        try {
          isDone = !this._iterator.moveNext();
        }
        catch (e) {
          let s = dart.stackTrace(e);
          this._iterator = null;
          dispatch._sendError(e, s);
          return;
        }
        if (!isDone) {
          dispatch._sendData(this._iterator.current);
        } else {
          this._iterator = null;
          dispatch._sendDone();
        }
      }
      clear() {
        if (this.isScheduled) this.cancelSchedule();
        this._iterator = null;
      }
    }
    return _IterablePendingEvents;
  });
  let _IterablePendingEvents = _IterablePendingEvents$(dynamic);

  // Function _nullDataHandler: (dynamic) → void
  function _nullDataHandler(value) {
  }

  // Function _nullErrorHandler: (dynamic, [StackTrace]) → void
  function _nullErrorHandler(error, stackTrace) {
    if (stackTrace === undefined) stackTrace = null;
    Zone.current.handleUncaughtError(error, stackTrace);
  }

  // Function _nullDoneHandler: () → void
  function _nullDoneHandler() {
  }

  class _DelayedEvent {
    constructor() {
      this.next = null;
      super();
    }
  }

  let _DelayedData$ = dart.generic(function(T) {
    class _DelayedData extends _DelayedEvent {
      constructor(value) {
        this.value = value;
        super();
      }
      perform(dispatch) {
        dispatch._sendData(this.value);
      }
    }
    return _DelayedData;
  });
  let _DelayedData = _DelayedData$(dynamic);

  class _DelayedError extends _DelayedEvent {
    constructor(error, stackTrace) {
      this.error = error;
      this.stackTrace = stackTrace;
      super();
    }
    perform(dispatch) {
      dispatch._sendError(this.error, this.stackTrace);
    }
  }

  class _DelayedDone {
    constructor() {
    }
    perform(dispatch) {
      dispatch._sendDone();
    }
    get next() { return null; }
    set next(_) {
      throw new core.StateError("No events after a done.");
    }
  }

  class _PendingEvents {
    constructor() {
      this._state = _STATE_UNSCHEDULED;
      super();
    }
    get isScheduled() { return this._state === _STATE_SCHEDULED; }
    get _eventScheduled() { return this._state >= _STATE_SCHEDULED; }
    schedule(dispatch) {
      if (this.isScheduled) return;
      dart.assert(!this.isEmpty);
      if (this._eventScheduled) {
        dart.assert(this._state === _STATE_CANCELED);
        this._state = _STATE_SCHEDULED;
        return;
      }
      scheduleMicrotask(() => {
        let oldState = this._state;
        this._state = _STATE_UNSCHEDULED;
        if (oldState === _STATE_CANCELED) return;
        this.handleNext(dispatch);
      });
      this._state = _STATE_SCHEDULED;
    }
    cancelSchedule() {
      if (this.isScheduled) this._state = _STATE_CANCELED;
    }
  }
  _PendingEvents._STATE_UNSCHEDULED = 0;
  _PendingEvents._STATE_SCHEDULED = 1;
  _PendingEvents._STATE_CANCELED = 3;

  class _StreamImplEvents extends _PendingEvents {
    constructor() {
      this.firstPendingEvent = null;
      this.lastPendingEvent = null;
      super();
    }
    get isEmpty() { return this.lastPendingEvent === null; }
    add(event) {
      if (this.lastPendingEvent === null) {
        this.firstPendingEvent = this.lastPendingEvent = event;
      } else {
        this.lastPendingEvent = this.lastPendingEvent.next = event;
      }
    }
    handleNext(dispatch) {
      dart.assert(!this.isScheduled);
      let event = this.firstPendingEvent;
      this.firstPendingEvent = event.next;
      if (this.firstPendingEvent === null) {
        this.lastPendingEvent = null;
      }
      event.perform(dispatch);
    }
    clear() {
      if (this.isScheduled) this.cancelSchedule();
      this.firstPendingEvent = this.lastPendingEvent = null;
    }
  }

  class _BroadcastLinkedList {
    constructor() {
      this._next = null;
      this._previous = null;
      super();
    }
    _unlink() {
      this._previous._next = this._next;
      this._next._previous = this._previous;
      this._next = this._previous = this;
    }
    _insertBefore(newNext) {
      let newPrevious = newNext._previous;
      newPrevious._next = this;
      newNext._previous = this._previous;
      this._previous._next = newNext;
      this._previous = newPrevious;
    }
  }

  let _DoneStreamSubscription$ = dart.generic(function(T) {
    class _DoneStreamSubscription {
      constructor(_onDone) {
        this._onDone = _onDone;
        this._zone = Zone.current;
        this._state = 0;
        this._schedule();
      }
      get _isSent() { return (this._state & _DONE_SENT) !== 0; }
      get _isScheduled() { return (this._state & _SCHEDULED) !== 0; }
      get isPaused() { return this._state >= _PAUSED; }
      _schedule() {
        if (this._isScheduled) return;
        this._zone.scheduleMicrotask(this._sendDone);
        this._state = _SCHEDULED;
      }
      onData(handleData) {
      }
      onError(handleError) {
      }
      onDone(handleDone) {
        this._onDone = handleDone;
      }
      pause(resumeSignal) {
        if (resumeSignal === undefined) resumeSignal = null;
        this._state = _PAUSED;
        if (resumeSignal !== null) resumeSignal.whenComplete(this.resume);
      }
      resume() {
        if (this.isPaused) {
          this._state = _PAUSED;
          if (!this.isPaused && !this._isSent) {
            this._schedule();
          }
        }
      }
      cancel() { return null; }
      asFuture(futureValue) {
        if (futureValue === undefined) futureValue = null;
        let result = new _Future();
        this._onDone = () => {
          result._completeWithValue(null);
        };
        return result;
      }
      _sendDone() {
        this._state = ~_SCHEDULED;
        if (this.isPaused) return;
        this._state = _DONE_SENT;
        if (this._onDone !== null) this._zone.runGuarded(this._onDone);
      }
    }
    _DoneStreamSubscription._DONE_SENT = 1;
    _DoneStreamSubscription._SCHEDULED = 2;
    _DoneStreamSubscription._PAUSED = 4;
    return _DoneStreamSubscription;
  });
  let _DoneStreamSubscription = _DoneStreamSubscription$(dynamic);

  let _AsBroadcastStream$ = dart.generic(function(T) {
    class _AsBroadcastStream extends Stream$(T) {
      constructor(_source, onListenHandler, onCancelHandler) {
        this._source = _source;
        this._onListenHandler = Zone.current.registerUnaryCallback(dart.as(onListenHandler, /* Unimplemented type (dynamic) → dynamic */));
        this._onCancelHandler = Zone.current.registerUnaryCallback(dart.as(onCancelHandler, /* Unimplemented type (dynamic) → dynamic */));
        this._zone = Zone.current;
        this._controller = null;
        this._subscription = null;
        super();
        this._controller = new _AsBroadcastStreamController(this._onListen, this._onCancel);
      }
      get isBroadcast() { return true; }
      listen(onData, opt$) {
        let onError = opt$.onError === undefined ? null : opt$.onError;
        let onDone = opt$.onDone === undefined ? null : opt$.onDone;
        let cancelOnError = opt$.cancelOnError === undefined ? null : opt$.cancelOnError;
        if (this._controller === null || this._controller.isClosed) {
          return new _DoneStreamSubscription(onDone);
        }
        if (this._subscription === null) {
          this._subscription = this._source.listen(this._controller.add, {onError: this._controller.addError, onDone: this._controller.close});
        }
        cancelOnError = core.identical(true, cancelOnError);
        return this._controller._subscribe(onData, onError, onDone, cancelOnError);
      }
      _onCancel() {
        let shutdown = (this._controller === null) || this._controller.isClosed;
        if (this._onCancelHandler !== null) {
          this._zone.runUnary(dart.as(this._onCancelHandler, /* Unimplemented type (dynamic) → dynamic */), new _BroadcastSubscriptionWrapper(this));
        }
        if (shutdown) {
          if (this._subscription !== null) {
            this._subscription.cancel();
            this._subscription = null;
          }
        }
      }
      _onListen() {
        if (this._onListenHandler !== null) {
          this._zone.runUnary(dart.as(this._onListenHandler, /* Unimplemented type (dynamic) → dynamic */), new _BroadcastSubscriptionWrapper(this));
        }
      }
      _cancelSubscription() {
        if (this._subscription === null) return;
        let subscription = this._subscription;
        this._subscription = null;
        this._controller = null;
        subscription.cancel();
      }
      _pauseSubscription(resumeSignal) {
        if (this._subscription === null) return;
        this._subscription.pause(resumeSignal);
      }
      _resumeSubscription() {
        if (this._subscription === null) return;
        this._subscription.resume();
      }
      get _isSubscriptionPaused() {
        if (this._subscription === null) return false;
        return this._subscription.isPaused;
      }
    }
    return _AsBroadcastStream;
  });
  let _AsBroadcastStream = _AsBroadcastStream$(dynamic);

  let _BroadcastSubscriptionWrapper$ = dart.generic(function(T) {
    class _BroadcastSubscriptionWrapper {
      constructor(_stream) {
        this._stream = _stream;
      }
      onData(handleData) {
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
      onError(handleError) {
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
      onDone(handleDone) {
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
      pause(resumeSignal) {
        if (resumeSignal === undefined) resumeSignal = null;
        this._stream._pauseSubscription(resumeSignal);
      }
      resume() {
        this._stream._resumeSubscription();
      }
      cancel() {
        this._stream._cancelSubscription();
        return null;
      }
      get isPaused() {
        return this._stream._isSubscriptionPaused;
      }
      asFuture(futureValue) {
        if (futureValue === undefined) futureValue = null;
        throw new core.UnsupportedError("Cannot change handlers of asBroadcastStream source subscription.");
      }
    }
    return _BroadcastSubscriptionWrapper;
  });
  let _BroadcastSubscriptionWrapper = _BroadcastSubscriptionWrapper$(dynamic);

  let _StreamIteratorImpl$ = dart.generic(function(T) {
    class _StreamIteratorImpl {
      constructor(stream) {
        this._subscription = null;
        this._current = dart.as(null, T);
        this._futureOrPrefetch = null;
        this._state = _STATE_FOUND;
        this._subscription = stream.listen(this._onData, {onError: this._onError, onDone: this._onDone, cancelOnError: true});
      }
      get current() { return this._current; }
      moveNext() {
        if (this._state === _STATE_DONE) {
          return new _Future.immediate(false);
        }
        if (this._state === _STATE_MOVING) {
          throw new core.StateError("Already waiting for next.");
        }
        if (this._state === _STATE_FOUND) {
          this._state = _STATE_MOVING;
          this._current = dart.as(null, T);
          this._futureOrPrefetch = new _Future();
          return dart.as(this._futureOrPrefetch, Future$(core.bool));
        } else {
          dart.assert(this._state >= _STATE_EXTRA_DATA);
          switch (this._state) {
            case _STATE_EXTRA_DATA:
              this._state = _STATE_FOUND;
              this._current = dart.as(this._futureOrPrefetch, T);
              this._futureOrPrefetch = null;
              this._subscription.resume();
              return new _Future.immediate(true);
            case _STATE_EXTRA_ERROR:
              let prefetch = dart.as(this._futureOrPrefetch, AsyncError);
              this._clear();
              return new _Future.immediateError(prefetch.error, prefetch.stackTrace);
            case _STATE_EXTRA_DONE:
              this._clear();
              return new _Future.immediate(false);
          }
        }
      }
      _clear() {
        this._subscription = null;
        this._futureOrPrefetch = null;
        this._current = dart.as(null, T);
        this._state = _STATE_DONE;
      }
      cancel() {
        let subscription = this._subscription;
        if (this._state === _STATE_MOVING) {
          let hasNext = dart.as(this._futureOrPrefetch, _Future$(core.bool));
          this._clear();
          hasNext._complete(false);
        } else {
          this._clear();
        }
        return subscription.cancel();
      }
      _onData(data) {
        if (this._state === _STATE_MOVING) {
          this._current = data;
          let hasNext = dart.as(this._futureOrPrefetch, _Future$(core.bool));
          this._futureOrPrefetch = null;
          this._state = _STATE_FOUND;
          hasNext._complete(true);
          return;
        }
        this._subscription.pause();
        dart.assert(this._futureOrPrefetch === null);
        this._futureOrPrefetch = data;
        this._state = _STATE_EXTRA_DATA;
      }
      _onError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        if (this._state === _STATE_MOVING) {
          let hasNext = dart.as(this._futureOrPrefetch, _Future$(core.bool));
          this._clear();
          hasNext._completeError(error, stackTrace);
          return;
        }
        this._subscription.pause();
        dart.assert(this._futureOrPrefetch === null);
        this._futureOrPrefetch = new AsyncError(error, stackTrace);
        this._state = _STATE_EXTRA_ERROR;
      }
      _onDone() {
        if (this._state === _STATE_MOVING) {
          let hasNext = dart.as(this._futureOrPrefetch, _Future$(core.bool));
          this._clear();
          hasNext._complete(false);
          return;
        }
        this._subscription.pause();
        this._futureOrPrefetch = null;
        this._state = _STATE_EXTRA_DONE;
      }
    }
    _StreamIteratorImpl._STATE_FOUND = 0;
    _StreamIteratorImpl._STATE_DONE = 1;
    _StreamIteratorImpl._STATE_MOVING = 2;
    _StreamIteratorImpl._STATE_EXTRA_DATA = 3;
    _StreamIteratorImpl._STATE_EXTRA_ERROR = 4;
    _StreamIteratorImpl._STATE_EXTRA_DONE = 5;
    return _StreamIteratorImpl;
  });
  let _StreamIteratorImpl = _StreamIteratorImpl$(dynamic);

  // Function _runUserCode: (() → dynamic, (dynamic) → dynamic, (dynamic, StackTrace) → dynamic) → dynamic
  function _runUserCode(userCode, onSuccess, onError) {
    try {
      onSuccess(userCode());
    }
    catch (e) {
      let s = dart.stackTrace(e);
      let replacement = Zone.current.errorCallback(e, s);
      if (replacement === null) {
        onError(e, s);
      } else {
        let error = _nonNullError(replacement.error);
        let stackTrace = replacement.stackTrace;
        onError(error, stackTrace);
      }
    }
  }

  // Function _cancelAndError: (StreamSubscription<dynamic>, _Future<dynamic>, dynamic, StackTrace) → void
  function _cancelAndError(subscription, future, error, stackTrace) {
    let cancelFuture = subscription.cancel();
    if (dart.is(cancelFuture, Future)) {
      cancelFuture.whenComplete(() => future._completeError(error, stackTrace));
    } else {
      future._completeError(error, stackTrace);
    }
  }

  // Function _cancelAndErrorWithReplacement: (StreamSubscription<dynamic>, _Future<dynamic>, dynamic, StackTrace) → void
  function _cancelAndErrorWithReplacement(subscription, future, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement !== null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    _cancelAndError(subscription, future, error, stackTrace);
  }

  // Function _cancelAndErrorClosure: (StreamSubscription<dynamic>, _Future<dynamic>) → dynamic
  function _cancelAndErrorClosure(subscription, future) { return ((error, stackTrace) => _cancelAndError(subscription, future, error, stackTrace)); }

  // Function _cancelAndValue: (StreamSubscription<dynamic>, _Future<dynamic>, dynamic) → void
  function _cancelAndValue(subscription, future, value) {
    let cancelFuture = subscription.cancel();
    if (dart.is(cancelFuture, Future)) {
      cancelFuture.whenComplete(() => future._complete(value));
    } else {
      future._complete(value);
    }
  }

  let _ForwardingStream$ = dart.generic(function(S, T) {
    class _ForwardingStream extends Stream$(T) {
      constructor(_source) {
        this._source = _source;
        super();
      }
      get isBroadcast() { return this._source.isBroadcast; }
      listen(onData, opt$) {
        let onError = opt$.onError === undefined ? null : opt$.onError;
        let onDone = opt$.onDone === undefined ? null : opt$.onDone;
        let cancelOnError = opt$.cancelOnError === undefined ? null : opt$.cancelOnError;
        cancelOnError = core.identical(true, cancelOnError);
        return this._createSubscription(onData, onError, onDone, cancelOnError);
      }
      _createSubscription(onData, onError, onDone, cancelOnError) {
        return new _ForwardingStreamSubscription(this, onData, onError, onDone, cancelOnError);
      }
      _handleData(data, sink) {
        let outputData = data;
        sink._add(outputData);
      }
      _handleError(error, stackTrace, sink) {
        sink._addError(error, stackTrace);
      }
      _handleDone(sink) {
        sink._close();
      }
    }
    return _ForwardingStream;
  });
  let _ForwardingStream = _ForwardingStream$(dynamic, dynamic);

  let _ForwardingStreamSubscription$ = dart.generic(function(S, T) {
    class _ForwardingStreamSubscription extends _BufferingStreamSubscription$(T) {
      constructor(_stream, onData, onError, onDone, cancelOnError) {
        this._stream = _stream;
        this._subscription = null;
        super(onData, onError, onDone, cancelOnError);
        this._subscription = this._stream._source.listen(this._handleData, {onError: this._handleError, onDone: this._handleDone});
      }
      _add(data) {
        if (this._isClosed) return;
        super._add(data);
      }
      _addError(error, stackTrace) {
        if (this._isClosed) return;
        super._addError(error, stackTrace);
      }
      _onPause() {
        if (this._subscription === null) return;
        this._subscription.pause();
      }
      _onResume() {
        if (this._subscription === null) return;
        this._subscription.resume();
      }
      _onCancel() {
        if (this._subscription !== null) {
          let subscription = this._subscription;
          this._subscription = null;
          subscription.cancel();
        }
        return null;
      }
      _handleData(data) {
        this._stream._handleData(data, this);
      }
      _handleError(error, stackTrace) {
        this._stream._handleError(error, stackTrace, this);
      }
      _handleDone() {
        this._stream._handleDone(this);
      }
    }
    return _ForwardingStreamSubscription;
  });
  let _ForwardingStreamSubscription = _ForwardingStreamSubscription$(dynamic, dynamic);

  // Function _addErrorWithReplacement: (_EventSink<dynamic>, dynamic, dynamic) → void
  function _addErrorWithReplacement(sink, error, stackTrace) {
    let replacement = Zone.current.errorCallback(error, dart.as(stackTrace, core.StackTrace));
    if (replacement !== null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    sink._addError(error, dart.as(stackTrace, core.StackTrace));
  }

  let _WhereStream$ = dart.generic(function(T) {
    class _WhereStream extends _ForwardingStream$(T, T) {
      constructor(source, test) {
        this._test = test;
        super(source);
      }
      _handleData(inputEvent, sink) {
        let satisfies = null;
        try {
          satisfies = this._test(inputEvent);
        }
        catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          return;
        }
        if (satisfies) {
          sink._add(inputEvent);
        }
      }
    }
    return _WhereStream;
  });
  let _WhereStream = _WhereStream$(dynamic);

  let _MapStream$ = dart.generic(function(S, T) {
    class _MapStream extends _ForwardingStream$(S, T) {
      constructor(source, transform) {
        this._transform = transform;
        super(source);
      }
      _handleData(inputEvent, sink) {
        let outputEvent = null;
        try {
          outputEvent = dart.as(this._transform(inputEvent), T);
        }
        catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          return;
        }
        sink._add(outputEvent);
      }
    }
    return _MapStream;
  });
  let _MapStream = _MapStream$(dynamic, dynamic);

  let _ExpandStream$ = dart.generic(function(S, T) {
    class _ExpandStream extends _ForwardingStream$(S, T) {
      constructor(source, expand) {
        this._expand = expand;
        super(source);
      }
      _handleData(inputEvent, sink) {
        try {
          for (let value of this._expand(inputEvent)) {
            sink._add(value);
          }
        }
        catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
        }
      }
    }
    return _ExpandStream;
  });
  let _ExpandStream = _ExpandStream$(dynamic, dynamic);

  let _HandleErrorStream$ = dart.generic(function(T) {
    class _HandleErrorStream extends _ForwardingStream$(T, T) {
      constructor(source, onError, test) {
        this._transform = onError;
        this._test = test;
        super(source);
      }
      _handleError(error, stackTrace, sink) {
        let matches = true;
        if (this._test !== null) {
          try {
            matches = this._test(error);
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _addErrorWithReplacement(sink, e, s);
            return;
          }
        }
        if (matches) {
          try {
            _invokeErrorHandler(this._transform, error, stackTrace);
          }
          catch (e) {
            let s = dart.stackTrace(e);
            if (core.identical(e, error)) {
              sink._addError(error, stackTrace);
            } else {
              _addErrorWithReplacement(sink, e, s);
            }
            return;
          }
        } else {
          sink._addError(error, stackTrace);
        }
      }
    }
    return _HandleErrorStream;
  });
  let _HandleErrorStream = _HandleErrorStream$(dynamic);

  let _TakeStream$ = dart.generic(function(T) {
    class _TakeStream extends _ForwardingStream$(T, T) {
      constructor(source, count) {
        this._remaining = count;
        super(source);
        if (!(typeof count == "number")) throw new core.ArgumentError(count);
      }
      _handleData(inputEvent, sink) {
        if (this._remaining > 0) {
          sink._add(inputEvent);
          this._remaining = 1;
          if (this._remaining === 0) {
            sink._close();
          }
        }
      }
    }
    return _TakeStream;
  });
  let _TakeStream = _TakeStream$(dynamic);

  let _TakeWhileStream$ = dart.generic(function(T) {
    class _TakeWhileStream extends _ForwardingStream$(T, T) {
      constructor(source, test) {
        this._test = test;
        super(source);
      }
      _handleData(inputEvent, sink) {
        let satisfies = null;
        try {
          satisfies = this._test(inputEvent);
        }
        catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          sink._close();
          return;
        }
        if (satisfies) {
          sink._add(inputEvent);
        } else {
          sink._close();
        }
      }
    }
    return _TakeWhileStream;
  });
  let _TakeWhileStream = _TakeWhileStream$(dynamic);

  let _SkipStream$ = dart.generic(function(T) {
    class _SkipStream extends _ForwardingStream$(T, T) {
      constructor(source, count) {
        this._remaining = count;
        super(source);
        if (!(typeof count == "number") || count < 0) throw new core.ArgumentError(count);
      }
      _handleData(inputEvent, sink) {
        if (this._remaining > 0) {
          this._remaining--;
          return;
        }
        sink._add(inputEvent);
      }
    }
    return _SkipStream;
  });
  let _SkipStream = _SkipStream$(dynamic);

  let _SkipWhileStream$ = dart.generic(function(T) {
    class _SkipWhileStream extends _ForwardingStream$(T, T) {
      constructor(source, test) {
        this._test = test;
        this._hasFailed = false;
        super(source);
      }
      _handleData(inputEvent, sink) {
        if (this._hasFailed) {
          sink._add(inputEvent);
          return;
        }
        let satisfies = null;
        try {
          satisfies = this._test(inputEvent);
        }
        catch (e) {
          let s = dart.stackTrace(e);
          _addErrorWithReplacement(sink, e, s);
          this._hasFailed = true;
          return;
        }
        if (!satisfies) {
          this._hasFailed = true;
          sink._add(inputEvent);
        }
      }
    }
    return _SkipWhileStream;
  });
  let _SkipWhileStream = _SkipWhileStream$(dynamic);

  let _DistinctStream$ = dart.generic(function(T) {
    class _DistinctStream extends _ForwardingStream$(T, T) {
      constructor(source, equals) {
        this._previous = _SENTINEL;
        this._equals = equals;
        super(source);
      }
      _handleData(inputEvent, sink) {
        if (core.identical(this._previous, _SENTINEL)) {
          this._previous = inputEvent;
          return sink._add(inputEvent);
        } else {
          let isEqual = null;
          try {
            if (this._equals === null) {
              isEqual = (dart.equals(this._previous, inputEvent));
            } else {
              isEqual = this._equals(dart.as(this._previous, T), inputEvent);
            }
          }
          catch (e) {
            let s = dart.stackTrace(e);
            _addErrorWithReplacement(sink, e, s);
            return null;
          }
          if (!isEqual) {
            sink._add(inputEvent);
            this._previous = inputEvent;
          }
        }
      }
    }
    dart.defineLazyProperties(_DistinctStream, {
      get _SENTINEL() { return new core.Object() },
      set _SENTINEL(x) {},
    });
    return _DistinctStream;
  });
  let _DistinctStream = _DistinctStream$(dynamic);

  let _EventSinkWrapper$ = dart.generic(function(T) {
    class _EventSinkWrapper {
      constructor(_sink) {
        this._sink = _sink;
      }
      add(data) {
        this._sink._add(data);
      }
      addError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        this._sink._addError(error, stackTrace);
      }
      close() {
        this._sink._close();
      }
    }
    return _EventSinkWrapper;
  });
  let _EventSinkWrapper = _EventSinkWrapper$(dynamic);

  let _SinkTransformerStreamSubscription$ = dart.generic(function(S, T) {
    class _SinkTransformerStreamSubscription extends _BufferingStreamSubscription$(T) {
      constructor(source, mapper, onData, onError, onDone, cancelOnError) {
        this._transformerSink = null;
        this._subscription = null;
        super(onData, onError, onDone, cancelOnError);
        let eventSink = new _EventSinkWrapper(this);
        this._transformerSink = mapper(eventSink);
        this._subscription = source.listen(this._handleData, {onError: this._handleError, onDone: this._handleDone});
      }
      get _isSubscribed() { return this._subscription !== null; }
      _add(data) {
        if (this._isClosed) {
          throw new core.StateError("Stream is already closed");
        }
        super._add(data);
      }
      _addError(error, stackTrace) {
        if (this._isClosed) {
          throw new core.StateError("Stream is already closed");
        }
        super._addError(error, stackTrace);
      }
      _close() {
        if (this._isClosed) {
          throw new core.StateError("Stream is already closed");
        }
        super._close();
      }
      _onPause() {
        if (this._isSubscribed) this._subscription.pause();
      }
      _onResume() {
        if (this._isSubscribed) this._subscription.resume();
      }
      _onCancel() {
        if (this._isSubscribed) {
          let subscription = this._subscription;
          this._subscription = null;
          subscription.cancel();
        }
        return null;
      }
      _handleData(data) {
        try {
          this._transformerSink.add(data);
        }
        catch (e) {
          let s = dart.stackTrace(e);
          this._addError(e, s);
        }
      }
      _handleError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        try {
          this._transformerSink.addError(error, dart.as(stackTrace, core.StackTrace));
        }
        catch (e) {
          let s = dart.stackTrace(e);
          if (core.identical(e, error)) {
            this._addError(error, dart.as(stackTrace, core.StackTrace));
          } else {
            this._addError(e, s);
          }
        }
      }
      _handleDone() {
        try {
          this._subscription = null;
          this._transformerSink.close();
        }
        catch (e) {
          let s = dart.stackTrace(e);
          this._addError(e, s);
        }
      }
    }
    return _SinkTransformerStreamSubscription;
  });
  let _SinkTransformerStreamSubscription = _SinkTransformerStreamSubscription$(dynamic, dynamic);

  let _StreamSinkTransformer$ = dart.generic(function(S, T) {
    class _StreamSinkTransformer {
      constructor(_sinkMapper) {
        this._sinkMapper = _sinkMapper;
      }
      bind(stream) { return new _BoundSinkStream(stream, this._sinkMapper); }
    }
    return _StreamSinkTransformer;
  });
  let _StreamSinkTransformer = _StreamSinkTransformer$(dynamic, dynamic);

  let _BoundSinkStream$ = dart.generic(function(S, T) {
    class _BoundSinkStream extends Stream$(T) {
      get isBroadcast() { return this._stream.isBroadcast; }
      constructor(_stream, _sinkMapper) {
        this._stream = _stream;
        this._sinkMapper = _sinkMapper;
        super();
      }
      listen(onData, opt$) {
        let onError = opt$.onError === undefined ? null : opt$.onError;
        let onDone = opt$.onDone === undefined ? null : opt$.onDone;
        let cancelOnError = opt$.cancelOnError === undefined ? null : opt$.cancelOnError;
        cancelOnError = core.identical(true, cancelOnError);
        let subscription = dart.as(new _SinkTransformerStreamSubscription(this._stream, this._sinkMapper, onData, onError, onDone, cancelOnError), StreamSubscription$(T));
        return subscription;
      }
    }
    return _BoundSinkStream;
  });
  let _BoundSinkStream = _BoundSinkStream$(dynamic, dynamic);

  let _HandlerEventSink$ = dart.generic(function(S, T) {
    class _HandlerEventSink {
      constructor(_handleData, _handleError, _handleDone, _sink) {
        this._handleData = _handleData;
        this._handleError = _handleError;
        this._handleDone = _handleDone;
        this._sink = _sink;
      }
      add(data) { return this._handleData(data, this._sink); }
      addError(error, stackTrace) {
        if (stackTrace === undefined) stackTrace = null;
        return this._handleError(error, stackTrace, this._sink)
      }
      close() { return this._handleDone(this._sink); }
    }
    return _HandlerEventSink;
  });
  let _HandlerEventSink = _HandlerEventSink$(dynamic, dynamic);

  let _StreamHandlerTransformer$ = dart.generic(function(S, T) {
    class _StreamHandlerTransformer extends _StreamSinkTransformer$(S, T) {
      constructor(opt$) {
        let handleData = opt$.handleData === undefined ? null : opt$.handleData;
        let handleError = opt$.handleError === undefined ? null : opt$.handleError;
        let handleDone = opt$.handleDone === undefined ? null : opt$.handleDone;
        super(dart.as((outputSink) => {
          if (handleData === null) handleData = _defaultHandleData;
          if (handleError === null) handleError = _defaultHandleError;
          if (handleDone === null) handleDone = _defaultHandleDone;
          return new _HandlerEventSink(handleData, handleError, handleDone, outputSink);
        }, _SinkMapper));
      }
      bind(stream) {
        return super.bind(stream);
      }
      static _defaultHandleData(data, sink) {
        sink.add(data);
      }
      static _defaultHandleError(error, stackTrace, sink) {
        sink.addError(error);
      }
      static _defaultHandleDone(sink) {
        sink.close();
      }
    }
    return _StreamHandlerTransformer;
  });
  let _StreamHandlerTransformer = _StreamHandlerTransformer$(dynamic, dynamic);

  let _StreamSubscriptionTransformer$ = dart.generic(function(S, T) {
    class _StreamSubscriptionTransformer {
      constructor(_transformer) {
        this._transformer = _transformer;
      }
      bind(stream) { return new _BoundSubscriptionStream(stream, this._transformer); }
    }
    return _StreamSubscriptionTransformer;
  });
  let _StreamSubscriptionTransformer = _StreamSubscriptionTransformer$(dynamic, dynamic);

  let _BoundSubscriptionStream$ = dart.generic(function(S, T) {
    class _BoundSubscriptionStream extends Stream$(T) {
      constructor(_stream, _transformer) {
        this._stream = _stream;
        this._transformer = _transformer;
        super();
      }
      listen(onData, opt$) {
        let onError = opt$.onError === undefined ? null : opt$.onError;
        let onDone = opt$.onDone === undefined ? null : opt$.onDone;
        let cancelOnError = opt$.cancelOnError === undefined ? null : opt$.cancelOnError;
        cancelOnError = core.identical(true, cancelOnError);
        let result = this._transformer(this._stream, cancelOnError);
        result.onData(onData);
        result.onError(onError);
        result.onDone(onDone);
        return result;
      }
    }
    return _BoundSubscriptionStream;
  });
  let _BoundSubscriptionStream = _BoundSubscriptionStream$(dynamic, dynamic);

  class Timer {
    constructor(duration, callback) {
      if (dart.equals(Zone.current, Zone.ROOT)) {
        return Zone.current.createTimer(duration, callback);
      }
      return Zone.current.createTimer(duration, Zone.current.bindCallback(callback, {runGuarded: true}));
    }
    /*constructor*/ periodic(duration, callback) {
      if (dart.equals(Zone.current, Zone.ROOT)) {
        return Zone.current.createPeriodicTimer(duration, callback);
      }
      return Zone.current.createPeriodicTimer(duration, Zone.current.bindUnaryCallback(dart.as(callback, /* Unimplemented type (dynamic) → dynamic */), {runGuarded: true}));
    }
    static run(callback) {
      new Timer(core.Duration.ZERO, callback);
    }
    /* Unimplemented external static Timer _createTimer(Duration duration, void callback()); */
    /* Unimplemented external static Timer _createPeriodicTimer(Duration duration, void callback(Timer timer)); */
  }
  dart.defineNamedConstructor(Timer, "periodic");

  class AsyncError {
    constructor(error, stackTrace) {
      this.error = error;
      this.stackTrace = stackTrace;
    }
    toString() { return dart.as(dart.dinvoke(this.error, "toString"), core.String); }
  }

  class _ZoneFunction {
    constructor(zone, function) {
      this.zone = zone;
      this.function = function;
    }
  }

  class ZoneSpecification {
    constructor(opt$) {
      return new _ZoneSpecification(opt$);
    }
    /*constructor*/ from(other, opt$) {
      let handleUncaughtError = opt$.handleUncaughtError === undefined ? null : opt$.handleUncaughtError;
      let run = opt$.run === undefined ? null : opt$.run;
      let runUnary = opt$.runUnary === undefined ? null : opt$.runUnary;
      let runBinary = opt$.runBinary === undefined ? null : opt$.runBinary;
      let registerCallback = opt$.registerCallback === undefined ? null : opt$.registerCallback;
      let registerUnaryCallback = opt$.registerUnaryCallback === undefined ? null : opt$.registerUnaryCallback;
      let registerBinaryCallback = opt$.registerBinaryCallback === undefined ? null : opt$.registerBinaryCallback;
      let errorCallback = opt$.errorCallback === undefined ? null : opt$.errorCallback;
      let scheduleMicrotask = opt$.scheduleMicrotask === undefined ? null : opt$.scheduleMicrotask;
      let createTimer = opt$.createTimer === undefined ? null : opt$.createTimer;
      let createPeriodicTimer = opt$.createPeriodicTimer === undefined ? null : opt$.createPeriodicTimer;
      let print = opt$.print === undefined ? null : opt$.print;
      let fork = opt$.fork === undefined ? null : opt$.fork;
      return new ZoneSpecification({handleUncaughtError: handleUncaughtError !== null ? handleUncaughtError : other.handleUncaughtError, run: run !== null ? run : other.run, runUnary: runUnary !== null ? runUnary : other.runUnary, runBinary: runBinary !== null ? runBinary : other.runBinary, registerCallback: registerCallback !== null ? registerCallback : other.registerCallback, registerUnaryCallback: registerUnaryCallback !== null ? registerUnaryCallback : other.registerUnaryCallback, registerBinaryCallback: registerBinaryCallback !== null ? registerBinaryCallback : other.registerBinaryCallback, errorCallback: errorCallback !== null ? errorCallback : other.errorCallback, scheduleMicrotask: scheduleMicrotask !== null ? scheduleMicrotask : other.scheduleMicrotask, createTimer: createTimer !== null ? createTimer : other.createTimer, createPeriodicTimer: createPeriodicTimer !== null ? createPeriodicTimer : other.createPeriodicTimer, print: print !== null ? print : other.print, fork: fork !== null ? fork : other.fork});
    }
  }
  dart.defineNamedConstructor(ZoneSpecification, "from");

  class _ZoneSpecification {
    constructor(opt$) {
      let handleUncaughtError = opt$.handleUncaughtError === undefined ? null : opt$.handleUncaughtError;
      let run = opt$.run === undefined ? null : opt$.run;
      let runUnary = opt$.runUnary === undefined ? null : opt$.runUnary;
      let runBinary = opt$.runBinary === undefined ? null : opt$.runBinary;
      let registerCallback = opt$.registerCallback === undefined ? null : opt$.registerCallback;
      let registerUnaryCallback = opt$.registerUnaryCallback === undefined ? null : opt$.registerUnaryCallback;
      let registerBinaryCallback = opt$.registerBinaryCallback === undefined ? null : opt$.registerBinaryCallback;
      let errorCallback = opt$.errorCallback === undefined ? null : opt$.errorCallback;
      let scheduleMicrotask = opt$.scheduleMicrotask === undefined ? null : opt$.scheduleMicrotask;
      let createTimer = opt$.createTimer === undefined ? null : opt$.createTimer;
      let createPeriodicTimer = opt$.createPeriodicTimer === undefined ? null : opt$.createPeriodicTimer;
      let print = opt$.print === undefined ? null : opt$.print;
      let fork = opt$.fork === undefined ? null : opt$.fork;
      this.handleUncaughtError = handleUncaughtError;
      this.run = run;
      this.runUnary = runUnary;
      this.runBinary = runBinary;
      this.registerCallback = registerCallback;
      this.registerUnaryCallback = registerUnaryCallback;
      this.registerBinaryCallback = registerBinaryCallback;
      this.errorCallback = errorCallback;
      this.scheduleMicrotask = scheduleMicrotask;
      this.createTimer = createTimer;
      this.createPeriodicTimer = createPeriodicTimer;
      this.print = print;
      this.fork = fork;
    }
  }

  class ZoneDelegate {
  }

  class Zone {
    /*constructor*/ _() {
    }
    static get current() { return _current; }
    static _enter(zone) {
      dart.assert(zone !== null);
      dart.assert(!core.identical(zone, _current));
      let previous = _current;
      _current = zone;
      return previous;
    }
    static _leave(previous) {
      dart.assert(previous !== null);
      Zone._current = previous;
    }
  }
  dart.defineNamedConstructor(Zone, "_");
  Zone.ROOT = dart.as(_ROOT_ZONE, Zone);
  Zone._current = dart.as(_ROOT_ZONE, Zone);

  // Function _parentDelegate: (_Zone) → ZoneDelegate
  function _parentDelegate(zone) {
    if (zone.parent === null) return null;
    return zone.parent._delegate;
  }

  class _ZoneDelegate {
    constructor(_delegationTarget) {
      this._delegationTarget = _delegationTarget;
    }
    handleUncaughtError(zone, error, stackTrace) {
      let implementation = this._delegationTarget._handleUncaughtError;
      let implZone = implementation.zone;
      return dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, error, stackTrace);
    }
    run(zone, f) {
      let implementation = this._delegationTarget._run;
      let implZone = implementation.zone;
      return dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, f);
    }
    runUnary(zone, f, arg) {
      let implementation = this._delegationTarget._runUnary;
      let implZone = implementation.zone;
      return dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, f, arg);
    }
    runBinary(zone, f, arg1, arg2) {
      let implementation = this._delegationTarget._runBinary;
      let implZone = implementation.zone;
      return dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, f, arg1, arg2);
    }
    registerCallback(zone, f) {
      let implementation = this._delegationTarget._registerCallback;
      let implZone = implementation.zone;
      return dart.as(dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, f), ZoneCallback);
    }
    registerUnaryCallback(zone, f) {
      let implementation = this._delegationTarget._registerUnaryCallback;
      let implZone = implementation.zone;
      return dart.as(dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, f), ZoneUnaryCallback);
    }
    registerBinaryCallback(zone, f) {
      let implementation = this._delegationTarget._registerBinaryCallback;
      let implZone = implementation.zone;
      return dart.as(dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, f), ZoneBinaryCallback);
    }
    errorCallback(zone, error, stackTrace) {
      let implementation = this._delegationTarget._errorCallback;
      let implZone = implementation.zone;
      if (core.identical(implZone, _ROOT_ZONE)) return null;
      return dart.as(dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, error, stackTrace), AsyncError);
    }
    scheduleMicrotask(zone, f) {
      let implementation = this._delegationTarget._scheduleMicrotask;
      let implZone = implementation.zone;
      dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, f);
    }
    createTimer(zone, duration, f) {
      let implementation = this._delegationTarget._createTimer;
      let implZone = implementation.zone;
      return dart.as(dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, duration, f), Timer);
    }
    createPeriodicTimer(zone, period, f) {
      let implementation = this._delegationTarget._createPeriodicTimer;
      let implZone = implementation.zone;
      return dart.as(dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, period, f), Timer);
    }
    print(zone, line) {
      let implementation = this._delegationTarget._print;
      let implZone = implementation.zone;
      dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, line);
    }
    fork(zone, specification, zoneValues) {
      let implementation = this._delegationTarget._fork;
      let implZone = implementation.zone;
      return dart.as(dart.dinvokef((implementation.function), implZone, _parentDelegate(implZone), zone, specification, zoneValues), Zone);
    }
  }

  class _Zone {
    constructor() {
    }
    inSameErrorZone(otherZone) {
      return core.identical(this, otherZone) || core.identical(this.errorZone, otherZone.errorZone);
    }
  }

  class _CustomZone extends _Zone {
    get _delegate() {
      if (this._delegateCache !== null) return this._delegateCache;
      this._delegateCache = new _ZoneDelegate(this);
      return this._delegateCache;
    }
    constructor(parent, specification, _map) {
      this.parent = parent;
      this._map = _map;
      this._runUnary = null;
      this._run = null;
      this._runBinary = null;
      this._registerCallback = null;
      this._registerUnaryCallback = null;
      this._registerBinaryCallback = null;
      this._errorCallback = null;
      this._scheduleMicrotask = null;
      this._createTimer = null;
      this._createPeriodicTimer = null;
      this._print = null;
      this._fork = null;
      this._handleUncaughtError = null;
      this._delegateCache = null;
      super();
      this._run = (specification.run !== null) ? new _ZoneFunction(this, specification.run) : this.parent._run;
      this._runUnary = (specification.runUnary !== null) ? new _ZoneFunction(this, specification.runUnary) : this.parent._runUnary;
      this._runBinary = (specification.runBinary !== null) ? new _ZoneFunction(this, specification.runBinary) : this.parent._runBinary;
      this._registerCallback = (specification.registerCallback !== null) ? new _ZoneFunction(this, specification.registerCallback) : this.parent._registerCallback;
      this._registerUnaryCallback = (specification.registerUnaryCallback !== null) ? new _ZoneFunction(this, specification.registerUnaryCallback) : this.parent._registerUnaryCallback;
      this._registerBinaryCallback = (specification.registerBinaryCallback !== null) ? new _ZoneFunction(this, specification.registerBinaryCallback) : this.parent._registerBinaryCallback;
      this._errorCallback = (specification.errorCallback !== null) ? new _ZoneFunction(this, specification.errorCallback) : this.parent._errorCallback;
      this._scheduleMicrotask = (specification.scheduleMicrotask !== null) ? new _ZoneFunction(this, specification.scheduleMicrotask) : this.parent._scheduleMicrotask;
      this._createTimer = (specification.createTimer !== null) ? new _ZoneFunction(this, specification.createTimer) : this.parent._createTimer;
      this._createPeriodicTimer = (specification.createPeriodicTimer !== null) ? new _ZoneFunction(this, specification.createPeriodicTimer) : this.parent._createPeriodicTimer;
      this._print = (specification.print !== null) ? new _ZoneFunction(this, specification.print) : this.parent._print;
      this._fork = (specification.fork !== null) ? new _ZoneFunction(this, specification.fork) : this.parent._fork;
      this._handleUncaughtError = (specification.handleUncaughtError !== null) ? new _ZoneFunction(this, specification.handleUncaughtError) : this.parent._handleUncaughtError;
    }
    get errorZone() { return this._handleUncaughtError.zone; }
    runGuarded(f) {
      try {
        return this.run(f);
      }
      catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }
    }
    runUnaryGuarded(f, arg) {
      try {
        return this.runUnary(f, arg);
      }
      catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }
    }
    runBinaryGuarded(f, arg1, arg2) {
      try {
        return this.runBinary(f, arg1, arg2);
      }
      catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }
    }
    bindCallback(f, opt$) {
      let runGuarded = opt$.runGuarded === undefined ? true : opt$.runGuarded;
      let registered = this.registerCallback(f);
      if (runGuarded) {
        return () => this.runGuarded(registered);
      } else {
        return () => this.run(registered);
      }
    }
    bindUnaryCallback(f, opt$) {
      let runGuarded = opt$.runGuarded === undefined ? true : opt$.runGuarded;
      let registered = this.registerUnaryCallback(f);
      if (runGuarded) {
        return (arg) => this.runUnaryGuarded(registered, arg);
      } else {
        return (arg) => this.runUnary(registered, arg);
      }
    }
    bindBinaryCallback(f, opt$) {
      let runGuarded = opt$.runGuarded === undefined ? true : opt$.runGuarded;
      let registered = this.registerBinaryCallback(f);
      if (runGuarded) {
        return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
      } else {
        return (arg1, arg2) => this.runBinary(registered, arg1, arg2);
      }
    }
    get(key) {
      let result = this._map.get(key);
      if (result !== null || this._map.containsKey(key)) return result;
      if (this.parent !== null) {
        let value = this.parent.get(key);
        if (value !== null) {
          this._map.set(key, value);
        }
        return value;
      }
      dart.assert(dart.equals(this, _ROOT_ZONE));
      return null;
    }
    handleUncaughtError(error, stackTrace) {
      let implementation = this._handleUncaughtError;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, error, stackTrace);
    }
    fork(opt$) {
      let specification = opt$.specification === undefined ? null : opt$.specification;
      let zoneValues = opt$.zoneValues === undefined ? null : opt$.zoneValues;
      let implementation = this._fork;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, specification, zoneValues), Zone);
    }
    run(f) {
      let implementation = this._run;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, f);
    }
    runUnary(f, arg) {
      let implementation = this._runUnary;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, f, arg);
    }
    runBinary(f, arg1, arg2) {
      let implementation = this._runBinary;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, f, arg1, arg2);
    }
    registerCallback(f) {
      let implementation = this._registerCallback;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, f), ZoneCallback);
    }
    registerUnaryCallback(f) {
      let implementation = this._registerUnaryCallback;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, f), ZoneUnaryCallback);
    }
    registerBinaryCallback(f) {
      let implementation = this._registerBinaryCallback;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, f), ZoneBinaryCallback);
    }
    errorCallback(error, stackTrace) {
      let implementation = this._errorCallback;
      dart.assert(implementation !== null);
      let implementationZone = implementation.zone;
      if (core.identical(implementationZone, _ROOT_ZONE)) return null;
      let parentDelegate = _parentDelegate(dart.as(implementationZone, _Zone));
      return dart.as(dart.dinvokef((implementation.function), implementationZone, parentDelegate, this, error, stackTrace), AsyncError);
    }
    scheduleMicrotask(f) {
      let implementation = this._scheduleMicrotask;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, f);
    }
    createTimer(duration, f) {
      let implementation = this._createTimer;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, duration, f), Timer);
    }
    createPeriodicTimer(duration, f) {
      let implementation = this._createPeriodicTimer;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.as(dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, duration, f), Timer);
    }
    print(line) {
      let implementation = this._print;
      dart.assert(implementation !== null);
      let parentDelegate = _parentDelegate(implementation.zone);
      return dart.dinvokef((implementation.function), implementation.zone, parentDelegate, this, line);
    }
  }

  // Function _rootHandleUncaughtError: (Zone, ZoneDelegate, Zone, dynamic, StackTrace) → void
  function _rootHandleUncaughtError(self, parent, zone, error, stackTrace) {
    _schedulePriorityAsyncCallback(() => {
      throw new _UncaughtAsyncError(error, stackTrace);
    });
  }

  // Function _rootRun: (Zone, ZoneDelegate, Zone, () → dynamic) → dynamic
  function _rootRun(self, parent, zone, f) {
    if (dart.equals(Zone._current, zone)) return f();
    let old = Zone._enter(zone);
    try {
      return f();
    }
    finally {
      Zone._leave(old);
    }
  }

  // Function _rootRunUnary: (Zone, ZoneDelegate, Zone, (dynamic) → dynamic, dynamic) → dynamic
  function _rootRunUnary(self, parent, zone, f, arg) {
    if (dart.equals(Zone._current, zone)) return f(arg);
    let old = Zone._enter(zone);
    try {
      return f(arg);
    }
    finally {
      Zone._leave(old);
    }
  }

  // Function _rootRunBinary: (Zone, ZoneDelegate, Zone, (dynamic, dynamic) → dynamic, dynamic, dynamic) → dynamic
  function _rootRunBinary(self, parent, zone, f, arg1, arg2) {
    if (dart.equals(Zone._current, zone)) return f(arg1, arg2);
    let old = Zone._enter(zone);
    try {
      return f(arg1, arg2);
    }
    finally {
      Zone._leave(old);
    }
  }

  // Function _rootRegisterCallback: (Zone, ZoneDelegate, Zone, () → dynamic) → () → dynamic
  function _rootRegisterCallback(self, parent, zone, f) {
    return f;
  }

  // Function _rootRegisterUnaryCallback: (Zone, ZoneDelegate, Zone, (dynamic) → dynamic) → (dynamic) → dynamic
  function _rootRegisterUnaryCallback(self, parent, zone, f) {
    return f;
  }

  // Function _rootRegisterBinaryCallback: (Zone, ZoneDelegate, Zone, (dynamic, dynamic) → dynamic) → (dynamic, dynamic) → dynamic
  function _rootRegisterBinaryCallback(self, parent, zone, f) {
    return f;
  }

  // Function _rootErrorCallback: (Zone, ZoneDelegate, Zone, Object, StackTrace) → AsyncError
  function _rootErrorCallback(self, parent, zone, error, stackTrace) { return null; }

  // Function _rootScheduleMicrotask: (Zone, ZoneDelegate, Zone, () → dynamic) → void
  function _rootScheduleMicrotask(self, parent, zone, f) {
    if (!core.identical(_ROOT_ZONE, zone)) {
      let hasErrorHandler = /* Unimplemented postfix operator: !_ROOT_ZONE.inSameErrorZone(zone) */;
      f = zone.bindCallback(f, {runGuarded: hasErrorHandler});
    }
    _scheduleAsyncCallback(f);
  }

  // Function _rootCreateTimer: (Zone, ZoneDelegate, Zone, Duration, () → void) → Timer
  function _rootCreateTimer(self, parent, zone, duration, callback) {
    if (!core.identical(_ROOT_ZONE, zone)) {
      callback = zone.bindCallback(callback);
    }
    return Timer._createTimer(duration, callback);
  }

  // Function _rootCreatePeriodicTimer: (Zone, ZoneDelegate, Zone, Duration, (Timer) → void) → Timer
  function _rootCreatePeriodicTimer(self, parent, zone, duration, callback) {
    if (!core.identical(_ROOT_ZONE, zone)) {
      callback = zone.bindUnaryCallback(dart.as(callback, /* Unimplemented type (dynamic) → dynamic */));
    }
    return Timer._createPeriodicTimer(duration, callback);
  }

  // Function _rootPrint: (Zone, ZoneDelegate, Zone, String) → void
  function _rootPrint(self, parent, zone, line) {
    _internal.printToConsole(line);
  }

  // Function _printToZone: (String) → void
  function _printToZone(line) {
    Zone.current.print(line);
  }

  // Function _rootFork: (Zone, ZoneDelegate, Zone, ZoneSpecification, Map<dynamic, dynamic>) → Zone
  function _rootFork(self, parent, zone, specification, zoneValues) {
    _internal.printToZone = _printToZone;
    if (specification === null) {
      specification = new ZoneSpecification();
    } else if (!dart.is(specification, _ZoneSpecification)) {
      throw new core.ArgumentError("ZoneSpecifications must be instantiated" +
          " with the provided constructor.");
    }
    let valueMap = null;
    if (zoneValues === null) {
      if (dart.is(zone, _Zone)) {
        valueMap = dart.as(zone._map, core.Map);
      } else {
        valueMap = new collection.HashMap();
      }
    } else {
      valueMap = new collection.HashMap.from(zoneValues);
    }
    return new _CustomZone(zone, specification, valueMap);
  }

  class _RootZoneSpecification {
    get handleUncaughtError() { return _rootHandleUncaughtError; }
    get run() { return _rootRun; }
    get runUnary() { return _rootRunUnary; }
    get runBinary() { return _rootRunBinary; }
    get registerCallback() { return _rootRegisterCallback; }
    get registerUnaryCallback() { return _rootRegisterUnaryCallback; }
    get registerBinaryCallback() { return _rootRegisterBinaryCallback; }
    get errorCallback() { return _rootErrorCallback; }
    get scheduleMicrotask() { return _rootScheduleMicrotask; }
    get createTimer() { return _rootCreateTimer; }
    get createPeriodicTimer() { return _rootCreatePeriodicTimer; }
    get print() { return _rootPrint; }
    get fork() { return _rootFork; }
  }

  class _RootZone extends _Zone {
    constructor() {
      super();
    }
    get _run() { return new _ZoneFunction(_ROOT_ZONE, _rootRun); }
    get _runUnary() { return new _ZoneFunction(_ROOT_ZONE, _rootRunUnary); }
    get _runBinary() { return new _ZoneFunction(_ROOT_ZONE, _rootRunBinary); }
    get _registerCallback() { return new _ZoneFunction(_ROOT_ZONE, _rootRegisterCallback); }
    get _registerUnaryCallback() { return new _ZoneFunction(_ROOT_ZONE, _rootRegisterUnaryCallback); }
    get _registerBinaryCallback() { return new _ZoneFunction(_ROOT_ZONE, _rootRegisterBinaryCallback); }
    get _errorCallback() { return new _ZoneFunction(_ROOT_ZONE, _rootErrorCallback); }
    get _scheduleMicrotask() { return new _ZoneFunction(_ROOT_ZONE, _rootScheduleMicrotask); }
    get _createTimer() { return new _ZoneFunction(_ROOT_ZONE, _rootCreateTimer); }
    get _createPeriodicTimer() { return new _ZoneFunction(_ROOT_ZONE, _rootCreatePeriodicTimer); }
    get _print() { return new _ZoneFunction(_ROOT_ZONE, _rootPrint); }
    get _fork() { return new _ZoneFunction(_ROOT_ZONE, _rootFork); }
    get _handleUncaughtError() { return new _ZoneFunction(_ROOT_ZONE, _rootHandleUncaughtError); }
    get parent() { return null; }
    get _map() { return _rootMap; }
    get _delegate() {
      if (_rootDelegate !== null) return _rootDelegate;
      return _rootDelegate = new _ZoneDelegate(this);
    }
    get errorZone() { return this; }
    runGuarded(f) {
      try {
        if (core.identical(_ROOT_ZONE, Zone._current)) {
          return f();
        }
        return _rootRun(null, null, this, f);
      }
      catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }
    }
    runUnaryGuarded(f, arg) {
      try {
        if (core.identical(_ROOT_ZONE, Zone._current)) {
          return f(arg);
        }
        return _rootRunUnary(null, null, this, f, arg);
      }
      catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }
    }
    runBinaryGuarded(f, arg1, arg2) {
      try {
        if (core.identical(_ROOT_ZONE, Zone._current)) {
          return f(arg1, arg2);
        }
        return _rootRunBinary(null, null, this, f, arg1, arg2);
      }
      catch (e) {
        let s = dart.stackTrace(e);
        return this.handleUncaughtError(e, s);
      }
    }
    bindCallback(f, opt$) {
      let runGuarded = opt$.runGuarded === undefined ? true : opt$.runGuarded;
      if (runGuarded) {
        return () => this.runGuarded(f);
      } else {
        return () => this.run(f);
      }
    }
    bindUnaryCallback(f, opt$) {
      let runGuarded = opt$.runGuarded === undefined ? true : opt$.runGuarded;
      if (runGuarded) {
        return (arg) => this.runUnaryGuarded(f, arg);
      } else {
        return (arg) => this.runUnary(f, arg);
      }
    }
    bindBinaryCallback(f, opt$) {
      let runGuarded = opt$.runGuarded === undefined ? true : opt$.runGuarded;
      if (runGuarded) {
        return (arg1, arg2) => this.runBinaryGuarded(f, arg1, arg2);
      } else {
        return (arg1, arg2) => this.runBinary(f, arg1, arg2);
      }
    }
    get(key) { return null; }
    handleUncaughtError(error, stackTrace) {
      return _rootHandleUncaughtError(null, null, this, error, stackTrace);
    }
    fork(opt$) {
      let specification = opt$.specification === undefined ? null : opt$.specification;
      let zoneValues = opt$.zoneValues === undefined ? null : opt$.zoneValues;
      return _rootFork(null, null, this, specification, zoneValues);
    }
    run(f) {
      if (core.identical(Zone._current, _ROOT_ZONE)) return f();
      return _rootRun(null, null, this, f);
    }
    runUnary(f, arg) {
      if (core.identical(Zone._current, _ROOT_ZONE)) return f(arg);
      return _rootRunUnary(null, null, this, f, arg);
    }
    runBinary(f, arg1, arg2) {
      if (core.identical(Zone._current, _ROOT_ZONE)) return f(arg1, arg2);
      return _rootRunBinary(null, null, this, f, arg1, arg2);
    }
    registerCallback(f) { return f; }
    registerUnaryCallback(f) { return f; }
    registerBinaryCallback(f) { return f; }
    errorCallback(error, stackTrace) { return null; }
    scheduleMicrotask(f) {
      _rootScheduleMicrotask(null, null, this, f);
    }
    createTimer(duration, f) {
      return Timer._createTimer(duration, f);
    }
    createPeriodicTimer(duration, f) {
      return Timer._createPeriodicTimer(duration, f);
    }
    print(line) {
      _internal.printToConsole(line);
    }
  }
  _RootZone._rootDelegate = null;
  dart.defineLazyProperties(_RootZone, {
    get _rootMap() { return new collection.HashMap() },
    set _rootMap(x) {},
  });

  let _ROOT_ZONE = new _RootZone();
  // Function runZoned: (() → dynamic, {zoneValues: Map<dynamic, dynamic>, zoneSpecification: ZoneSpecification, onError: Function}) → dynamic
  function runZoned(body, opt$) {
    let zoneValues = opt$.zoneValues === undefined ? null : opt$.zoneValues;
    let zoneSpecification = opt$.zoneSpecification === undefined ? null : opt$.zoneSpecification;
    let onError = opt$.onError === undefined ? null : opt$.onError;
    let errorHandler = null;
    if (onError !== null) {
      errorHandler = (self, parent, zone, error, stackTrace) => {
        try {
          if (dart.is(onError, ZoneBinaryCallback)) {
            return self.parent.runBinary(dart.as(onError, /* Unimplemented type (dynamic, dynamic) → dynamic */), error, stackTrace);
          }
          return self.parent.runUnary(dart.as(onError, /* Unimplemented type (dynamic) → dynamic */), error);
        }
        catch (e) {
          let s = dart.stackTrace(e);
          if (core.identical(e, error)) {
            return parent.handleUncaughtError(zone, error, stackTrace);
          } else {
            return parent.handleUncaughtError(zone, e, s);
          }
        }
      };
    }
    if (zoneSpecification === null) {
      zoneSpecification = new ZoneSpecification({handleUncaughtError: errorHandler});
    } else if (errorHandler !== null) {
      zoneSpecification = new ZoneSpecification.from(zoneSpecification, {handleUncaughtError: errorHandler});
    }
    let zone = Zone.current.fork({specification: zoneSpecification, zoneValues: zoneValues});
    if (onError !== null) {
      return zone.runGuarded(body);
    } else {
      return zone.run(body);
    }
  }

  // Exports:
  async.DeferredLibrary = DeferredLibrary;
  async.DeferredLoadException = DeferredLoadException;
  async.Future = Future;
  async.Future$ = Future$;
  async.TimeoutException = TimeoutException;
  async.Completer = Completer;
  async.Completer$ = Completer$;
  async.scheduleMicrotask = scheduleMicrotask;
  async.Stream = Stream;
  async.Stream$ = Stream$;
  async.StreamSubscription = StreamSubscription;
  async.StreamSubscription$ = StreamSubscription$;
  async.EventSink = EventSink;
  async.EventSink$ = EventSink$;
  async.StreamView = StreamView;
  async.StreamView$ = StreamView$;
  async.StreamConsumer = StreamConsumer;
  async.StreamConsumer$ = StreamConsumer$;
  async.StreamSink = StreamSink;
  async.StreamSink$ = StreamSink$;
  async.StreamTransformer = StreamTransformer;
  async.StreamTransformer$ = StreamTransformer$;
  async.StreamIterator = StreamIterator;
  async.StreamIterator$ = StreamIterator$;
  async.StreamController = StreamController;
  async.StreamController$ = StreamController$;
  async.Timer = Timer;
  async.AsyncError = AsyncError;
  async.ZoneSpecification = ZoneSpecification;
  async.ZoneDelegate = ZoneDelegate;
  async.Zone = Zone;
  async.runZoned = runZoned;
})(async || (async = {}));
