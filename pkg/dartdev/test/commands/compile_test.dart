// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:dart2native/dart2native_macho.dart' show pipeStream;
import 'package:dart2native/macho.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

const int compileErrorExitCode = 64;

void main() {
  ensureRunFromSdkBinDart();

  group('compile -', defineCompileTests, timeout: longTimeout);
}

const String soundNullSafetyMessage = 'Info: Compiling with sound null safety';
const String unsoundNullSafetyMessage =
    'Info: Compiling without sound null safety';
const String unsoundNullSafetyError =
    'Error: the flag --no-sound-null-safety is not supported in Dart 3.';
const String unsoundNullSafetyWarning =
    'Warning: the flag --no-sound-null-safety is deprecated and pending removal.';
String usingTargetOSMessageForPlatform(String targetOS) =>
    'Specializing Platform getters for target OS $targetOS.';
final String usingTargetOSMessage =
    usingTargetOSMessageForPlatform(Platform.operatingSystem);
String crossOSNotAllowedError(String command) =>
    "'dart compile $command' does not support cross-OS compilation.";
final String hostOSMessage = 'Host OS: ${Platform.operatingSystem}';
String targetOSMessage(String targetOS) => 'Target OS: $targetOS';

void defineCompileTests() {
  final isRunningOnIA32 = Platform.version.contains('ia32');

  if (Platform.isMacOS) {
    test('Compile exe for MacOS signing', () async {
      final p = project(mainSrc: '''void main() {}''');
      final inFile =
          path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
      final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

      var result = await p.run(
        [
          'compile',
          'exe',
          '-o',
          outFile,
          inFile,
        ],
      );

      expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(outFile).existsSync(), true,
          reason: 'File not found: $outFile');

      if (!MachOFile.containsSnapshot(File(outFile))) {
        throw FormatException('Snapshot not found in standalone executable');
      }

      // Ensure that the exe can be signed.
      final codeSigningProcess = await Process.start('codesign', [
        '-o',
        'runtime',
        '-s',
        '-',
        outFile,
      ]);

      final signingResult = await codeSigningProcess.exitCode;
      expect(signingResult, 0);
    }, skip: isRunningOnIA32);

    test('Changing snapshot contents fails to validate', () async {
      final p = project(mainSrc: '''void main() {}''');
      final inFile =
          path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
      final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));
      final corruptedFile =
          path.canonicalize(path.join(p.dirPath, 'myexe-corrupted'));

      var result = await p.run(
        [
          'compile',
          'exe',
          '-o',
          outFile,
          inFile,
        ],
      );

      expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(File(outFile).existsSync(), true,
          reason: 'File not found: $outFile');

      final macho = MachOFile.fromFile(File(outFile));
      final snapshotNote = macho.snapshotNote;
      if (snapshotNote == null) {
        throw FormatException('Snapshot not found in standalone executable');
      }

      if (macho.hasCodeSignature) {
        // Verify the resulting executable using codesign.
        result = Process.runSync('codesign', [
          '-v',
          outFile,
        ]);

        expect(result.stderr, isEmpty);
        expect(result.exitCode, 0);
      } else {
        // Sign the executable first.
        final codeSigningProcess = await Process.start('codesign', [
          '-o',
          'runtime',
          '-s',
          '-',
          outFile,
        ]);

        final signingResult = await codeSigningProcess.exitCode;
        expect(signingResult, 0);
      }

      // Pick a random range of bytes within the snapshot.
      final rand = Random();
      final offset1 = rand.nextInt(snapshotNote.fileSize);
      final offset2 = rand.nextInt(snapshotNote.fileSize);
      final int start = snapshotNote.fileOffset + min(offset1, offset2);
      final int size = max(offset1, offset2) - min(offset1, offset2);

      // Write the corrupted version of the executable, corrupting the bytes in
      // the calculated range by incrementing them (modulo 256).
      final original = File(outFile).openSync();
      final corrupted = File(corruptedFile).openSync(mode: FileMode.write);
      await pipeStream(original, corrupted, numToWrite: start);
      final bytesToCorrupt = original.readSync(size);
      for (int i = 0; i < bytesToCorrupt.length; i++) {
        bytesToCorrupt[i] = (bytesToCorrupt[i] + 1) % 256;
      }
      corrupted.writeFromSync(bytesToCorrupt);
      await pipeStream(original, corrupted);

      // (Fail to) verify the resulting executable using codesign.
      result = Process.runSync('codesign', [
        '-v',
        corruptedFile,
      ]);

      expect(result.stderr, isNotEmpty);
      expect(result.exitCode, 1);
    }, skip: isRunningOnIA32);
  }

  // *** NOTE ***: These tests *must* be run with the `--use-sdk` option
  // as they depend on a fully built SDK to resolve various snapshot files
  // used by compilation.
  test('Running from built SDK', () {
    final Directory binDir = File(Platform.resolvedExecutable).parent;
    expect(binDir.path, contains('bin'));
  });

  test('Implicit --help', () async {
    final p = project();
    var result = await p.run(
      [
        'compile',
      ],
    );
    expect(result.stderr, contains('Compile Dart'));
    expect(result.exitCode, compileErrorExitCode);
  });

  test('--help', () async {
    final p = project();
    final result = await p.run(
      ['compile', '--help'],
    );
    expect(result.stdout, contains('Compile Dart'));
    expect(
      result.stdout,
      contains(
        'Usage: dart compile <subcommand> [arguments]',
      ),
    );

    expect(result.stdout, contains('jit-snapshot'));
    expect(result.stdout, contains('kernel'));
    expect(result.stdout, contains('js'));
    expect(result.stdout, contains('aot-snapshot'));
    expect(result.stdout, contains('exe'));
    expect(result.exitCode, 0);
  });

  test('--help --verbose', () async {
    final p = project();
    final result = await p.run(
      ['compile', '--help', '--verbose'],
    );
    expect(result.stdout, contains('Compile Dart'));
    expect(
      result.stdout,
      contains(
        'Usage: dart [vm-options] compile <subcommand> [arguments]',
      ),
    );
    expect(result.exitCode, 0);
  });

  test('Compile and run jit snapshot', () async {
    final p = project(mainSrc: 'void main() { print("I love jit"); }');
    final outFile = path.join(p.dirPath, 'main.jit');
    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '-o',
        outFile,
        p.relativeFilePath,
      ],
    );
    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    result = await p.run(['run', 'main.jit']);
    expect(result.stdout, contains('I love jit'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile and run jit snapshot with environment variables', () async {
    final p = project(mainSrc: '''
        void main() {
          print('1: ' + const String.fromEnvironment('foo'));
          print('2: ' + const String.fromEnvironment('bar'));
        }''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'main.jit'));

    var result = await p.run([
      'compile',
      'jit-snapshot',
      '-Dfoo=bar',
      '--define=bar=foo',
      '-o',
      outFile,
      '-v',
      inFile,
    ]);
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);
    final file = File(outFile);
    expect(file.existsSync(), true, reason: 'File not found: $outFile');

    result = await p.run(['run', 'main.jit']);

    // Ensure the -D and --define arguments were processed correctly.
    expect(result.stdout, contains('1: bar'));
    expect(result.stdout, contains('2: foo'));
  });

  Future<void> basicCompileTest() async {
    final p = project(mainSrc: 'void main() { print("I love executables"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'lib', 'main.exe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '-v',
        inFile,
      ],
    );

    // Executables should be (host) OS-specific by default.
    expect(result.stdout, contains(usingTargetOSMessage));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    result = Process.runSync(
      outFile,
      [],
    );

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('I love executables'));
  }

  test('Compile and run executable', basicCompileTest, skip: isRunningOnIA32);

  test('Compile to executable disabled on IA32', () async {
    final p = project(mainSrc: 'void main() { print("I love executables"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));

    var result = await p.run(
      [
        'compile',
        'exe',
        inFile,
      ],
    );

    expect(result.stderr,
        "'dart compile exe' is not supported on x86 architectures");
    expect(result.exitCode, 64);
  }, skip: !isRunningOnIA32);

  test('Compile to AOT snapshot disabled on IA32', () async {
    final p = project(mainSrc: 'void main() { print("I love executables"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        inFile,
      ],
    );

    expect(result.stderr,
        "'dart compile aot-snapshot' is not supported on x86 architectures");
    expect(result.exitCode, 64);
  }, skip: !isRunningOnIA32);

  test('Compile and run executable with options', () async {
    final p = project(
        mainSrc: 'void main() {print(const String.fromEnvironment("life"));}');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '-v',
        '--define',
        'life=42',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, contains(usingTargetOSMessage));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    result = Process.runSync(
      outFile,
      [],
    );

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('42'));
  }, skip: isRunningOnIA32);

  test('Compile executable cannot compile cross-OS', () async {
    final p = project(
        mainSrc: 'void main() {print(const String.fromEnvironment("cross"));}');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));
    final targetOS = Platform.isLinux ? 'macos' : 'linux';

    var result = await p.run(
      [
        'compile',
        'exe',
        '-v',
        '--target-os',
        targetOS,
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stderr, contains(crossOSNotAllowedError('exe')));
    expect(result.stderr, contains(hostOSMessage));
    expect(result.stderr, contains(targetOSMessage(targetOS)));
    expect(result.exitCode, 128);
  }, skip: isRunningOnIA32);

  test('Compile and run aot snapshot', () async {
    final p = project(mainSrc: 'void main() { print("I love AOT"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'main.aot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '-v',
        '-o',
        'main.aot',
        inFile,
      ],
    );

    // AOT snapshots should not be OS-specific by default.
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    final Directory binDir = File(Platform.resolvedExecutable).parent;
    result = Process.runSync(
      path.join(binDir.path, 'dartaotruntime'),
      [outFile],
    );

    expect(result.stdout, contains('I love AOT'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: isRunningOnIA32);

  test('Compile aot snapshot can compile to host platform', () async {
    final targetOS = Platform.operatingSystem;
    final p = project(mainSrc: 'void main() { print("I love $targetOS"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'main.aot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '-v',
        '--target-os',
        targetOS,
        '-o',
        'main.aot',
        inFile,
      ],
    );

    expect(result.stdout, contains(usingTargetOSMessageForPlatform(targetOS)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    final Directory binDir = File(Platform.resolvedExecutable).parent;
    result = Process.runSync(
      path.join(binDir.path, 'dartaotruntime'),
      [outFile],
    );

    expect(result.stdout, contains('I love $targetOS'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: isRunningOnIA32);

  test('Compile aot snapshot can compile cross platform', () async {
    final targetOS = Platform.isLinux ? 'windows' : 'linux';
    final p = project(mainSrc: 'void main() { print("I love $targetOS"); }');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'main.aot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '-v',
        '--target-os',
        targetOS,
        '-o',
        'main.aot',
        inFile,
      ],
    );

    expect(result.stdout, contains(usingTargetOSMessageForPlatform(targetOS)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    final Directory binDir = File(Platform.resolvedExecutable).parent;
    result = Process.runSync(
      path.join(binDir.path, 'dartaotruntime'),
      [outFile],
    );

    expect(result.stdout, contains('I love $targetOS'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: isRunningOnIA32);

  test('Compile and run kernel snapshot', () async {
    final p = project(mainSrc: 'void main() { print("I love kernel"); }');
    final outFile = path.join(p.dirPath, 'main.dill');
    var result = await p.run(
      [
        'compile',
        'kernel',
        '-v',
        '-o',
        outFile,
        p.relativeFilePath,
      ],
    );
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);

    result = await p.run(['run', 'main.dill']);
    expect(result.stdout, contains('I love kernel'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile JS', () async {
    final p = project(mainSrc: '''
        void main() {
          print('1: ' + const String.fromEnvironment('foo'));
          print('2: ' + const String.fromEnvironment('bar'));
        }''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'main.js'));

    final result = await p.run([
      'compile',
      'js',
      '-m',
      '-Dfoo=bar',
      '--define=bar=foo',
      '-o',
      outFile,
      '-v',
      inFile,
    ]);
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    final file = File(outFile);
    expect(file.existsSync(), true, reason: 'File not found: $outFile');

    // Ensure the -D and --define arguments were processed correctly.
    final contents = file.readAsStringSync();
    expect(contents.contains('1: bar'), true);
    expect(contents.contains('2: foo'), true);
  });

  test('Compile exe with error', () async {
    final p = project(mainSrc: '''
void main() {
  int? i;
  i.isEven;
}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('Error: '));
    // The CFE doesn't print to stderr, so all output is piped to stderr, even
    // including info-only output:
    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, compileErrorExitCode);
    expect(File(outFile).existsSync(), false,
        reason: 'File not found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile exe with warnings', () async {
    final p = project(mainSrc: '''
void main() {
  int i = 0;
  i?.isEven;
}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, contains('Warning: '));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile exe with sound null safety', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile exe with unsound null safety', () async {
    final p = project(mainSrc: '''
void main() {}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '--no-sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, contains(unsoundNullSafetyError));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 64);
    expect(File(outFile).existsSync(), false, reason: 'File found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile and run exe with --sound-null-safety', () async {
    final p = project(mainSrc: '''void main() {
      print((<int?>[] is List<int>) ? 'oh no' : 'sound');
    }''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '--sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');

    result = Process.runSync(
      outFile,
      [],
    );

    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('sound'));
  }, skip: isRunningOnIA32);

  test('Compile exe without info', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    // Only printed when -v/--verbose is used, not --verbosity.
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile exe without warnings', () async {
    final p = project(mainSrc: '''
void main() {
  int i = 0;
  i?.isEven;
}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myexe'));

    var result = await p.run(
      [
        'compile',
        'exe',
        '--verbosity=error',
        '-o',
        outFile,
        inFile,
      ],
    );

    // Only printed when -v/--verbose is used, not --verbosity.
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: isRunningOnIA32);

  test('Compile JS with sound null safety', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjs'));

    var result = await p.run(
      [
        'compile',
        'js',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile JS with unsound null safety', () async {
    final p = project(mainSrc: '''
// @dart=2.9
void main() {}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjs'));

    var result = await p.run(
      [
        'compile',
        'js',
        '--no-sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, contains(unsoundNullSafetyError));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 1);
    expect(File(outFile).existsSync(), false,
        reason: 'File not found: $outFile');
  });

  test('Compile JS without info', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjs'));

    var result = await p.run(
      [
        'compile',
        'js',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile JS without warnings', () async {
    final p = project(mainSrc: '''
void main() {
  int i = 0;
  i?.isEven;
}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjs'));

    var result = await p.run(
      [
        'compile',
        'js',
        '--verbosity=error',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('Compile AOT snapshot with sound null safety', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myaot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile AOT snapshot with unsound null safety', () async {
    final p = project(mainSrc: '''
void main() {}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myaot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '--no-sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, contains(unsoundNullSafetyMessage));
    expect(result.stdout, contains(unsoundNullSafetyWarning));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile AOT snapshot without info', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myaot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    // Only printed when -v/--verbose is used, not --verbosity.
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  }, skip: isRunningOnIA32);

  test('Compile AOT snapshot without warnings', () async {
    final p = project(mainSrc: '''
void main() {
  int i = 0;
  i?.isEven;
}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myaot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '--verbosity=error',
        '-o',
        outFile,
        inFile,
      ],
    );

    // Only printed when -v/--verbose is used, not --verbosity.
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: isRunningOnIA32);

  test('Compile AOT snapshot with warnings', () async {
    final p = project(mainSrc: '''
void main() {
  int i = 0;
  i?.isEven;
}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myaot'));

    var result = await p.run(
      [
        'compile',
        'aot-snapshot',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    // Only printed when -v/--verbose is used, not --verbosity.
    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stdout, contains('Warning: '));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: isRunningOnIA32);

  test('Compile kernel with invalid output directory', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--verbosity=warning',
        '-o',
        '/somewhere/nowhere/test.dill',
        inFile,
      ],
    );
    expect(
      result.stderr,
      predicate(
        (dynamic o) => '$o'.contains('Unable to open file'),
      ),
    );
    expect(result.exitCode, 255);
  });

  test('Compile kernel with invalid trailing argument', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
        'invalid-arg',
      ],
    );

    expect(result.stdout, isEmpty);
    expect(
      result.stderr,
      predicate(
        (dynamic o) =>
            '$o'.contains('Unexpected arguments after Dart entry point.'),
      ),
    );
    expect(result.exitCode, 64);
    expect(File(outFile).existsSync(), false, reason: 'File found: $outFile');
  });

  test('Compile kernel with default (sound null safety)', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '-v',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(usingTargetOSMessage)));
    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile kernel with unsound null safety', () async {
    final p = project(mainSrc: '''
void main() {}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--no-sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, contains(unsoundNullSafetyMessage));
    expect(result.stdout, contains(unsoundNullSafetyWarning));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile kernel with --sound-null-safety', () async {
    final p = project(mainSrc: '''void main() {
      print((<int?>[] is List<int>) ? 'oh no' : 'sound');
    }''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile kernel with --no-sound-null-safety', () async {
    final p = project(mainSrc: '''void main() {
      print((<int?>[] is List<int>) ? 'unsound' : 'oh no');
    }''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--no-sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.stdout, contains(unsoundNullSafetyWarning));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile kernel without info', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile kernel without warning', () async {
    final p = project(mainSrc: '''
void main() {
    int i;
    i?.isEven;
}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--verbosity=error',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, contains('must be assigned before it can be used'));
    expect(result.exitCode, 254);
  });

  test('Compile kernel with warnings', () async {
    final p = project(mainSrc: '''
void main() {
    int i = 0;
    i?.isEven;
}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'kernel',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, contains('Warning:'));
    expect(result.exitCode, 0);
  });

  test('Compile JIT snapshot with default (sound null safety)', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjit'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile JIT snapshot with unsound null safety', () async {
    final p = project(mainSrc: '''
void main() {}
''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjit'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '--no-sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stdout, contains(unsoundNullSafetyError));
    expect(result.exitCode, 64);
    expect(File(outFile).existsSync(), false, reason: 'File found: $outFile');
  });

  test('Compile JIT snapshot with --sound-null-safety', () async {
    final p = project(mainSrc: '''void main() {
      print((<int?>[] is List<int>) ? 'oh no' : 'sound');
    }''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjit'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '--sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile JIT snapshot with --no-sound-null-safety', () async {
    final p = project(mainSrc: '''void main() {
      print((<int?>[] is List<int>) ? 'unsound' : 'oh no');
    }''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'mydill'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '--no-sound-null-safety',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.stdout, contains(unsoundNullSafetyError));
    expect(result.exitCode, 64);
    expect(File(outFile).existsSync(), false, reason: 'File found: $outFile');
  });

  test('Compile JIT snapshot with training args', () async {
    final p =
        project(mainSrc: '''void main(List<String> args) => print(args);''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjit'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '-o',
        outFile,
        inFile,
        'foo',
        // Ensure training args aren't parsed by the CLI.
        // See https://github.com/dart-lang/sdk/issues/49302
        '-e',
        '--foobar=bar',
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.stdout,
        predicate((dynamic o) => '$o'.contains('[foo, -e, --foobar=bar]')));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile JIT snapshot without info', () async {
    final p = project(mainSrc: '''void main() {}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjit'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.exitCode, 0);
    expect(File(outFile).existsSync(), true,
        reason: 'File not found: $outFile');
  });

  test('Compile JIT snapshot without warnings', () async {
    final p = project(mainSrc: '''
void main() {
    int i;
    i?.isEven;
}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjit'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '--verbosity=error',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, contains('must be assigned before it can be used'));
    expect(result.exitCode, 254);
  });

  test('Compile JIT snapshot with warnings', () async {
    final p = project(mainSrc: '''
void main() {
    int i = 0;
    i?.isEven;
}''');
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outFile = path.canonicalize(path.join(p.dirPath, 'myjit'));

    var result = await p.run(
      [
        'compile',
        'jit-snapshot',
        '--verbosity=warning',
        '-o',
        outFile,
        inFile,
      ],
    );

    expect(result.stderr, isNot(contains(soundNullSafetyMessage)));
    expect(result.stderr, contains('Warning:'));
    expect(result.exitCode, 0);
  });

  if (Platform.isMacOS) {
    test('Compile and run executable from signed dartaotruntime', () async {
      // Either the locally built dartaotruntime is already linker signed
      // (on M1) or it is unsigned (on X64). For this test, sign the
      // dartaotruntime executable with a non-linker signed adhoc signature,
      // which won't cause issues with any other tests that use it. This
      // ensures the code signing path in dart2native is exercised on X64
      // (macOS <11.0), and also mimics the case for end users that are using
      // the published Dart SDK (which is fully signed, not linker signed).
      final Directory binDir = File(Platform.resolvedExecutable).parent;
      final String originalRuntimePath =
          path.join(binDir.path, 'dartaotruntime');
      final codeSigningProcess = await Process.start('codesign', [
        '-o',
        'runtime',
        '-s',
        '-',
        originalRuntimePath,
      ]);

      final signingResult = await codeSigningProcess.exitCode;
      expect(signingResult, 0);

      // Now perform the same basic compile and run test with the signed
      // dartaotruntime.
      await basicCompileTest();
    }, skip: isRunningOnIA32);
  }
}
