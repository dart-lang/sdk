// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dap_adapters/dap.dart';
import 'package:test/test.dart';

main() {
  group('DartLaunchRequestArguments', () {
    test('handles only required arguments', () async {
      final json = '{"program":"a"}';
      final decoded = DartLaunchRequestArguments.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );
      expect(decoded.program, 'a');
      final encoded = jsonEncode(decoded.toJson());
      expect(encoded, json);
    });

    test('handles env variables map', () async {
      final json = '{"env":{"a":"b"},"program":"a"}';
      final decoded = DartLaunchRequestArguments.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );
      expect(decoded.env!['a'], 'b');
      final encoded = jsonEncode(decoded.toJson());
      expect(encoded, json);
    });

    test('handles additional project paths list', () async {
      final json = '{"additionalProjectPaths":["a","b"],"program":"a"}';
      final decoded = DartLaunchRequestArguments.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );
      expect(decoded.additionalProjectPaths, ['a', 'b']);
      final encoded = jsonEncode(decoded.toJson());
      expect(encoded, json);
    });
  });
}
