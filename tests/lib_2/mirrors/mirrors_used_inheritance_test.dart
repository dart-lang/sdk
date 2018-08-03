// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to make sure that all members of reflectable classes are reflectable,
// including ones inherited from super classes and the overriding members
// of subclasses.

@MirrorsUsed(metaTargets: "Meta")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class Meta {
  const Meta();
}

class Super {
  var inheritedField = 1;
  var overriddenField = 1;

  inheritedMethod(x) => x;
  overriddenMethod(x) => x;
}

@Meta()
class Reflected extends Super {
  var overriddenField = 2;
  var subclassedField = 2;

  overriddenMethod(x) => 2 * x;
  subclassedMethod(x) => 2 * x;
}

class Subclass extends Reflected {
  var subclassedField = 4;
  var subclassField = 4;

  subclassedMethod(x) => 4 * x;
  subclassMethod(x) => 4 * x;
}

tryCall(object, symbol, value, expected) {
  var mirror = reflect(object);
  var result = mirror.invoke(symbol, [value]).reflectee;
  Expect.equals(result, expected);
}

tryField(object, symbol, expected) {
  var mirror = reflect(object);
  var result = mirror.getField(symbol).reflectee;
  Expect.equals(result, expected);
}

main() {
  var objects = [new Reflected(), new Subclass()];

  // Make sure the subclass methods are alive.
  Subclass sub = objects[1];
  sub.subclassField = 9;
  print(sub.subclassMethod(9));

  var index = 1;
  if (new DateTime.now().year == 1984) {
    index = 0;
  }

  // Reflect an instance of [Subclass], which should only expose the interface
  // of [Reflected].
  var subclass = objects[index];
  tryCall(subclass, #inheritedMethod, 11, 11);
  tryCall(subclass, #overriddenMethod, 11, 22);
  tryCall(subclass, #subclassedMethod, 11, 44);
  tryField(subclass, #inheritedField, 1);
  tryField(subclass, #overriddenField, 2);
  tryField(subclass, #subclassedField, 4);
  Expect.throws(() => reflect(subclass).invoke(#subclassMethod, [11]));
  Expect.throws(() => reflect(subclass).getField(#subclassField));
}
