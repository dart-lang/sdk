#!/usr/bin/env dart
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dev_compiler/src/compiler/command.dart';

final String scriptDirectory = p.dirname(p.fromUri(Platform.script));
String outputDirectory;

/// Compiles the packages that the DDC tests use to JS into the given output
/// directory. Usage:
///
///     dart build_pkgs.dart <output_dir> [travis]
///
/// If "travis" is passed, builds the all of the modules tested on Travis.
/// Otherwise, only builds the modules needed by the tests.
void main(List<String> arguments) {
  var isTravis = arguments.isNotEmpty && arguments.last == "travis";
  if (isTravis) {
    arguments = arguments.toList();
    arguments.removeLast();
  }

  if (arguments.length != 1) {
    print("Usage: dart build_pkgs.dart <output_dir> [travis]");
    exit(1);
  }

  outputDirectory = arguments[0];
  new Directory(outputDirectory).createSync(recursive: true);

  // Build leaf packages. These have no other package dependencies.

  // Under pkg.
  compileModule('async_helper');
  compileModule('expect', libs: ['minitest']);
  compileModule('js', libs: ['js_util']);
  compileModule('meta');
  if (isTravis) {
    compileModule('lookup_map');
    compileModule('microlytics', libs: ['html_channels']);
    compileModule('typed_mock');
  }

  // Under third_party/pkg.
  compileModule('collection');
  compileModule('matcher');
  compileModule('path');
  if (isTravis) {
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
  }

  // Composite packages with dependencies.
  compileModule('stack_trace', deps: ['path']);
  if (isTravis) {
    compileModule('async', deps: ['collection']);
  }

  if (!isTravis) {
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
  var sdkSummary = p.join(scriptDirectory, "../lib/sdk/ddc_sdk.sum");
  var args = [
    '--dart-sdk-summary=$sdkSummary',
    '-o${outputDirectory}/$module.js'
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
      args.add('-s${outputDirectory}/$dep.sum');
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
    args.add('--url-mapping=package:async_helper/async_helper.dart,' +
        p.join(scriptDirectory, "../test/codegen/async_helper.dart"));
  }

  var exitCode = compile(args);
  if (exitCode != 0) exit(exitCode);
}
