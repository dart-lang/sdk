// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2wasm/dev/compile.dart';

Future<void> main(List<String> args) async {
  Uri? platformPath;
  Uri? librariesSpecPath;
  final rest = <String>[];

  for (final arg in args) {
    if (arg.startsWith('--platform=')) {
      platformPath = Uri.base.resolveUri(
        Uri.file(arg.substring('--platform='.length)),
      );
    } else if (arg.startsWith('--libraries-spec=')) {
      librariesSpecPath = Uri.base.resolveUri(
        Uri.file(arg.substring('--libraries-spec='.length)),
      );
    } else {
      rest.add(arg);
    }
  }

  if (rest.length != 2) {
    stderr.writeln(
      'Usage: dart2wasm_dev.dart [options] <input.dart> <output.wasm>',
    );
    exit(64);
  }

  final mainUri = Uri.base.resolveUri(Uri.file(rest[0]));
  final outputPath = rest[1];
  File(outputPath).writeAsBytesSync(
    await compile(
      mainUri,
      platformPath: platformPath,
      librariesSpecPath: librariesSpecPath,
    ),
  );
}
