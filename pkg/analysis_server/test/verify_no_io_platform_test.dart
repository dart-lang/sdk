// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_testing/package_root.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  // To support dart2js and dart2wasm environments used by
  // pkg/dartpad_worker, we avoid `Platform` from `dart:io` in favor of
  // `package:analyzer/src/util/platform_info.dart`.
  for (var packagePath in [
    'analysis_server',
    'analysis_server_plugin',
    'analyzer',
    'analyzer_plugin',
    'linter',
  ]) {
    group(packagePath, () {
      _buildTests(packagePath: packagePath);
    });
  }
}

/// Files allowed to reference `Platform` from `dart:io`.
const _exemptions = <Pattern>[
  // Implements `PlatformInfo` on `dart:io` by delegating to `Platform`.
  'analyzer/lib/src/util/platform_info_io.dart',
];

void _buildTests({required String packagePath}) {
  var provider = PhysicalResourceProvider.INSTANCE;
  var pathContext = provider.pathContext;
  var pkgRootPath = pathContext.normalize(packageRoot);

  var libFolder = provider
      .getFolder(pkgRootPath)
      .getFolder(packagePath)
      .getFolder('lib');

  var platformRegExp = RegExp(r'\bPlatform\.');
  for (var file in libFolder.allFiles) {
    if (!file_paths.isDart(pathContext, file.path)) {
      continue;
    }
    var relativePath = path.posix.joinAll(
      pathContext.split(pathContext.relative(file.path, from: pkgRootPath)),
    );
    if (_exemptions.any(relativePath.contains)) {
      continue;
    }
    test(relativePath, () {
      var content = file.readAsStringSync();
      for (var line in LineSplitter.split(content)) {
        if (line.trimLeft().startsWith('//')) {
          continue;
        }
        if (platformRegExp.hasMatch(line)) {
          fail(
            'Should use `platform` from '
            '`package:analyzer/src/util/platform_info.dart` instead of '
            '`Platform` from `dart:io`: $line',
          );
        }
      }
    });
  }
}

extension on Folder {
  Iterable<File> get allFiles sync* {
    var queue = Queue<Folder>();
    queue.add(this);
    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      var children = current.getChildren();
      for (var child in children) {
        if (child is File) {
          yield child;
        } else if (child is Folder) {
          queue.add(child);
        }
      }
    }
  }
}
