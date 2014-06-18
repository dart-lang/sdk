// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.solve_report;

import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../source_registry.dart';
import '../utils.dart';
import 'version_solver.dart';

/// Generates and displays nicely formatted reports for the results of running
/// a version resolution.
///
/// If [showAll] is true, then all of the previous and current dependencies
/// are shown and their changes relative to the previous lock file are
/// highlighted. Otherwise, only overrides are shown.
///
/// Returns the number of changed dependencies.
int show(SourceRegistry sources, Package root, LockFile previousLockFile,
         SolveResult result, {bool showAll: false}) {
  var report = new _SolveReport(sources, root, previousLockFile, result);
  return report.show(showAll: showAll);
}

/// Unlike [SolveResult], which is the static data describing a resolution,
/// this class contains the mutable state used while generating the report
/// itself.
///
/// It's a report builder.
class _SolveReport {
  final SourceRegistry _sources;
  final Package _root;
  final LockFile _previousLockFile;
  final SolveResult _result;

  /// The dependencies in [_result], keyed by package name.
  final _dependencies = new Map<String, PackageId>();

  final _output = new StringBuffer();

  _SolveReport(this._sources, this._root, this._previousLockFile,
      this._result) {
    // Fill the map so we can use it later.
    for (var id in _result.packages) {
      _dependencies[id.name] = id;
    }
  }

  /// Displays a report of the results of the version resolution relative to
  /// the previous lock file.
  ///
  /// If [showAll] is true, then all of the previous and current dependencies
  /// are shown and their changes relative to the previous lock file are
  /// highlighted. Otherwise, only overrides are shown.
  ///
  /// Returns the number of changed dependencies.
  int show({bool showAll: false}) {
    if (showAll) _reportChanges();
    _reportOverrides();

    // Count how many dependencies actually changed.
    var dependencies = _dependencies.keys.toSet();
    dependencies.addAll(_previousLockFile.packages.keys);
    dependencies.remove(_root.name);

    return dependencies.where((name) {
      var oldId = _previousLockFile.packages[name];
      var newId = _dependencies[name];

      // Added or removed dependencies count.
      if (oldId == null) return true;
      if (newId == null) return true;

      // The dependency existed before, so see if it was modified.
      return !_descriptionsEqual(oldId, newId) ||
          oldId.version != newId.version;
    }).length;
  }

  /// Displays a report of all of the previous and current dependencies and
  /// how they have changed.
  void _reportChanges() {
    _output.clear();

    // Show the new set of dependencies ordered by name.
    var names = _result.packages.map((id) => id.name).toList();
    names.remove(_root.name);
    names.sort();
    names.forEach(_reportPackage);

    // Show any removed ones.
    var removed = _previousLockFile.packages.keys.toSet();
    removed.removeAll(names);
    if (removed.isNotEmpty) {
      _output.writeln("These packages are no longer being depended on:");
      removed = removed.toList();
      removed.sort();
      removed.forEach(_reportPackage);
    }

    log.message(_output);
  }

  /// Displays a warning about the overrides currently in effect.
  void _reportOverrides() {
    _output.clear();

    if (_result.overrides.isNotEmpty) {
      _output.writeln("Warning: You are using these overridden dependencies:");
      var overrides = _result.overrides.map((dep) => dep.name).toList();
      overrides.sort((a, b) => a.compareTo(b));

      overrides.forEach(
          (name) => _reportPackage(name, highlightOverride: false));

      log.warning(_output);
    }
  }

  /// Reports the results of the upgrade on the package named [name].
  ///
  /// If [highlightOverride] is true (or absent), writes "(override)" next to
  /// overridden packages.
  void _reportPackage(String name, {bool highlightOverride}) {
    if (highlightOverride == null) highlightOverride = true;

    var newId = _dependencies[name];
    var oldId = _previousLockFile.packages[name];
    var id = newId != null ? newId : oldId;

    var isOverridden = _result.overrides.map(
        (dep) => dep.name).contains(id.name);

    var changed = false;

    // Show a one-character "icon" describing the change. They are:
    //
    //     ! The package is being overridden.
    //     - The package was removed.
    //     + The package was added.
    //     > The package was upgraded from a lower version.
    //     < The package was downgraded from a higher version.
    //     * Any other change between the old and new package.
    if (isOverridden) {
      _output.write(log.magenta("! "));
    } else if (newId == null) {
      _output.write(log.red("- "));
    } else if (oldId == null) {
      _output.write(log.green("+ "));
    } else if (!_descriptionsEqual(oldId, newId)) {
      _output.write(log.cyan("* "));
      changed = true;
    } else if (oldId.version < newId.version) {
      _output.write(log.green("> "));
      changed = true;
    } else if (oldId.version > newId.version) {
      _output.write(log.cyan("< "));
      changed = true;
    } else {
      // Unchanged.
      _output.write("  ");
    }

    _output.write(log.bold(id.name));
    _output.write(" ");
    _writeId(id);

    // If the package was upgraded, show what it was upgraded from.
    if (changed) {
      _output.write(" (was ");
      _writeId(oldId);
      _output.write(")");
    }

    // Highlight overridden packages.
    if (isOverridden && highlightOverride) {
      _output.write(" ${log.magenta('(overridden)')}");
    }

    // See if there are any newer versions of the package that we were
    // unable to upgrade to.
    if (newId != null) {
      var versions = _result.availableVersions[newId.name];
      var newerStable = 0;
      var newerUnstable = 0;

      for (var version in versions) {
        if (version > newId.version) {
          if (version.isPreRelease) {
            newerUnstable++;
          } else {
            newerStable++;
          }
        }
      }

      // If there are newer stable versions, only show those.
      var message;
      if (newerStable > 0) {
        message = "($newerStable newer "
            "${pluralize('version', newerStable)} available)";
      } else if (newerUnstable > 0) {
        message = "($newerUnstable newer unstable "
            "${pluralize('version', newerUnstable)} available)";
      }

      if (message != null) _output.write(" ${log.cyan(message)}");
    }

    _output.writeln();
  }

  /// Returns `true` if [a] and [b] are from the same source and have the same
  /// description.
  bool _descriptionsEqual(PackageId a, PackageId b) {
    if (a.source != b.source) return false;
    return _sources[a.source].descriptionsEqual(a.description, b.description);
  }

  /// Writes a terse description of [id] (not including its name) to the output.
  void _writeId(PackageId id) {
    _output.write(id.version);

    var source = _sources[id.source];
    if (source != _sources.defaultSource) {
      var description = source.formatDescription(_root.dir, id.description);
      _output.write(" from ${id.source} $description");
    }
  }
}