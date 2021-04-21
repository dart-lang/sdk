// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';

import 'doc.dart';
import 'rule.dart';

@Deprecated('To be removed')
void main(List<String> args) => grind(args);

Iterable<String> get sourcePaths => sources.map((dir) => dir.path);

Iterable<FileSystemEntity> get sources => existingSourceDirs.expand((dir) {
      // Skip:
      //   'test/rules'
      //   'test/_data'
      if (dir.path == 'test') {
        return dir.listSync(followLinks: false).where(
            (dir) => dir.path != 'test/rules' && dir.path != 'test/_data');
      }
      return [dir];
    });

@Task('Generate lint rule docs.')
void docs() {
  var args = context.invocation.arguments;
  var dir = args.getOption('dir');
  generateDocs(dir);
}

@Task('Format linter sources.')
void format() {
  Pub.run('dart_style',
      script: 'format', arguments: ['--overwrite', ...sourcePaths]);
}

@Task('Generate a lint rule stub.')
void rule() {
  var args = context.invocation.arguments;
  var name = args.getOption('name')!;
  generateRule(name, outDir: Directory.current.path);
}

@DefaultTask()
@Task('Validate linter sources.')
void validate() {
  Analyzer.analyze(sourcePaths, fatalWarnings: true);
}
