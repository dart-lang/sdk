// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.transformer_cache;

import 'package:path/path.dart' as p;

import '../io.dart';
import '../log.dart' as log;
import '../package_graph.dart';
import '../sdk.dart' as sdk;
import '../utils.dart';
import 'transformer_id.dart';

/// A cache for managing a snapshot of the first "stage" of transformers to
/// load.
///
/// This uses the [_stageTransformers] notion of a stage. Transformers are
/// divided into stages for loading based on which transformers are needed to
/// load one another. For example, if a transformer T1 produces a file that's
/// imported by another transformer T2, T2 must be put in a stage after T1.
///
/// We only cache the first stage because it's the only stage whose contents are
/// independent of any configuration. Since most transformers don't import the
/// output of other transformers, many packages will only have one stage.
class TransformerCache {
  final PackageGraph _graph;

  /// The set of transformer ids that were previously cached.
  ///
  /// If there was no previous cache, this will be empty.
  Set<TransformerId> _oldTransformers;

  /// The set of transformer ids that are newly cached or re-used from the
  /// previous cache.
  Set<TransformerId> _newTransformers;

  /// The directory in which transformers are cached.
  ///
  /// This may be `null` if there's no physical entrypoint directory.
  String _dir;

  /// The directory of the manifest listing which transformers were cached.
  String get _manifestPath => p.join(_dir, "manifest.txt");

  /// Loads the transformer cache for [environment].
  ///
  /// This may modify the cache.
  TransformerCache.load(PackageGraph graph)
      : _graph = graph,
        _dir = graph.entrypoint.root.path(".pub/transformers") {
    _oldTransformers = _parseManifest();
  }

  /// Clear the cache if it depends on any package in [changedPackages].
  void clearIfOutdated(Set<String> changedPackages) {
    var snapshotDependencies = unionAll(_oldTransformers.map((id) {
      return _graph.transitiveDependencies(id.package)
          .map((package) => package.name).toSet();
    }));

    // If none of the snapshot's dependencies have changed, then we can reuse
    // it.
    if (!overlaps(changedPackages, snapshotDependencies)) return;

    // Otherwise, delete it.
    deleteEntry(_dir);
    _oldTransformers = new Set();
  }

  /// Returns the path for the transformer snapshot for [transformers], or
  /// `null` if the transformers shouldn't be cached.
  ///
  /// There may or may not exist a file at the returned path. If one does exist,
  /// it can safely be used to load the stage. Otherwise, a snapshot of the
  /// stage should be written there.
  String snapshotPath(Set<TransformerId> transformers) {
    var path = p.join(_dir, "transformers.snapshot");
    if (_newTransformers != null) return path;

    if (transformers.any((id) => _graph.isPackageMutable(id.package))) {
      log.fine("Not caching mutable transformers.");
      deleteEntry(_dir);
      return null;
    }

    if (!_oldTransformers.containsAll(transformers)) {
      log.fine("Cached transformer snapshot is out-of-date, deleting.");
      deleteEntry(path);
    } else {
      log.fine("Using cached transformer snapshot.");
    }

    _newTransformers = transformers;
    return path;
  }

  /// Saves the manifest to the transformer cache.
  void save() {
    // If we didn't write any snapshots, there's no need to write a manifest.
    if (_newTransformers == null) {
      if (_dir != null) deleteEntry(_dir);
      return;
    }

    // We only need to rewrite the manifest if we created a new snapshot.
    if (_oldTransformers.containsAll(_newTransformers)) return;

    ensureDir(_dir);
    writeTextFile(_manifestPath,
        "${sdk.version}\n" +
        ordered(_newTransformers.map((id) => id.serialize())).join(","));
  }

  /// Parses the cache manifest and returns the set of previously-cached
  /// transformers.
  ///
  /// If the manifest indicates that the SDK version is out-of-date, this
  /// deletes the existing cache. Otherwise, 
  Set<TransformerId> _parseManifest() {
    if (!fileExists(_manifestPath)) return new Set();

    var manifest = readTextFile(_manifestPath).split("\n");

    // The first line of the manifest is the SDK version. We want to clear out
    // the snapshots even if they're VM-compatible, since pub's transformer
    // isolate scaffolding may have changed.
    if (manifest.removeAt(0) != sdk.version.toString()) {
      deleteEntry(_dir);
      return new Set();
    }

    /// The second line of the manifest is a list of transformer ids used to
    /// create the existing snapshot.
    return manifest.single.split(",")
        .map((id) => new TransformerId.parse(id, null))
        .toSet();
  }
}
