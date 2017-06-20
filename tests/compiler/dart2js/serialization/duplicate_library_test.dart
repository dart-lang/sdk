// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.duplicate_libraryc_test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/names.dart';
import '../memory_compiler.dart';
import 'helper.dart';

void main(List<String> args) {
  asyncTest(() async {
    SerializedData data =
        await serializeDartCore(arguments: new Arguments.from(args));
    Map<String, String> sourceFiles = data.toMemorySourceFiles();
    List<Uri> resolutionInputs = data.toUris();
    Uri extraUri = Uri.parse('memory:extraUri');
    sourceFiles[extraUri.path] = data.data;
    resolutionInputs.add(extraUri);

    DiagnosticCollector collector = new DiagnosticCollector();
    await runCompiler(
        entryPoint: Uris.dart_core,
        memorySourceFiles: sourceFiles,
        resolutionInputs: resolutionInputs,
        diagnosticHandler: collector,
        options: [Flags.analyzeAll]);
    Expect.isTrue(collector.errors.isNotEmpty,
        "Expected duplicate serialized library errors.");
  });
}
