// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Definitions used to run the polymer linter and deploy tools without using
 * pub serve or pub deploy.
 */
library polymer.src.barback_runner;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:yaml/yaml.dart';


/** Collects different parameters needed to configure and run barback. */
class BarbackOptions {
  /** Phases of transformers to run. */
  final List<List<Transformer>> phases;

  /** Package to treat as the current package in barback. */
  final String currentPackage;

  /**
   * Mapping between package names and the path in the file system where
   * to find the sources of such package.
   */
  final Map<String, String> packageDirs;

  /** Whether to run transformers on the test folder. */
  final bool transformTests;

  /** Whether to apply transformers on polymer dependencies. */
  final bool transformPolymerDependencies;

  /** Directory where to generate code, if any. */
  final String outDir;

  BarbackOptions(this.phases, this.outDir, {currentPackage, packageDirs,
      this.transformTests: false, this.transformPolymerDependencies: false})
      : currentPackage = (currentPackage != null
          ? currentPackage : readCurrentPackageFromPubspec()),
        packageDirs = (packageDirs != null
          ? packageDirs : _readPackageDirsFromPub(currentPackage));

}

/**
 * Creates a barback system as specified by [options] and runs it.  Returns a
 * future that contains the list of assets generated after barback runs to
 * completion.
 */
Future<AssetSet> runBarback(BarbackOptions options) {
  var barback = new Barback(new _PolymerPackageProvider(options.packageDirs));
  _initBarback(barback, options);
  _attachListeners(barback);
  if (options.outDir == null) return barback.getAllAssets();
  return _emitAllFiles(barback, options);
}

/** Extract the current package from the pubspec.yaml file. */
String readCurrentPackageFromPubspec() {
  var pubspec = new File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('error: pubspec.yaml file not found, please run this script from '
        'your package root directory.');
    return null;
  }
  return loadYaml(pubspec.readAsStringSync())['name'];
}

/**
 * Extract a mapping between package names and the path in the file system where
 * to find the sources of such package. This map will contain an entry for the
 * current package and everything it depends on (extracted via `pub
 * list-pacakge-dirs`).
 */
Map<String, String> _readPackageDirsFromPub(String currentPackage) {
  var dartExec = new Options().executable;
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
  map.forEach((k, v) { map[k] = path.dirname(v); });
  map[currentPackage] = '.';
  return map;
}

/** Internal packages used by polymer. */
// TODO(sigmund): consider computing this list by recursively parsing
// pubspec.yaml files in the `Options.packageDirs`.
final Set<String> _polymerPackageDependencies = [
    'analyzer_experimental', 'args', 'barback', 'browser', 'csslib',
    'custom_element', 'fancy_syntax', 'html5lib', 'html_import', 'js',
    'logging', 'mdv', 'meta', 'mutation_observer', 'observe', 'path', 'polymer',
    'polymer_expressions', 'serialization', 'shadow_dom', 'source_maps',
    'stack_trace', 'unittest', 'unmodifiable_collection', 'yaml'].toSet();

/** Return the relative path of each file under [subDir] in [package]. */
Iterable<String> _listPackageDir(String package, String subDir,
    BarbackOptions options) {
  var packageDir = options.packageDirs[package];
  if (packageDir == null) return const [];
  var dir = new Directory(path.join(packageDir, subDir));
  if (!dir.existsSync()) return const [];
  return dir.listSync(recursive: true, followLinks: false)
      .where((f) => f is File)
      .map((f) => path.relative(f.path, from: packageDir));
}

/** A simple provider that reads files directly from the pub cache. */
class _PolymerPackageProvider implements PackageProvider {
  Map<String, String> packageDirs;
  Iterable<String> get packages => packageDirs.keys;

  _PolymerPackageProvider(this.packageDirs);

  Future<Asset> getAsset(AssetId id) => new Future.value(
      new Asset.fromPath(id, path.join(packageDirs[id.package],
      // Assets always use the posix style paths
      path.joinAll(path.posix.split(id.path)))));
}

/** Tell barback which transformers to use and which assets to process. */
void _initBarback(Barback barback, BarbackOptions options) {
  var assets = [];
  void addAssets(String package, String subDir) {
    for (var filepath in _listPackageDir(package, subDir, options)) {
      assets.add(new AssetId(package, filepath));
    }
  }

  for (var package in options.packageDirs.keys) {
    // There is nothing to do in the 'polymer' package and its dependencies.
    if (!options.transformPolymerDependencies &&
        _polymerPackageDependencies.contains(package)) continue;
    barback.updateTransformers(package, options.phases);

    // Notify barback to process anything under 'lib' and 'asset'.
    addAssets(package, 'lib');
    addAssets(package, 'asset');
  }

  // In case of the current package, include also 'web'.
  addAssets(options.currentPackage, 'web');
  if (options.transformTests) addAssets(options.currentPackage, 'test');

  barback.updateSources(assets);
}

/** Attach error listeners on [barback] so we can report errors. */
void _attachListeners(Barback barback) {
  // Listen for errors and results
  barback.errors.listen((e) {
    var trace = getAttachedStackTrace(e);
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
}

/**
 * Emits all outputs of [barback] and copies files that we didn't process (like
 * polymer's libraries).
 */
Future _emitAllFiles(Barback barback, BarbackOptions options) {
  return _emitFiles(barback, options, 'web').then((res) {
    if (options.transformTests) return _emitFiles(barback, options, 'test');
    return res;
  });
}

Future _emitFiles(Barback barback, BarbackOptions options, String emitSubDir) {
  return barback.getAllAssets().then((assets) {
    // Copy all the assets we transformed
    var futures = [];
    for (var asset in assets) {
      var id = asset.id;
      var filepath;
      if (id.package == options.currentPackage &&
          id.path.startsWith('$emitSubDir/')) {
        filepath = path.join(options.outDir, id.path);
      } else if (id.path.startsWith('lib/')) {
        filepath = path.join(options.outDir, emitSubDir, 'packages', id.package,
            id.path.substring(4));
      } else {
        // TODO(sigmund): do something about other assets?
        continue;
      }

      _ensureDir(path.dirname(filepath));
      var writer = new File(filepath).openWrite();
      futures.add(writer.addStream(asset.read()).then((_) => writer.close()));
    }
    return Future.wait(futures).then((_) {
      // Copy also all the files we didn't process
      var futures = [];
      for (var package in _polymerPackageDependencies) {
        for (var relpath in _listPackageDir(package, 'lib', options)) {
          var inpath = path.join(options.packageDirs[package], relpath);
          var outpath = path.join(options.outDir, emitSubDir,
              'packages', package, relpath.substring(4));
          _ensureDir(path.dirname(outpath));

          var writer = new File(outpath).openWrite();
          futures.add(writer.addStream(new File(inpath).openRead())
            .then((_) => writer.close()));
        }
      }
      return Future.wait(futures);
    }).then((_) => assets);
  });
}

/** Ensure [dirpath] exists. */
void _ensureDir(var dirpath) {
  new Directory(dirpath).createSync(recursive: true);
}
