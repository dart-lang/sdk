// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:serialization/serialization.dart';
import 'package:unittest/unittest.dart';

class Thing {
  var name;
}

void main() {

  test("Serializing something without a library directive", () {
    var thing = new Thing()..name = 'testThing';
    var s = new Serialization()
      ..addRuleFor(Thing);
    var serialized = s.write(thing);
    var newThing = s.read(serialized);
    expect(thing.name, newThing.name);
  });
}