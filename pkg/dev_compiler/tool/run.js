// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var args = process.argv.slice(2);
if (args.length != 1) {
  throw new Error("Usage: node test/run.js <test-module-name>");
}
var test = args[0];

var requirejs = require('requirejs');
var ddcdir = __dirname + '/../';
requirejs.config({
  baseUrl: ddcdir + 'gen/codegen_output',
  paths: {
    dart_sdk: ddcdir + 'lib/js/amd/dart_sdk',
    async_helper: ddcdir + 'gen/codegen_output/pkg/async_helper',
    expect: ddcdir + 'gen/codegen_output/pkg/expect',
    js: ddcdir + 'gen/codegen_output/pkg/js',
    matcher: ddcdir + 'gen/codegen_output/pkg/matcher',
    minitest: ddcdir + 'gen/codegen_output/pkg/minitest',
    path: ddcdir + 'gen/codegen_output/pkg/path',
    stack_trace: ddcdir + 'gen/codegen_output/pkg/stack_trace',
    unittest: ddcdir + 'gen/codegen_output/pkg/unittest',
  }
});

// TODO(vsm): Factor out test framework code in test/browser/language_tests.js
// and use here.  Async tests and unittests won't work without it.

var module = requirejs(test);
test = test.split('/').slice(-1)[0];
module[test].main();
