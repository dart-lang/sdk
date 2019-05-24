// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:compiler/src/commandline_options.dart';

main(List<String> args) async {
  Stopwatch stopwatch = new Stopwatch();
  String input;
  String serializedInput;
  String output = 'out.js';
  List<String> arguments = [];
  int start = 0;
  int stop = 3;
  int shards;
  bool enableAssertions = false;
  for (String arg in args) {
    if (arg.startsWith('-')) {
      if (arg.startsWith('--start=')) {
        start = int.parse(arg.substring('--start='.length));
      } else if (arg.startsWith('--stop=')) {
        stop = int.parse(arg.substring('--stop='.length));
      } else if (arg.startsWith('--shards=')) {
        shards = int.parse(arg.substring('--shards='.length));
      } else if (arg == '-ea' || arg == '--enable_asserts') {
        enableAssertions = true;
      } else if (arg.startsWith('--in=')) {
        serializedInput = arg.substring('--in='.length);
      } else if (arg.startsWith('-o')) {
        output = arg.substring('-o'.length);
      } else if (arg.startsWith('--out=')) {
        output = arg.substring('--out='.length);
      } else {
        arguments.add(arg);
      }
    } else {
      if (input != null) {
        print("Multiple entrypoints provided: '${input}' and '${arg}'.");
        exit(-1);
      }
      input = arg;
    }
  }

  if (input == null) {
    print("No entrypoint provided.");
    exit(-1);
  }

  serializedInput ??= output;

  String inputPrefix = serializedInput;
  if (serializedInput.endsWith('.js')) {
    inputPrefix = output.substring(0, output.length - '.js'.length);
  }
  String outputPrefix = output;
  if (output.endsWith('.js')) {
    outputPrefix = output.substring(0, output.length - '.js'.length);
  }

  List<String> baseOptions = ['--packages=${Platform.packageConfig}'];
  if (enableAssertions) {
    baseOptions.add('--enable_asserts');
  }
  baseOptions.add('package:compiler/src/dart2js.dart');
  baseOptions.addAll(arguments);

  String cfeOutput = '${inputPrefix}0.dill';
  String dillOutput = '${inputPrefix}.dill';
  String dataOutput = '${inputPrefix}.dill.data';
  String codeOutput = '${outputPrefix}.code';
  shards ??= 2;

  stopwatch.start();
  if (start <= 0 && stop >= 0) {
    await subProcess(
        baseOptions, [input, Flags.cfeOnly, '--out=$cfeOutput'], '0:\t');
  }
  if (start <= 1 && stop >= 1) {
    await subProcess(
        baseOptions,
        [cfeOutput, '--out=$dillOutput', '${Flags.writeData}=${dataOutput}'],
        '1:\t');
  }
  if (shards <= 1) {
    await subProcess(
        baseOptions,
        [dillOutput, '${Flags.readData}=${dataOutput}', '--out=${output}'],
        '3:\t');
  } else {
    if (start <= 2 && stop >= 2) {
      List<List<String>> additionalArguments = [];
      List<String> outputPrefixes = [];
      for (int shard = 0; shard < shards; shard++) {
        additionalArguments.add([
          dillOutput,
          '${Flags.readData}=${dataOutput}',
          '${Flags.codegenShard}=$shard',
          '${Flags.codegenShards}=$shards',
          '${Flags.writeCodegen}=${codeOutput}'
        ]);
        outputPrefixes.add('2:${shard + 1}/$shards\t');
      }

      Stopwatch subwatch = new Stopwatch();
      subwatch.start();
      await Future.wait(new List<Future>.generate(shards, (int shard) {
        return subProcess(
            baseOptions, additionalArguments[shard], outputPrefixes[shard]);
      }));
      subwatch.stop();
      print('2:\tTotal time: ${_formatMs(subwatch.elapsedMilliseconds)}');
    }
    if (start <= 3 && stop >= 3) {
      await subProcess(
          baseOptions,
          [
            dillOutput,
            '${Flags.readData}=${dataOutput}',
            '${Flags.readCodegen}=${codeOutput}',
            '${Flags.codegenShards}=$shards',
            '--out=${output}'
          ],
          '3:\t');
    }
  }
  stopwatch.stop();
  print('Total time: ${_formatMs(stopwatch.elapsedMilliseconds)}');
}

Future subProcess(List<String> baseOptions, List<String> additionalOptions,
    String outputPrefix) async {
  List<String> options = []..addAll(baseOptions)..addAll(additionalOptions);
  print(
      '${outputPrefix}Command: ${Platform.resolvedExecutable} ${options.join(' ')}');
  Process process = await Process.start(Platform.resolvedExecutable, options,
      runInShell: true);
  _Prefixer stdoutPrefixer = new _Prefixer(outputPrefix, stdout);
  _Prefixer stderrOutputter = new _Prefixer(outputPrefix, stderr);
  process.stdout.transform(utf8.decoder).listen(stdoutPrefixer);
  process.stderr.transform(utf8.decoder).listen(stderrOutputter);

  int exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}

class _Prefixer {
  final String _prefix;
  final Stdout _stdout;
  bool _atNewLine = true;

  _Prefixer(this._prefix, this._stdout);

  void call(String text) {
    int index = 0;
    while (index < text.length) {
      if (_atNewLine) {
        _stdout.write(_prefix);
        _atNewLine = false;
      }
      int pos = text.indexOf('\n', index);
      if (pos != -1) {
        _stdout.write(text.substring(index, pos + 1));
        _atNewLine = true;
        index = pos + 1;
      } else {
        _stdout.write(text.substring(index));
        index = text.length;
      }
    }
  }
}

String _formatMs(int ms) {
  return (ms / 1000).toStringAsFixed(3) + 's';
}
