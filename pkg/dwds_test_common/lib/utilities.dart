// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

const webdevDirName = 'webdev';
const dwdsDirName = 'dwds';
const fixturesDirName = 'fixtures';

/// The path to the project root directory, e.g. `webdev/` or `pkg/` in the
/// Dart SDK.
String get projectRootDir {
  return p.dirname(_dwdsTestCommonPackageRoot);
}

/// The path to the DWDS directory in the local machine, e.g.
/// 'webdev/dwds' or 'pkg/dwds'.
String get dwdsPath {
  return p.join(projectRootDir, dwdsDirName);
}

/// The path to the fixtures directory in the local machine, e.g.
/// 'webdev/dwds_test_common/fixtures' or 'pkg/dwds_test_common/fixtures'.
String get fixturesPath {
  return p.join(_dwdsTestCommonPackageRoot, fixturesDirName);
}

/// The path to the webdev/dwds_test_common or pkg/dwds_test_common package
/// root in the local machine, e.g. 'webdev/dwds_test_common' or
/// 'pkg/dwds_test_common'.
String get _dwdsTestCommonPackageRoot {
  final scriptPath = Platform.script.toFilePath();
  final isTest = scriptPath.contains('dart_test.kernel');
  if (isTest) {
    // When running tests, p.current might be dwds, so we need to check
    // if we're in webdev/dwds_test_common or pkg/dwds_test_common or need to
    // navigate to it.
    var current = p.current;
    if (p.basename(current) == 'dwds') {
      // Check if dwds_test_common exists as a sibling
      final testCommonPath = p.join(p.dirname(current), 'dwds_test_common');
      if (Directory(testCommonPath).existsSync()) {
        return testCommonPath;
      }
    }
    return current; // p.current is the package root for tests
  }
  var current = p.dirname(scriptPath);
  while (current != p.dirname(current)) {
    if (File(p.join(current, 'pubspec.yaml')).existsSync()) {
      return current; // This is the package root
    }
    current = p.dirname(current);
  }
  throw StateError(
    'Could not find `dwds_test_common` package root from '
    '${Platform.script.path}.',
  );
}

// Creates a path compatible for web.
String webCompatiblePath(List<String> pathParts) {
  final context = p.Context(style: p.Style.posix);
  return context.joinAll([...pathParts]);
}

/// Expects one of [pathFromWebdev], [pathFromDwds] or [pathFromFixtures] to
/// be provided. Returns the absolute path in the local machine to that path,
/// e.g. absolutePath(pathFromFixtures: '_test/example') ->
/// '/workstation/webdev/dwds_test_common/fixtures/_test/example'
String absolutePath({
  String? pathFromWebdev,
  String? pathFromDwds,
  String? pathFromFixtures,
}) {
  if (pathFromWebdev != null) {
    assert(pathFromDwds == null && pathFromFixtures == null);
    return p.normalize(p.join(projectRootDir, pathFromWebdev));
  }
  if (pathFromDwds != null) {
    assert(pathFromFixtures == null);
    return p.normalize(p.join(dwdsPath, pathFromDwds));
  }
  if (pathFromFixtures != null) {
    assert(pathFromDwds == null && pathFromWebdev == null);
    return p.normalize(p.join(fixturesPath, pathFromFixtures));
  }
  throw Exception('Expected a path parameter.');
}

bool dartSdkIsAtLeast(String sdkVersion) {
  final expectedVersion = Version.parse(sdkVersion);
  final actualVersion = Version.parse(Platform.version.split(' ')[0]);
  return actualVersion >= expectedVersion;
}
