// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:front_end/src/api_unstable/vm.dart'
    show printDiagnosticMessage, resolveInputUri;

import 'package:dart2wasm/compile.dart';
import 'package:dart2wasm/translator.dart';

final Map<String, void Function(TranslatorOptions, bool)> boolOptionMap = {
  "export-all": (o, value) => o.exportAll = value,
  "inlining": (o, value) => o.inlining = value,
  "lazy-constants": (o, value) => o.lazyConstants = value,
  "local-nullability": (o, value) => o.localNullability = value,
  "name-section": (o, value) => o.nameSection = value,
  "nominal-types": (o, value) => o.nominalTypes = value,
  "parameter-nullability": (o, value) => o.parameterNullability = value,
  "polymorphic-specialization": (o, value) =>
      o.polymorphicSpecialization = value,
  "print-kernel": (o, value) => o.printKernel = value,
  "print-wasm": (o, value) => o.printWasm = value,
  "runtime-types": (o, value) => o.runtimeTypes = value,
  "string-data-segments": (o, value) => o.stringDataSegments = value,
};
final Map<String, void Function(TranslatorOptions, int)> intOptionMap = {
  "watch": (o, value) => (o.watchPoints ??= []).add(value),
};

Never usage(String message) {
  print("Usage: dart2wasm [<options>] <infile.dart> <outfile.wasm>");
  print("");
  print("Options:");
  print("  --dart-sdk=<path>");
  print("");
  for (String option in boolOptionMap.keys) {
    print("  --[no-]$option");
  }
  print("");
  for (String option in intOptionMap.keys) {
    print("  --$option <value>");
  }
  print("");

  throw message;
}

Future<int> main(List<String> args) async {
  Uri sdkPath = Platform.script.resolve("../../../sdk");
  TranslatorOptions options = TranslatorOptions();
  List<String> nonOptions = [];
  void Function(TranslatorOptions, int)? intOptionFun = null;
  for (String arg in args) {
    if (intOptionFun != null) {
      intOptionFun(options, int.parse(arg));
      intOptionFun = null;
    } else if (arg.startsWith("--dart-sdk=")) {
      String path = arg.substring("--dart-sdk=".length);
      sdkPath = Uri.file(Directory(path).absolute.path);
    } else if (arg.startsWith("--no-")) {
      var optionFun = boolOptionMap[arg.substring(5)];
      if (optionFun == null) usage("Unknown option $arg");
      optionFun(options, false);
    } else if (arg.startsWith("--")) {
      var optionFun = boolOptionMap[arg.substring(2)];
      if (optionFun != null) {
        optionFun(options, true);
      } else {
        intOptionFun = intOptionMap[arg.substring(2)];
        if (intOptionFun == null) usage("Unknown option $arg");
      }
    } else {
      nonOptions.add(arg);
    }
  }
  if (intOptionFun != null) {
    usage("Missing argument to ${args.last}");
  }

  if (nonOptions.length != 2) usage("Requires two file arguments");
  String input = nonOptions[0];
  String output = nonOptions[1];
  Uri mainUri = resolveInputUri(input);

  Uint8List? module = await compileToModule(mainUri, sdkPath, options,
      (message) => printDiagnosticMessage(message, print));

  if (module == null) {
    exitCode = 1;
    return exitCode;
  }

  await File(output).writeAsBytes(module);

  return 0;
}
