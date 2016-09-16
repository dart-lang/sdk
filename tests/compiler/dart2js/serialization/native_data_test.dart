// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.native_data_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/js_backend/native_data.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import '../memory_compiler.dart';
import 'helper.dart';
import 'test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Arguments arguments = new Arguments.from(args);
    Uri uri = Uris.dart_html;
    if (arguments.filename != null) {
      uri = Uri.base.resolve(nativeToUriPath(arguments.filename));
    }
    await checkNativeData(uri, verbose: arguments.verbose);
  });
}

Future checkNativeData(Uri uri, {bool verbose: false}) async {
  print('------------------------------------------------------------------');
  print('analyze normal: $uri');
  print('------------------------------------------------------------------');
  SerializationResult result = await serialize(uri);
  Compiler compiler1 = result.compiler;
  SerializedData serializedData = result.serializedData;

  print('------------------------------------------------------------------');
  print('analyze deserialized: $uri');
  print('------------------------------------------------------------------');
  Compiler compiler2 = compilerFor(
      memorySourceFiles: serializedData.toMemorySourceFiles(),
      resolutionInputs: serializedData.toUris(),
      options: [Flags.analyzeAll]);
  await compiler2.run(uri);

  JavaScriptBackend backend1 = compiler1.backend;
  JavaScriptBackend backend2 = compiler2.backend;
  NativeData nativeData1 = backend1.nativeData;
  NativeData nativeData2 = backend2.nativeData;

  checkMaps(nativeData1.jsInteropNames, nativeData2.jsInteropNames,
      "NativeData.jsInteropNames", areElementsEquivalent, equality,
      verbose: verbose);

  checkMaps(nativeData1.nativeMemberName, nativeData2.nativeMemberName,
      "NativeData.nativeMemberName", areElementsEquivalent, equality,
      verbose: verbose);

  checkMaps(nativeData1.nativeClassTagInfo, nativeData2.nativeClassTagInfo,
      "NativeData.nativeClassTagInfo", areElementsEquivalent, equality,
      verbose: verbose);

  checkMaps(
      nativeData1.nativeMethodBehavior,
      nativeData2.nativeMethodBehavior,
      "NativeData.nativeMethodBehavior",
      areElementsEquivalent,
      testNativeBehavior,
      verbose: verbose);

  checkMaps(
      nativeData1.nativeFieldLoadBehavior,
      nativeData2.nativeFieldLoadBehavior,
      "NativeData.nativeFieldLoadBehavior",
      areElementsEquivalent,
      testNativeBehavior,
      verbose: verbose);

  checkMaps(
      nativeData1.nativeFieldStoreBehavior,
      nativeData2.nativeFieldStoreBehavior,
      "NativeData.nativeFieldStoreBehavior",
      areElementsEquivalent,
      testNativeBehavior,
      verbose: verbose);
}
