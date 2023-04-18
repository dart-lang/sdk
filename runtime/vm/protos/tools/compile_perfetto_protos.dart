// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

Future<void> compilePerfettoProtos() async {
  final processResult = await Process.run(
    './tools/build.py',
    ['-mdebug', '-ax64', '--no-goma', 'runtime/vm:perfetto_protos'],
  );

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

Future<void> copyPerfettoProtoHeaders() async {
  final copySource = Directory('./out/DebugX64/gen/runtime/vm/protos').path;
  final copyDestination = Directory('./runtime/vm').path;

  late final executable;
  late final args;
  if (Platform.operatingSystem == 'windows') {
    executable = 'xcopy';
    args = [copySource, copyDestination, '/e', '/i'];
  } else {
    executable = 'cp';
    args = ['-R', copySource, copyDestination];
  }
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

  for (final file
      in Directory('./runtime/vm/protos').listSync(recursive: true)) {
    if (!(file is File) || !file.path.endsWith('.pbzero.h')) {
      continue;
    }
    final contentsIncludingPrependedNotices = r'''
// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: This file should only ever be modified by modifying the
// corresponding .proto file and then running
// `dart runtime/vm/protos/tools/compile_perfetto_protos.dart` from the SDK root
// directory.
''' +
        file.readAsStringSync();
    file.writeAsStringSync(contentsIncludingPrependedNotices, flush: true);
  }
}

main(List<String> files) async {
  if (!Directory('./runtime/vm').existsSync()) {
    print('Error: this tool must be run from the root directory of the SDK.');
    return;
  }
  await compilePerfettoProtos();
  await copyPerfettoProtoHeaders();
}
