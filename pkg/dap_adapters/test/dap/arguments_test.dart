// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dap_adapters/dap_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('DartLaunchRequestArguments', () {
    test('handles only required arguments', () {
      final json = '{"program":"a"}';
      final decoded = DartLaunchRequestArguments.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );
      expect(decoded.program, 'a');
      final encoded = jsonEncode(decoded.toJson());
      expect(encoded, json);
    });

    test('handles env variables map', () {
      final json = '{"env":{"a":"b"},"program":"a"}';
      final decoded = DartLaunchRequestArguments.fromJson(
        jsonDecode(json) as Map<String, Object?>,
      );
      expect(decoded.env!['a'], 'b');
      final encoded = jsonEncode(decoded.toJson());
      expect(encoded, json);
    });

    test('handles additional project paths list', () {
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
