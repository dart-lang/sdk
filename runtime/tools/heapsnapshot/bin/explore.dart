// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_console/dart_console.dart';
import 'package:heapsnapshot/src/cli.dart';

class ConsoleErrorPrinter extends Output {
  final Console console;

  ConsoleErrorPrinter(this.console);

  void printError(String error) {
    console.writeErrorLine(error);
  }

  void print(String message) {
    console.writeLine(message);
  }
}

void main() async {
  final console = Console.scrolling();

  console.write('The ');
  console.setForegroundColor(ConsoleColor.brightYellow);
  console.write('Dart VM *.heapsnapshot analysis tool');
  console.resetColorAttributes();
  console.writeLine('');

  console.writeLine('Type `exit` or use Ctrl+D to exit.');
  console.writeLine('');

  final errors = ConsoleErrorPrinter(console);
  final cliState = CliState(errors);

  while (true) {
    void writePrompt() {
      console.setForegroundColor(ConsoleColor.brightBlue);
      console.write('(hsa) ');
      console.resetColorAttributes();
      console.setForegroundColor(ConsoleColor.brightGreen);
    }

    writePrompt();
    final response = console.readLine(cancelOnEOF: true);
    console.resetColorAttributes();
    if (response == null) return;
    if (response.isEmpty) continue;

    final args = response
        .split(' ')
        .map((p) => p.trim())
        .where((p) => !p.isEmpty)
        .toList();
    if (args.isEmpty) continue;
    if (args.length == 1 && args.single == 'exit') {
      return;
    }

    await cliCommandRunner.run(cliState, args);
  }
}
