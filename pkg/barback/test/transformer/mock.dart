// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.mock;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

/// The abstract base class for transformers used to test barback.
///
/// This adds the ability to pause and resume different components of the
/// transformers, and to tell whether they're running, when they start running,
/// and how many times they've run.
///
/// Transformers extending this should override [doIsPrimary] and [doApply]
/// rather than [isPrimary] and [apply], and they should use [getInput] and
/// [getPrimary] rather than [transform.getInput] and [transform.primaryInput].
abstract class MockTransformer extends Transformer {
  /// The number of times the transformer has been applied.
  ///
  /// This is scheduled. The Future will complete at the point in the schedule
  /// that this is called.
  Future<int> get numRuns => schedule(() => _numRuns);
  var _numRuns = 0;

  /// The number of currently running transforms.
  int _runningTransforms = 0;

  /// A completer for pausing the transformer before it finishes running [apply].
  Completer _apply;

  /// Completers for pausing the transformer before it finishes running
  /// [isPrimary].
  final _isPrimary = new Map<AssetId, Completer>();

  /// Completers for pausing the transformer before it finishes getting inputs
  /// the [Transform].
  final _getInput = new Map<AssetId, Completer>();

  /// Completer for pausing the transformer before it accesses [primaryInput].
  Completer _primaryInput;

  /// A completer that completes once this transformer begins running.
  ///
  /// Once this transformer finishes running, this is reset to a new completer,
  /// so it can be used multiple times.
  var _started = new Completer();

  /// `true` if any transforms are currently running.
  ///
  /// This is scheduled. The Future will complete at the point in the schedule
  /// that this is called.
  Future<bool> get isRunning => schedule(() => _runningTransforms > 0);

  /// If this is set to `true`, the transformer will consume its primary input
  /// during [apply].
  bool consumePrimary = false;

  /// Pauses the schedule until this transformer begins running.
  void waitUntilStarted() {
    schedule(() => _started.future, "wait until $this starts");
  }

  /// Causes the transformer to pause after running [apply] but before the
  /// returned Future completes.
  ///
  /// This can be resumed by calling [resumeApply]. This operation is scheduled.
  void pauseApply() {
    schedule(() {
      _apply = new Completer();
    }, "pause apply for $this");
  }

  /// Resumes the transformer's [apply] call after [pauseApply] was called.
  ///
  /// This operation is scheduled.
  void resumeApply() {
    schedule(() {
      _apply.complete();
      _apply = null;
    }, "resume apply for $this");
  }

  /// Causes the transformer to pause after running [isPrimary] on the asset
  /// with the given [name], but before the returned Future completes.
  ///
  /// This can be resumed by calling [resumeIsPrimary]. This operation is
  /// scheduled.
  void pauseIsPrimary(String name) {
    schedule(() {
      _isPrimary[new AssetId.parse(name)] = new Completer();
    }, "pause isPrimary($name) for $this");
  }

  /// Resumes the transformer's [isPrimary] call on the asset with the given
  /// [name] after [pauseIsPrimary] was called.
  ///
  /// This operation is scheduled.
  void resumeIsPrimary(String name) {
    schedule(() {
      _isPrimary.remove(new AssetId.parse(name)).complete();
    }, "resume isPrimary($name) for $this");
  }

  /// Causes the transformer to pause while loading the secondary input with
  /// the given [name].
  ///
  /// This can be resumed by calling [resumeGetInput]. This operation is
  /// scheduled.
  void pauseGetInput(String name) {
    schedule(() {
      _getInput[new AssetId.parse(name)] = new Completer();
    }, "pause getInput($name) for $this");
  }

  /// Resumes the transformer's loading of the input with the given [name] after
  /// [pauseGetInput] was called.
  ///
  /// This operation is scheduled.
  void resumeGetInput(String name) {
    schedule(() {
      _getInput.remove(new AssetId.parse(name)).complete();
    }, "resume getInput($name) for $this");
  }

  /// Causes the transformer to pause before accessing [primaryInput].
  ///
  /// This can be resumed by calling [resumeGetPrimary]. This operation is
  /// scheduled.
  void pausePrimaryInput() {
    schedule(() {
      _primaryInput = new Completer();
    }, "pause primaryInput for $this");
  }

  /// Resumes the transformer's invocation of [primaryInput] after
  /// [pauseGetPrimary] was called.
  ///
  /// This operation is scheduled.
  void resumePrimaryInput() {
    schedule(() {
      _primaryInput.complete();
      _primaryInput = null;
    }, "resume getPrimary() for $this");
  }

  /// Like [Transform.getInput], but respects [pauseGetInput].
  ///
  /// This is intended for use by subclasses of [MockTransformer].
  Future<Asset> getInput(Transform transform, AssetId id) {
    return newFuture(() {
      if (_getInput.containsKey(id)) return _getInput[id].future;
    }).then((_) => transform.getInput(id));
  }

  /// Like [Transform.primaryInput], but respects [pauseGetPrimary].
  ///
  /// This is intended for use by subclasses of [MockTransformer].
  Future<Asset> getPrimary(Transform transform) {
    return newFuture(() {
      if (_primaryInput != null) return _primaryInput.future;
    }).then((_) => transform.primaryInput);
  }

  Future<bool> isPrimary(AssetId id) {
    return newFuture(() => doIsPrimary(id)).then((result) {
      return newFuture(() {
        if (_isPrimary.containsKey(id)) {
          return _isPrimary[id].future;
        }
      }).then((_) => result);
    });
  }

  Future apply(Transform transform) {
    _numRuns++;
    if (_runningTransforms == 0) _started.complete();
    _runningTransforms++;
    if (consumePrimary) transform.consumePrimary();
    return newFuture(() => doApply(transform)).then((_) {
      if (_apply != null) return _apply.future;
    }).whenComplete(() {
      _runningTransforms--;
      if (_runningTransforms == 0) _started = new Completer();
    });
  }

  /// The wrapped version of [isPrimary] for subclasses to override.
  ///
  /// This may return a `Future<bool>` or, if it's entirely synchronous, a
  /// `bool`.
  doIsPrimary(AssetId id);

  /// The wrapped version of [doApply] for subclasses to override.
  ///
  /// If this does asynchronous work, it should return a [Future] that completes
  /// once it's finished.
  doApply(Transform transform);
}
