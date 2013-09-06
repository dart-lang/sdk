// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Temporary deploy command used to create a version of the app that can be
 * compiled with dart2js and deployed. Following pub layout conventions, this
 * script will treat any HTML file under a package 'web/' and 'test/'
 * directories as entry points.
 *
 * From an application package you can run deploy by creating a small program
 * as follows:
 *
 *    import "package:polymer/deploy.dart" as deploy;
 *    main() => deploy.main();
 *
 * This library should go away once `pub deploy` can be configured to run
 * barback transformers.
 */
library polymer.deploy;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:polymer/src/transform.dart' show phases;
import 'package:stack_trace/stack_trace.dart';
import 'package:yaml/yaml.dart';
import 'package:args/args.dart';

main() {
  var args = _parseArgs(new Options().arguments);
  if (args == null) return;

  var test = args['test'];
  if (test != null) {
    _initForTest(test);
  }

  print('polymer/deploy.dart: creating a deploy target for "$_currentPackage"');
  var outDir = args['out'];
  _run(outDir, test != null).then(
      (_) => print('Done! All files written to "$outDir"'));
}

// TODO(jmesserly): the current deploy/barback architecture is very unfriendly
// to deploying a single test. We need to fix it somehow but it isn't clear yet.
void _initForTest(String testFile) {
  var testDir = path.normalize(path.dirname(testFile));

  // A test must be allowed to import things in the package.
  // So we must find its package root, given the entry point. We can do this
  // by walking up to find pubspec.yaml.
  var pubspecDir = _findDirWithFile(path.absolute(testDir), 'pubspec.yaml');
  if (pubspecDir == null) {
    print('error: pubspec.yaml file not found, please run this script from '
        'your package root directory or a subdirectory.');
    exit(1);
  }

  _currentPackage = '_test';
  _packageDirs = {'_test' : pubspecDir};
}

String _findDirWithFile(String dir, String filename) {
  while (!new File(path.join(dir, filename)).existsSync()) {
    var parentDir = path.dirname(dir);
    // If we reached root and failed to find it, bail.
    if (parentDir == dir) return null;
    dir = parentDir;
  }
  return dir;
}

/**
 * API exposed for testing purposes. Runs this deploy command but prentend that
 * the sources under [webDir] belong to package 'test'.
 */
Future runForTest(String webDir, String outDir) {
  _currentPackage = 'test';

  // associate package dirs with their location in the repo:
  _packageDirs = {'test' : '.'};
  _addPackages('..');
  _addPackages('../third_party');
  _addPackages('../../third_party/pkg');
  return _run(webDir, outDir);
}

_addPackages(String dir) {
  for (var packageDir in new Directory(dir).listSync().map((d) => d.path)) {
    _packageDirs[path.basename(packageDir)] = packageDir;
  }
}

Future _run(String outDir, bool includeTests) {
  var barback = new Barback(new _PolymerDeployProvider());
  _initializeBarback(barback, includeTests);
  _attachListeners(barback);
  return _emitAllFiles(barback, 'web', outDir).then(
      (_) => includeTests ? _emitAllFiles(barback, 'test', outDir) : null);
}

/** Tell barback which transformers to use and which assets to process. */
void _initializeBarback(Barback barback, bool includeTests) {
  var assets = [];
  void addAssets(String package, String subDir) {
    for (var filepath in _listDir(package, subDir)) {
      assets.add(new AssetId(package, filepath));
    }
  }

  for (var package in _packageDirs.keys) {
    // Do not process packages like 'polymer' where there is nothing to do.
    if (_ignoredPackages.contains(package)) continue;
    barback.updateTransformers(package, phases);

    // notify barback to process anything under 'lib' and 'asset'
    addAssets(package, 'lib');
    addAssets(package, 'asset');
  }

  // In case of the current package, include also 'web'.
  addAssets(_currentPackage, 'web');
  if (includeTests) addAssets(_currentPackage, 'test');

  barback.updateSources(assets);
}

/** Return the relative path of each file under [subDir] in a [package]. */
Iterable<String> _listDir(String package, String subDir) {
  var packageDir = _packageDirs[package];
  if (packageDir == null) return const [];
  var dir = new Directory(path.join(packageDir, subDir));
  if (!dir.existsSync()) return const [];
  return dir.listSync(recursive: true, followLinks: false)
      .where((f) => f is File)
      .map((f) => path.relative(f.path, from: packageDir));
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

/** Ensure [dirpath] exists. */
void _ensureDir(var dirpath) {
  new Directory(dirpath).createSync(recursive: true);
}

/**
 * Emits all outputs of [barback] and copies files that we didn't process (like
 * polymer's libraries).
 */
Future _emitAllFiles(Barback barback, String webDir, String outDir) {
  return barback.getAllAssets().then((assets) {
    // Copy all the assets we transformed
    var futures = [];
    for (var asset in assets) {
      var id = asset.id;
      var filepath;
      if (id.package == _currentPackage && id.path.startsWith('$webDir/')) {
        filepath = path.join(outDir, id.path);
      } else if (id.path.startsWith('lib/')) {
        filepath = path.join(outDir, webDir, 'packages', id.package,
            id.path.substring(4));
      } else {
        // TODO(sigmund): do something about other assets?
        continue;
      }

      _ensureDir(path.dirname(filepath));
      var writer = new File(filepath).openWrite();
      futures.add(writer.addStream(asset.read()).then((_) => writer.close()));
    }
    return Future.wait(futures);
  }).then((_) {
    // Copy also all the files we didn't process
    var futures = [];
    for (var package in _ignoredPackages) {
      for (var relpath in _listDir(package, 'lib')) {
        var inpath = path.join(_packageDirs[package], relpath);
        var outpath = path.join(outDir, webDir, 'packages', package,
            relpath.substring(4));
        _ensureDir(path.dirname(outpath));

        var writer = new File(outpath).openWrite();
        futures.add(writer.addStream(new File(inpath).openRead())
          .then((_) => writer.close()));
      }
    }
    return Future.wait(futures);
  });
}

/** A simple provider that reads files directly from the pub cache. */
class _PolymerDeployProvider implements PackageProvider {

  Iterable<String> get packages => _packageDirs.keys;
  _PolymerDeployProvider();

  Future<Asset> getAsset(AssetId id) =>
      new Future.value(new Asset.fromPath(id, path.join(
              _packageDirs[id.package],
              // Assets always use the posix style paths
              path.joinAll(path.posix.split(id.path)))));
}


/** The current package extracted from the pubspec.yaml file. */
String _currentPackage = () {
  var pubspec = new File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('error: pubspec.yaml file not found, please run this script from '
        'your package root directory.');
    return null;
  }
  return loadYaml(pubspec.readAsStringSync())['name'];
}();

/**
 * Maps package names to the path in the file system where to find the sources
 * of such package. This map will contain an entry for the current package and
 * everything it depends on (extracted via `pub list-pacakge-dirs`).
 */
Map<String, String> _packageDirs = () {
  var pub = path.join(path.dirname(new Options().executable),
      Platform.isWindows ? 'pub.bat' : 'pub');
  var result = Process.runSync(pub, ['list-package-dirs']);
  if (result.exitCode != 0) {
    print("unexpected error invoking 'pub':");
    print(result.stdout);
    print(result.stderr);
    exit(result.exitCode);
  }
  var map = JSON.decode(result.stdout)["packages"];
  map.forEach((k, v) { map[k] = path.dirname(v); });
  map[_currentPackage] = '.';
  return map;
}();

/**
 * Internal packages used by polymer which we can copy directly to the output
 * folder without having to process them with barback.
 */
// TODO(sigmund): consider computing this list by recursively parsing
// pubspec.yaml files in the [_packageDirs].
final Set<String> _ignoredPackages =
    (const [ 'analyzer_experimental', 'args', 'barback', 'browser', 'csslib',
             'custom_element', 'fancy_syntax', 'html5lib', 'html_import', 'js',
             'logging', 'mdv', 'meta', 'mutation_observer', 'observe', 'path',
             'polymer', 'polymer_expressions', 'serialization', 'shadow_dom',
             'source_maps', 'stack_trace', 'unittest',
             'unmodifiable_collection', 'yaml'
           ]).toSet();

ArgResults _parseArgs(arguments) {
  var parser = new ArgParser()
      ..addFlag('help', abbr: 'h', help: 'Displays this help message.',
          defaultsTo: false, negatable: false)
      ..addOption('out', abbr: 'o', help: 'Directory where to generated files.',
          defaultsTo: 'out')
      ..addOption('test', help: 'Deploy the test at the given path.\n'
          'Note: currently this will deploy all tests in its directory,\n'
          'but it will eventually deploy only the specified test.');
  try {
    var results = parser.parse(arguments);
    if (results['help']) {
      _showUsage(parser);
      return null;
    }
    return results;
  } on FormatException catch (e) {
    print(e.message);
    _showUsage(parser);
    return null;
  }
}

_showUsage(parser) {
  print('Usage: dart package:polymer/deploy.dart [options]');
  print(parser.getUsage());
}
