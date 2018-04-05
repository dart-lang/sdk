// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';

import 'doc.dart';
import 'rule.dart';

//TODO(pq): add a validate task.
main(args) => grind(args);

@Task('Generate lint rule docs.')
docs() {
  TaskArgs args = context.invocation.arguments;
  String dir = args.getOption('dir');
  generateDocs(dir);
}

@Task('Generate a lint rule stub.')
rule() {
  TaskArgs args = context.invocation.arguments;
  String name = args.getOption('name');
  generateRule(name, outDir: Directory.current.path);
}

@Task('Format the linter sources.')
format() {
  var toFormat = existingSourceDirs.expand((dir) {
    // Skip:
    //   'test/rules'
    //   'test/_data'
    if (dir.path == 'test') {
      return dir
          .listSync(followLinks: false)
          .where((dir) => dir.path != 'test/rules' && dir.path != 'test/_data');
    }
    return [dir];
  });
  Pub.run('dart_style',
      script: 'format',
      arguments: ['--overwrite']..addAll(toFormat.map((dir) => dir.path)));
}
