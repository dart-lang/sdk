// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:heapsnapshot/src/cli.dart';
import 'package:heapsnapshot/src/console.dart';

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

class CompletionKeyHandler extends KeyHandler {
  final CliState cliState;
  CompletionKeyHandler(this.cliState);

  bool handleKey(LineEditBuffer buffer, Key lastPressed) {
    if (lastPressed.isControl &&
        lastPressed.controlChar == ControlCharacter.tab &&
        buffer.completionText.isNotEmpty) {
      buffer.insert(buffer.completionText);
      buffer.completionText = '';
      return true;
    }

    buffer.completionText = '';

    if (!lastPressed.isControl) {
      final incomplete = buffer.text.substring(0, buffer.index);
      final complete = cliCommandRunner.completeCommand(cliState, incomplete);
      if (complete != null) {
        if (!complete.startsWith(incomplete)) {
          throw 'CompletionError: Suggestion "$complete" does not start with "$incomplete".';
        }
        if (complete.length > incomplete.length) {
          buffer.completionText = complete.substring(incomplete.length);
        }
      }
    }
    return false;
  }
}

Future<void> main(List<String> args) async {
  final console = SmartConsole();

  console.write('The ');
  console.setForegroundColor(ConsoleColor.brightYellow);
  console.write('Dart VM *.heapsnapshot analysis tool');
  console.resetColorAttributes();
  console.writeLine('');

  console.writeLine('Type `exit` or use Ctrl+D to exit.');
  console.writeLine('');

  final errors = ConsoleErrorPrinter(console);
  final cliState = CliState(errors);

  console.completionHandler = CompletionKeyHandler(cliState);

  if (args.isNotEmpty) {
    if (args.length == 1 && args.single.trim().isNotEmpty) {
      console.setForegroundColor(ConsoleColor.brightYellow);
      console.writeLine('Will try to load ${args.single.trim()}.');
      console.resetColorAttributes();
      console.writeLine('');
      if (await cliCommandRunner.run(cliState, ['load', args.single.trim()])) {
        return;
      }
    } else {
      console.setForegroundColor(ConsoleColor.brightRed);
      console.writeLine('When giving arguments, only one argument - '
          'the snapshot to load - is supported. Ignoring arguments.');
      console.resetColorAttributes();
      console.writeLine('');
    }
  }

  while (true) {
    final response = console.smartReadLine();
    console.resetColorAttributes();
    if (response.shouldExit) return;
    if (response.wasCancelled) {
      console.write(console.newLine);
      continue;
    }

    final args = response.text
        .split(' ')
        .map((p) => p.trim())
        .where((p) => !p.isEmpty)
        .toList();
    if (args.isEmpty) continue;

    if (await cliCommandRunner.run(cliState, args)) {
      return;
    }
  }
}
