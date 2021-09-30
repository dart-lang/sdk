// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a helper script which performs IL matching for AOT IL tests.
// See runtime/docs/infra/il_tests.md for more information.

import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    throw 'Usage: compare_il <*_il_test.dart> <output.il>';
  }

  final testFile = args[0];
  final ilFile = args[1];

  final graphs = _extractGraphs(ilFile);

  final expectations = _extractExpectations(testFile);

  for (var expectation in expectations.entries) {
    // Find a graph for this expectation. We expect that function names are
    // unique enough to identify a specific graph.
    final graph =
        graphs.entries.singleWhere((e) => e.key.contains(expectation.key));

    // Extract the list of opcodes, ignoring irrelevant things like
    // ParallelMove.
    final gotOpcodesIgnoringMoves = graph.value
        .where((instr) => instr.opcode != 'ParallelMove')
        .map((instr) => instr.opcode)
        .toList();

    // Check that expectations are the prefix of gotOpcodesIgnoringMoves.
    print('Matching ${graph.key}');
    for (var i = 0; i < expectation.value.length; i++) {
      final gotOpcode = gotOpcodesIgnoringMoves[i];
      final expectedOpcode = expectation.value[i];
      if (gotOpcode != expectedOpcode) {
        throw 'Failed to match graph of ${graph.key} to '
            'expectations for ${expectation.key} at instruction ${i}: '
            'got ${gotOpcode} expected ${expectedOpcode}';
      }
    }
    print('... ok');
  }

  exit(0); // Success.
}

// IL instruction extracted from flow graph dump.
class Instruction {
  final String raw;

  Instruction(this.raw);

  String get opcode {
    final match = instructionPattern.firstMatch(raw)!;
    final op = match.namedGroup('opcode')!;
    final blockType = match.namedGroup('block_type');

    // Handle blocks which look like "B%d[%s]".
    if (blockType != null) {
      return blockTypes[blockType]!;
    }

    // Handle parallel moves specially.
    if (op.startsWith('ParallelMove')) {
      return 'ParallelMove';
    }

    // Handle branches.
    if (op.startsWith(branchIfPrefix)) {
      return 'Branch(${op.substring(branchIfPrefix.length)})';
    }

    // Normal instruction.
    return op;
  }

  @override
  String toString() => 'Instruction($opcode)';

  static final instructionPattern = RegExp(
      r'^\s*\d+:\s+(v\d+ <- )?(?<opcode>[^:[(]+(?<block_type>\[[\w ]+\])?)');

  static const blockTypes = {
    '[join]': 'JoinEntry',
    '[target]': 'TargetEntry',
    '[graph]': 'GraphEntry',
    '[function entry]': 'FunctionEntry'
  };

  static const branchIfPrefix = 'Branch if ';
}

Map<String, List<Instruction>> _extractGraphs(String ilFile) {
  final graphs = <String, List<Instruction>>{};

  final reader = LineReader(ilFile);

  var instructions = <Instruction>[];
  while (reader.hasMore) {
    if (reader.testNext('*** BEGIN CFG')) {
      reader.next(); // Skip phase name.
      final functionName = reader.next();
      while (!reader.testNext('*** END CFG')) {
        var curr = reader.next();

        // If instruction line ends with '{' search for a matching '}' (it will
        // be on its own line).
        if (curr.endsWith('{')) {
          do {
            curr += '\n' + reader.current;
          } while (reader.next() != '}');
        }

        instructions.add(Instruction(curr));
      }

      graphs[functionName] = instructions;
      instructions = <Instruction>[];
    } else {
      reader.next();
    }
  }

  return graphs;
}

Map<String, List<String>> _extractExpectations(String testFile) {
  final expectations = <String, List<String>>{};

  final reader = LineReader(testFile);

  final matchILPattern = RegExp(r'^// MatchIL\[AOT\]=(?<value>.*)$');
  final matcherPattern = RegExp(r'^// __ (?<value>.*)$');

  var matchers = <String>[];
  while (reader.hasMore) {
    var functionName = reader.matchNext(matchILPattern);
    if (functionName != null) {
      // Read comment block which follows `// MatchIL[AOT]=...`.
      while (reader.hasMore && reader.current.startsWith('//')) {
        final match = matcherPattern.firstMatch(reader.next());
        if (match != null) {
          matchers.add(match.namedGroup('value')!);
        }
      }
      expectations[functionName] = matchers;
      matchers = <String>[];
    } else {
      reader.next();
    }
  }

  return expectations;
}

class LineReader {
  final List<String> lines;
  int lineno = 0;

  LineReader(String path) : lines = File(path).readAsLinesSync();

  String get current => lines[lineno];

  bool get hasMore => lineno < lines.length;

  String next() {
    final curr = current;
    lineno++;
    return curr;
  }

  bool testNext(String expected) {
    if (current == expected) {
      next();
      return true;
    }
    return false;
  }

  String? matchNext(RegExp pattern) {
    final m = pattern.firstMatch(current);
    return m?.namedGroup('value');
  }
}
