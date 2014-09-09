library pub.error_group;
import 'dart:async';
class ErrorGroup {
  final _futures = <_ErrorGroupFuture>[];
  final _streams = <_ErrorGroupStream>[];
  var _isDone = false;
  final _doneCompleter = new Completer();
  _ErrorGroupFuture _done;
  Future get done => _done;
  ErrorGroup() {
    this._done = new _ErrorGroupFuture(this, _doneCompleter.future);
  }
  Future registerFuture(Future future) {
    if (_isDone) {
      throw new StateError(
          "Can't register new members on a complete " "ErrorGroup.");
    }
    var wrapped = new _ErrorGroupFuture(this, future);
    _futures.add(wrapped);
    return wrapped;
  }
  Stream registerStream(Stream stream) {
    if (_isDone) {
      throw new StateError(
          "Can't register new members on a complete " "ErrorGroup.");
    }
    var wrapped = new _ErrorGroupStream(this, stream);
    _streams.add(wrapped);
    return wrapped;
  }
  void signalError(var error, [StackTrace stackTrace]) {
    if (_isDone) {
      throw new StateError("Can't signal errors on a complete ErrorGroup.");
    }
    _signalError(error, stackTrace);
  }
  void _signalError(var error, [StackTrace stackTrace]) {
    if (_isDone) return;
    var caught = false;
    for (var future in _futures) {
      if (future._isDone || future._hasListeners) caught = true;
      future._signalError(error, stackTrace);
    }
    for (var stream in _streams) {
      if (stream._isDone || stream._hasListeners) caught = true;
      stream._signalError(error, stackTrace);
    }
    _isDone = true;
    _done._signalError(error, stackTrace);
    if (!caught && !_done._hasListeners) scheduleMicrotask(() {
      throw error;
    });
  }
  void _signalFutureComplete(_ErrorGroupFuture future) {
    if (_isDone) return;
    _isDone = _futures.every((future) => future._isDone) &&
        _streams.every((stream) => stream._isDone);
    if (_isDone) _doneCompleter.complete();
  }
  void _signalStreamComplete(_ErrorGroupStream stream) {
    if (_isDone) return;
    _isDone = _futures.every((future) => future._isDone) &&
        _streams.every((stream) => stream._isDone);
    if (_isDone) _doneCompleter.complete();
  }
}
class _ErrorGroupFuture implements Future {
  final ErrorGroup _group;
  var _isDone = false;
  final _completer = new Completer();
  bool _hasListeners = false;
  _ErrorGroupFuture(this._group, Future inner) {
    inner.then((value) {
      if (!_isDone) _completer.complete(value);
      _isDone = true;
      _group._signalFutureComplete(this);
    }).catchError(_group._signalError);
    _completer.future.catchError((_) {});
  }
  Future then(onValue(value), {Function onError}) {
    _hasListeners = true;
    return _completer.future.then(onValue, onError: onError);
  }
  Future catchError(Function onError, {bool test(Object error)}) {
    _hasListeners = true;
    return _completer.future.catchError(onError, test: test);
  }
  Future whenComplete(void action()) {
    _hasListeners = true;
    return _completer.future.whenComplete(action);
  }
  Future timeout(Duration timeLimit, {void onTimeout()}) {
    _hasListeners = true;
    return _completer.future.timeout(timeLimit, onTimeout: onTimeout);
  }
  Stream asStream() {
    _hasListeners = true;
    return _completer.future.asStream();
  }
  void _signalError(var error, [StackTrace stackTrace]) {
    if (!_isDone) _completer.completeError(error, stackTrace);
    _isDone = true;
  }
}
class _ErrorGroupStream extends Stream {
  final ErrorGroup _group;
  var _isDone = false;
  final StreamController _controller;
  Stream _stream;
  StreamSubscription _subscription;
  bool get _hasListeners => _controller.hasListener;
  _ErrorGroupStream(this._group, Stream inner)
      : _controller = new StreamController(sync: true) {
    _stream = inner.isBroadcast ?
        _controller.stream.asBroadcastStream(onCancel: (sub) => sub.cancel()) :
        _controller.stream;
    _subscription = inner.listen((v) {
      _controller.add(v);
    }, onError: (e, [stackTrace]) {
      _group._signalError(e, stackTrace);
    }, onDone: () {
      _isDone = true;
      _group._signalStreamComplete(this);
      _controller.close();
    });
  }
  StreamSubscription listen(void onData(value), {Function onError, void
      onDone(), bool cancelOnError}) {
    return _stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: true);
  }
  void _signalError(var e, [StackTrace stackTrace]) {
    if (_isDone) return;
    _subscription.cancel();
    new Future.value().then((_) {
      _controller.addError(e, stackTrace);
      _controller.close();
    });
  }
}
