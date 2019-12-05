// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';

import 'doc.dart';
import 'rule.dart';

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
  final args = context.invocation.arguments;
  final dir = args.getOption('dir');
  generateDocs(dir);
}

@Task('Format linter sources.')
void format() {
  Pub.run('dart_style',
      script: 'format', arguments: ['--overwrite', ...sourcePaths]);
}

@Task('Generate a lint rule stub.')
void rule() {
  final args = context.invocation.arguments;
  final name = args.getOption('name');
  generateRule(name, outDir: Directory.current.path);
}

@DefaultTask()
@Task('Validate linter sources.')
void validate() {
  Analyzer.analyze(sourcePaths, fatalWarnings: true);
}
