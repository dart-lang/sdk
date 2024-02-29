// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart' as utils;

void main() {
  utils.ensureRunFromSdkBinDart();

  group(
    'tooling-daemon',
    () {
      final dartToolingDaemonRegExp = RegExp(
        r'The Dart Tooling Daemon is listening on ws://(127.0.0.1:.*)',
      );
      Process? process;

      tearDown(() {
        process?.kill();
        process = null;
      });

      test('starts up', () async {
        final project = utils.project();
        process = await project.start(['tooling-daemon']);
        final stdout = process!.stdout
            .transform<String>(utf8.decoder)
            .transform<String>(const LineSplitter());

        expect(await stdout.first, contains(dartToolingDaemonRegExp));
      });
    },
    timeout: utils.longTimeout,
  );
}
