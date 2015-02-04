// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.version_queue;

import 'dart:async';
import 'dart:collection' show Queue;

import '../package.dart';

/// A function that asynchronously returns a sequence of package IDs.
typedef Future<Iterable<PackageId>> PackageIdGenerator();

/// A prioritized, asynchronous queue of the possible versions that can be
/// selected for one package.
///
/// If there is a locked version, that comes first, followed by other versions
/// in descending order. This avoids requesting the list of versions until
/// needed (i.e. after any locked version has been consumed) to avoid unneeded
/// network requests.
class VersionQueue {
  /// The set of allowed versions that match [_constraint].
  ///
  /// If [_locked] is not `null`, this will initially be `null` until we
  /// advance past the locked version.
  Queue<PackageId> _allowed;

  /// The callback that will generate the sequence of packages. This will be
  /// called as lazily as possible.
  final PackageIdGenerator _allowedGenerator;

  /// The currently locked version of the package, or `null` if there is none,
  /// or we have advanced past it.
  PackageId _locked;

  /// Gets the currently selected version.
  PackageId get current {
    if (_locked != null) return _locked;
    return _allowed.first;
  }

  /// Whether the currently selected version has been responsible for a solve
  /// failure, or depends on a package that has.
  ///
  /// The solver uses this to determine which packages to backtrack to after a
  /// failure occurs. Any selected package that did *not* cause the failure can
  /// be skipped by the backtracker.
  bool get hasFailed => _hasFailed;
  bool _hasFailed = false;

  /// Creates a new [VersionQueue] queue for starting with the optional
  /// [locked] package followed by the results of calling [allowedGenerator].
  ///
  /// This is asynchronous so that [current] can always be accessed
  /// synchronously. If there is no locked version, we need to get the list of
  /// versions asynchronously before we can determine what the first one is.
  static Future<VersionQueue> create(PackageId locked,
      PackageIdGenerator allowedGenerator) {
    var versions = new VersionQueue._(locked, allowedGenerator);

    // If there is a locked version, it's the current one so it's synchronously
    // available now.
    if (locked != null) return new Future.value(versions);

    // Otherwise, the current version needs to be calculated before we can
    // return.
    return versions._calculateAllowed().then((_) => versions);
  }

  VersionQueue._(this._locked, this._allowedGenerator);

  /// Tries to advance to the next possible version.
  ///
  /// Returns `true` if it moved to a new version (which can be accessed from
  /// [current]. Returns `false` if there are no more versions.
  Future<bool> advance() {
    // Any failure was the fault of the previous version, not necessarily the
    // new one.
    _hasFailed = false;

    // If we have a locked version, consume it first.
    if (_locked != null) {
      // Advancing past the locked version, so need to load the others now
      // so that [current] is available.
      return _calculateAllowed().then((_) {
        _locked = null;
        return _allowed.isNotEmpty;
      });
    }

    // Move to the next allowed version.
    _allowed.removeFirst();
    return new Future.value(_allowed.isNotEmpty);
  }

  /// Marks the selected version as being directly or indirectly responsible
  /// for a solve failure.
  void fail() {
    _hasFailed = true;
  }

  /// Determines the list of allowed versions matching its constraint and places
  /// them in [_allowed].
  Future _calculateAllowed() {
    return _allowedGenerator().then((allowed) {
      _allowed = new Queue<PackageId>.from(allowed);
    });
  }
}
