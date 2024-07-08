// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart';
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:front_end/src/api_unstable/dart2js.dart'
    show computePlatformBinariesLocation;

main(List<String> args) {
  asyncTest(() async {
    Directory dir = await Directory.systemTemp.createTemp('on_disk');
    Uri dillUri = dir.uri.resolve('out.dill');
    Uri closedWorldUri = dir.uri.resolve('world.data');
    Uri globalInferenceUri = dir.uri.resolve('global.data');
    Uri outUri = dir.uri.resolve('out.js');
    String buildRoot =
        computePlatformBinariesLocation(forceBuildDir: true).toFilePath();
    var commonArgs = [
      Flags.verbose,
      '--libraries-spec=$sdkLibrariesSpecificationUri',
      '--no-sound-null-safety',
      // Unsound platform dill files are no longer packaged in the SDK and must
      // be read from the build directory during tests.
      '--platform-binaries=$buildRoot',
      '${Flags.closedWorldUri}=$closedWorldUri',
      '${Flags.globalInferenceUri}=$globalInferenceUri',
    ];
    await internalMain([
          'pkg/compiler/test/codesize/swarm/swarm.dart',
          '${Flags.stage}=cfe',
          '--out=${dillUri}',
        ] +
        commonArgs);
    await internalMain([
          'pkg/compiler/test/codesize/swarm/swarm.dart',
          '${Flags.inputDill}=$dillUri',
          '${Flags.stage}=closed-world',
        ] +
        commonArgs);
    await internalMain([
          '$dillUri',
          '${Flags.stage}=global-inference',
          '--out=${outUri}',
        ] +
        commonArgs);
    await internalMain([
          '$dillUri',
          '${Flags.stage}=codegen-emit-js',
          '--out=${outUri}',
        ] +
        commonArgs);
    await dir.delete(recursive: true);
  });
}
