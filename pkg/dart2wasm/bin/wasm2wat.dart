// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

import 'package:wasm_builder/src/serialize/printer.dart';
import 'package:wasm_builder/wasm_builder.dart';

void main(List<String> args) {
  final result = argParser.parse(args);
  if (result.flag('help')) {
    print('Usage: wasm2wat.dart [...options...] <input.wasm>');
    print(argParser.usage);
    exit(0);
  }

  final input = result.rest.single;
  final output = result['output'] as String?;

  List<RegExp> getFilter(String optionName) {
    final filterStrings = result[optionName] as List<String>;
    return [for (final f in filterStrings) RegExp(f)];
  }

  final functionFilters = getFilter('function-name-filter');
  final typeFilters = getFilter('type-name-filter');
  final globalFilters = getFilter('global-name-filter');
  final settings = ModulePrintSettings(
      functionFilters: functionFilters,
      typeFilters: typeFilters,
      globalFilters: globalFilters);

  final wasmBytes = File(input).readAsBytesSync();

  final deserializer = Deserializer(wasmBytes);
  final module = Module.deserialize(deserializer);
  final wat = module.printAsWat(settings: settings);
  if (output != null) {
    File(output).writeAsStringSync(wat);
  } else {
    print(wat);
  }
}

final argParser = ArgParser()
  ..addMultiOption('function-name-filter',
      abbr: 'f',
      help: 'Only print function bodies if the function name matches. '
          'The name filter is interpreted as a Dart `RegExp`.')
  ..addMultiOption('type-name-filter',
      abbr: 't',
      help: 'Only print type constituents if the type name matches. '
          'The name filter is interpreted as a Dart `RegExp`.')
  ..addMultiOption('global-name-filter',
      abbr: 'g',
      help: 'Only print global initializers if the global name matches. '
          'The name filter is interpreted as a Dart `RegExp`.')
  ..addFlag('help', abbr: 'h', help: 'Print the help of this tool.')
  ..addFlag('prefer-multiline',
      abbr: 'm',
      help:
          'Prefer to print global initializers & type definitions as multi line.',
      defaultsTo: /* wami equivalent is false */ false)
  ..addOption('output',
      abbr: 'o',
      help:
          'The filepath where the output will be written to (default: stdout).');
