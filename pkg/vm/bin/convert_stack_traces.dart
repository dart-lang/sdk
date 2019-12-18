// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:convert";
import "dart:io" as io;

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:vm/elf/convert.dart';
import 'package:vm/elf/dwarf.dart';

final ArgParser _argParser = new ArgParser(allowTrailingOptions: true)
  ..addOption('elf',
      abbr: 'e',
      help: 'Path to ELF file with debugging information',
      defaultsTo: null,
      valueHelp: 'FILE')
  ..addOption('input',
      abbr: 'i',
      help: 'Path to input file',
      defaultsTo: null,
      valueHelp: 'FILE')
  ..addOption('location',
      abbr: 'l',
      help: 'PC address to convert to a file name and line number',
      defaultsTo: null,
      valueHelp: 'INT')
  ..addOption('output',
      abbr: 'o',
      help: 'Path to output file',
      defaultsTo: null,
      valueHelp: 'FILE')
  ..addFlag('verbose',
      abbr: 'v',
      help: 'Translate all frames, not just frames for user or library code',
      defaultsTo: false);

final String _usage = '''
Usage: convert_stack_traces [options]

Takes text that includes DWARF-based stack traces with PC addresses and
outputs the same text, but with the DWARF stack traces converted to stack traces
that contain function names, file names, and line numbers.

Reads from the file named by the argument to -i/--input as input, or stdin if
no input flag is given.

Outputs the converted contents to the file named by the argument to
-o/--output, or stdout if no output flag is given.

The -e/-elf option must be provided, and DWARF debugging information is
read from the file named by its argument.

When the -v/--verbose option is given, the converter translates all frames, not
just those corresponding to user or library code.

If an -l/--location option is provided, then the file and line number
information for the given location is looked up and output instead.

Options:
${_argParser.usage}
''';

const int _badUsageExitCode = 1;

Future<void> main(List<String> arguments) async {
  final ArgResults options = _argParser.parse(arguments);

  if ((options.rest.length > 0) || (options['elf'] == null)) {
    print(_usage);
    io.exitCode = _badUsageExitCode;
    return;
  }

  int location = null;
  if (options['location'] != null) {
    location = int.tryParse(options['location']);
    if (location == null) {
      // Try adding an initial "0x", as DWARF stack traces don't normally
      // include the hex marker on the PC addresses.
      location = int.tryParse("0x" + options['location']);
    }
    if (location == null) {
      print("Location could not be parsed as an int: ${options['location']}\n");
      print(_usage);
      io.exitCode = _badUsageExitCode;
      return;
    }
  }

  final dwarf = Dwarf.fromFile(options['elf']);

  final output = options['output'] != null
      ? io.File(options['output']).openWrite()
      : io.stdout;
  final verbose = options['verbose'];

  var convertedStream;
  if (location != null) {
    final frames = dwarf
        .callInfo(location, includeInternalFrames: verbose)
        ?.map((CallInfo c) => c.toString());
    if (frames == null) {
      throw "No call information found for PC 0x${location.toRadixString(16)}";
    }
    convertedStream = Stream.fromIterable(frames);
  } else {
    final input = options['input'] != null
        ? io.File(options['input']).openRead()
        : io.stdin;

    convertedStream = input
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(
            DwarfStackTraceDecoder(dwarf, includeInternalFrames: verbose));
  }

  await convertedStream.forEach(output.writeln);
  await output.flush();
  await output.close();
}
