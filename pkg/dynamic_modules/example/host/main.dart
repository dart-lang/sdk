// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A simple calculator command-line program.
///
/// To demonstrate the value of dynamic modules, only addition is supported as a
/// built-in operation. The calculator is extensible and new operations can be
/// loaded dynamically through dynamic modules.
///
/// This library is the entrypoint of the host application. That means this code
/// is compiled ahead of time and optimized. Only declarations mentioned in
/// `dynamic_interface.yaml` are exposed to dynamic modules that can be loaded
/// later.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dynamic_modules/dynamic_modules.dart';
import '../common/common.dart';

void main(List<String> args) async {
  // Use a directory to find dynamic modules when requested.
  if (args.length != 1) {
    print('Usage: dart main.dart <modules_directory>');
    exit(1);
  }
  final modulesDir = Directory(args[0]);
  if (!modulesDir.existsSync()) {
    print('Error: Directory ${modulesDir.path} does not exist.');
    exit(1);
  }

  final registry = CalculatorRegistry();
  registry.addOperation(AdditionOperation());

  print('Calculator started. Type "help" for instructions.');
  void showPrompt() {
    stdout.write('\n > ');
    stdout.flush();
  }

  showPrompt();

  await for (String line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed == 'exit' || trimmed == 'quit') {
      break;
    }
    if (trimmed == 'help') {
      print('Instructions:');
      print('  load <name>            - Loads <modules_dir>/<name>.bytecode');
      print('  <op> <arg1> <arg2> ... - Applies operation <op> to arguments');
      print('  exit                   - Exits the calculator');
      showPrompt();
      continue;
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    final command = parts[0];

    if (command == 'load') {
      if (parts.length != 2) {
        print('Error: Invalid load command. Usage: load <module_name>');
        showPrompt();
        continue;
      }
      final moduleName = parts[1];
      // NOTE: A real application should have additional checks to ensure files
      // are loaded from a safe location (e.g. safe folder, using TLS if loaded
      // from the network, etc).
      final file = File.fromUri(modulesDir.uri.resolve('$moduleName.bytecode'));
      if (!file.existsSync()) {
        print('Error: Module file ${file.uri} not found.');
        showPrompt();
        continue;
      }

      try {
        final bytes = await file.readAsBytes();
        // NOTE: this API is about to be removed and replaced with a different API
        // that requires provenance validation.
        final entrypointResult = await loadModuleFromBytes(
          Uint8List.fromList(bytes),
        );

        // We established an implicit contract: dynamic modules for the
        // calculator must return a function of this type.
        if (entrypointResult is void Function(Registry)) {
          entrypointResult(registry);
        } else {
          print(
            'Error: Invalid module entrypoint result type: ${entrypointResult.runtimeType}',
          );
        }
      } catch (e) {
        print('Error loading module: $e');
      }
      showPrompt();
    } else {
      // Any other name is looked up as an operation in the registry.
      final op = registry.operations[command];
      if (op == null) {
        print('Error: Unknown operation "$command"');
        showPrompt();
        continue;
      }

      final args = <num>[];
      var valid = true;
      for (var i = 1; i < parts.length; i++) {
        final argStr = parts[i];
        num? val = num.tryParse(argStr);
        if (val == null) {
          final constantOp = registry.operations[argStr];
          if (constantOp != null) {
            try {
              val = constantOp.apply([]);
            } catch (_) {}
          }
        }
        if (val == null) {
          print(
            'Error: Invalid argument "$argStr", must be a number or constant.',
          );
          valid = false;
          break;
        }
        args.add(val);
      }
      if (!valid) {
        showPrompt();
        continue;
      }

      try {
        final result = op.apply(args);
        print('Result: $result');
      } catch (e) {
        print('Error executing operation: $e');
      }
      showPrompt();
    }
  }
}

/// Registry where all operations will be accumulated.
///
/// This is the registry implementation that will be provided to dynamic moduels
/// to register their operations. Even though we only expose the abstract method
/// [Registry.addOperation], the compiler knows that the implementation in this
/// class is a potential target and must be treated as an exposed function of
/// this application.
class CalculatorRegistry implements Registry {
  final Map<String, Operation> operations = {};

  @override
  void addOperation(Operation op) {
    if (operations.containsKey(op.name)) {
      print("Warning: Overwriting operation '${op.name}'");
    }
    operations[op.name] = op;
    print("Registered operation: ${op.name}");
  }
}

/// The built-in addition operation.
///
/// This is the only operation supported upfront before loading dynamic modules.
class AdditionOperation implements Operation {
  @override
  String get name => '+';

  @override
  num apply(List<num> arguments) {
    return arguments.fold(0, (sum, val) => sum + val);
  }
}
