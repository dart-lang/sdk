// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Abstractions for the different sources of truth for different packages.

import 'dart:io';

import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:path/path.dart' as path;

/// Return a resolved path including the home directory in place of tilde
/// references.
String resolveTildePath(String originalPath) {
  if (originalPath == null || !originalPath.startsWith('~/')) {
    return originalPath;
  }

  String homeDir;

  if (Platform.isWindows) {
    homeDir = path.absolute(Platform.environment['USERPROFILE']);
  } else {
    homeDir = path.absolute(Platform.environment['HOME']);
  }

  return path.join(homeDir, originalPath.substring(2));
}

/// The pub cache inherited by this process.
final String defaultPubCache =
    Platform.environment['PUB_CACHE'] ?? resolveTildePath('~/.pub-cache');
final String defaultPlaygroundPath =
    Platform.environment['TRIAL_MIGRATION_PLAYGROUND'] ??
        resolveTildePath('~/.nnbd_trial_migration');
Uri get thisSdkUri => Uri.file(thisSdkRepo);

class Playground {
  final String playgroundPath;

  /// If [clean] is true, this will delete the playground.  Otherwise,
  /// if it exists it will assume it is properly constructed.
  Playground(this.playgroundPath, bool clean) {
    Directory playground = Directory(playgroundPath);
    if (clean) {
      if (playground.existsSync()) {
        playground.deleteSync(recursive: true);
      }
    }
    if (!playground.existsSync()) playground.createSync();
  }

  /// Build an environment for subprocesses.
  Map<String, String> get env => {'PUB_CACHE': pubCachePath};

  String get pubCachePath => path.join(playgroundPath, '.pub-cache');
}

/// Returns the path to the SDK repository this script is a part of.
final String thisSdkRepo = () {
  var maybeSdkRepoDir = Platform.script.toFilePath();
  while (maybeSdkRepoDir != path.dirname(maybeSdkRepoDir)) {
    maybeSdkRepoDir = path.dirname(maybeSdkRepoDir);
    if (File(path.join(maybeSdkRepoDir, 'README.dart-sdk')).existsSync()) {
      return maybeSdkRepoDir;
    }
  }
  throw UnsupportedError(
      'Script ${Platform.script} using this library must be within the SDK repository');
}();

/// Abstraction for an unmanaged package.
class ManualPackage extends Package {
  final String _packagePath;
  ManualPackage(this._packagePath) : super(_packagePath);

  @override
  List<String> get migrationPaths => [_packagePath];
}

/// Abstraction for a package fetched via Git.
class GitPackage extends Package {
  final String _clonePath;
  final bool _keepUpdated;
  final String label;
  final Playground _playground;

  GitPackage._(this._clonePath, this._playground, this._keepUpdated,
      {String name, this.label = 'master'})
      : super(name ?? _buildName(_clonePath));

  static Future<GitPackage> gitPackageFactory(
      String clonePath, Playground playground, bool keepUpdated,
      {String name, String label = 'master'}) async {
    GitPackage gitPackage = GitPackage._(clonePath, playground, keepUpdated,
        name: name, label: label);
    await gitPackage._init();
    return gitPackage;
  }

  /// Calculate the "humanish" name of the clone (see `git help clone`).
  static String _buildName(String clonePath) {
    if (Directory(clonePath).existsSync()) {
      // assume we are cloning locally
      return path.basename(clonePath);
    }
    List<String> pathParts = clonePath.split(_pathAndPeriodSplitter);
    int indexOfName = pathParts.lastIndexOf('git') - 1;
    if (indexOfName < 0) {
      throw ArgumentError(
          'GitPackage can not figure out the name for $clonePath, pass it in manually?');
    }
    return pathParts[indexOfName];
  }

  static final RegExp _pathAndPeriodSplitter = RegExp('[\\/.]');

  /// Initialize the package with a shallow clone.  Run only once per
  /// [GitPackage] instance.
  Future<void> _init() async {
    if (_keepUpdated || !await Directory(packagePath).exists()) {
      // Clone or update.
      if (await Directory(packagePath).exists()) {
        await launcher.runStreamed('git', ['pull'],
            workingDirectory: packagePath);
      } else {
        await launcher.runStreamed('git',
            ['clone', '--branch=$label', '--depth=1', _clonePath, packagePath],
            workingDirectory: _playground.playgroundPath);
        await launcher.runStreamed('git', ['checkout', '-b', '_test_migration'],
            workingDirectory: packagePath);
        await launcher.runStreamed(
            'git', ['branch', '--set-upstream-to', 'origin/$label'],
            workingDirectory: packagePath);
        // TODO(jcollins-g): allow for migrating dependencies?
      }
      await pubTracker.runFutureFromClosure(() =>
          launcher.runStreamed('pub', ['get'], workingDirectory: packagePath));
    }
  }

  SubprocessLauncher _launcher;
  SubprocessLauncher get launcher =>
      _launcher ??= SubprocessLauncher('$name-$label', _playground.env);

  String _packagePath;
  String get packagePath =>
      // TODO(jcollins-g): allow packages from subdirectories of clones
      _packagePath ??= path.join(_playground.playgroundPath, '$name-$label');

  @override
  List<String> get migrationPaths => [_packagePath];

  @override
  String toString() {
    return '$_clonePath ($label)' + (_keepUpdated ? ' [synced]' : '');
  }
}

/// Abstraction for a package fetched via pub.
class PubPackage extends Package {
  PubPackage(String name, [String version]) : super(name) {
    throw UnimplementedError();
  }

  @override
  // TODO: implement packagePath
  List<String> get migrationPaths => throw UnimplementedError();
}

/// Abstraction for a package located within pkg or third_party/pkg.
class SdkPackage extends Package {
  /// Where to find packages.  Constructor searches in-order.
  static final List<String> _searchPaths = [
    'pkg',
    path.join('third_party', 'pkg'),
  ];

  SdkPackage(String name) : super(name) {
    for (String potentialPath
        in _searchPaths.map((p) => path.join(thisSdkRepo, p, name))) {
      if (Directory(potentialPath).existsSync()) {
        _packagePath = potentialPath;
      }
    }
    if (_packagePath == null) {
      throw ArgumentError('Package $name not found in SDK');
    }
  }

  /* late final */ String _packagePath;
  @override
  List<String> get migrationPaths => [_packagePath];

  @override
  String toString() => path.relative(_packagePath, from: thisSdkRepo);
}

/// Base class for pub, github, SDK, or possibly other package sources.
abstract class Package {
  final String name;

  Package(this.name);

  /// Returns the set of directories for this package.
  List<String> get migrationPaths;

  @override
  String toString() => name;
}

/// Abstraction for compiled Dart SDKs (not this repository).
class Sdk {
  /// The root of the compiled SDK.
  /* late final */ String sdkPath;

  Sdk(String sdkPath) {
    this.sdkPath = path.canonicalize(sdkPath);
  }
}
