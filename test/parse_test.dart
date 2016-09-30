// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:test/test.dart';

main() {
  group('parse', () {
    test('hello_world', () {
      var helloWorld = new File('test/hello_world/hello_world.js.info.json');
      var json = JSON.decode(helloWorld.readAsStringSync());
      var decoded = new AllInfoJsonCodec().decode(json);

      var program = decoded.program;
      expect(program, isNotNull);

      expect(program.entrypoint, isNotNull);
      expect(program.size, 10124);
      expect(program.compilationMoment,
          DateTime.parse("2016-09-30 13:44:11.847439"));
      expect(program.compilationDuration,
          new Duration(seconds: 3, microseconds: 717112));
      expect(program.noSuchMethodEnabled, false);
      expect(program.minified, false);
    }, skip: "need to update dart2js first");
  });
}
