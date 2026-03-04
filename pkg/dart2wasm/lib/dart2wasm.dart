// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:front_end/src/api_unstable/vm.dart' show resolveInputUri;
import 'package:front_end/src/api_unstable/vm.dart' as fe;

import 'dynamic_modules.dart' show DynamicModuleType;
import 'generate_wasm.dart';
import 'option.dart';

// Used to allow us to keep defaults on their respective option structs.
// Note: When adding new options, consider if CLI options should be add
// to `pkg/dartdev/lib/src/commands/compile.dart` too.
final WasmCompilerOptions _d = WasmCompilerOptions.defaultOptions();

final List<Option> options = [
  Flag("help", (o, _) {}, abbr: "h", negatable: false, defaultsTo: false),
  IntOption("optimization-level",
      (o, value) => o.translatorOptions.optimizationLevel = value,
      abbr: "O"),
  Flag("import-shared-memory",
      (o, value) => o.translatorOptions.importSharedMemory = value,
      defaultsTo: _d.translatorOptions.importSharedMemory),
  Flag("inlining", (o, value) => o.translatorOptions.inliningOverride = value),
  Flag("minify", (o, value) => o.translatorOptions.minifyOverride = value),
  Flag("dry-run", (o, value) => o.dryRun = value, defaultsTo: _d.dryRun),
  StringMultiOption(
      "phases",
      (o, values) => o.phases = [...values.map(CompilerPhase.parse)]
        ..sort((a, b) => a.index.compareTo(b.index))),
  Flag("polymorphic-specialization",
      (o, value) => o.translatorOptions.polymorphicSpecialization = value,
      defaultsTo: _d.translatorOptions.polymorphicSpecialization),
  Flag("print-kernel", (o, value) => o.translatorOptions.printKernel = value,
      defaultsTo: _d.translatorOptions.printKernel),
  Flag("print-wasm", (o, value) => o.translatorOptions.printWasm = value,
      defaultsTo: _d.translatorOptions.printWasm),
  Flag("js-compatibility", (o, value) {
    o.translatorOptions.jsCompatibility = value;
    o.environment['dart.wasm.js_compatibility'] = 'true';
  }, defaultsTo: _d.translatorOptions.jsCompatibility),
  Flag(
      "enable-asserts", (o, value) => o.translatorOptions.enableAsserts = value,
      defaultsTo: _d.translatorOptions.enableAsserts),
  Flag("omit-explicit-checks",
      (o, value) => o.translatorOptions.omitExplicitTypeChecks = value,
      defaultsTo: _d.translatorOptions.omitExplicitTypeChecks),
  Flag("omit-implicit-checks",
      (o, value) => o.translatorOptions.omitImplicitTypeChecksOverride = value,
      defaultsTo: _d.translatorOptions.omitImplicitTypeChecks),
  Flag("omit-bounds-checks", (o, value) {
    o.translatorOptions.omitBoundsChecksOverride = value;
  }, defaultsTo: _d.translatorOptions.omitBoundsChecks),
  Flag("verbose", (o, value) => o.translatorOptions.verbose = value,
      defaultsTo: _d.translatorOptions.verbose),
  Flag("unique-constant-names",
      (o, value) => o.translatorOptions.uniqueConstantNames = value,
      defaultsTo: true, negatable: true),
  Flag("verify-type-checks",
      (o, value) => o.translatorOptions.verifyTypeChecks = value,
      defaultsTo: _d.translatorOptions.verifyTypeChecks),
  Flag('enable-protobuf-tree-shaker',
      (o, value) => o.translatorOptions.enableProtobufTreeShaker = value,
      defaultsTo: _d.translatorOptions.enableProtobufTreeShaker),
  Flag('enable-protobuf-mixin-tree-shaker',
      (o, value) => o.translatorOptions.enableProtobufMixinTreeShaker = value,
      defaultsTo: _d.translatorOptions.enableProtobufMixinTreeShaker),
  Flag("enable-experimental-wasm-interop",
      (o, value) => o.translatorOptions.enableExperimentalWasmInterop = value,
      defaultsTo: _d.translatorOptions.enableExperimentalWasmInterop),
  IntOption(
      "inlining-limit", (o, value) => o.translatorOptions.inliningLimit = value,
      defaultsTo: "${_d.translatorOptions.inliningLimit}"),
  IntOption("shared-memory-max-pages",
      (o, value) => o.translatorOptions.sharedMemoryMaxPages = value),
  UriOption("packages", (o, value) => o.packagesPath = value),
  UriOption("libraries-spec", (o, value) => o.librariesSpecPath = value),
  UriOption("platform", (o, value) => o.platformPath = value),
  IntMultiOption(
      "watch", (o, values) => o.translatorOptions.watchPoints = values),
  StringMultiOption(
      "define", (o, values) => o.environment.addAll(processEnvironment(values)),
      abbr: "D", splitCommas: false),
  StringMultiOption(
      "enable-experiment",
      (o, values) =>
          o.feExperimentalFlags = processFeExperimentalFlags(values)),
  StringOption("multi-root-scheme", (o, value) => o.multiRootScheme = value),
  UriMultiOption("multi-root", (o, values) => o.multiRoots = values),
  StringMultiOption("delete-tostring-package-uri",
      (o, values) => o.deleteToStringPackageUri = values),
  StringOption("depfile", (o, value) => o.depFile = value),
  StringOption(
      "dump-kernel-after-cfe", (o, value) => o.dumpKernelAfterCfe = value,
      hide: true),
  StringOption(
      "dump-kernel-before-tfa", (o, value) => o.dumpKernelBeforeTfa = value,
      hide: true),
  StringOption(
      "dump-kernel-after-tfa", (o, value) => o.dumpKernelAfterTfa = value,
      hide: true),
  Flag("enable-experimental-ffi",
      (o, value) => o.translatorOptions.enableExperimentalFfi = value,
      defaultsTo: _d.translatorOptions.enableExperimentalFfi),
  // Use same flag with dart2js for disabling source maps.
  Flag("no-source-maps",
      (o, value) => o.translatorOptions.generateSourceMaps = !value,
      defaultsTo: !_d.translatorOptions.generateSourceMaps),
  // Options for deferred loading
  Flag("enable-deferred-loading",
      (o, value) => o.translatorOptions.enableDeferredLoading = value,
      defaultsTo: _d.translatorOptions.enableDeferredLoading),
  UriOption("load-ids", (o, value) => o.loadsIdsUri = value),
  UriOption("read-program-split",
      (o, value) => o.programSplitConstraintsUri = value),
  Flag("enable-multi-module-stress-test-mode",
      (o, value) => o.translatorOptions.enableMultiModuleStressTestMode = value,
      defaultsTo: _d.translatorOptions.enableMultiModuleStressTestMode),

  Flag("require-js-string-builtin",
      (o, value) => o.translatorOptions.requireJsStringBuiltin = value,
      defaultsTo: _d.translatorOptions.requireJsStringBuiltin),

  // Flags for dynamic modules
  StringOption("dynamic-module-type",
      (o, value) => o.dynamicModuleType = DynamicModuleType.parse(value)),

  // The modified dill file to be output by the dynamic main module compilation.
  // The dill will contain the AST for the main module as well as some
  // annotations to help identify entities when compiling dynamic submodules.
  UriOption(
      "dynamic-module-main", (o, value) => o.dynamicMainModuleUri = value),

  // A yaml file describing the interface of the main module accessible from
  // dynamic submodules.
  UriOption(
      "dynamic-module-interface", (o, value) => o.dynamicInterfaceUri = value),

  // A binary metadata file produced by the dynamic main module compilation.
  UriOption("dynamic-module-metadata",
      (o, value) => o.dynamicModuleMetadataFile = value),

  Flag("validate-dynamic-modules",
      (o, value) => o.validateDynamicModules = value,
      defaultsTo: true, negatable: true),
  UriOption("wasm-opt", (o, value) => o.wasmOptPath = value),
  // The maximum number of concurrent wasm-opt processes to run. Defaults to the
  // number of processors on the machine. Use -1 to run with no limit.
  IntOption("wasm-opt-process-limit",
      (o, value) => o.maxActiveWasmOptProcesses = value),
  Flag("save-unopt", (o, value) => o.saveUnopt = value),
  Flag("strip-wasm", (o, value) => o.stripWasm = value, negatable: true),
  IntMultiOption("wasm-opt-module-ids",
      (o, value) => o.moduleIdsToOptimize = value.toSet()),
  UriOption("recorded-uses", (o, value) => o.recordedUsesFile = value),
];

Map<fe.ExperimentalFlag, bool> processFeExperimentalFlags(
        List<String> experiments) =>
    fe.parseExperimentalFlags(fe.parseExperimentalArguments(experiments),
        onError: (error) => throw ArgumentError(error),
        onWarning: (warning) => print(warning));

Map<String, String> processEnvironment(List<String> defines) =>
    Map<String, String>.fromEntries(defines.map((d) {
      int index = d.indexOf('=');
      if (index == -1) {
        throw ArgumentError('Bad define string: $d');
      }
      return MapEntry<String, String>(
          d.substring(0, index), d.substring(index + 1));
    }));

WasmCompilerOptions parseArguments(List<String> arguments) {
  args.ArgParser parser = args.ArgParser();
  for (Option arg in options) {
    arg.applyToParser(parser);
  }

  Never usage() {
    print("Usage: dart2wasm [<options>] <infile.dart> <outfile.wasm>");
    print("");
    print("Options:");
    for (String line in parser.usage.split('\n')) {
      print('\t$line');
    }
    exit(64);
  }

  try {
    args.ArgResults results = parser.parse(arguments);
    if (results['help']) {
      usage();
    }
    List<String> rest = results.rest;
    if (rest.length != 2) {
      throw ArgumentError('Requires two positional file arguments');
    }
    WasmCompilerOptions compilerOptions = WasmCompilerOptions(
        mainUri: resolveInputUri(rest[0]), outputFile: rest[1]);
    for (Option arg in options) {
      if (results.wasParsed(arg.name)) {
        arg.applyToOptions(compilerOptions, results[arg.name]);
      }
    }
    if ((compilerOptions.librariesSpecPath == null) ==
        (compilerOptions.platformPath == null)) {
      print('Either --libraries-spec or --platform has to be supplied.');
      usage();
    }
    return compilerOptions;
  } catch (e, s) {
    print(s);
    print('Argument Error: $e');
    usage();
  }
}

Future<int> main(List<String> args) async {
  WasmCompilerOptions options = parseArguments(args);
  return generateWasm(options, errorPrinter: stderr.writeln);
}
