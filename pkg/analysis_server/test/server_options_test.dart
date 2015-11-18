// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library analysis_server.test.server_options;

import 'package:analysis_server/src/server_options.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  initializeTestEnvironment();

  group('server_options', () {
    test('basic - []', () {
      var options = new ServerOptions.fromContents('''# ignored
foo: bar
baz: padded   
''');
      expect(options['foo'], equals('bar'));
      expect(options['baz'], equals('padded'));
    });
    test('basic - isSet', () {
      var options = new ServerOptions.fromContents('''foo: true
bar: TRUE
baz: false
foobar: off
''');
      expect(options.isSet('foo'), isTrue);
      expect(options.isSet('bar'), isTrue);
      expect(options.isSet('baz'), isFalse);
      expect(options.isSet('foobar'), isFalse);
      expect(options.isSet('does_not_exist'), isFalse);
      expect(options.isSet('does_not_exist', defaultValue: true), isTrue);
    });

    test('basic - getStringValue', () {
      var options = new ServerOptions.fromContents('''foo: someValue
''');
      expect(options.getStringValue('foo'), equals('someValue'));
      expect(options.getStringValue('not_there'), isNull);
      expect(options.getStringValue('not_there', defaultValue: 'bar'),
          equals('bar'));
    });
  });
}
