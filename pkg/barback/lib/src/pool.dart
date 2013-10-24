import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';

/// Manages an abstract pool of resources with a limit on how many may be in use
/// at once.
///
/// When a resource is needed, the user should call [checkOut]. When the
/// returned future completes with a [PoolResource], the resource may be
/// allocated. Once the resource has been released, the user should call
/// [PoolResource.release]. The pool will ensure that only a certain number of
/// [PoolResource]s may be checked out at once.
class Pool {
  /// Completers for checkouts beyond the first [_maxCheckedOutResources].
  ///
  /// When an item is released, the next element of [_pendingResources] will be
  /// completed.
  final _pendingResources = new Queue<Completer<PoolResource>>();

  /// The maximum number of resources that may be checked out at once.
  final int _maxCheckedOutResources;

  /// The number of resources that are currently checked out.
  int _checkedOutResources = 0;

  /// The timeout timer.
  ///
  /// If [_timeout] isn't null, this timer is set as soon as the resource limit
  /// is reached and is reset every time an resource is released or a new
  /// resource is requested. If it fires, that indicates that the caller became
  /// deadlocked, likely due to files waiting for additional files to be read
  /// before they could be closed.
  Timer _timer;

  /// The amount of time to wait before timing out the pending resources.
  Duration _timeout;

  /// Creates a new pool with the given limit on how many resources may be
  /// checked out at once.
  ///
  /// If [timeout] is passed, then if that much time passes without any activity
  /// all pending [checkOut] futures will throw an exception. This is indented
  /// to avoid deadlocks.
  Pool(this._maxCheckedOutResources, {Duration timeout})
      : _timeout = timeout;

  /// Check out a [PoolResource].
  ///
  /// If the maximum number of resources is already checked out, this will delay
  /// until one of them is released.
  Future<PoolResource> checkOut() {
    if (_checkedOutResources < _maxCheckedOutResources) {
      _checkedOutResources++;
      return new Future.value(new PoolResource._(this));
    } else {
      var completer = new Completer<PoolResource>();
      _pendingResources.add(completer);
      _heartbeat();
      return completer.future;
    }
  }

  /// Checks out a resource for the duration of [callback], which may return a
  /// Future.
  ///
  /// The return value of [callback] is piped to the returned Future.
  Future withResource(callback()) {
    return checkOut().then((resource) =>
        new Future.sync(callback).whenComplete(resource.release));
  }

  /// If there are any pending checkouts, this will fire the oldest one.
  void _onResourceReleased() {
    if (_pendingResources.isEmpty) {
      _checkedOutResources--;
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
      return;
    }

    _heartbeat();
    var pending = _pendingResources.removeFirst();
    pending.complete(new PoolResource._(this));
  }

  /// Indicates that some external action has occurred and the timer should be
  /// restarted.
  void _heartbeat() {
    if (_timer != null) _timer.cancel();
    if (_timeout == null) {
      _timer = null;
    } else {
      _timer = new Timer(_timeout, _onTimeout);
    }
  }

  /// Handles [_timer] timing out by causing all pending resource completers to
  /// emit exceptions.
  void _onTimeout() {
    for (var completer in _pendingResources) {
      completer.completeException("Pool deadlock: all resources have been "
          "checked out for too long.", new Trace.current().vmTrace);
    }
    _pendingResources.clear();
    _timer = null;
  }
}

/// A member of a [Pool].
///
/// A [PoolResource] is a token that indicates that a resource is allocated.
/// When the associated resource is released, the user should call [release].
class PoolResource {
  final Pool _pool;

  /// Whether [this] has been released yet.
  bool _released = false;

  PoolResource._(this._pool);

  /// Tells the parent [Pool] that the resource associated with this resource is
  /// no longer allocated, and that a new [PoolResource] may be checked out.
  void release() {
    if (_released) {
      throw new StateError("A PoolResource may only be released once.");
    }
    _released = true;
    _pool._onResourceReleased();
  }
}