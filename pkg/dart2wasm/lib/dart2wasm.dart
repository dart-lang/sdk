// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:front_end/src/api_unstable/vm.dart'
    show printDiagnosticMessage, resolveInputUri;
import 'package:front_end/src/api_unstable/vm.dart' as fe;

import 'package:dart2wasm/compile.dart';
import 'package:dart2wasm/compiler_options.dart';
import 'package:dart2wasm/option.dart';

// Used to allow us to keep defaults on their respective option structs.
final CompilerOptions _d = CompilerOptions.defaultOptions();

final List<Option> options = [
  Flag("help", (o, _) {}, abbr: "h", negatable: false, defaultsTo: false),
  Flag("export-all", (o, value) => o.translatorOptions.exportAll = value,
      defaultsTo: _d.translatorOptions.exportAll),
  Flag("import-shared-memory",
      (o, value) => o.translatorOptions.importSharedMemory = value,
      defaultsTo: _d.translatorOptions.importSharedMemory),
  Flag("inlining", (o, value) => o.translatorOptions.inlining = value,
      defaultsTo: _d.translatorOptions.inlining),
  Flag("name-section", (o, value) => o.translatorOptions.nameSection = value,
      defaultsTo: _d.translatorOptions.nameSection),
  Flag("polymorphic-specialization",
      (o, value) => o.translatorOptions.polymorphicSpecialization = value,
      defaultsTo: _d.translatorOptions.polymorphicSpecialization),
  Flag("print-kernel", (o, value) => o.translatorOptions.printKernel = value,
      defaultsTo: _d.translatorOptions.printKernel),
  Flag("print-wasm", (o, value) => o.translatorOptions.printWasm = value,
      defaultsTo: _d.translatorOptions.printWasm),
  Flag(
      "enable-asserts", (o, value) => o.translatorOptions.enableAsserts = value,
      defaultsTo: _d.translatorOptions.enableAsserts),
  Flag("omit-type-checks",
      (o, value) => o.translatorOptions.omitTypeChecks = value,
      defaultsTo: _d.translatorOptions.omitTypeChecks),
  IntOption(
      "inlining-limit", (o, value) => o.translatorOptions.inliningLimit = value,
      defaultsTo: "${_d.translatorOptions.inliningLimit}"),
  IntOption("shared-memory-max-pages",
      (o, value) => o.translatorOptions.sharedMemoryMaxPages = value),
  UriOption("dart-sdk", (o, value) => o.sdkPath = value,
      defaultsTo: "${_d.sdkPath}"),
  UriOption("packages", (o, value) => o.packagesPath = value),
  UriOption("libraries-spec", (o, value) => o.librariesSpecPath = value),
  UriOption("platform", (o, value) => o.platformPath = value),
  IntMultiOption(
      "watch", (o, values) => o.translatorOptions.watchPoints = values),
  StringMultiOption(
      "define", (o, values) => o.environment = processEnvironment(values),
      abbr: "D"),
  StringMultiOption(
      "enable-experiment",
      (o, values) =>
          o.feExperimentalFlags = processFeExperimentalFlags(values)),
  StringOption("multi-root-scheme", (o, value) => o.multiRootScheme = value),
  UriMultiOption("multi-root", (o, values) => o.multiRoots = values),
  StringOption("depfile", (o, value) => o.depFile = value),
  StringOption(
      "js-runtime-output", (o, value) => o.outputJSRuntimeFile = value),
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

CompilerOptions parseArguments(List<String> arguments) {
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
    CompilerOptions compilerOptions =
        CompilerOptions(mainUri: resolveInputUri(rest[0]), outputFile: rest[1]);
    for (Option arg in options) {
      if (results.wasParsed(arg.name)) {
        arg.applyToOptions(compilerOptions, results[arg.name]);
      }
    }
    return compilerOptions;
  } catch (e, s) {
    print(s);
    print('Argument Error: ' + e.toString());
    usage();
  }
}

Future<int> main(List<String> args) async {
  CompilerOptions options = parseArguments(args);
  CompilerOutput? output = await compileToModule(
      options, (message) => printDiagnosticMessage(message, print));

  if (output == null) {
    exitCode = 1;
    return exitCode;
  }

  await File(options.outputFile).writeAsBytes(output.wasmModule);

  final String outputJSRuntimeFile = options.outputJSRuntimeFile ??
      '${options.outputFile.substring(0, options.outputFile.lastIndexOf('.'))}.mjs';
  await File(outputJSRuntimeFile).writeAsString(output.jsRuntime);

  return 0;
}
