// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Abstractions for the different sources of truth for different packages.

import 'dart:convert';
import 'dart:io';

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

Uri get thisSdkUri => Uri.file(thisSdkRepo);

/// Abstraction for an unmanaged package.
class ManualPackage extends Package {
  ManualPackage(this.packagePath) : super(packagePath);

  @override
  final String packagePath;
}

/// Abstraction for a package fetched via Github.
class GitHubPackage extends Package {
  GitHubPackage(String name, [String label]) : super(name) {
    throw UnimplementedError();
  }

  @override
  // TODO: implement packagePath
  String get packagePath => null;
}

/// Abstraction for a package fetched via pub.
class PubPackage extends Package {
  PubPackage(String name, [String version]) : super(name) {
    throw UnimplementedError();
  }

  @override
  // TODO: implement packagePath
  String get packagePath => null;
}

/// Abstraction for a package located within pkg or third_party/pkg.
class SdkPackage extends Package {
  /// Where to find packages.  Constructor searches in-order.
  static List<String> _searchPaths = [
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
    if (_packagePath == null)
      throw ArgumentError('Package $name not found in SDK');
  }

  /* late final */ String _packagePath;
  @override
  String get packagePath => _packagePath;

  @override
  String toString() => path.relative(packagePath, from: thisSdkRepo);
}

/// Base class for pub, github, SDK, or possibly other package sources.
abstract class Package {
  final String name;

  Package(this.name);

  /// Returns the root directory of the package.
  String get packagePath;

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

  /// Returns true if the SDK was built with --nnbd.
  ///
  /// May throw if [sdkPath] is invalid, or there is an error parsing
  /// the libraries.json file.
  bool get isNnbdSdk {
    // TODO(jcollins-g): contact eng-prod for a more foolproof detection method
    String libraries = path.join(sdkPath, 'lib', 'libraries.json');
    var decodedJson = JsonDecoder().convert(File(libraries).readAsStringSync());
    return ((decodedJson['comment:1'] as String).contains('sdk_nnbd'));
  }
}
