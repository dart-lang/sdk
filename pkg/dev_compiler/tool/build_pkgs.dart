#!/usr/bin/env dart
import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:dev_compiler/src/compiler/shared_command.dart';

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

/// List of language experiments to enable when building.
List<String> experiments;

/// Whether to force the analyzer backend to generate code even if there are
/// errors.
bool unsafeForceCompile;

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
  var argParser = ArgParser();
  argParser.addOption("analyzer-sdk",
      help: "Path to SDK analyzer summary '.sum' file");
  argParser.addOption("kernel-sdk",
      help: "Path to SDK Kernel summary '.dill' file");
  argParser.addOption("output",
      abbr: "o", help: "Directory to write output to.");
  argParser.addFlag("travis",
      help: "Build the additional packages tested on Travis.");
  argParser.addMultiOption("enable-experiment",
      help: "Enable experimental language features.");
  argParser.addFlag("unsafe-force-compile",
      help: "Generate output even if compile errors are reported.");

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

  var isTravis = argResults["travis"] as bool;
  analyzerSummary = argResults["analyzer-sdk"] as String;
  kernelSummary = argResults["kernel-sdk"] as String;
  outputDirectory = argResults["output"] as String;
  experiments = argResults["enable-experiment"] as List<String>;
  unsafeForceCompile = argResults["unsafe-force-compile"] as bool;

  // Build leaf packages. These have no other package dependencies.

  // Under pkg.
  await compileModule('async_helper');
  await compileModule('expect', libs: ['minitest']);
  await compileModule('js', libs: ['js_util']);
  await compileModule('meta');

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
    {List<String> libs = const [], List<String> deps = const []}) async {
  makeArgs({bool kernel = false}) {
    var pkgDirectory = p.join(outputDirectory, kernel ? 'pkg_kernel' : 'pkg');
    Directory(pkgDirectory).createSync(recursive: true);

    return [
      if (kernel) '-k',
      if (experiments.isNotEmpty)
        '--enable-experiment=${experiments.join(",")}',
      if (unsafeForceCompile && !kernel) '--unsafe-force-compile',
      '--dart-sdk-summary=${kernel ? kernelSummary : analyzerSummary}',
      '-o${pkgDirectory}/$module.js',
      'package:$module/$module.dart',
      for (var lib in libs) 'package:$module/$lib.dart',
      for (var dep in deps) '-s${pkgDirectory}/$dep.${kernel ? "dill" : "sum"}',
    ];
  }

  if (analyzerSummary != null) {
    var result = await compile(ParsedArguments.from(makeArgs()));
    if (!result.success) exit(result.exitCode);
  }
  if (kernelSummary != null) {
    var result = await compile(ParsedArguments.from(makeArgs(kernel: true)));
    if (!result.success) exit(result.exitCode);
  }
}
