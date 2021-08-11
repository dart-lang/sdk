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
      var helloWorld = new File('test/hello_world/hello_world.js.info.json');
      var json = jsonDecode(helloWorld.readAsStringSync());
      var decoded = new AllInfoJsonCodec().decode(json);

      var program = decoded.program;
      expect(program, isNotNull);

      expect(program.entrypoint, isNotNull);
      expect(program.size, 10324);
      expect(program.compilationMoment,
          DateTime.parse("2017-04-17 09:46:41.661617"));
      expect(program.compilationDuration, new Duration(microseconds: 357402));
      expect(program.toJsonDuration, new Duration(milliseconds: 4));
      expect(program.dumpInfoDuration, new Duration(seconds: 0));
      expect(program.noSuchMethodEnabled, false);
      expect(program.minified, false);
    });
  });
}
