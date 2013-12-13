// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.pool;

import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';

import 'utils.dart';

// TODO(nweiz): put this somewhere that it can be shared between packages.
/// Manages an abstract pool of resources with a limit on how many may be in use
/// at once.
///
/// When a resource is needed, the user should call [request]. When the returned
/// future completes with a [PoolResource], the resource may be allocated. Once
/// the resource has been released, the user should call [PoolResource.release].
/// The pool will ensure that only a certain number of [PoolResource]s may be
/// allocated at once.
class Pool {
  /// Completers for requests beyond the first [_maxAllocatedResources].
  ///
  /// When an item is released, the next element of [_requestedResources] will
  /// be completed.
  final _requestedResources = new Queue<Completer<PoolResource>>();

  /// The maximum number of resources that may be allocated at once.
  final int _maxAllocatedResources;

  /// The number of resources that are currently allocated.
  int _allocatedResources = 0;

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
  /// allocated at once.
  ///
  /// If [timeout] is passed, then if that much time passes without any activity
  /// all pending [request] futures will throw an exception. This is indented
  /// to avoid deadlocks.
  Pool(this._maxAllocatedResources, {Duration timeout})
      : _timeout = timeout;

  /// Request a [PoolResource].
  ///
  /// If the maximum number of resources is already allocated, this will delay
  /// until one of them is released.
  Future<PoolResource> request() {
    if (_allocatedResources < _maxAllocatedResources) {
      _allocatedResources++;
      return new Future.value(new PoolResource._(this));
    } else {
      var completer = new Completer<PoolResource>();
      _requestedResources.add(completer);
      _resetTimer();
      return completer.future;
    }
  }

  /// Requests a resource for the duration of [callback], which may return a
  /// Future.
  ///
  /// The return value of [callback] is piped to the returned Future.
  Future withResource(callback()) {
    return request().then((resource) =>
        syncFuture(callback).whenComplete(resource.release));
  }

  /// If there are any pending requests, this will fire the oldest one.
  void _onResourceReleased() {
    if (_requestedResources.isEmpty) {
      _allocatedResources--;
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
      return;
    }

    _resetTimer();
    var pending = _requestedResources.removeFirst();
    pending.complete(new PoolResource._(this));
  }

  /// A resource has been requested, allocated, or released.
  void _resetTimer() {
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
    for (var completer in _requestedResources) {
      completer.completeError("Pool deadlock: all resources have been "
          "allocated for too long.", new Chain.current());
    }
    _requestedResources.clear();
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
  /// no longer allocated, and that a new [PoolResource] may be allocated.
  void release() {
    if (_released) {
      throw new StateError("A PoolResource may only be released once.");
    }
    _released = true;
    _pool._onResourceReleased();
  }
}
