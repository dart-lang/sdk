#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:dart2native/dart2native.dart';
import 'package:path/path.dart' as path;

final String executableSuffix = Platform.isWindows ? '.exe' : '';
final String snapshotDir = path.dirname(Platform.script.toFilePath());
final String binDir = path.canonicalize(path.join(snapshotDir, '..'));
final String sdkDir = path.canonicalize(path.join(binDir, '..'));
final String dart = path.join(binDir, 'dart${executableSuffix}');
final String genKernel = path.join(snapshotDir, 'gen_kernel.dart.snapshot');
final String dartaotruntime =
    path.join(binDir, 'dartaotruntime${executableSuffix}');
final String genSnapshot =
    path.join(binDir, 'utils', 'gen_snapshot${executableSuffix}');
final String platformDill =
    path.join(sdkDir, 'lib', '_internal', 'vm_platform_strong.dill');

Future<void> generateNative(
    Kind kind,
    String sourceFile,
    String outputFile,
    String packages,
    List<String> defines,
    bool enableAsserts,
    bool verbose) async {
  final Directory tempDir = Directory.systemTemp.createTempSync();
  try {
    final String kernelFile = path.join(tempDir.path, 'kernel.dill');
    final String snapshotFile = (kind == Kind.aot
        ? outputFile
        : path.join(tempDir.path, 'snapshot.aot'));

    if (verbose) {
      print('Generating AOT kernel dill.');
    }
    final kernelResult = await generateAotKernel(dart, genKernel, platformDill,
        sourceFile, kernelFile, packages, defines);
    if (kernelResult.exitCode != 0) {
      stderr.writeln(kernelResult.stdout);
      stderr.writeln(kernelResult.stderr);
      await stderr.flush();
      throw 'Generating AOT kernel dill failed!';
    }

    if (verbose) {
      print('Generating AOT snapshot.');
    }
    final snapshotResult = await generateAotSnapshot(
        genSnapshot, kernelFile, snapshotFile, enableAsserts);
    if (snapshotResult.exitCode != 0) {
      stderr.writeln(snapshotResult.stdout);
      stderr.writeln(snapshotResult.stderr);
      await stderr.flush();
      throw 'Generating AOT snapshot failed!';
    }

    if (kind == Kind.exe) {
      if (verbose) {
        print('Generating executable.');
      }
      await writeAppendedExecutable(dartaotruntime, snapshotFile, outputFile);

      if (Platform.isLinux || Platform.isMacOS) {
        if (verbose) {
          print('Marking binary executable.');
        }
        await markExecutable(outputFile);
      }
    }

    print('Generated: ${outputFile}');
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void printUsage(final ArgParser parser) {
  print('''
Usage: dart2native <main-dart-file> [<options>]

Generates an executable or an AOT snapshot from <main-dart-file>.
''');
  print(parser.usage);
}

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser()
    ..addMultiOption('define', abbr: 'D', valueHelp: 'key=value', help: '''
Set values of environment variables.
To specify multiple variables, use multiple flags or use commas to separate pairs.
Example:
dart2native -Da=1,b=2 -Dc=3 --define=d=4 main.dart''')
    ..addFlag('enable-asserts',
        negatable: false, help: 'Enable assert statements.')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Displays this help message.')
    ..addOption('output',
        abbr: 'o', valueHelp: 'path', help: 'Put the output in file <path>.')
    ..addOption('output-kind',
        abbr: 'k',
        allowed: ['exe', 'aot'],
        defaultsTo: 'exe',
        valueHelp: 'exe|aot',
        help: 'Generate a standalone executable or an AOT snapshot.')
    ..addOption('packages',
        abbr: 'p', valueHelp: 'path', help: 'Use the .packages file at <path>.')
    ..addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Show verbose output.');

  ArgResults parsedArgs;
  try {
    parsedArgs = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    await stderr.flush();
    printUsage(parser);
    exit(1);
  }

  if (parsedArgs['help']) {
    printUsage(parser);
    exit(0);
  }

  if (parsedArgs.rest.length != 1) {
    printUsage(parser);
    exit(1);
  }

  final Kind kind = {
    'aot': Kind.aot,
    'exe': Kind.exe,
  }[parsedArgs['output-kind']];

  final sourcePath = path.canonicalize(path.normalize(parsedArgs.rest[0]));
  final outputPath =
      path.canonicalize(path.normalize(parsedArgs['output'] != null
          ? parsedArgs['output']
          : {
              Kind.aot: '${sourcePath}.aot',
              Kind.exe: '${sourcePath}.exe',
            }[kind]));

  if (!FileSystemEntity.isFileSync(sourcePath)) {
    stderr.writeln(
        '"${sourcePath}" is not a file. See \'--help\' for more information.');
    await stderr.flush();
    exit(1);
  }

  try {
    await generateNative(
        kind,
        sourcePath,
        outputPath,
        parsedArgs['packages'],
        parsedArgs['define'],
        parsedArgs['enable-asserts'],
        parsedArgs['verbose']);
  } catch (e) {
    stderr.writeln('Failed to generate native files:');
    stderr.writeln(e);
    await stderr.flush();
    exit(1);
  }
}
