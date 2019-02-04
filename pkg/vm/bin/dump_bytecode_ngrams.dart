// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:vm/bytecode/ngrams.dart';

final ArgParser _argParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('basic-blocks',
      help: 'Only allow control flow as the last instruction in a window',
      defaultsTo: true)
  ..addOption('output',
      abbr: 'o', help: 'Path to output file', defaultsTo: null)
  ..addFlag('merge-pushes',
      help: 'Do not distinguish among different kinds of Push opcodes',
      defaultsTo: false)
  ..addFlag('sort',
      abbr: 's', help: 'Sort the output by ngram frequency', defaultsTo: true)
  ..addOption('threshold',
      abbr: 't', help: 'Minimum ngram count threshold', defaultsTo: "1")
  ..addOption('window', abbr: 'w', help: 'Window size', defaultsTo: "3");

final String _usage = '''
Usage: dump_bytecode_ngrams [options] input.trace

Dumps stats about a dynamic bytecode instruction trace produced with the
Dart VM option --interpreter-trace-file, e.g.:

\$ dart --enable-interpreter --interpreter-trace-file=trace program.dart

Options:
${_argParser.usage}
''';

const int _badUsageExitCode = 1;

int main(List<String> arguments) {
  final ArgResults options = _argParser.parse(arguments);
  if ((options.rest.length != 1) || (options['output'] == null)) {
    print(_usage);
    return _badUsageExitCode;
  }

  final basicBlocks = options['basic-blocks'];
  final input = options.rest.single;
  final output = options['output'];
  final mergePushes = options['merge-pushes'];
  final windowSize = int.parse(options['window']);
  final sort = options['sort'];
  final threshold = int.parse(options['threshold']);

  if (!(new io.File(input).existsSync())) {
    print("The file '$input' does not exist");
    print(_usage);
    return _badUsageExitCode;
  }

  NGramReader nGramReader = new NGramReader(input);
  nGramReader.readAllNGrams(windowSize,
      basicBlocks: basicBlocks, mergePushes: mergePushes);
  nGramReader.writeNGramStats(output, sort: sort, minCount: threshold);
  return 0;
}
