// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main(List<String> args) async {
  // Change to package root so relative paths work in CI
  final scriptDir = p.dirname(p.fromUri(Platform.script));
  final packageRoot = p.dirname(scriptDir);
  Directory.current = packageRoot;

  try {
    watch.start();
    if (args.isNotEmpty) {
      throw ArgumentError('No command line args are supported');
    }

    final packagesPath = findNearestPackageConfigPath();
    final client = await FrontendServerClient.start(
      'org-dartlang-root:///$app',
      outputDill,
      p.join(sdkDir, 'lib', '_internal', 'vm_platform_strong.dill'),
      packagesJson: packagesPath ?? '.dart_tool/package_config.json',
      target: 'vm',
      // Use an absolute filesystem root so org-dartlang-root:/// URIs resolve reliably in CI
      fileSystemRoots: [Directory.current.path],
      fileSystemScheme: 'org-dartlang-root',
      verbose: true,
    );
    _print('compiling $app');
    var result = await client.compile();
    client.accept();
    _print('done compiling $app');

    Process appProcess;
    final vmServiceCompleter = Completer<VmService>();
    appProcess = await Process.start(Platform.resolvedExecutable, [
      '--enable-vm-service=0',
      result.dillOutput!,
    ]);
    final sawHelloWorld = Completer<void>();
    appProcess.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stdout.writeln('APP -> $line');
          if (line == 'hello/world') {
            sawHelloWorld.complete();
          }
          if (line.startsWith(
            'The Dart DevTools debugger and profiler is available at:',
          )) {
            final observatoryUri =
                '${line.split(' ').last.replaceFirst('http', 'ws')}ws';
            if (!vmServiceCompleter.isCompleted) {
              vmServiceCompleter.complete(vmServiceConnectUri(observatoryUri));
            }
          }
        });
    appProcess.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stderr.writeln('APP -> $line');
        });

    final vmService = await vmServiceCompleter.future;
    await sawHelloWorld.future;

    _print('editing $app');
    final appFile = File(app);
    final originalContent = await appFile.readAsString();
    final newContent = originalContent.replaceFirst('hello', 'goodbye');
    await appFile.writeAsString(newContent);

    _print('recompiling $app with edits');
    result = await client.compile([Uri.parse('org-dartlang-root:///$app')]);
    client.accept();
    _print('done recompiling $app');
    _print('reloading $app');
    final vm = await vmService.getVM();
    await vmService.reloadSources(
      vm.isolates!.first.id!,
      rootLibUri: result.dillOutput!,
    );

    _print('restoring $app to original contents');
    await appFile.writeAsString(originalContent);
    _print('exiting');
    await client.shutdown().timeout(
      const Duration(seconds: 1),
      onTimeout: () {
        client.kill();
        return 1;
      },
    );
  } finally {
    Directory(p.join('.dart_tool', 'out')).deleteSync(recursive: true);
  }
}

void _print(String message) {
  print('${watch.elapsed}: $message');
}

final app = 'example/app/main.dart';
final outputDill = p.join('.dart_tool', 'out', 'example_app.dill');
final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
final watch = Stopwatch();
