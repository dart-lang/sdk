// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A regression test for dart2js generating illegal JavaScript code
// dynamically in non-csp mode.  The name of the field "defaultValue"
// in JavaScript is "default".  This meant that dart2js would create a
// constructor function that looked like this:
//
// function TrackElement(default) { this.default = default; }

import 'dart:html';

import 'package:expect/minitest.dart';

void main() {
  test('', () {
    if (!TrackElement.supported) return;
    document.body.append(new TrackElement()..defaultValue = true);
    var trackElement = document.query('track') as TrackElement;
    if (!trackElement.defaultValue) {
      throw 'Expected default value to be true';
    }
    trackElement.defaultValue = false;
    if (trackElement.defaultValue) {
      throw 'Expected default value to be false';
    }
  });
}
