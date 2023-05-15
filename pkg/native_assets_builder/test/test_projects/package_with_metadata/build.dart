// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_assets_cli/native_assets_cli.dart';

const packageName = 'native_add';

void main(List<String> args) async {
  final buildConfig = await BuildConfig.fromArgs(args);
  final buildOutput = BuildOutput(
    metadata: Metadata({
      'some_key': 'some_value',
      'some_int': 3,
    }),
  );
  await buildOutput.writeToFile(outDir: buildConfig.outDir);
}
