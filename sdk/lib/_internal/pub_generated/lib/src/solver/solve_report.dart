library pub.solver.solve_report;
import 'package:pub_semver/pub_semver.dart';
import '../lock_file.dart';
import '../log.dart' as log;
import '../package.dart';
import '../source_registry.dart';
import '../utils.dart';
import 'version_solver.dart';
class SolveReport {
  final SolveType _type;
  final SourceRegistry _sources;
  final Package _root;
  final LockFile _previousLockFile;
  final SolveResult _result;
  final _dependencies = new Map<String, PackageId>();
  final _output = new StringBuffer();
  SolveReport(this._type, this._sources, this._root, this._previousLockFile,
      this._result) {
    for (var id in _result.packages) {
      _dependencies[id.name] = id;
    }
  }
  void show() {
    _reportChanges();
    _reportOverrides();
  }
  void summarize({bool dryRun: false}) {
    var dependencies = _dependencies.keys.toSet();
    dependencies.addAll(_previousLockFile.packages.keys);
    dependencies.remove(_root.name);
    var numChanged = dependencies.where((name) {
      var oldId = _previousLockFile.packages[name];
      var newId = _dependencies[name];
      if (oldId == null) return true;
      if (newId == null) return true;
      return !_sources.idsEqual(oldId, newId);
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
  void _reportChanges() {
    _output.clear();
    var names = _result.packages.map((id) => id.name).toList();
    names.remove(_root.name);
    names.sort();
    names.forEach(_reportPackage);
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
  void _reportOverrides() {
    _output.clear();
    if (_result.overrides.isNotEmpty) {
      _output.writeln("Warning: You are using these overridden dependencies:");
      var overrides = _result.overrides.map((dep) => dep.name).toList();
      overrides.sort((a, b) => a.compareTo(b));
      overrides.forEach(
          (name) => _reportPackage(name, alwaysShow: true, highlightOverride: false));
      log.warning(_output);
    }
  }
  void _reportPackage(String name, {bool alwaysShow: false,
      bool highlightOverride: true}) {
    var newId = _dependencies[name];
    var oldId = _previousLockFile.packages[name];
    var id = newId != null ? newId : oldId;
    var isOverridden =
        _result.overrides.map((dep) => dep.name).contains(id.name);
    var changed = false;
    var addedOrRemoved = false;
    var icon;
    if (isOverridden) {
      icon = log.magenta("! ");
    } else if (newId == null) {
      icon = log.red("- ");
      addedOrRemoved = true;
    } else if (oldId == null) {
      icon = log.green("+ ");
      addedOrRemoved = true;
    } else if (!_sources.idDescriptionsEqual(oldId, newId)) {
      icon = log.cyan("* ");
      changed = true;
    } else if (oldId.version < newId.version) {
      icon = log.green("> ");
      changed = true;
    } else if (oldId.version > newId.version) {
      icon = log.cyan("< ");
      changed = true;
    } else {
      icon = "  ";
    }
    if (_type == SolveType.GET && !(alwaysShow || changed || addedOrRemoved)) {
      return;
    }
    _output.write(icon);
    _output.write(log.bold(id.name));
    _output.write(" ");
    _writeId(id);
    if (changed) {
      _output.write(" (was ");
      _writeId(oldId);
      _output.write(")");
    }
    if (isOverridden && highlightOverride) {
      _output.write(" ${log.magenta('(overridden)')}");
    }
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
  void _writeId(PackageId id) {
    _output.write(id.version);
    var source = _sources[id.source];
    if (source != _sources.defaultSource) {
      var description = source.formatDescription(_root.dir, id.description);
      _output.write(" from ${id.source} $description");
    }
  }
}
