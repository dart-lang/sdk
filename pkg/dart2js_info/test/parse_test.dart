// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dart2js_info/json_info_codec.dart';
import 'package:test/test.dart';

import 'test_shared.dart';

void main() {
  group('parse', () {
    test('hello_world', () async {
      var content = await helloWorldDumpInfo();
      var json = jsonDecode(content);
      var decoded = AllInfoJsonCodec().decode(json);

      final program = decoded.program;
      expect(program, isNotNull);

      expect(program!.entrypoint, isNotNull);
      expect(program.size, 90293);
      expect(program.compilationMoment,
          DateTime.parse("2022-07-14 17:35:15.006337"));
      expect(program.compilationDuration, Duration(microseconds: 1289072));
      expect(program.toJsonDuration, Duration(milliseconds: 2));
      expect(program.dumpInfoDuration, Duration(seconds: 0));
      expect(program.noSuchMethodEnabled, false);
      expect(program.minified, false);
    });
  });
}
