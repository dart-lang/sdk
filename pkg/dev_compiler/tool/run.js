// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a utility to run and debug an individual DDC compiled test.
/// Tests can be run with either node or devtool (a Chrome-based utility with
/// DOM APIs and developer tools support).
///
/// Install devtool via:
/// > npm install -g devtool
///
/// Run via:
/// > devtool tool/run.js -- corelib/apply2_test
/// or
/// > node tool/run.js corelib/apply2_test
///
/// See TODO below on async / unittest support. 

var args = process.argv.slice(2);
if (args.length != 1) {
  throw new Error("Usage: devtool tool/run.js <test-module-name>");
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
var sdk = requirejs('dart_sdk');
sdk.dart.ignoreWhitelistedErrors(false);

let negative = /negative_test/.test(test);
function finish(e) {
  if (negative) {
    if (e) {
      e = null;
    } else {
      e = new Error("test marked as 'negative' but did not throw");
    }
  }
  if (e) {
    console.log('Test ' + test + ' failed:\n' + e.toString());
    sdk.dart.stackPrint(e);
  } else {
    console.log('Test ' + test + ' passed.');
  }
}

sdk.dart.ignoreWhitelistedErrors(false);
sdk._isolate_helper.startRootIsolate(() => {}, []);
// Make it easier to debug test failures and required for formatter test that
// assumes custom formatters are enabled.
sdk._debugger.registerDevtoolsFormatter();

var async_helper = requirejs('async_helper').async_helper;
async_helper.asyncTestInitialize(finish);

var module = requirejs(test);
var lib = test.split('/').slice(-1)[0];
try {
  if (module[lib]._expectRuntimeError) negative = true;
  var result = module[lib].main();
  // async_helper tests call finish directly - call here for all other
  // tests.
  if (!async_helper.asyncTestStarted) {
    if (!result || !(sdk.async.Future.is(result))) {
      finish();
    } else {
      // Wait iff result is a future
      result.then(sdk.dart.dynamic)(() => finish(), { onError: (e) => finish(e) });
    }
  }
} catch (e) {
  finish(e);
}
