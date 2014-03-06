// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.package_graph;

import 'dart:async';
import 'dart:collection';

import 'asset_cascade.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'build_result.dart';
import 'errors.dart';
import 'log.dart';
import 'package_provider.dart';
import 'transformer.dart';
import 'utils.dart';

/// The collection of [AssetCascade]s for an entire application.
///
/// This tracks each package's [AssetCascade] and routes asset requests between
/// them.
class PackageGraph {
  /// The provider that exposes asset and package information.
  final PackageProvider provider;

  /// The [AssetCascade] for each package.
  final _cascades = <String, AssetCascade>{};

  /// A stream that emits a [BuildResult] each time the build is completed,
  /// whether or not it succeeded.
  ///
  /// This will emit a result only once every package's [AssetCascade] has
  /// finished building.
  ///
  /// If an unexpected error in barback itself occurs, it will be emitted
  /// through this stream's error channel.
  Stream<BuildResult> get results => _resultsController.stream;
  final _resultsController =
      new StreamController<BuildResult>.broadcast(sync: true);

  /// A stream that emits any errors from the graph or the transformers.
  ///
  /// This emits errors as they're detected. If an error occurs in one part of
  /// the graph, unrelated parts will continue building.
  ///
  /// This will not emit programming errors from barback itself. Those will be
  /// emitted through the [results] stream's error channel.
  Stream<BarbackException> get errors => _errors;
  Stream<BarbackException> _errors;

  /// The stream of [LogEntry] objects used to report transformer log entries.
  Stream<LogEntry> get log => _logController.stream;
  final _logController = new StreamController<LogEntry>.broadcast(sync: true);

  /// Whether [this] is dirty and still has more processing to do.
  bool get _isDirty => _cascades.values.any((cascade) => cascade.isDirty);

  /// Whether a [BuildResult] is scheduled to be emitted on [results] (see
  /// [_tryScheduleResult]).
  bool _resultScheduled = false;

  /// The most recent [BuildResult] emitted on [results].
  BuildResult _lastResult;

  // TODO(nweiz): This can have bogus errors if an error is created and resolved
  // in the space of one build.
  /// The errors that have occurred since the current build started.
  ///
  /// This will be empty if no build is occurring.
  final _accumulatedErrors = new Queue<BarbackException>();

  /// The most recent error emitted from a cascade's result stream.
  ///
  /// This is used to pipe an unexpected error from a build to the resulting
  /// [Future] returned by [getAllAssets].
  var _lastUnexpectedError;

  /// The stack trace for [_lastUnexpectedError].
  StackTrace _lastUnexpectedErrorTrace;

  /// Creates a new [PackageGraph] that will transform assets in all packages
  /// made available by [provider].
  PackageGraph(this.provider) {
    _inErrorZone(() {
      for (var package in provider.packages) {
        var cascade = new AssetCascade(this, package);
        _cascades[package] = cascade;
        cascade.onLog.listen(_onLog);
        cascade.onDone.listen((_) => _tryScheduleResult());
      }

      _errors = mergeStreams(_cascades.values.map((cascade) => cascade.errors),
          broadcast: true);
      _errors.listen(_accumulatedErrors.add);
    });
  }

  /// Gets the asset node identified by [id].
  ///
  /// If [id] is for a generated or transformed asset, this will wait until it
  /// has been created and return it. This means that the returned asset will
  /// always be [AssetState.AVAILABLE].
  ///
  /// If the asset cannot be found, returns null.
  Future<AssetNode> getAssetNode(AssetId id) {
    return _inErrorZone(() {
      var cascade = _cascades[id.package];
      if (cascade != null) return cascade.getAssetNode(id);
      return new Future.value(null);
    });
  }

  /// Gets all output assets.
  ///
  /// If a build is currently in progress, waits until it completes. The
  /// returned future will complete with an error if the build is not
  /// successful.
  ///
  /// Any transforms using [LazyTransformer]s will be forced to generate
  /// concrete outputs, and those outputs will be returned.
  Future<AssetSet> getAllAssets() {
    for (var cascade in _cascades.values) {
      _inErrorZone(() => cascade.forceAllTransforms());
    }

    if (_isDirty) {
      // A build is still ongoing, so wait for it to complete and try again.
      return results.first.then((_) => getAllAssets());
    }

    // If an unexpected error occurred, complete with that.
    if (_lastUnexpectedError != null) {
      var error = _lastUnexpectedError;
      _lastUnexpectedError = null;
      return new Future.error(error, _lastUnexpectedErrorTrace);
    }

    // If the last build completed with an error, complete the future with it.
    if (!_lastResult.succeeded) {
      return new Future.error(BarbackException.aggregate(_lastResult.errors));
    }

    // Otherwise, return all of the final output assets.
    var assets = unionAll(_cascades.values.map(
        (cascade) => cascade.availableOutputs.toSet()));

    return new Future.value(new AssetSet.from(assets));
  }

  /// Adds [sources] to the graph's known set of source assets.
  ///
  /// Begins applying any transforms that can consume any of the sources. If a
  /// given source is already known, it is considered modified and all
  /// transforms that use it will be re-applied.
  void updateSources(Iterable<AssetId> sources) {
    groupBy(sources, (id) => id.package).forEach((package, ids) {
      var cascade = _cascades[package];
      if (cascade == null) throw new ArgumentError("Unknown package $package.");
      _inErrorZone(() => cascade.updateSources(ids));
    });

    // It's possible for adding sources not to cause any processing. The user
    // still expects there to be a build, though, so we emit one immediately.
    _tryScheduleResult();
  }

  /// Removes [removed] from the graph's known set of source assets.
  void removeSources(Iterable<AssetId> sources) {
    groupBy(sources, (id) => id.package).forEach((package, ids) {
      var cascade = _cascades[package];
      if (cascade == null) throw new ArgumentError("Unknown package $package.");
      _inErrorZone(() => cascade.removeSources(ids));
    });

    // It's possible for removing sources not to cause any processing. The user
    // still expects there to be a build, though, so we emit one immediately.
    _tryScheduleResult();
  }

  void updateTransformers(String package,
      Iterable<Iterable<Transformer>> transformers) {
    _inErrorZone(() => _cascades[package].updateTransformers(transformers));

    // It's possible for updating transformers not to cause any processing. The
    // user still expects there to be a build, though, so we emit one
    // immediately.
    _tryScheduleResult();
  }

  /// A handler for a log entry from an [AssetCascade].
  void _onLog(LogEntry entry) {
    if (entry.level == LogLevel.ERROR) {
      // TODO(nweiz): keep track of stack chain.
      _accumulatedErrors.add(
          new TransformerException(entry.transform, entry.message, null));
    }

    if (_logController.hasListener) {
      _logController.add(entry);
    } else if (entry.level != LogLevel.FINE) {
      // No listeners, so just print entry.
      var buffer = new StringBuffer();
      buffer.write("[${entry.level} ${entry.transform}] ");

      if (entry.span != null) {
        buffer.write(entry.span.getLocationMessage(entry.message));
      } else {
        buffer.write(entry.message);
      }

      print(buffer);
    }
  }

  /// If [this] is done processing, schedule a [BuildResult] to be emitted on
  /// [results].
  ///
  /// This schedules the result (as opposed to just emitting one directly on
  /// [BuildResult]) to ensure that calling multiple functions synchronously
  /// produces only a single [BuildResult].
  void _tryScheduleResult() {
    if (_isDirty) return;
    if (_resultScheduled) return;

    _resultScheduled = true;
    newFuture(() {
      _resultScheduled = false;
      if (_isDirty) return;

      _lastResult = new BuildResult(_accumulatedErrors);
      _accumulatedErrors.clear();
      _resultsController.add(_lastResult);
    });
  }

  /// Run [body] in an error-handling [Zone] and pipe any unexpected errors to
  /// the error channel of [results].
  ///
  /// [body] can return a value or a [Future] that will be piped to the returned
  /// [Future]. If it throws a [BarbackException], that exception will be piped
  /// to the returned [Future] as well. Any other exceptions will be piped to
  /// [results].
  Future _inErrorZone(body()) {
    var completer = new Completer.sync();
    runZoned(() {
      syncFuture(body).then(completer.complete).catchError((error, stackTrace) {
        if (error is! BarbackException) throw error;
        completer.completeError(error, stackTrace);
      });
    }, onError: (error, stackTrace) {
      _lastUnexpectedError = error;
      _lastUnexpectedErrorTrace = stackTrace;
      _resultsController.addError(error, stackTrace);
    });
    return completer.future;
  }
}
