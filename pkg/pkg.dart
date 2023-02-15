// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// List the packages in pkg/ as well information about their
/// analysis_options.yaml configuration.

import 'dart:io';

void main(List<String> args) {
  const indent = 24;

  var dirs = Directory('pkg').listSync().whereType<Directory>().toList();
  dirs.sort((a, b) => a.path.compareTo(b.path));

  for (var dir in dirs) {
    var pubspec = File('${dir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;

    var options = File('${dir.path}/analysis_options.yaml');
    var name = dir.path.split('/').last;

    if (options.existsSync()) {
      var type = '** custom **';
      var optionsContent = options.readAsStringSync();
      if (optionsContent.contains('package:lints/core.yaml')) {
        type = 'core';
      } else if (optionsContent.contains('package:lints/recommended.yaml')) {
        type = 'recommended';
      }
      print('${name.padRight(indent)}: $type');
    } else {
      print('${name.padRight(indent)}: default');
    }
  }
}
