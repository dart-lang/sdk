// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

final executable = Platform.executable;

main() async {
  // Run the Dart VM with or without:
  //     --packages=<packages|package_config>
  for (final runWithPackagesArg in const [true, false]) {
    // Run the isolate with or without
    //    Isolate.spawnUri(..., packageConfig: <packages|package_config>)
    print('TEST runWithPackagesArg = $runWithPackagesArg ');
    for (final spawnWithPackageConfig in const [true, false]) {
      print('TEST spawnWithPackageConfig = $spawnWithPackageConfig ');
      final bool checkForResolveUri =
          runWithPackagesArg || !spawnWithPackageConfig;
      await runDotPackagesTest(
          runWithPackagesArg, spawnWithPackageConfig, checkForResolveUri);
      for (final optionalPackageUri in const [true, false]) {
        print('TEST optionalPackageUri = $optionalPackageUri');
        await runPackageConfigTest(runWithPackagesArg, spawnWithPackageConfig,
            optionalPackageUri, checkForResolveUri);
      }
    }
  }
}

Future runPackageConfigTest(bool withPackagesArg, bool spawnWithArg,
    bool optionalPackageUri, bool checkForResolveUri) async {
  await withApplicationDirAndDotDartToolPackageConfig(
      (String tempDir, String packageJson, String mainFile) async {
    final args = [if (withPackagesArg) '--packages=$packageJson', mainFile];
    await run(executable, args);
  }, spawnWithArg, optionalPackageUri, checkForResolveUri);
}

Future runDotPackagesTest(
    bool withPackagesArg, bool spawnWithArg, bool checkForResolveUri) async {
  await withApplicationDirAndDotPackages(
      (String tempDir, String dotPackagesFile, String mainFile) async {
    final args = [
      if (withPackagesArg) '--packages=$dotPackagesFile',
      mainFile,
    ];
    await run(executable, args);
  }, spawnWithArg, checkForResolveUri);
}

Future withApplicationDirAndDotPackages(
    Future fn(String tempDir, String packagesDir, String mainFile),
    bool spawnWithArg,
    bool checkForResolveUri) async {
  await withTempDir((String tempDir) async {
    // Setup ".packages"
    final dotPackagesFile =
        path.join(tempDir, spawnWithArg ? 'baz.packages' : '.packages');
    await File(dotPackagesFile).writeAsString(buildDotPackages('foo'));

    final mainFile = path.join(tempDir, 'main.dart');
    final childIsolateFile = path.join(tempDir, 'child_isolate.dart');
    final importUri = 'package:foo/child_isolate.dart';
    await File(childIsolateFile).writeAsString(buildChildIsolate());
    await File(mainFile).writeAsString(buildMainIsolate(
        importUri,
        spawnWithArg ? dotPackagesFile : null,
        checkForResolveUri ? childIsolateFile : null));

    await fn(tempDir, dotPackagesFile, mainFile);
  });
}

Future withApplicationDirAndDotDartToolPackageConfig(
    Future fn(String tempDir, String packageJson, String mainFile),
    bool spawnWithArg,
    bool optionalPackageUri,
    bool checkForResolveUri) async {
  await withTempDir((String tempDir) async {
    // Setup ".dart_tool/package_config.json"
    final dotDartToolDir = path.join(tempDir, '.dart_tool');
    await Directory(dotDartToolDir).create();
    final packageConfigJsonFile = path.join(
        dotDartToolDir, spawnWithArg ? 'baz.packages' : 'package_config.json');
    await File(packageConfigJsonFile)
        .writeAsString(buildPackageConfig('foo', optionalPackageUri));

    // Setup actual application
    final mainFile = path.join(tempDir, 'main.dart');
    final childIsolateFile = path.join(tempDir, 'child_isolate.dart');
    final importUri = 'package:foo/child_isolate.dart';
    await File(childIsolateFile).writeAsString(buildChildIsolate());
    await File(mainFile).writeAsString(buildMainIsolate(
        importUri,
        spawnWithArg ? packageConfigJsonFile : null,
        checkForResolveUri ? childIsolateFile : null));

    await fn(tempDir, packageConfigJsonFile, mainFile);
  });
}

Future withTempDir(Future fn(String dir)) async {
  final dir = await Directory.systemTemp.createTemp('spawn_uri');
  try {
    await fn(dir.absolute.path);
  } finally {
    await dir.delete(recursive: true);
  }
}

Future<ProcessResult> run(String executable, List<String> args,
    {String cwd}) async {
  print('Running $executable ${args.join(' ')}');
  final String workingDirectory = cwd ?? Directory.current.absolute.path;
  final result = await Process.run(executable, ['--trace-loading', ...args],
      workingDirectory: workingDirectory);
  print('exitCode:\n${result.exitCode}');
  print('stdout:\n${result.stdout}');
  print('stdout:\n${result.stderr}');
  Expect.equals(0, result.exitCode);
  return result;
}

String buildDotPackages(String packageName) => '$packageName:.';

String buildPackageConfig(String packageName, bool optionalPackageUri) => '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "$packageName",
      "rootUri": "../"
      ${optionalPackageUri ? ', "packageUri": "./"' : ''}
    }
  ]
}
''';

String buildChildIsolate() => '''
  import 'dart:isolate';

  main(List<String> args, SendPort message) {
    message.send('child isolate is done');
  }
''';

String buildMainIsolate(
        String spawnUri, String packageConfigUri, String childIsolatePath) =>
    '''
  import 'dart:isolate';
  import 'dart:io' as io;

  main(List<String> args) async {
    io.exitCode = 1;

    final uri = Uri.parse('$spawnUri');
    final resolvedUri = await Isolate.resolvePackageUri(uri);
    if ("""\${resolvedUri?.toFilePath()}""" != r"""$childIsolatePath""") {
      throw 'Could not Isolate.resolvePackageUri(uri).';
    }

    final rp = ReceivePort();
    final isolateArgs = <String>['a'];
    await Isolate.spawnUri(
        uri,
        isolateArgs,
        rp.sendPort,
        packageConfig: ${packageConfigUri != null ? 'Uri.file(r"$packageConfigUri")' : 'null'});
    final childIsolateMessage = await rp.first;
    if (childIsolateMessage != 'child isolate is done') {
      throw 'Did not receive correct message from child isolate.';
    }

    // Test was successful.
    io.exitCode = 0;
  }
''';
