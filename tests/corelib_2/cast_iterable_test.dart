// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";
import 'cast_helper.dart';

void main() {
  testDowncastDirectAccess();
  testDowncastNoDirectAccess();
  testDowncastUntouchableElements();
  testUpcast();
}

void testDowncastDirectAccess() {
  var iterable = new Iterable<C>.generate(elements.length, (n) => elements[n]);

  // An iterable that (likely) can do direct access.
  var dIterable = Iterable.castFrom<C, D>(iterable);

  Expect.throws(() => dIterable.first, null, "direct.first");
  Expect.equals(d, dIterable.elementAt(1));
  Expect.throws(() => dIterable.elementAt(2), null, "direct.2"); // E is not D.
  Expect.equals(f, dIterable.skip(3).first); // Skip does not access element.
  Expect.equals(null, dIterable.skip(3).elementAt(1));

  Expect.throws(() => dIterable.toList(), null, "direct.toList");
}

void testDowncastNoDirectAccess() {
  var iterable = new Iterable<C>.generate(elements.length, (n) => elements[n]);

  // An iterable that cannot do direct access.
  var dIterable = Iterable.castFrom<C, D>(iterable.where((_) => true));

  Expect.throws(() => dIterable.first, null, "nonDirect.first");
  Expect.equals(d, dIterable.elementAt(1));
  // E is not D.
  Expect.throws(() => dIterable.elementAt(2), null, "nonDirect.2");
  Expect.equals(f, dIterable.skip(3).first); // Skip does not access element.
  Expect.equals(null, dIterable.skip(3).elementAt(1));

  Expect.throws(() => dIterable.toList(), null, "nonDirect.toList");
}

void testDowncastUntouchableElements() {
  // Iterable that definitely won't survive accessing element 3.
  var iterable = new Iterable<C>.generate(
      elements.length, (n) => n == 3 ? throw "untouchable" : elements[n]);
  var dIterable = Iterable.castFrom<C, D>(iterable);

  Expect.throws(() => dIterable.first, null, "untouchable.first");
  Expect.equals(d, dIterable.elementAt(1));
  Expect.throws(() => dIterable.elementAt(3), null, "untouchable.3");
  // Skip does not access element.
  Expect.equals(null, dIterable.skip(4).first);
  Expect.equals(null, dIterable.skip(3).elementAt(1));

  Expect.throws(() => dIterable.toList(), null, "untouchable.toList");
}

void testUpcast() {
  var iterable = new Iterable<C>.generate(elements.length, (n) => elements[n]);

  var objectIterable = Iterable.castFrom<C, Object>(iterable);
  Expect.listEquals(elements, objectIterable.toList());
}
