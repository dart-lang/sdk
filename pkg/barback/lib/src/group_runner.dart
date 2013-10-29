// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.group_runner;

import 'dart:async';

import 'asset_cascade.dart';
import 'asset_node.dart';
import 'log.dart';
import 'phase.dart';
import 'stream_pool.dart';
import 'transformer_group.dart';

/// A class that process all of the phases in a single transformer group.
///
/// A group takes many inputs, processes them, and emits many outputs.
class GroupRunner {
  /// The phases defined by this group.
  final _phases = new List<Phase>();

  /// A stream that emits an event whenever this group becomes dirty and needs
  /// to be run.
  ///
  /// This may emit events when the group was already dirty or while processing
  /// transforms. Events are emitted synchronously to ensure that the dirty
  /// state is thoroughly propagated as soon as any assets are changed.
  Stream get onDirty => _onDirtyPool.stream;
  final _onDirtyPool = new StreamPool.broadcast();

  /// Whether this group is dirty and needs to be run.
  bool get isDirty => _phases.any((phase) => phase.isDirty);

  /// A stream that emits an event whenever any transforms in this group logs
  /// an entry.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  // TODO(nweiz): move to a more push-based way of propagating outputs and get
  // rid of this. Once that's done, see if we can unify GroupRunner and
  // AssetCascade.
  /// The set of outputs that has been returned by [process].
  ///
  /// [process] is expected to only return new outputs, so this is used to
  /// ensure that it does so.
  final _alreadyEmittedOutputs = new Set<AssetNode>();

  GroupRunner(AssetCascade cascade, TransformerGroup group) {
    var lastPhase = new Phase(cascade, group.phases.first);
    _phases.add(lastPhase);
    for (var phase in group.phases.skip(1)) {
      lastPhase = lastPhase.addPhase(phase);
      _phases.add(lastPhase);
    }

    for (var phase in _phases) {
      _onDirtyPool.add(phase.onDirty);
      _onLogPool.add(phase.onLog);
    }
  }

  /// Adds a new asset as an input for this group.
  void addInput(AssetNode node) {
    _phases.first.addInput(node);
  }

  /// Removes this group and all sub-phases within it.
  void remove() {
    _phases.first.remove();
  }

  /// Processes this group.
  ///
  /// Returns a future that completes with any new outputs produced by the
  /// group.
  Future<Set<AssetNode>> process() {
    // Process the first phase that needs to do work.
    for (var phase in _phases) {
      var future = phase.process();
      if (future != null) return future.then((_) => process());
    }

    // If we get here, all phases are done processing.
    var newOutputs = _phases.last.availableOutputs
        .difference(_alreadyEmittedOutputs);
    for (var output in newOutputs) {
      output.whenRemoved(() => _alreadyEmittedOutputs.remove(output));
    }
    _alreadyEmittedOutputs.addAll(newOutputs);

    return new Future.value(newOutputs);
  }
}
