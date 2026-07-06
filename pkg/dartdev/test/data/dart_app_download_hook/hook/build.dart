// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    final packageName = input.packageName;
    if (input.config.code.targetOS == OS.linux) {
      final dylibName = OS.linux.libraryFileName(
        packageName,
        DynamicLoadingBundled(),
      );
      final file = File.fromUri(input.outputDirectory.resolve(dylibName));
      await file.writeAsString('simulated downloaded asset for $packageName');
      output.assets.code.add(
        CodeAsset(
          package: packageName,
          name: 'src/${packageName}_bindings_generated.dart',
          linkMode: DynamicLoadingBundled(),
          file: file.uri,
        ),
      );
    } else {
      throw UnsupportedError('Only linux cross compilation is supported');
    }
  });
}
