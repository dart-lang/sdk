// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.solver.solve_report;

import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../source_registry.dart';
import '../utils.dart';
import '../version.dart';
import 'version_solver.dart';

/// Unlike [SolveResult], which is the static data describing a resolution,
/// this class contains the mutable state used while generating the report
/// itself.
///
/// It's a report builder.
class SolveReport {
  final SolveType _type;
  final SourceRegistry _sources;
  final Package _root;
  final LockFile _previousLockFile;
  final SolveResult _result;

  /// The dependencies in [_result], keyed by package name.
  final _dependencies = new Map<String, PackageId>();

  final _output = new StringBuffer();

  SolveReport(this._type, this._sources, this._root, this._previousLockFile,
      this._result) {
    // Fill the map so we can use it later.
    for (var id in _result.packages) {
      _dependencies[id.name] = id;
    }
  }

  /// Displays a report of the results of the version resolution relative to
  /// the previous lock file.
  void show() {
    _reportChanges();
    _reportOverrides();
  }

  /// Displays a one-line message summarizing what changes were made (or would
  /// be made) to the lockfile.
  ///
  /// If [dryRun] is true, describes it in terms of what would be done.
  void summarize({bool dryRun: false}) {
    // Count how many dependencies actually changed.
    var dependencies = _dependencies.keys.toSet();
    dependencies.addAll(_previousLockFile.packages.keys);
    dependencies.remove(_root.name);

    var numChanged = dependencies.where((name) {
      var oldId = _previousLockFile.packages[name];
      var newId = _dependencies[name];

      // Added or removed dependencies count.
      if (oldId == null) return true;
      if (newId == null) return true;

      // The dependency existed before, so see if it was modified.
      return !_descriptionsEqual(oldId, newId) ||
          oldId.version != newId.version;
    }).length;

    if (dryRun) {
      if (numChanged == 0) {
        log.message("No dependencies would change.");
      } else if (numChanged == 1) {
        log.message("Would change $numChanged dependency.");
      } else {
        log.message("Would change $numChanged dependencies.");
      }
    } else {
      if (numChanged == 0) {
        if (_type == SolveType.GET) {
          log.message("Got dependencies!");
        } else {
          log.message("No dependencies changed.");
        }
      } else if (numChanged == 1) {
        log.message("Changed $numChanged dependency!");
      } else {
        log.message("Changed $numChanged dependencies!");
      }
    }
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
      removed.forEach((name) => _reportPackage(name, alwaysShow: true));
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
          (name) => _reportPackage(name, alwaysShow: true,
              highlightOverride: false));

      log.warning(_output);
    }
  }

  /// Reports the results of the upgrade on the package named [name].
  ///
  /// If [alwaysShow] is true, the package is reported even if it didn't change,
  /// regardless of [_type]. If [highlightOverride] is true (or absent), writes
  /// "(override)" next to overridden packages.
  void _reportPackage(String name,
      {bool alwaysShow: false, bool highlightOverride: true}) {
    var newId = _dependencies[name];
    var oldId = _previousLockFile.packages[name];
    var id = newId != null ? newId : oldId;

    var isOverridden = _result.overrides.map(
        (dep) => dep.name).contains(id.name);

    // If the package was previously a dependency but the dependency has
    // changed in some way.
    var changed = false;

    // If the dependency was added or removed.
    var addedOrRemoved = false;

    // Show a one-character "icon" describing the change. They are:
    //
    //     ! The package is being overridden.
    //     - The package was removed.
    //     + The package was added.
    //     > The package was upgraded from a lower version.
    //     < The package was downgraded from a higher version.
    //     * Any other change between the old and new package.
    var icon;
    if (isOverridden) {
      icon = log.magenta("! ");
    } else if (newId == null) {
      icon = log.red("- ");
      addedOrRemoved = true;
    } else if (oldId == null) {
      icon = log.green("+ ");
      addedOrRemoved = true;
    } else if (!_descriptionsEqual(oldId, newId)) {
      icon = log.cyan("* ");
      changed = true;
    } else if (oldId.version < newId.version) {
      icon = log.green("> ");
      changed = true;
    } else if (oldId.version > newId.version) {
      icon = log.cyan("< ");
      changed = true;
    } else {
      // Unchanged.
      icon = "  ";
    }

    if (_type == SolveType.GET && !(alwaysShow || changed || addedOrRemoved)) {
      return;
    }

    _output.write(icon);
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
    if (newId != null && _type != SolveType.DOWNGRADE) {
      var versions = _result.availableVersions[newId.name];

      var newerStable = false;
      var newerUnstable = false;

      for (var version in versions) {
        if (version > newId.version) {
          if (version.isPreRelease) {
            newerUnstable = true;
          } else {
            newerStable = true;
          }
        }
      }

      // If there are newer stable versions, only show those.
      var message;
      if (newerStable) {
        message = "(${maxAll(versions, Version.prioritize)} available)";
      } else if (newerUnstable) {
        message = "(${maxAll(versions)} available)";
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