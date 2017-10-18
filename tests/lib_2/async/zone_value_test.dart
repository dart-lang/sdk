// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  // Unique object.
  var baz = new Mimic(new Object());
  // Not so unique object that thinks it's the same as baz.
  var mimic = new Mimic(baz.original);

  // runGuarded calls run, captures the synchronous error (if any) and
  // gives that one to handleUncaughtError.

  Expect.identical(Zone.ROOT, Zone.current);

  // Create a map with various key types.
  Map zoneValues = new Map();
  zoneValues[#foo] = 499;
  zoneValues["bar"] = [];
  zoneValues[baz] = "baz";
  zoneValues[0] = "zero!";
  zoneValues[null] = baz;

  Zone forked = Zone.current.fork(zoneValues: zoneValues);

  // Values are not present when not inside the zone.
  Expect.identical(Zone.ROOT, Zone.current);
  Expect.isNull(Zone.current[#foo]);
  Expect.isNull(Zone.current["bar"]);
  Expect.isNull(Zone.current[baz]);
  Expect.isNull(Zone.current[mimic]);
  Expect.isNull(Zone.current[0]);
  Expect.isNull(Zone.current[null]);
  Expect.isNull(Zone.current["qux"]);

  // Changing the original map has no effect after the zone is created.
  zoneValues[#foo] = -1;

  // Values are available directly on the zone.
  Expect.equals(499, forked[#foo]);
  Expect.listEquals([], forked["bar"]);
  Expect.equals("baz", forked[baz]);
  Expect.equals("baz", forked[mimic]);
  Expect.equals("zero!", forked[0]);
  Expect.equals("zero!", forked[0.0]); // Lookup uses equality.
  Expect.equals("zero!", forked[-0.0]);
  Expect.equals(baz, forked[null]);
  Expect.isNull(forked["qux"]);

  forked.run(() {
    Expect.identical(forked, Zone.current); // Sanity check.
    // Values are present on current when inside zone.
    Expect.equals(499, Zone.current[#foo]);
    Expect.listEquals([], Zone.current["bar"]);
    Expect.equals("baz", Zone.current[baz]);
    Expect.equals("baz", Zone.current[mimic]);
    Expect.equals("zero!", Zone.current[0]);
    Expect.equals("zero!", Zone.current[0.0]); // Lookup uses equality.
    Expect.equals("zero!", Zone.current[-0.0]);
    Expect.equals(baz, Zone.current[null]);
    Expect.isNull(Zone.current["qux"]);
  });

  // Values are still not present when not inside the zone.
  Expect.identical(Zone.ROOT, Zone.current);
  Expect.isNull(Zone.current[#foo]);
  Expect.isNull(Zone.current["bar"]);
  Expect.isNull(Zone.current[baz]);
  Expect.isNull(Zone.current[mimic]);
  Expect.isNull(Zone.current[0]);
  Expect.isNull(Zone.current[null]);
  Expect.isNull(Zone.current["qux"]);

  // Modifying the stored values work as expected.
  zoneValues["bar"].add(42);

  forked.run(() {
    Expect.identical(forked, Zone.current); // Sanity check.
    // Values are still there when inside the zone. The list was modified.
    Expect.equals(499, Zone.current[#foo]);
    Expect.listEquals([42], Zone.current["bar"]);
    Expect.equals("baz", Zone.current[baz]);
    Expect.equals("baz", Zone.current[mimic]);
    Expect.equals("zero!", Zone.current[0]);
    Expect.equals(baz, Zone.current[null]);
    Expect.isNull(Zone.current["qux"]);
  });

  // Creating a further nested zone with new values allows keeping, overriding,
  // and shadowing existing values from the outer zone.
  zoneValues = new Map();
  zoneValues[#foo] = -499; //     Values can be overridden.
  zoneValues["bar"] = null; //    Values can be changed to null.
  zoneValues["qux"] = 99; //      Values can be added
  // Overriding with equal, but not identical, key is possible.
  zoneValues[mimic] = "floo";
  zoneValues[0.0] = "zero!ZERO!";

  Zone forkedChild = forked.fork(zoneValues: zoneValues);

  // New values available on zone.
  Expect.equals(-499, forkedChild[#foo]); //         Overridden.
  Expect.isNull(forkedChild["bar"]); //              Overridden to null.
  Expect.equals("floo", forkedChild[baz]); //        Overridden by mimic.
  Expect.equals("floo", forkedChild[mimic]); //      Now recognizes mimic.
  Expect.equals("zero!ZERO!", forkedChild[0]); //    Overridden by 0.0.
  Expect.equals("zero!ZERO!", forkedChild[0.0]); // Overriding 0.
  Expect.equals(baz, forkedChild[null]); //          Inherited.
  Expect.equals(99, forkedChild["qux"]); //          Added.

  forkedChild.run(() {
    Expect.identical(forkedChild, Zone.current); // Sanity check.
    // New values available on current zone when the zone is current.
    Expect.equals(-499, Zone.current[#foo]); //         Overridden.
    Expect.isNull(Zone.current["bar"]); //              Overridden to null.
    Expect.equals("floo", Zone.current[baz]); //        Overridden by mimic.
    Expect.equals("floo", Zone.current[mimic]); //      Now recognizes mimic.
    Expect.equals("zero!ZERO!", Zone.current[0]); //    Overridden by 0.0.
    Expect.equals("zero!ZERO!", Zone.current[0.0]); // Overriding 0.
    Expect.equals(baz, Zone.current[null]); //          Inherited.
    Expect.equals(99, Zone.current["qux"]); //          Added.
  });

  // Parent zone values are unchanged.
  Expect.equals(499, forked[#foo]);
  Expect.listEquals([42], forked["bar"]);
  Expect.equals("baz", forked[baz]);
  Expect.equals("baz", forked[mimic]);
  Expect.equals("zero!", forked[0]);
  Expect.equals("zero!", forked[0.0]); // Lookup uses equality.
  Expect.equals("zero!", forked[-0.0]);
  Expect.equals(baz, forked[null]);
  Expect.isNull(forked["qux"]);
}

// Class of objects that consider themselves equal to their originals.
// Sees through mimickry.
class Mimic {
  final Object original;
  Mimic(this.original);
  int get hashCode => original.hashCode;
  bool operator ==(Object other) =>
      (other is Mimic) ? this == other.original : original == other;
}
