#!/usr/bin/env dart
import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:front_end/compilation_message.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/summary_generator.dart';
import 'package:path/path.dart' as p;

import 'package:dev_compiler/src/analyzer/command.dart' as analyzer;
import 'package:dev_compiler/src/kernel/target.dart';

final String scriptDirectory = p.dirname(p.fromUri(Platform.script));

final String repoDirectory = p.normalize(p.join(scriptDirectory, "../../../"));

/// Path to the SDK analyzer summary file, "ddc_sdk.sum".
String analyzerSummary;

/// Path to the SDK kernel summary file, "ddc_sdk.dill".
String kernelSummary;

/// The directory that output is written to.
///
/// The DDC kernel SDK should be directly in this directory. The resulting
/// packages will be placed in a "pkg" subdirectory of this.
String outputDirectory;

String get pkgDirectory => p.join(outputDirectory, "pkg");

/// Compiles the packages that the DDC tests use to JS into the given output
/// directory.
///
/// If "--travis" is passed, builds the all of the modules tested on Travis.
/// Otherwise, only builds the modules needed by the tests.
///
/// If "--analyzer-sdk" is provided, uses that summary file and compiles the
/// packages to JS and analyzer summaries against that SDK summary. Otherwise,
/// it skips generating analyzer summaries and compiling to JS.
///
/// If "--kernel-sdk" is provided, uses that summary file and generates kernel
/// summaries for the test packages against that SDK summary. Otherwise, skips
/// generating kernel summaries.
Future main(List<String> arguments) async {
  var argParser = new ArgParser();
  argParser.addOption("analyzer-sdk",
      help: "Path to SDK analyzer summary '.sum' file");
  argParser.addOption("kernel-sdk",
      help: "Path to SDK Kernel summary '.dill' file");
  argParser.addOption("output",
      abbr: "o", help: "Directory to write output to.");
  argParser.addFlag("travis",
      help: "Build the additional packages tested on Travis.");

  ArgResults argResults;
  try {
    argResults = argParser.parse(arguments);
  } on ArgParserException catch (ex) {
    _usageError(argParser, ex.message);
  }

  if (argResults.rest.isNotEmpty) {
    _usageError(
        argParser, 'Unexpected arguments "${argResults.rest.join(' ')}".');
  }

  var isTravis = argResults["travis"];
  analyzerSummary = argResults["analyzer-sdk"];
  kernelSummary = argResults["kernel-sdk"];
  outputDirectory = argResults["output"];

  new Directory(pkgDirectory).createSync(recursive: true);

  // Build leaf packages. These have no other package dependencies.

  // Under pkg.
  await compileModule('async_helper');
  await compileModule('expect', libs: ['minitest']);
  await compileModule('js', libs: ['js_util']);
  await compileModule('meta');
  if (isTravis) {
    await compileModule('microlytics', libs: ['html_channels']);
    await compileModule('typed_mock');
  }

  // Under third_party/pkg.
  await compileModule('collection');
  await compileModule('path');
  if (isTravis) {
    await compileModule('args', libs: ['command_runner']);
    await compileModule('charcode');
    await compileModule('fixnum');
    await compileModule('logging');
    await compileModule('markdown');
    await compileModule('mime');
    await compileModule('plugin', libs: ['manager']);
    await compileModule('typed_data');
    await compileModule('usage');
    await compileModule('utf');
  }

  // Composite packages with dependencies.
  await compileModule('stack_trace', deps: ['path']);
  await compileModule('matcher', deps: ['stack_trace']);
  if (isTravis) {
    await compileModule('async', deps: ['collection']);
  }

  if (!isTravis) {
    await compileModule('unittest', deps: [
      'matcher',
      'path',
      'stack_trace'
    ], libs: [
      'html_config',
      'html_individual_config',
      'html_enhanced_config'
    ]);
  }
}

void _usageError(ArgParser parser, [String message]) {
  if (message != null) {
    stderr.writeln(message);
    stderr.writeln();
  }

  stderr.writeln("Usage: dart build_pkgs.dart ...");
  stderr.writeln();
  stderr.writeln(parser.usage);
  exit(1);
}

/// Compiles a [module] with a single matching ".dart" library and additional
/// [libs] and [deps] on other modules.
Future compileModule(String module,
    {List<String> libs, List<String> deps}) async {
  if (analyzerSummary != null) compileModuleUsingAnalyzer(module, libs, deps);
  if (kernelSummary != null) await compileKernelSummary(module, libs, deps);
}

void compileModuleUsingAnalyzer(
    String module, List<String> libraries, List<String> dependencies) {
  var args = [
    '--dart-sdk-summary=$analyzerSummary',
    '-o${pkgDirectory}/$module.js'
  ];

  // There is always a library that matches the module.
  args.add('package:$module/$module.dart');

  // Add any additional libraries.
  if (libraries != null) {
    for (var lib in libraries) {
      args.add('package:$module/$lib.dart');
    }
  }

  // Add summaries for any modules this depends on.
  if (dependencies != null) {
    for (var dep in dependencies) {
      args.add('-s${pkgDirectory}/$dep.sum');
    }
  }

  // TODO(rnystrom): Hack. DDC has its own forked copy of async_helper that
  // has a couple of differences from pkg/async_helper. We should unfork them,
  // but I'm not sure how they'll affect the other non-DDC tests. For now, just
  // use ours.
  if (module == 'async_helper') {
    args.add('--url-mapping=package:async_helper/async_helper.dart,' +
        p.join(scriptDirectory, "../test/codegen/async_helper.dart"));
  }

  var exitCode = analyzer.compile(args);
  if (exitCode != 0) exit(exitCode);
}

Future compileKernelSummary(
    String module, List<String> libraries, List<String> dependencies) async {
  var succeeded = true;

  void errorHandler(CompilationMessage error) {
    if (error.severity == Severity.error) succeeded = false;
  }

  var options = new CompilerOptions()
    ..sdkSummary = p.toUri(kernelSummary)
    ..packagesFileUri = _uriInRepo(".packages")
    ..strongMode = true
    ..debugDump = true
    ..chaseDependencies = true
    ..onError = errorHandler
    ..reportMessages = true
    ..target = new DevCompilerTarget();

  var inputs = <Uri>[];

  if (module == "async_helper") {
    // TODO(rnystrom): Hack. DDC has its own forked copy of async_helper that
    // has a couple of differences from pkg/async_helper. We should unfork them,
    // but I'm not sure how they'll affect the other non-DDC tests. For now,
    // just use ours.
    inputs.add(_uriInRepo("pkg/dev_compiler/test/codegen/async_helper.dart"));
  } else {
    // There is always a library that matches the module.
    inputs.add(Uri.parse("package:$module/$module.dart"));

    // Add any other libraries too.
    if (libraries != null) {
      for (var lib in libraries) {
        inputs.add(Uri.parse("package:$module/$lib.dart"));
      }
    }
  }

  // Add summaries for any modules this depends on.
  if (dependencies != null) {
    var uris = <Uri>[];

    for (var dep in dependencies) {
      uris.add(p.toUri(p.absolute(p.join(pkgDirectory, "$dep.dill"))));
    }

    options.inputSummaries = uris;
  }

  // Compile the summary.
  var bytes = await summaryFor(inputs, options);
  var dillFile = new File(p.join(pkgDirectory, "$module.dill"));
  if (succeeded) {
    dillFile.writeAsBytesSync(bytes);
  } else {
    // Don't leave the previous version of the file on failure.
    if (dillFile.existsSync()) dillFile.deleteSync();

    stderr.writeln("Could not generate kernel summary for $module.");
    exit(1);
  }
}

Uri _uriInRepo(String pathInRepo) {
  // Walk up to repo root.
  var result = p.join(scriptDirectory, "../../../");
  result = p.join(result, pathInRepo);
  return p.toUri(p.absolute(p.normalize(result)));
}
