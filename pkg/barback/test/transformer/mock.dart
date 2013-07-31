// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.mock;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';

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
  int get numRuns => _numRuns;
  var _numRuns = 0;

  /// The number of currently running transforms.
  int _runningTransforms = 0;

  // A completer for pausing the transformer before it finishes running [apply].
  Completer _apply;

  // Completers for pausing the transformer before it finishes running
  // [isPrimary].
  final _isPrimary = new Map<AssetId, Completer>();

  // Completers for pausing the transformer before it finishes getting inputs
  // the [Transform].
  final _getInput = new Map<AssetId, Completer>();

  /// A future that completes when this transformer begins running.
  ///
  /// Once this transformer finishes running, this is reset to a new completer,
  /// so it can be used multiple times.
  Future get started => _started.future;
  var _started = new Completer();

  /// `true` if any transforms are currently running.
  bool get isRunning => _runningTransforms > 0;

  /// Causes the transformer to pause after running [apply] but before the
  /// returned Future completes.
  ///
  /// This can be resumed by calling [resumeApply].
  void pauseApply() {
    _apply = new Completer();
  }

  /// Resumes the transformer's [apply] call after [pauseApply] was called.
  void resumeApply() {
    _apply.complete();
    _apply = null;
  }

  /// Causes the transformer to pause after running [isPrimary] on the asset
  /// with the given [name], but before the returned Future completes.
  ///
  /// This can be resumed by calling [resumeIsPrimary].
  void pauseIsPrimary(String name) {
    _isPrimary[new AssetId.parse(name)] = new Completer();
  }

  /// Resumes the transformer's [isPrimary] call on the asset with the given
  /// [name] after [pauseIsPrimary] was called.
  void resumeIsPrimary(String name) {
    _isPrimary.remove(new AssetId.parse(name)).complete();
  }

  /// Causes the transformer to pause while loading the input with the given
  /// [name]. This can be the primary input or a secondary input.
  ///
  /// This can be resumed by calling [resumeGetInput].
  void pauseGetInput(String name) {
    _getInput[new AssetId.parse(name)] = new Completer();
  }

  /// Resumes the transformer's loading of the input with the given [name] after
  /// [pauseGetInput] was called.
  void resumeGetInput(String name) {
    _getInput.remove(new AssetId.parse(name)).complete();
  }

  /// Like [Transform.getInput], but respects [pauseGetInput].
  ///
  /// This is intended for use by subclasses of [MockTransformer].
  Future<Asset> getInput(Transform transform, AssetId id) {
    return newFuture(() {
      if (_getInput.containsKey(id)) return _getInput[id].future;
    }).then((_) => transform.getInput(id));
  }

  /// Like [Transform.primaryInput], but respects [pauseGetInput].
  ///
  /// This is intended for use by subclasses of [MockTransformer].
  Future<Asset> getPrimary(Transform transform) =>
      getInput(transform, transform.primaryId);

  Future<bool> isPrimary(Asset asset) {
    return newFuture(() => doIsPrimary(asset)).then((result) {
      return newFuture(() {
        if (_isPrimary.containsKey(asset.id)) {
          return _isPrimary[asset.id].future;
        }
      }).then((_) => result);
    });
  }

  Future apply(Transform transform) {
    _numRuns++;
    if (_runningTransforms == 0) _started.complete();
    _runningTransforms++;
    return newFuture(() => doApply(transform)).then((_) {
      if (_apply != null) return _apply.future;
    }).whenComplete(() {
      _runningTransforms--;
      if (_runningTransforms == 0) _started = new Completer();
    });
  }

  /// The wrapped version of [isPrimary] for subclasses to override.
  Future<bool> doIsPrimary(Asset asset);

  /// The wrapped version of [doApply] for subclasses to override.
  Future doApply(Transform transform);
}
