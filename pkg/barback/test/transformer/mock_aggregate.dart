// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.mock_aggregate;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';
import 'package:scheduled_test/scheduled_test.dart';

/// The abstract base class for aggregate transformers used to test barback.
///
/// This adds the ability to pause and resume different components of the
/// transformers, and to tell whether they're running, when they start running,
/// and how many times they've run.
///
/// Transformers extending this should override [doClassifyPrimary] and
/// [doApply] rather than [classifyPrimary] and [apply], and they should use
/// [getInput] and [getPrimaryInputs] rather than [transform.getInput] and
/// [transform.primaryInputs].
abstract class MockAggregateTransformer extends AggregateTransformer {
  /// The number of times the transformer has been applied.
  ///
  /// This is scheduled. The Future will complete at the point in the schedule
  /// that this is called.
  Future<int> get numRuns => schedule(() => _numRuns);
  var _numRuns = 0;

  /// The number of currently running transforms.
  int _runningTransforms = 0;

  /// A completer for pausing the transformer before it finishes running
  /// [apply].
  Completer _apply;

  /// Completers for pausing the transformer before it finishes running
  /// [classifyPrimary].
  final _classifyPrimary = new Map<AssetId, Completer>();

  /// Completers for pausing the transformer before it finishes getting inputs
  /// the [Transform].
  final _getInput = new Map<AssetId, Completer>();

  /// Completer for pausing the transformer before it accesses
  /// [getPrimaryInputs].
  Completer _primaryInputs;

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

  /// All elements of this set will be automatically consumed during [apply].
  final consumePrimaries = new Set<String>();

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

  /// Causes the transformer to pause after running [classifyPrimary] on the
  /// asset with the given [name], but before the returned Future completes.
  ///
  /// This can be resumed by calling [resumeClassifyPrimary]. This operation is
  /// scheduled.
  void pauseClassifyPrimary(String name) {
    schedule(() {
      _classifyPrimary[new AssetId.parse(name)] = new Completer();
    }, "pause classifyPrimary($name) for $this");
  }

  /// Resumes the transformer's [classifyPrimary] call on the asset with the
  /// given [name] after [pauseClassifyPrimary] was called.
  ///
  /// This operation is scheduled.
  void resumeClassifyPrimary(String name) {
    schedule(() {
      _classifyPrimary.remove(new AssetId.parse(name)).complete();
    }, "resume classifyPrimary($name) for $this");
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

  /// Causes the transformer to pause before accessing [getPrimaryInputs].
  ///
  /// This can be resumed by calling [resumePrimaryInputs]. This operation is
  /// scheduled.
  void pausePrimaryInputs() {
    schedule(() {
      _primaryInputs = new Completer();
    }, "pause primaryInputs for $this");
  }

  /// Resumes the transformer's invocation of [primaryInputs] after
  /// [pausePrimaryInputs] was called.
  ///
  /// This operation is scheduled.
  void resumePrimaryInputs() {
    schedule(() {
      _primaryInputs.complete();
      _primaryInputs = null;
    }, "resume primaryInputs for $this");
  }

  /// Like [AggregateTransform.getInput], but respects [pauseGetInput].
  ///
  /// This is intended for use by subclasses of [MockAggregateTransformer].
  Future<Asset> getInput(AggregateTransform transform, AssetId id) {
    return newFuture(() {
      if (_getInput.containsKey(id)) return _getInput[id].future;
    }).then((_) => transform.getInput(id));
  }

  /// Like [AggregateTransform.primaryInputs], but respects
  /// [pausePrimaryInputs].
  ///
  /// This is intended for use by subclasses of [MockAggregateTransformer].
  Stream<Asset> getPrimaryInputs(AggregateTransform transform) {
    return futureStream(newFuture(() {
      if (_primaryInputs != null) return _primaryInputs.future;
    }).then((_) => transform.primaryInputs));
  }

  Future<String> classifyPrimary(AssetId id) {
    return newFuture(() => doClassifyPrimary(id)).then((result) {
      return newFuture(() {
        if (_classifyPrimary.containsKey(id)) {
          return _classifyPrimary[id].future;
        }
      }).then((_) => result);
    });
  }

  Future apply(AggregateTransform transform) {
    _numRuns++;
    if (_runningTransforms == 0) _started.complete();
    _runningTransforms++;
    return newFuture(() => doApply(transform)).then((_) {
      if (_apply != null) return _apply.future;
    }).whenComplete(() {
      for (var id in consumePrimaries) {
        transform.consumePrimary(new AssetId.parse(id));
      }
      _runningTransforms--;
      if (_runningTransforms == 0) _started = new Completer();
    });
  }

  /// The wrapped version of [classifyPrimary] for subclasses to override.
  ///
  /// This may return a `Future<String>` or, if it's entirely synchronous, a
  /// `String`.
  doClassifyPrimary(AssetId id);

  /// The wrapped version of [doApply] for subclasses to override.
  ///
  /// If this does asynchronous work, it should return a [Future] that completes
  /// once it's finished.
  doApply(AggregateTransform transform);
}
