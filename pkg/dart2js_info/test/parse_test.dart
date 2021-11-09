// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/json_info_codec.dart';
import 'package:test/test.dart';

main() {
  group('parse', () {
    test('hello_world', () {
      var uri = Platform.script.resolve('hello_world/hello_world.js.info.json');
      var helloWorld = File.fromUri(uri);
      var json = jsonDecode(helloWorld.readAsStringSync());
      var decoded = AllInfoJsonCodec().decode(json);

      var program = decoded.program;
      expect(program, isNotNull);

      expect(program.entrypoint, isNotNull);
      expect(program.size, 94182);
      expect(program.compilationMoment,
          DateTime.parse("2021-09-27 15:32:00.380236"));
      expect(program.compilationDuration, Duration(microseconds: 2848001));
      expect(program.toJsonDuration, Duration(milliseconds: 3));
      expect(program.dumpInfoDuration, Duration(seconds: 0));
      expect(program.noSuchMethodEnabled, false);
      expect(program.minified, false);
    });
  });
}
