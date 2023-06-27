// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:async';
import 'dart:io' show Directory, File, InternetAddress, stdin;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:vm/incremental_compiler.dart' show IncrementalCompiler;

import 'frontend_server.dart';
import 'src/binary_protocol.dart';
import 'src/resident_frontend_server.dart';

/// Entry point for this module, that creates either a `_FrontendCompiler`
/// instance or a `ResidentFrontendServer` instance and
/// processes user input.
/// `compiler` is an optional parameter so it can be replaced with mocked
/// version for testing.
Future<int> starter(
  List<String> args, {
  CompilerInterface? compiler,
  Stream<List<int>>? input,
  StringSink? output,
  IncrementalCompiler? generator,
  BinaryPrinterFactory? binaryPrinterFactory,
}) async {
  ArgResults options;
  try {
    options = argParser.parse(args);
  } catch (error) {
    print('ERROR: $error\n');
    print(usage);
    return 1;
  }
  if (options['resident-info-file-name'] != null) {
    var serverSubscription = await residentListenAndCompile(
        InternetAddress.loopbackIPv4,
        0,
        File(options['resident-info-file-name']));
    return serverSubscription == null ? 1 : 0;
  }

  if (options['train']) {
    if (options.rest.isEmpty) {
      throw Exception('Must specify input.dart');
    }

    final String input = options.rest[0];
    final String sdkRoot = options['sdk-root'];
    final String? platform = options['platform'];
    final Directory temp =
        Directory.systemTemp.createTempSync('train_frontend_server');
    try {
      final String outputTrainingDill = path.join(temp.path, 'app.dill');
      final List<String> args = <String>[
        '--incremental',
        '--sdk-root=$sdkRoot',
        '--output-dill=$outputTrainingDill',
      ];
      if (platform != null) {
        args.add('--platform=${Uri.file(platform)}');
      }
      options = argParser.parse(args);
      compiler ??=
          FrontendCompiler(output, printerFactory: binaryPrinterFactory);

      await compiler.compile(input, options, generator: generator);
      compiler.acceptLastDelta();
      await compiler.recompileDelta();
      compiler.acceptLastDelta();
      compiler.resetIncrementalCompiler();
      await compiler.recompileDelta();
      compiler.acceptLastDelta();
      await compiler.recompileDelta();
      compiler.acceptLastDelta();
      return 0;
    } finally {
      temp.deleteSync(recursive: true);
    }
  }

  final binaryProtocolAddressStr = options['binary-protocol-address'];
  if (binaryProtocolAddressStr is String) {
    await runBinaryProtocol(binaryProtocolAddressStr);
    return 0;
  }

  compiler ??= FrontendCompiler(
    output,
    printerFactory: binaryPrinterFactory,
    unsafePackageSerialization: options["unsafe-package-serialization"],
    incrementalSerialization: options["incremental-serialization"],
    useDebuggerModuleNames: options['debugger-module-names'],
    emitDebugMetadata: options['experimental-emit-debug-metadata'],
    emitDebugSymbols: options['emit-debug-symbols'],
    canaryFeatures: options['dartdevc-canary'],
  );

  if (options.rest.isNotEmpty) {
    return await compiler.compile(options.rest[0], options,
            generator: generator)
        ? 0
        : 254;
  }

  Completer<int> completer = Completer<int>();
  var subscription = listenAndCompile(
      compiler, input ?? stdin, options, completer,
      generator: generator);
  return completer.future.then((value) {
    subscription.cancel();
    return value;
  });
}
