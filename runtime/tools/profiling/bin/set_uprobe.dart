// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:profiling/src/elf_utils.dart';

// TODO(vegorov): update this to support Android ARM64 both for standalone
// binaries and Flutter applications. Prototype code for that is available
// in https://dart-review.googlesource.com/c/sdk/+/239661.
void main(List<String> args) async {
  if (args.length != 3) {
    print(
        'Usage: pkg/vm/tool/set_uprobe.dart <probe-name> <symbol> <AOT snapshot SO file>');
    exit(-1);
  }

  final [probeName, symbol, sharedObject] = args;

  final uprobeAddress =
      await _computeProbesVirtualAddress(sharedObject, symbol);
  final loadingBias = loadingBiasOf(sharedObject);

  final uprobeFileOffset = (uprobeAddress + loadingBias).toRadixString(16);

  final soName = p.basename(sharedObject);
  final soPath = p.canonicalize(p.absolute(sharedObject));

  // TODO(vegorov) ARM64 support
  final threadRegister = "r14";
  final resultRegister = "ax";

  final uprobeFormat = symbol == 'AllocationProbePoint'
      ? 'addr=%$resultRegister:s64 top=+${await _getThreadTopOffset()}(%$threadRegister):s64 cid=-1(%$resultRegister):b20@12/32'
      : '';

  final probe = 'p:$probeName $soPath:0x$uprobeFileOffset $uprobeFormat';
  print(probe);

  File('/sys/kernel/tracing/uprobe_events').writeAsStringSync(probe);
}

Future<int> _computeProbesVirtualAddress(
    String sharedObject, String targetSymbol) async {
  int offset = 0;
  if (targetSymbol == 'AllocationProbePoint') {
    offset = await _determineAllocProbeOffset(sharedObject);
  }

  final targetRe = RegExp('\\b$targetSymbol\\b');
  final matches = <String, int>{
    for (final (:addr, :name) in textSymbolsOf(sharedObject))
      if (targetRe.hasMatch(name)) name: addr,
  };

  if (matches.isEmpty) {
    throw 'Symbol $targetSymbol not found in $sharedObject';
  }

  if (matches.length != 1) {
    throw 'Multiple symbols match: ${matches.keys}';
  }

  final entry = matches.entries.single;
  print('placing uprobe on ${entry.key} at '
      '0x${entry.value.toRadixString(16)}+$offset');
  return entry.value + offset;
}

// `AllocationProbePoint` stub should have a probe placed at a place where
// stack frame is properly setup so that unwinding succeeds. The stub itself
// contains a dummy test immediate instruction which encodes the offset at
// which the probe should be placed.
Future<int> _determineAllocProbeOffset(String sharedObject) async {
  // Dump SO file to get the address of the interesting symbol.
  final disassembly = await _exec('llvm-objdump', [
    '--disassemble-symbols=stub AllocationProbePoint',
    '-Mintel',
    sharedObject,
  ]);

  // We are looking for `test al, imm` or `tst x0, #imm` where `imm` is a
  // hexadecimal immediate encoding offset to the probe point within the stub.
  final pattern = RegExp(
      r'^\s+[a-f0-9]+:(( [a-f0-9]{2})+| [a-f0-9]{8})\s+(test|tst)\s+(al|x0),\s+#?0x(?<offset>[0-9a-f]+)\s*$',
      multiLine: true);

  final match = pattern.firstMatch(disassembly);
  if (match == null) {
    print(disassembly);
    throw StateError(
        'failed to find test-immediate instruction encoding the probe offset');
  }

  return int.parse(match.namedGroup('offset')!, radix: 16);
}

Future<String> _getThreadTopOffset() async {
  // TODO(vegorov) ARM64 support
  final sdkSrc = Platform.script.resolve('../../../..').toFilePath();
  await _exec(
      'ninja', ['-C', 'out/ReleaseX64', '-j1000', '-l64', 'offsets_extractor'],
      workingDirectory: sdkSrc);
  final offsets =
      await _exec(p.join(sdkSrc, 'out/ReleaseX64/offsets_extractor'), []);
  final line = offsets
      .split('\n')
      .firstWhere((line) => line.contains('Thread_top_offset'));
  final offset = RegExp(r' = (?<offset>0x[a-f\d]+);$')
      .firstMatch(line)!
      .namedGroup('offset')!;

  return int.parse(offset).toString();
}

Future<String> _exec(String executable, List<String> args,
    {String? workingDirectory}) async {
  final result =
      await Process.run(executable, args, workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw StateError('''
Failed to run $executable ${args.join(' ')}
stdout:
${result.stdout}

stderr:

${result.stderr}
''');
  }
  return result.stdout as String;
}
