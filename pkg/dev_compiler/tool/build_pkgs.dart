#!/usr/bin/env dart
import 'dart:io';

import 'package:dev_compiler/src/compiler/command.dart';

/// Compiles the packages that the DDC tests use to JS into:
///
/// gen/codegen_output/pkg/...
///
/// Assumes the working directory is pkg/dev_compiler.
///
/// If no arguments are passed, builds the all of the modules tested on Travis.
/// If "test" is passed, only builds the modules needed by the tests.
void main(List<String> arguments) {
  var test = arguments.length == 1 && arguments[0] == 'test';

  new Directory("gen/codegen_output/pkg").createSync(recursive: true);

  // Build leaf packages. These have no other package dependencies.

  // Under pkg.
  compileModule('async_helper');
  compileModule('expect', libs: ['minitest']);
  compileModule('js', libs: ['js_util']);
  if (!test) {
    compileModule('lookup_map');
    compileModule('meta');
    compileModule('microlytics', libs: ['html_channels']);
    compileModule('typed_mock');
  }

  // Under third_party/pkg.
  compileModule('collection');
  compileModule('matcher');
  compileModule('path');
  if (!test) {
    compileModule('args', libs: ['command_runner']);
    compileModule('charcode');
    compileModule('fixnum');
    compileModule('logging');
    compileModule('markdown');
    compileModule('mime');
    compileModule('plugin', libs: ['manager']);
    compileModule('typed_data');
    compileModule('usage');
    compileModule('utf');
    compileModule('when');
  }

  // Composite packages with dependencies.
  compileModule('stack_trace', deps: ['path']);
  if (!test) {
    compileModule('async', deps: ['collection']);
  }

  if (test) {
    compileModule('unittest',
        deps: ['matcher', 'path', 'stack_trace'],
        libs: ['html_config', 'html_individual_config', 'html_enhanced_config'],
        unsafeForceCompile: true);
  }
}

/// Compiles a [module] with a single matching ".dart" library and additional
/// [libs] and [deps] on other modules.
void compileModule(String module,
    {List<String> libs, List<String> deps, bool unsafeForceCompile: false}) {
  var args = [
    '--dart-sdk-summary=lib/sdk/ddc_sdk.sum',
    '-ogen/codegen_output/pkg/$module.js'
  ];

  // There is always a library that matches the module.
  args.add('package:$module/$module.dart');

  // Add any additional libraries.
  if (libs != null) {
    for (var lib in libs) {
      args.add('package:$module/$lib.dart');
    }
  }

  // Add summaries for any modules this depends on.
  if (deps != null) {
    for (var dep in deps) {
      args.add('-sgen/codegen_output/pkg/$dep.sum');
    }
  }

  if (unsafeForceCompile) {
    args.add('--unsafe-force-compile');
  }

  // TODO(rnystrom): Hack. DDC has its own forked copy of async_helper that
  // has a couple of differences from pkg/async_helper. We should unfork them,
  // but I'm not sure how they'll affect the other non-DDC tests. For now, just
  // use ours.
  if (module == 'async_helper') {
    args.add('--url-mapping=package:async_helper/async_helper.dart,'
        'test/codegen/async_helper.dart');
  }

  compile(args);
}
