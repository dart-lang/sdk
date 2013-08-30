// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Temporary deploy command used to create a version of the app that can be
 * compiled with dart2js and deployed. This library should go away once `pub
 * deploy` can be configured to run barback transformers.
 *
 * From an application package you can run this program by calling dart with a
 * 'package:' url to this file:
 *
 *    dart package:polymer/deploy.dart
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
  print('polymer/deploy.dart: creating a deploy target for "$_currentPackage"');
  var outDir = args['out'];
  _run(args['webdir'], outDir).then(
      (_) => print('Done! All files written to "$outDir"'));
}

/**
 * API exposed for testing purposes. Runs this deploy command but prentend that
 * the sources under [webDir] belong to package 'test'.
 */
Future runForTest(String webDir, String outDir) {
  _currentPackage = 'test';

  // associate package dirs with their location in the repo:
  _packageDirs = {'test' : '.'};
  addPackages(String dir) {
    for (var packageDir in new Directory(dir).listSync().map((d) => d.path)) {
      _packageDirs[path.basename(packageDir)] = packageDir;
    }
  }
  addPackages('..');
  addPackages('../third_party');
  addPackages('../../third_party/pkg');
  return _run(webDir, outDir);
}

Future _run(String webDir, String outDir) {
  var barback = new Barback(new _PolymerDeployProvider());
  _initializeBarback(barback, webDir);
  _attachListeners(barback);
  return _emitAllFiles(barback, webDir, outDir);
}

/** Tell barback which transformers to use and which assets to process. */
void _initializeBarback(Barback barback, String webDir) {
  var assets = [];
  for (var package in _packageDirs.keys) {
    // Do not process packages like 'polymer' where there is nothing to do.
    if (_ignoredPackages.contains(package)) continue;
    barback.updateTransformers(package, phases);

    // notify barback to process anything under 'lib' and 'asset'
    for (var filepath in _listDir(package, 'lib')) {
      assets.add(new AssetId(package, filepath));
    }

    for (var filepath in _listDir(package, 'asset')) {
      assets.add(new AssetId(package, filepath));
    }
  }

  // In case of the current package, include also 'web'.
  for (var filepath in _listDir(_currentPackage, webDir)) {
    assets.add(new AssetId(_currentPackage, filepath));
  }
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
      ..addFlag('help', abbr: 'h', help: 'Displays this help message',
          defaultsTo: false, negatable: false)
      ..addOption('webdir', help: 'Directory containing the application',
          defaultsTo: 'web')
      ..addOption('out', abbr: 'o', help: 'Directory where to generated files',
          defaultsTo: 'out');
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
