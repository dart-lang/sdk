part of dart.async;

abstract class StreamController<T> implements StreamSink<T> {
  Stream<T> get stream;
  factory StreamController({void onListen(), void onPause(), void onResume(),
      onCancel(), bool sync: false}) {
    if (onListen == null &&
        onPause == null &&
        onResume == null &&
        onCancel == null) {
      return ((__x96) => DDC$RT.cast(__x96,
              DDC$RT.type((_StreamController<dynamic> _) {}),
              DDC$RT.type((StreamController<T> _) {}), "CastDynamic",
              """line 83, column 14 of dart:async/stream_controller.dart: """,
              __x96 is StreamController<T>, false))(sync
          ? new _NoCallbackSyncStreamController()
          : new _NoCallbackAsyncStreamController());
    }
    return sync
        ? new _SyncStreamController<T>(onListen, onPause, onResume, onCancel)
        : new _AsyncStreamController<T>(onListen, onPause, onResume, onCancel);
  }
  factory StreamController.broadcast(
      {void onListen(), void onCancel(), bool sync: false}) {
    return sync
        ? new _SyncBroadcastStreamController<T>(onListen, onCancel)
        : new _AsyncBroadcastStreamController<T>(onListen, onCancel);
  }
  StreamSink<T> get sink;
  bool get isClosed;
  bool get isPaused;
  bool get hasListener;
  void addError(Object error, [StackTrace stackTrace]);
  Future addStream(Stream<T> source, {bool cancelOnError: true});
}
abstract class _StreamControllerLifecycle<T> {
  StreamSubscription<T> _subscribe(
      void onData(T data), Function onError, void onDone(), bool cancelOnError);
  void _recordPause(StreamSubscription<T> subscription) {}
  void _recordResume(StreamSubscription<T> subscription) {}
  Future _recordCancel(StreamSubscription<T> subscription) => null;
}
abstract class _StreamController<T>
    implements StreamController<T>, _StreamControllerLifecycle<T>, _EventSink<T>, _EventDispatch<T> {
  static const int _STATE_INITIAL = 0;
  static const int _STATE_SUBSCRIBED = 1;
  static const int _STATE_CANCELED = 2;
  static const int _STATE_SUBSCRIPTION_MASK = 3;
  static const int _STATE_CLOSED = 4;
  static const int _STATE_ADDSTREAM = 8;
  var _varData;
  int _state = _STATE_INITIAL;
  _Future _doneFuture;
  _StreamController();
  _NotificationHandler get _onListen;
  _NotificationHandler get _onPause;
  _NotificationHandler get _onResume;
  _NotificationHandler get _onCancel;
  Stream<T> get stream => ((__x97) => DDC$RT.cast(__x97,
      DDC$RT.type((_ControllerStream<dynamic> _) {}),
      DDC$RT.type((Stream<T> _) {}), "CastExact",
      """line 293, column 27 of dart:async/stream_controller.dart: """,
      __x97 is Stream<T>, false))(new _ControllerStream(this));
  StreamSink<T> get sink => new _StreamSinkWrapper<T>(this);
  bool get _isCanceled => (_state & _STATE_CANCELED) != 0;
  bool get hasListener => (_state & _STATE_SUBSCRIBED) != 0;
  bool get _isInitialState =>
      (_state & _STATE_SUBSCRIPTION_MASK) == _STATE_INITIAL;
  bool get isClosed => (_state & _STATE_CLOSED) != 0;
  bool get isPaused =>
      hasListener ? _subscription._isInputPaused : !_isCanceled;
  bool get _isAddingStream => (_state & _STATE_ADDSTREAM) != 0;
  bool get _mayAddEvent => (_state < _STATE_CLOSED);
  _PendingEvents get _pendingEvents {
    assert(_isInitialState);
    if (!_isAddingStream) {
      return DDC$RT.cast(_varData, dynamic, _PendingEvents, "CastGeneral",
          """line 334, column 14 of dart:async/stream_controller.dart: """,
          _varData is _PendingEvents, true);
    }
    _StreamControllerAddStreamState state = DDC$RT.cast(_varData, dynamic,
        DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
        "CastGeneral",
        """line 336, column 45 of dart:async/stream_controller.dart: """,
        _varData is _StreamControllerAddStreamState<dynamic>, true);
    return DDC$RT.cast(state.varData, dynamic, _PendingEvents, "CastGeneral",
        """line 337, column 12 of dart:async/stream_controller.dart: """,
        state.varData is _PendingEvents, true);
  }
  _StreamImplEvents _ensurePendingEvents() {
    assert(_isInitialState);
    if (!_isAddingStream) {
      if (_varData == null) _varData = new _StreamImplEvents();
      return DDC$RT.cast(_varData, dynamic, _StreamImplEvents, "CastGeneral",
          """line 345, column 14 of dart:async/stream_controller.dart: """,
          _varData is _StreamImplEvents, true);
    }
    _StreamControllerAddStreamState state = DDC$RT.cast(_varData, dynamic,
        DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
        "CastGeneral",
        """line 347, column 45 of dart:async/stream_controller.dart: """,
        _varData is _StreamControllerAddStreamState<dynamic>, true);
    if (state.varData == null) state.varData = new _StreamImplEvents();
    return DDC$RT.cast(state.varData, dynamic, _StreamImplEvents, "CastGeneral",
        """line 349, column 12 of dart:async/stream_controller.dart: """,
        state.varData is _StreamImplEvents, true);
  }
  _ControllerSubscription get _subscription {
    assert(hasListener);
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = DDC$RT.cast(_varData, dynamic,
          DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
          "CastGeneral",
          """line 358, column 50 of dart:async/stream_controller.dart: """,
          _varData is _StreamControllerAddStreamState<dynamic>, true);
      return DDC$RT.cast(addState.varData, dynamic,
          DDC$RT.type((_ControllerSubscription<dynamic> _) {}), "CastGeneral",
          """line 359, column 14 of dart:async/stream_controller.dart: """,
          addState.varData is _ControllerSubscription<dynamic>, true);
    }
    return DDC$RT.cast(_varData, dynamic,
        DDC$RT.type((_ControllerSubscription<dynamic> _) {}), "CastGeneral",
        """line 361, column 12 of dart:async/stream_controller.dart: """,
        _varData is _ControllerSubscription<dynamic>, true);
  }
  Error _badEventState() {
    if (isClosed) {
      return new StateError("Cannot add event after closing");
    }
    assert(_isAddingStream);
    return new StateError("Cannot add event while adding a stream");
  }
  Future addStream(Stream<T> source, {bool cancelOnError: true}) {
    if (!_mayAddEvent) throw _badEventState();
    if (_isCanceled) return new _Future.immediate(null);
    _StreamControllerAddStreamState addState =
        new _StreamControllerAddStreamState(
            this, _varData, source, cancelOnError);
    _varData = addState;
    _state |= _STATE_ADDSTREAM;
    return addState.addStreamFuture;
  }
  Future get done => _ensureDoneFuture();
  Future _ensureDoneFuture() {
    if (_doneFuture == null) {
      _doneFuture = _isCanceled ? Future._nullFuture : new _Future();
    }
    return _doneFuture;
  }
  void add(T value) {
    if (!_mayAddEvent) throw _badEventState();
    _add(value);
  }
  void addError(Object error, [StackTrace stackTrace]) {
    error = _nonNullError(error);
    if (!_mayAddEvent) throw _badEventState();
    AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    _addError(error, stackTrace);
  }
  Future close() {
    if (isClosed) {
      return _ensureDoneFuture();
    }
    if (!_mayAddEvent) throw _badEventState();
    _closeUnchecked();
    return _ensureDoneFuture();
  }
  void _closeUnchecked() {
    _state |= _STATE_CLOSED;
    if (hasListener) {
      _sendDone();
    } else if (_isInitialState) {
      _ensurePendingEvents().add(const _DelayedDone());
    }
  }
  void _add(T value) {
    if (hasListener) {
      _sendData(value);
    } else if (_isInitialState) {
      _ensurePendingEvents().add(new _DelayedData<T>(value));
    }
  }
  void _addError(Object error, StackTrace stackTrace) {
    if (hasListener) {
      _sendError(error, stackTrace);
    } else if (_isInitialState) {
      _ensurePendingEvents().add(new _DelayedError(error, stackTrace));
    }
  }
  void _close() {
    assert(_isAddingStream);
    _StreamControllerAddStreamState addState = DDC$RT.cast(_varData, dynamic,
        DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
        "CastGeneral",
        """line 482, column 48 of dart:async/stream_controller.dart: """,
        _varData is _StreamControllerAddStreamState<dynamic>, true);
    _varData = addState.varData;
    _state &= ~_STATE_ADDSTREAM;
    addState.complete();
  }
  StreamSubscription<T> _subscribe(void onData(T data), Function onError,
      void onDone(), bool cancelOnError) {
    if (!_isInitialState) {
      throw new StateError("Stream has already been listened to.");
    }
    _ControllerSubscription subscription = new _ControllerSubscription(
        this, onData, onError, onDone, cancelOnError);
    _PendingEvents pendingEvents = _pendingEvents;
    _state |= _STATE_SUBSCRIBED;
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = DDC$RT.cast(_varData, dynamic,
          DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
          "CastGeneral",
          """line 505, column 50 of dart:async/stream_controller.dart: """,
          _varData is _StreamControllerAddStreamState<dynamic>, true);
      addState.varData = subscription;
      addState.resume();
    } else {
      _varData = subscription;
    }
    subscription._setPendingEvents(pendingEvents);
    subscription._guardCallback(() {
      _runGuarded(_onListen);
    });
    return DDC$RT.cast(subscription,
        DDC$RT.type((_ControllerSubscription<dynamic> _) {}),
        DDC$RT.type((StreamSubscription<T> _) {}), "CastDynamic",
        """line 516, column 12 of dart:async/stream_controller.dart: """,
        subscription is StreamSubscription<T>, false);
  }
  Future _recordCancel(StreamSubscription<T> subscription) {
    Future result;
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = DDC$RT.cast(_varData, dynamic,
          DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
          "CastGeneral",
          """line 530, column 50 of dart:async/stream_controller.dart: """,
          _varData is _StreamControllerAddStreamState<dynamic>, true);
      result = addState.cancel();
    }
    _varData = null;
    _state =
        (_state & ~(_STATE_SUBSCRIBED | _STATE_ADDSTREAM)) | _STATE_CANCELED;
    if (_onCancel != null) {
      if (result == null) {
        try {
          result = ((__x98) => DDC$RT.cast(__x98, dynamic,
              DDC$RT.type((Future<dynamic> _) {}), "CastGeneral",
              """line 542, column 20 of dart:async/stream_controller.dart: """,
              __x98 is Future<dynamic>, true))(_onCancel());
        } catch (e, s) {
          result = new _Future().._asyncCompleteError(e, s);
        }
      } else {
        result = result.whenComplete(_onCancel);
      }
    }
    void complete() {
      if (_doneFuture != null && _doneFuture._mayComplete) {
        _doneFuture._asyncComplete(null);
      }
    }
    if (result != null) {
      result = result.whenComplete(complete);
    } else {
      complete();
    }
    return result;
  }
  void _recordPause(StreamSubscription<T> subscription) {
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = DDC$RT.cast(_varData, dynamic,
          DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
          "CastGeneral",
          """line 572, column 50 of dart:async/stream_controller.dart: """,
          _varData is _StreamControllerAddStreamState<dynamic>, true);
      addState.pause();
    }
    _runGuarded(_onPause);
  }
  void _recordResume(StreamSubscription<T> subscription) {
    if (_isAddingStream) {
      _StreamControllerAddStreamState addState = DDC$RT.cast(_varData, dynamic,
          DDC$RT.type((_StreamControllerAddStreamState<dynamic> _) {}),
          "CastGeneral",
          """line 580, column 50 of dart:async/stream_controller.dart: """,
          _varData is _StreamControllerAddStreamState<dynamic>, true);
      addState.resume();
    }
    _runGuarded(_onResume);
  }
}
abstract class _SyncStreamControllerDispatch<T>
    implements _StreamController<T> {
  void _sendData(T data) {
    _subscription._add(data);
  }
  void _sendError(Object error, StackTrace stackTrace) {
    _subscription._addError(error, stackTrace);
  }
  void _sendDone() {
    _subscription._close();
  }
}
abstract class _AsyncStreamControllerDispatch<T>
    implements _StreamController<T> {
  void _sendData(T data) {
    _subscription._addPending(new _DelayedData(data));
  }
  void _sendError(Object error, StackTrace stackTrace) {
    _subscription._addPending(new _DelayedError(error, stackTrace));
  }
  void _sendDone() {
    _subscription._addPending(const _DelayedDone());
  }
}
class _AsyncStreamController<T> extends _StreamController<T>
    with _AsyncStreamControllerDispatch<T> {
  final _NotificationHandler _onListen;
  final _NotificationHandler _onPause;
  final _NotificationHandler _onResume;
  final _NotificationHandler _onCancel;
  _AsyncStreamController(void this._onListen(), void this._onPause(),
      void this._onResume(), this._onCancel());
}
class _SyncStreamController<T> extends _StreamController<T>
    with _SyncStreamControllerDispatch<T> {
  final _NotificationHandler _onListen;
  final _NotificationHandler _onPause;
  final _NotificationHandler _onResume;
  final _NotificationHandler _onCancel;
  _SyncStreamController(void this._onListen(), void this._onPause(),
      void this._onResume(), this._onCancel());
}
abstract class _NoCallbacks {
  _NotificationHandler get _onListen => null;
  _NotificationHandler get _onPause => null;
  _NotificationHandler get _onResume => null;
  _NotificationHandler get _onCancel => null;
}
class _NoCallbackAsyncStreamController = _StreamController
    with _AsyncStreamControllerDispatch, _NoCallbacks;
class _NoCallbackSyncStreamController = _StreamController
    with _SyncStreamControllerDispatch, _NoCallbacks;
typedef _NotificationHandler();
Future _runGuarded(_NotificationHandler notificationHandler) {
  if (notificationHandler == null) return null;
  try {
    var result = notificationHandler();
    if (result is Future) return DDC$RT.cast(result, dynamic,
        DDC$RT.type((Future<dynamic> _) {}), "CastGeneral",
        """line 665, column 34 of dart:async/stream_controller.dart: """,
        result is Future<dynamic>, true);
    return null;
  } catch (e, s) {
    Zone.current.handleUncaughtError(e, s);
  }
}
class _ControllerStream<T> extends _StreamImpl<T> {
  _StreamControllerLifecycle<T> _controller;
  _ControllerStream(this._controller);
  StreamSubscription<T> _createSubscription(void onData(T data),
          Function onError, void onDone(), bool cancelOnError) =>
      _controller._subscribe(onData, onError, onDone, cancelOnError);
  int get hashCode => _controller.hashCode ^ 0x35323532;
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _ControllerStream) return false;
    _ControllerStream otherStream = DDC$RT.cast(other, Object,
        DDC$RT.type((_ControllerStream<dynamic> _) {}), "CastGeneral",
        """line 693, column 37 of dart:async/stream_controller.dart: """,
        other is _ControllerStream<dynamic>, true);
    return identical(otherStream._controller, this._controller);
  }
}
class _ControllerSubscription<T> extends _BufferingStreamSubscription<T> {
  final _StreamControllerLifecycle<T> _controller;
  _ControllerSubscription(this._controller, void onData(T data),
      Function onError, void onDone(), bool cancelOnError)
      : super(onData, onError, onDone, cancelOnError);
  Future _onCancel() {
    return _controller._recordCancel(this);
  }
  void _onPause() {
    _controller._recordPause(this);
  }
  void _onResume() {
    _controller._recordResume(this);
  }
}
class _StreamSinkWrapper<T> implements StreamSink<T> {
  final StreamController _target;
  _StreamSinkWrapper(this._target);
  void add(T data) {
    _target.add(data);
  }
  void addError(Object error, [StackTrace stackTrace]) {
    _target.addError(error, stackTrace);
  }
  Future close() => _target.close();
  Future addStream(Stream<T> source, {bool cancelOnError: true}) =>
      _target.addStream(source, cancelOnError: cancelOnError);
  Future get done => _target.done;
}
class _AddStreamState<T> {
  final _Future addStreamFuture;
  final StreamSubscription addSubscription;
  _AddStreamState(_EventSink<T> controller, Stream source, bool cancelOnError)
      : addStreamFuture = new _Future(),
        addSubscription = source.listen(DDC$RT.wrap((void f(T __u99)) {
          void c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam",
              """line 745, column 41 of dart:async/stream_controller.dart: """,
              x0 is T, false));
          return f == null ? null : c;
        }, controller._add, DDC$RT.type((__t102<T> _) {}), __t100, "Wrap",
                """line 745, column 41 of dart:async/stream_controller.dart: """,
                controller._add is __t100),
            onError: ((__x104) => DDC$RT.cast(__x104, dynamic, Function,
                    "CastGeneral",
                    """line 746, column 50 of dart:async/stream_controller.dart: """,
                    __x104 is Function, true))(cancelOnError
                ? makeErrorHandler(controller)
                : controller._addError),
            onDone: controller._close,
            cancelOnError: cancelOnError);
  static makeErrorHandler(_EventSink controller) => (e, StackTrace s) {
    controller._addError(e, s);
    controller._close();
  };
  void pause() {
    addSubscription.pause();
  }
  void resume() {
    addSubscription.resume();
  }
  Future cancel() {
    var cancel = addSubscription.cancel();
    if (cancel == null) {
      addStreamFuture._asyncComplete(null);
      return null;
    }
    return cancel.whenComplete(() {
      addStreamFuture._asyncComplete(null);
    });
  }
  void complete() {
    addStreamFuture._asyncComplete(null);
  }
}
class _StreamControllerAddStreamState<T> extends _AddStreamState<T> {
  var varData;
  _StreamControllerAddStreamState(_StreamController controller, this.varData,
      Stream source, bool cancelOnError)
      : super(DDC$RT.cast(controller,
          DDC$RT.type((_StreamController<dynamic> _) {}),
          DDC$RT.type((_EventSink<T> _) {}), "CastDynamic",
          """line 798, column 15 of dart:async/stream_controller.dart: """,
          controller is _EventSink<T>, false), source, cancelOnError) {
    if (controller.isPaused) {
      addSubscription.pause();
    }
  }
}
typedef void __t100(dynamic __u101);
typedef void __t102<T>(T __u103);
