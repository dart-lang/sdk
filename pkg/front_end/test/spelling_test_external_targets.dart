// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show Directory, File, FileSystemEntity;

import 'package:testing/testing.dart'
    show Chain, FileBasedTestDescription, TestDescription, runMe;

import 'spelling_test_base.dart' show SpellContext;

import 'spell_checking_utils.dart' as spell;

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<SpellContext> createContext(
    Chain suite, Map<String, String> environment) async {
  bool interactive = environment["interactive"] == "true";
  return new SpellContextExternal(interactive: interactive);
}

class SpellContextExternal extends SpellContext {
  SpellContextExternal({bool interactive}) : super(interactive: interactive);

  @override
  List<spell.Dictionaries> get dictionaries => const <spell.Dictionaries>[];

  @override
  bool get onlyDenylisted => true;

  Stream<TestDescription> list(Chain suite) async* {
    for (String subdir in const ["pkg/", "sdk/"]) {
      Directory testRoot = new Directory.fromUri(suite.uri.resolve(subdir));
      if (await testRoot.exists()) {
        Stream<FileSystemEntity> files =
            testRoot.list(recursive: true, followLinks: false);
        await for (FileSystemEntity entity in files) {
          if (entity is! File) continue;
          String path = entity.uri.path;
          if (suite.exclude.any((RegExp r) => path.contains(r))) continue;
          if (suite.pattern.any((RegExp r) => path.contains(r))) {
            yield new FileBasedTestDescription(suite.uri, entity);
          }
        }
      } else {
        throw "${suite.uri} isn't a directory";
      }
    }
  }
}
