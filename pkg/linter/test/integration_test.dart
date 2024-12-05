// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:test/test.dart';

import '../tool/checks/check_all_yaml.dart';
import '../tool/checks/check_messages_yaml.dart';
import 'mocks.dart';

void main() {
  group('integration', () {
    group('config', () {
      var currentOut = outSink;
      var collectingOut = CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });
    });

    group('examples', () {
      test('all.yaml', () {
        var errors = checkAllYaml();
        if (errors != null) {
          fail(errors);
        }
      });
    });

    test('messages.yaml', checkMessagesYaml);
  });
}
