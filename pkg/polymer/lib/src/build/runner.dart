// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Definitions used to run the polymer linter and deploy tools without using
/// pub serve or pub deploy.
library polymer.src.build.runner;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:yaml/yaml.dart';


/// Collects different parameters needed to configure and run barback.
class BarbackOptions {
  /// Phases of transformers to run for the current package.
  /// Use packagePhases to specify phases for other packages.
  final List<List<Transformer>> phases;

  /// Package to treat as the current package in barback.
  final String currentPackage;

  /// Directory root for the current package.
  final String packageHome;

  /// Mapping between package names and the path in the file system where
  /// to find the sources of such package.
  final Map<String, String> packageDirs;

  /// Whether to run transformers on the test folder.
  final bool transformTests;

  /// Directory where to generate code, if any.
  final String outDir;

  /// Disregard files that match these filters when copying in non
  /// transformed files
  List<String> fileFilter;

  /// Whether to print error messages using a json-format that tools, such as
  /// the Dart Editor, can process.
  final bool machineFormat;

  /// Whether to follow symlinks when listing directories. By default this is
  /// false because directories have symlinks for the packages directory created
  /// by pub, but it can be turned on for custom uses of this library.
  final bool followLinks;

  /// Phases of transformers to apply to packages other than the current
  /// package, keyed by the package name.
  final Map<String, List<List<Transformer>>> packagePhases;

  BarbackOptions(this.phases, this.outDir, {currentPackage, String packageHome,
      packageDirs, this.transformTests: false, this.machineFormat: false,
      this.followLinks: false,
      this.packagePhases: const {},
      this.fileFilter: const []})
      : currentPackage = (currentPackage != null
          ? currentPackage : readCurrentPackageFromPubspec()),
        packageHome = packageHome,
        packageDirs = (packageDirs != null
          ? packageDirs : readPackageDirsFromPub(packageHome, currentPackage));

}

/// Creates a barback system as specified by [options] and runs it.  Returns a
/// future that contains the list of assets generated after barback runs to
/// completion.
Future<AssetSet> runBarback(BarbackOptions options) {
  var barback = new Barback(new _PackageProvider(options.packageDirs));
  _initBarback(barback, options);
  _attachListeners(barback, options);
  if (options.outDir == null) return barback.getAllAssets();
  return _emitAllFiles(barback, options);
}

/// Extract the current package from the pubspec.yaml file.
String readCurrentPackageFromPubspec([String dir]) {
  var pubspec = new File(
      dir == null ? 'pubspec.yaml' : path.join(dir, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    print('error: pubspec.yaml file not found, please run this script from '
        'your package root directory.');
    return null;
  }
  return loadYaml(pubspec.readAsStringSync())['name'];
}

/// Extract a mapping between package names and the path in the file system
/// which has the source of the package. This map will contain an entry for the
/// current package and everything it depends on (extracted via `pub
/// list-package-dirs`).
Map<String, String> readPackageDirsFromPub(
    [String packageHome, String currentPackage]) {
  var cachedDir = Directory.current;
  if (packageHome != null) {
    Directory.current = new Directory(packageHome);
  } else {
    packageHome = cachedDir.path;
  }

  var dartExec = Platform.executable;
  // If dartExec == dart, then dart and pub are in standard PATH.
  var sdkDir = dartExec == 'dart' ? '' : path.dirname(dartExec);
  var pub = path.join(sdkDir, Platform.isWindows ? 'pub.bat' : 'pub');
  var result = Process.runSync(pub, ['list-package-dirs']);
  if (result.exitCode != 0) {
    print("unexpected error invoking 'pub':");
    print(result.stdout);
    print(result.stderr);
    exit(result.exitCode);
  }
  var map = JSON.decode(result.stdout)["packages"];
  map.forEach((k, v) { map[k] = path.absolute(packageHome, path.dirname(v)); });

  if (currentPackage == null) {
    currentPackage = readCurrentPackageFromPubspec(packageHome);
  }
  map[currentPackage] = packageHome;

  Directory.current = cachedDir;
  return map;
}

bool shouldSkip(List<String> filters, String path) {
  return filters.any((filter) => path.contains(filter));
}

/// Return the relative path of each file under [subDir] in [package].
Iterable<String> _listPackageDir(String package, String subDir,
    BarbackOptions options) {
  var packageDir = options.packageDirs[package];
  if (packageDir == null) return const [];
  var dir = new Directory(path.join(packageDir, subDir));
  if (!dir.existsSync()) return const [];
  return dir.listSync(recursive: true, followLinks: options.followLinks)
      .where((f) => f is File)
      .where((f) => !shouldSkip(options.fileFilter, f.path))
      .map((f) => path.relative(f.path, from: packageDir));
}

/// A simple provider that reads files directly from the pub cache.
class _PackageProvider implements PackageProvider {
  Map<String, String> packageDirs;
  Iterable<String> get packages => packageDirs.keys;

  _PackageProvider(this.packageDirs);

  Future<Asset> getAsset(AssetId id) => new Future.value(
      new Asset.fromPath(id, path.join(packageDirs[id.package],
      _toSystemPath(id.path))));
}

/// Convert asset paths to system paths (Assets always use the posix style).
String _toSystemPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.joinAll(path.posix.split(assetPath));
}

/// Tell barback which transformers to use and which assets to process.
void _initBarback(Barback barback, BarbackOptions options) {
  var assets = [];
  void addAssets(String package, String subDir) {
    for (var filepath in _listPackageDir(package, subDir, options)) {
      assets.add(new AssetId(package, filepath));
    }
  }

  for (var package in options.packageDirs.keys) {
    // Notify barback to process anything under 'lib' and 'asset'.
    addAssets(package, 'lib');
    addAssets(package, 'asset');

    if (options.packagePhases.containsKey(package)) {
      barback.updateTransformers(package, options.packagePhases[package]);
    }
  }
  barback.updateTransformers(options.currentPackage, options.phases);

  // In case of the current package, include also 'web'.
  addAssets(options.currentPackage, 'web');
  if (options.transformTests) addAssets(options.currentPackage, 'test');

  // Add the sources after the transformers so all transformers are present
  // when barback starts processing the assets.
  barback.updateSources(assets);
}

/// Attach error listeners on [barback] so we can report errors.
void _attachListeners(Barback barback, BarbackOptions options) {
  // Listen for errors and results
  barback.errors.listen((e) {
    var trace = null;
    if (e is Error) trace = e.stackTrace;
    if (trace != null) {
      print(Trace.format(trace));
    }
    print('error running barback: $e');
    exit(1);
  });

  barback.results.listen((result) {
    if (!result.succeeded) {
      print("build failed with errors: ${result.errors}");
      exit(1);
    }
  });

  barback.log.listen((entry) {
    if (options.machineFormat) {
      print(_jsonFormatter(entry));
    } else {
      print(_consoleFormatter(entry));
    }
  });
}

/// Emits all outputs of [barback] and copies files that we didn't process (like
/// dependent package's libraries).
Future _emitAllFiles(Barback barback, BarbackOptions options) {
  return barback.getAllAssets().then((assets) {
    // Delete existing output folder before we generate anything
    var dir = new Directory(options.outDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    return _emitPackagesDir(options)
      .then((_) => _emitTransformedFiles(assets, options))
      .then((_) => _addPackagesSymlinks(assets, options))
      .then((_) => assets);
  });
}

Future _emitTransformedFiles(AssetSet assets, BarbackOptions options) {
  // Copy all the assets we transformed
  var futures = [];
  var currentPackage = options.currentPackage;
  var transformTests = options.transformTests;
  var outPackages = path.join(options.outDir, 'packages');

  return Future.forEach(assets, (asset) {
    var id = asset.id;
    var dir = _firstDir(id.path);
    if (dir == null) return null;

    var filepath;
    if (dir == 'lib') {
      // Put lib files directly under the packages folder (e.g. 'lib/foo.dart'
      // will be emitted at out/packages/package_name/foo.dart).
      filepath = path.join(outPackages, id.package,
          _toSystemPath(id.path.substring(4)));
    } else if (id.package == currentPackage &&
        (dir == 'web' || (transformTests && dir == 'test'))) {
      filepath = path.join(options.outDir, _toSystemPath(id.path));
    } else {
      // TODO(sigmund): do something about other assets?
      return null;
    }

    return _writeAsset(filepath, asset);
  });
}

/// Adds a package symlink from each directory under `out/web/foo/` to
/// `out/packages`.
void _addPackagesSymlinks(AssetSet assets, BarbackOptions options) {
  var outPackages = path.join(options.outDir, 'packages');
  var currentPackage = options.currentPackage;
  for (var asset in assets) {
    var id = asset.id;
    if (id.package != currentPackage) continue;
    var firstDir = _firstDir(id.path);
    if (firstDir == null) continue;

    if (firstDir == 'web' || (options.transformTests && firstDir == 'test')) {
      var dir = path.join(options.outDir, path.dirname(_toSystemPath(id.path)));
      var linkPath = path.join(dir, 'packages');
      var link = new Link(linkPath);
      if (!link.existsSync()) {
        var targetPath = Platform.operatingSystem == 'windows'
            ? path.normalize(path.absolute(outPackages))
            : path.normalize(path.relative(outPackages, from: dir));
        link.createSync(targetPath);
      }
    }
  }
}

/// Emits a 'packages' directory directly under `out/packages` with the contents
/// of every file that was not transformed by barback.
Future _emitPackagesDir(BarbackOptions options) {
  var outPackages = path.join(options.outDir, 'packages');
  _ensureDir(outPackages);

  // Copy all the files we didn't process
  var dirs = options.packageDirs;
  return Future.forEach(dirs.keys, (package) {
    return Future.forEach(_listPackageDir(package, 'lib', options), (relpath) {
      var inpath = path.join(dirs[package], relpath);
      var outpath = path.join(outPackages, package, relpath.substring(4));
      return _copyFile(inpath, outpath);
    });
  });
}

/// Ensure [dirpath] exists.
void _ensureDir(String dirpath) {
  new Directory(dirpath).createSync(recursive: true);
}

/// Returns the first directory name on a url-style path, or null if there are
/// no slashes.
String _firstDir(String url) {
  var firstSlash = url.indexOf('/');
  if (firstSlash == -1) return null;
  return url.substring(0, firstSlash);
}

/// Copy a file from [inpath] to [outpath].
Future _copyFile(String inpath, String outpath) {
  _ensureDir(path.dirname(outpath));
  return new File(inpath).openRead().pipe(new File(outpath).openWrite());
}

/// Write contents of an [asset] into a file at [filepath].
Future _writeAsset(String filepath, Asset asset) {
  _ensureDir(path.dirname(filepath));
  return asset.read().pipe(new File(filepath).openWrite());
}

String _kindFromEntry(LogEntry entry) {
  var level = entry.level;
  return level == LogLevel.ERROR ? 'error'
      : (level == LogLevel.WARNING ? 'warning' : 'info');
}

/// Formatter that generates messages using a format that can be parsed
/// by tools, such as the Dart Editor, for reporting error messages.
String _jsonFormatter(LogEntry entry) {
  var kind = _kindFromEntry(entry);
  var span = entry.span;
  return JSON.encode((span == null)
      ? [{'method': kind, 'params': {'message': entry.message}}]
      : [{'method': kind,
          'params': {
            'file': span.sourceUrl.toString(),
            'message': entry.message,
            'line': span.start.line + 1,
            'charStart': span.start.offset,
            'charEnd': span.end.offset,
          }}]);
}

/// Formatter that generates messages that are easy to read on the console (used
/// by default).
String _consoleFormatter(LogEntry entry) {
  var kind = _kindFromEntry(entry);
  var useColors = stdioType(stdout) == StdioType.TERMINAL;
  var levelColor = (kind == 'error') ? _RED_COLOR : _MAGENTA_COLOR;
  var output = new StringBuffer();
  if (useColors) output.write(levelColor);
  output..write(kind)..write(' ');
  if (useColors) output.write(_NO_COLOR);
  if (entry.span == null) {
    output.write(entry.message);
  } else {
    output.write(entry.span.message(entry.message,
          color: useColors ? levelColor : null));
  }
  return output.toString();
}

const String _RED_COLOR = '\u001b[31m';
const String _MAGENTA_COLOR = '\u001b[35m';
const String _NO_COLOR = '\u001b[0m';
