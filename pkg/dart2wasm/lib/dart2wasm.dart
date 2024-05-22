// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:front_end/src/api_unstable/vm.dart' show resolveInputUri;
import 'package:front_end/src/api_unstable/vm.dart' as fe;

import 'generate_wasm.dart';
import 'option.dart';

// Used to allow us to keep defaults on their respective option structs.
// Note: When adding new options, consider if CLI options should be add
// to `pkg/dartdev/lib/src/commands/compile.dart` too.
final WasmCompilerOptions _d = WasmCompilerOptions.defaultOptions();

final List<Option> options = [
  Flag("help", (o, _) {}, abbr: "h", negatable: false, defaultsTo: false),
  Flag("export-all", (o, value) => o.translatorOptions.exportAll = value,
      defaultsTo: _d.translatorOptions.exportAll),
  Flag("import-shared-memory",
      (o, value) => o.translatorOptions.importSharedMemory = value,
      defaultsTo: _d.translatorOptions.importSharedMemory),
  Flag("inlining", (o, value) => o.translatorOptions.inlining = value,
      defaultsTo: _d.translatorOptions.inlining),
  Flag("minify", (o, value) => o.translatorOptions.minify = value,
      defaultsTo: _d.translatorOptions.minify),
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
      (o, value) => o.translatorOptions.omitImplicitTypeChecks = value,
      defaultsTo: _d.translatorOptions.omitImplicitTypeChecks),
  // TODO(http://dartbug.com/54675): Deprecate & Remove this one.
  Flag("omit-type-checks", (o, value) {
    o.translatorOptions.omitImplicitTypeChecks = value;
    o.translatorOptions.omitExplicitTypeChecks = value;
  },
      defaultsTo: _d.translatorOptions.omitImplicitTypeChecks &&
          _d.translatorOptions.omitExplicitTypeChecks),
  Flag("omit-bounds-checks", (o, value) {
    o.translatorOptions.omitBoundsChecks = value;
  }, defaultsTo: _d.translatorOptions.omitBoundsChecks),
  Flag("verbose", (o, value) => o.translatorOptions.verbose = value,
      defaultsTo: _d.translatorOptions.verbose),
  Flag("verify-type-checks",
      (o, value) => o.translatorOptions.verifyTypeChecks = value,
      defaultsTo: _d.translatorOptions.verifyTypeChecks),
  IntOption(
      "inlining-limit", (o, value) => o.translatorOptions.inliningLimit = value,
      defaultsTo: "${_d.translatorOptions.inliningLimit}"),
  IntOption("shared-memory-max-pages",
      (o, value) => o.translatorOptions.sharedMemoryMaxPages = value),
  StringOption("dart-sdk", (o, value) {
    /* ignored: Remove when flutter no longer passes this. */
  }, defaultsTo: null, hide: true),
  UriOption("packages", (o, value) => o.packagesPath = value),
  UriOption("libraries-spec", (o, value) => o.librariesSpecPath = value),
  UriOption("platform", (o, value) => o.platformPath = value),
  IntMultiOption(
      "watch", (o, values) => o.translatorOptions.watchPoints = values),
  StringMultiOption(
      "define", (o, values) => o.environment.addAll(processEnvironment(values)),
      abbr: "D"),
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
      "js-runtime-output", (o, value) => o.outputJSRuntimeFile = value),
  StringOption(
      "dump-kernel-after-cfe", (o, value) => o.dumpKernelAfterCfe = value,
      hide: true),
  StringOption(
      "dump-kernel-before-tfa", (o, value) => o.dumpKernelBeforeTfa = value,
      hide: true),
  StringOption(
      "dump-kernel-after-tfa", (o, value) => o.dumpKernelAfterTfa = value,
      hide: true),
];

Map<fe.ExperimentalFlag, bool> processFeExperimentalFlags(
        List<String> experiments) =>
    fe.parseExperimentalFlags(fe.parseExperimentalArguments(experiments),
        onError: (error) => throw ArgumentError(error),
        onWarning: (warning) => print(warning));

Map<String, String> processEnvironment(List<String> defines) =>
    Map<String, String>.fromEntries(defines.map((d) {
      List<String> keyAndValue = d.split('=');
      if (keyAndValue.length != 2) {
        throw ArgumentError('Bad define string: $d');
      }
      return MapEntry<String, String>(keyAndValue[0], keyAndValue[1]);
    }));

WasmCompilerOptions parseArguments(List<String> arguments) {
  args.ArgParser parser = args.ArgParser();
  for (Option arg in options) {
    arg.applyToParser(parser);
  }

  Never usage() {
    print("Usage: dart2wasm [<options>] <infile.dart> <outfile.wasm>");
    print("");
    print("*NOTE*: Wasm compilation is experimental.");
    print("The support may change, or be removed, with no advance notice.");
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
