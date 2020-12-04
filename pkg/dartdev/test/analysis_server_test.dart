// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/analysis_server.dart';
import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('AnalysisServer', () {
    TestProject p;

    setUp(() {
      log = Logger.standard();
      p = project();
    });

    tearDown(() => p?.dispose());

    test('can start', () async {
      AnalysisServer server = AnalysisServer(io.Directory(sdk.sdkPath), p.dir);
      await server.start();
      await server.shutdown();
    });

    test('can send message', () async {
      AnalysisServer server = AnalysisServer(io.Directory(sdk.sdkPath), p.dir);
      await server.start();

      final response = await server.getVersion();
      expect(response, isNotEmpty);

      await server.shutdown();
    });
  });
}
