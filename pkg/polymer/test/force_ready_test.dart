// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => window.on['HTMLImportsLoaded']);

  /// We do not port the full test, since this just proxies through to the
  /// polymer js implementation.
  test('can force ready', () {
    expect(Polymer.waitingFor.length, 1);
    expect(Polymer.waitingFor[0], querySelector('polymer-element'));
    Polymer.forceReady();
    return Polymer.onReady;
  });
});
