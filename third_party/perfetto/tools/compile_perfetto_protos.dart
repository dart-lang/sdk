// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ffi';

final hostArch = switch (Abi.current()) {
  Abi.linuxArm => 'arm',
  Abi.macosArm64 || Abi.linuxArm64 => 'arm64',
  Abi.macosX64 || Abi.linuxX64 => 'x64',
  _ => throw 'Unsupported platform',
};

Future<void> compilePerfettoProtos() async {
  final processResult = await Process.run('./tools/build.py', [
    '-mdebug',
    '-a$hostArch',
    'third_party/perfetto:perfetto_protos_protozero',
    'third_party/perfetto:perfetto_protos_dart',
  ]);

  final int exitCode = processResult.exitCode;
  final String stdout = processResult.stdout.trim();
  final String stderr = processResult.stderr.trim();
  if (exitCode != 0) {
    print('exit-code: $exitCode');
    print('stdout:');
    print('${stdout}');
    print('stderr:');
    print('${stderr}');
  }
}

const noticesToPrepend = r'''
// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart third_party/perfetto/tools/compile_perfetto_protos.dart` from the
// SDK root directory.
''';

Future<void> copyGeneratedFiles({
  required Directory source,
  required Directory destination,
}) async {
  final executable = 'cp';
  final args = ['-R', source.path, destination.path];
  final processResult = await Process.run(executable, args);

  final int exitCode = processResult.exitCode;
  final String stdout = processResult.stdout.trim();
  final String stderr = processResult.stderr.trim();
  if (exitCode != 0) {
    print('exit-code: $exitCode');
    print('stdout:');
    print('${stdout}');
    print('stderr:');
    print('${stderr}');
  }

  for (final file in Directory(
    '${destination.path}/protos',
  ).listSync(recursive: true)) {
    if (!(file is File &&
        (file.path.endsWith('.pbzero.h') ||
            file.path.endsWith('.pb.dart') ||
            file.path.endsWith('.pbenum.dart') ||
            file.path.endsWith('.pbjson.dart') ||
            file.path.endsWith('.pbserver.dart')))) {
      continue;
    }
    if (file.path.endsWith('.pbenum.dart') &&
        file.readAsStringSync().indexOf('class') == -1) {
      // Sometimes .pbenum.dart files that are effictively empty get generated,
      // so we delete them.
      file.deleteSync();
      continue;
    }

    final contentsIncludingPrependedNotices =
        noticesToPrepend + file.readAsStringSync();
    file.writeAsStringSync(contentsIncludingPrependedNotices, flush: true);
  }
}

void createFileThatExportsAllGeneratedDartCode() {
  final file = File('./pkg/vm_service_protos/lib/vm_service_protos.dart');
  if (!file.existsSync()) {
    file.createSync();
  }
  file.writeAsStringSync(noticesToPrepend + '\n');

  final generatedDartFilePaths =
      Directory('./pkg/vm_service_protos/lib/src/protos/perfetto')
          .listSync(recursive: true)
          .where((entity) => entity is File)
          .map((file) => file.path)
          .toList();
  generatedDartFilePaths.sort();
  for (final path in generatedDartFilePaths) {
    final pathToExport = path.replaceAll('./pkg/vm_service_protos/lib/', '');
    file.writeAsStringSync("export '$pathToExport';\n", mode: FileMode.append);
  }
}

main(List<String> files) async {
  if (!Directory('./third_party/perfetto').existsSync()) {
    print('Error: this tool must be run from the root directory of the SDK.');
    return;
  }

  final outDir = Platform.isMacOS ? 'xcodebuild' : 'out';
  final buildDir = '$outDir/Debug${hostArch.toUpperCase()}';

  await compilePerfettoProtos();
  await copyGeneratedFiles(
    destination: Directory('third_party/perfetto'),
    source: Directory('$buildDir/gen/third_party/perfetto/protos'),
  );
  await copyGeneratedFiles(
    destination: Directory('./pkg/vm_service_protos/lib/src'),
    source: Directory('$buildDir/gen/pkg/vm_service_protos/lib/src/protos'),
  );
  createFileThatExportsAllGeneratedDartCode();
}
