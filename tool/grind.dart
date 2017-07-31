// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unscripted/unscripted.dart';

import 'doc.dart';
import 'rule.dart';

main([List<String> args]) {
  _addTask('rule',
      parser: (String name) =>
          generateRule(name, outDir: Directory.current.path),
      description: 'Generate a lint rule stub.',
      valueHelp: 'Name of rule to generate.');

  _addTask('docs',
      parser: generateDocs,
      description: 'Generate lint rule docs.',
      valueHelp: 'Documentation `lints/` directory.');

  grind(args);
}

_addTask(String name, {String description, Parser parser, String valueHelp}) {
  addTask(new GrinderTask(name, taskFunction: () {
    String value = context.invocation.positionals.first;
    parser(value);
  },
      description: description,
      positionals: [new Positional(valueHelp: valueHelp)]));
}

typedef void Parser(String s);
