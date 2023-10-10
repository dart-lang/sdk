// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:heap_snapshot/analysis.dart';
import 'package:heapsnapshot/src/cli.dart';
import 'package:path/path.dart' as path;

import 'package:test/test.dart';

class FakeAnalysis implements Analysis {
  @override
  final IntSet roots = IntSet();

  @override
  dynamic noSuchMethod(Invocation i) {}
}

main() {
  late CliState cliState;

  String? complete(String text) =>
      cliCommandRunner.completeCommand(cliState, text);

  group('cli-completion no snapshot loaded', () {
    setUp(() {
      cliState = CliState(CompletionCollector());
    });

    // <...incomplete-load-command...>
    test('complete load command', () {
      expect(complete('l'), 'load');
    });

    // <...incomplete-stats-command...> fails
    test('complete stats command fails', () {
      // Since there was no snapshot loaded, commands operating on loaded
      // snapshot should not auto-complete yet.
      expect(complete('s'), null);
    });

    // load <...incomplete-file...>
    test('complete incomplete file', () {
      final snapshotDir = Directory.systemTemp.createTempSync('snapshot');
      try {
        final file = path.join(snapshotDir.path, 'foobar.heapsnapshot');
        File(file).createSync();

        // Ensure auto-complete works for files.
        expect(complete('load ${path.join(snapshotDir.path, 'fo')}'),
            'load $file');
      } finally {
        snapshotDir.deleteSync(recursive: true);
      }
    });
  });

  group('cli-completion snapshot loaded', () {
    setUp(() {
      cliState = CliState(CompletionCollector());
      cliState.initialize(FakeAnalysis());
    });

    // <...incomplete-command...>
    test('complete command', () {
      expect(complete('s'), 'stats');
    });

    // <command> <...incomplete-option...>
    test('complete command short option', () {
      expect(complete('stats -'), 'stats -c');
    });
    test('complete command long option', () {
      expect(complete('stats --m'), 'stats --max');
    });

    // <command> <...incomplete-args...>
    test('complete command arg', () {
      cliState.namedSets.nameSet({1}, 'foobar');
      expect(complete('stats f'), 'stats foobar');
    });

    // <expr>
    test('complete default eval command', () {
      cliState.namedSets.nameSet({1}, 'foobar');
      expect(complete('foo'), 'foobar');
    });
  });

  group('cli-completion meta commands', () {
    setUp(() {
      cliState = CliState(CompletionCollector());
    });

    test('complete short-help', () {
      expect(complete('h'), 'h');
    });
    test('complete long-help', () {
      expect(complete('he'), 'help');
    });
    test('complete short-help-command', () {
      expect(complete('h lo'), 'h load');
    });
    test('complete long-help-command', () {
      expect(complete('help lo'), 'help load');
    });

    test('complete exit', () {
      expect(complete('e'), 'exit');
    });
    test('complete short-quit', () {
      expect(complete('q'), 'q');
    });
    test('complete long-quit', () {
      expect(complete('qu'), 'quit');
    });
  });
}
