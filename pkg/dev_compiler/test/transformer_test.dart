// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.transformer.transformer_test;

import 'package:barback/barback.dart' show BarbackMode, BarbackSettings;
import 'package:dev_compiler/transformer.dart';
import 'package:dev_compiler/src/compiler.dart' show defaultRuntimeFiles;
import 'package:test/test.dart';
import 'package:transformer_test/utils.dart';

makePhases([Map config = const {}]) => [
      [
        new DdcTransformer.asPlugin(
            new BarbackSettings(config, BarbackMode.RELEASE))
      ]
    ];

final Map<String, String> runtimeInput = new Map.fromIterable(
    defaultRuntimeFiles,
    key: (f) => 'dev_compiler|lib/runtime/$f',
    value: (_) => '');

Map<String, String> createInput(Map<String, String> input) =>
    {}..addAll(input)..addAll(runtimeInput);

void main() {
  group('$DdcTransformer', () {
    testPhases(
        r'compiles simple code',
        makePhases(),
        createInput({
          'foo|lib/Foo.dart': r'''
            class Foo {}
          '''
        }),
        {
          'foo|web/foo/Foo.js': r'''
dart_library.library('foo/Foo', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  class Foo extends core.Object {}
  // Exports:
  exports.Foo = Foo;
});
//# sourceMappingURL=Foo.js.map
'''
              .trimLeft()
        });

    testPhases(
        r'honours arguments',
        makePhases({
          'args': ['--destructure-named-params', '--modules=es6']
        }),
        createInput({
          'foo|lib/Foo.dart': r'''
            int foo({String s : '?'}) {}
          '''
        }),
        {
          'foo|web/foo/Foo.js': r'''
const exports = {};
import dart from "../dart/_runtime";
import core from "../dart/core";
let dartx = dart.dartx;
function foo({s = '?'} = {}) {
}
dart.fn(foo, core.int, [], {s: core.String});
// Exports:
exports.foo = foo;
export default exports;
//# sourceMappingURL=Foo.js.map
'''
              .trimLeft()
        });

    testPhases(
        'forwards errors',
        makePhases(),
        createInput({
          'foo|lib/Foo.dart': r'''
            foo() {
              var x = 1;
              x = '2';
            }
          '''
        }),
        {},
        [
          "warning: A value of type \'String\' cannot be assigned to a variable of type \'int\' (package:foo/Foo.dart 3 19)",
          "error: Type check failed: '2' (String) is not of type int (package:foo/Foo.dart 3 19)"
        ]);
  });
}
