// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unscripted/unscripted.dart';

import 'rule.dart';

main([List<String> args]) {
  addTask(new GrinderTask('rule', taskFunction: () {
    String ruleName = context.invocation.positionals.first;
    _generate(ruleName);
  },
      description: 'Generate a lint rule stub.',
      positionals: [new Positional(valueHelp: 'Name of rule to generate')]));

  grind(args);
}

void _generate(String ruleName) {
  generateRule(ruleName, outDir: Directory.current.path);
}
