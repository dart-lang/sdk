// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

void main() {
  Expect.identical(Zone.root, Zone.current); // Sanity check.

  // Distinct objects only equal to each other.
  var wrap = Wrap(Object());
  var wrap2 = Wrap(wrap.id);

  Expect.equals(wrap, wrap2);
  Expect.equals(wrap2, wrap);

  // Create a map with various key types.
  var barList = <Object?>[];
  var zoneValues = <Object?, Object?>{
    #foo: 499,
    "bar": barList,
    wrap: "wrap",
    0: "zero!",
    null: "nullKey",
  };

  Zone forked = Zone.current.fork(zoneValues: zoneValues);

  // Values are not present when not inside the zone.
  Expect.identical(Zone.root, Zone.current);
  Expect.isNull(Zone.current[#foo]);
  Expect.isNull(Zone.current["bar"]);
  Expect.isNull(Zone.current[wrap]);
  Expect.isNull(Zone.current[wrap2]);
  Expect.isNull(Zone.current[0]);
  Expect.isNull(Zone.current[null]);
  Expect.isNull(Zone.current["qux"]); // Not key in zoneValues at all.

  // Changing the original map has no effect after the zone is created.
  zoneValues[#foo] = -1;

  // Values are available directly on the zone.
  Expect.equals(499, forked[#foo]);
  Expect.identical(barList, forked["bar"]);
  Expect.equals("wrap", forked[wrap]);
  Expect.equals("wrap", forked[wrap2]); // Because wrap == wrap2.
  Expect.equals("zero!", forked[0]);
  Expect.equals("zero!", forked[0.0]); // Lookup uses equality.
  Expect.equals("zero!", forked[-0.0]);
  Expect.equals("nullKey", forked[null]);
  Expect.isNull(forked["qux"]); // Wasn't added as key.

  forked.run(() {
    // Changing zone doesn't change what the zone does.
    Expect.identical(forked, Zone.current); // Sanity check.
    // Values are present on current when inside zone.
    Expect.equals(499, Zone.current[#foo]);
    Expect.identical(barList, Zone.current["bar"]);
    Expect.equals("wrap", Zone.current[wrap]);
    Expect.equals("wrap", Zone.current[wrap2]);
    Expect.equals("zero!", Zone.current[0]);
    Expect.equals("zero!", Zone.current[0.0]); // Lookup uses equality.
    Expect.equals("zero!", Zone.current[-0.0]);
    Expect.equals("nullKey", Zone.current[null]);
    Expect.isNull(Zone.current["qux"]);

    // And doesn't change what the root zone does.
    Expect.isNull(Zone.root[#foo]);
    Expect.isNull(Zone.root["bar"]);
    Expect.isNull(Zone.root[wrap]);
    Expect.isNull(Zone.root[wrap2]);
    Expect.isNull(Zone.root[0]);
    Expect.isNull(Zone.root[null]);
    Expect.isNull(Zone.root["qux"]);
  });

  // Values are still not present when not inside the zone.
  Expect.identical(Zone.root, Zone.current);
  Expect.isNull(Zone.current[#foo]);
  Expect.isNull(Zone.current["bar"]);
  Expect.isNull(Zone.current[wrap]);
  Expect.isNull(Zone.current[wrap2]);
  Expect.isNull(Zone.current[0]);
  Expect.isNull(Zone.current[null]);
  Expect.isNull(Zone.current["qux"]);

  // Modifying the stored values work as expected.
  barList.add(42); // Updates the list stored in the zone.
  Expect.listEquals([42], forked["bar"]);
  Expect.identical(barList, forked["bar"]);

  forked.run(() {
    Expect.listEquals([42], Zone.current["bar"]);
    Expect.identical(zoneValues["bar"], Zone.current["bar"]);
  });

  // Creating a further nested zone with new values allows keeping, overriding,
  // and shadowing existing values from the outer zone.
  var newZoneValues = <Object?, Object?>{
    #foo: -499, //     Values can be overridden.
    "qux": 99, //      Values can be added
    // Keys shadow everything they are equal to.
    wrap2: "wrap2",
    0.0: null, //    Values can be changed to null.
    // Not shadowing the `null` key.
  };

  Zone forkedChild = forked.fork(zoneValues: newZoneValues);

  // New values available on zone.
  Expect.equals(-499, forkedChild[#foo]); //         Overridden.
  Expect.isNull(forkedChild[0]); //                  Overridden to null.
  Expect.isNull(forkedChild[0.0]); //                Overridden to null.
  Expect.isNull(forkedChild[-0.0]); //               Overridden to null.
  Expect.equals("wrap2", forkedChild[wrap]); //      Overridden by equal.
  Expect.equals("wrap2", forkedChild[wrap2]); //     Overridden by equal.
  Expect.equals("nullKey", forkedChild[null]); //    Inherited.
  Expect.identical(zoneValues["bar"], forkedChild["bar"]); // Inherited.
  Expect.equals(99, forkedChild["qux"]); //          Added.

  forkedChild.run(() {
    Expect.identical(forkedChild, Zone.current); // Sanity check.
    Expect.identical(forked, forkedChild.parent);
    // New values available on current zone when the zone is current.
    Expect.equals(-499, Zone.current[#foo]);
    Expect.isNull(Zone.current[0]);
    Expect.isNull(Zone.current[0.0]);
    Expect.isNull(Zone.current[-0.0]);
    Expect.equals("wrap2", Zone.current[wrap]);
    Expect.equals("wrap2", Zone.current[wrap2]);
    Expect.equals("nullKey", Zone.current[null]);
    Expect.identical(zoneValues["bar"], Zone.current["bar"]);
    Expect.equals(99, Zone.current["qux"]);
  });

  // Parent zone values are unchanged.
  Expect.equals(499, forked[#foo]);
  Expect.identical(barList, forked["bar"]);
  Expect.equals("wrap", forked[wrap]);
  Expect.equals("wrap", forked[wrap2]);
  Expect.equals("zero!", forked[0]);
  Expect.equals("zero!", forked[0.0]); // Lookup uses equality.
  Expect.equals("zero!", forked[-0.0]);
  Expect.equals("nullKey", forked[null]);
  Expect.isNull(forked["qux"]);
}

// Objects equal to other wraps with the same ID.
class Wrap {
  final Object id;
  Wrap(this.id);
  int get hashCode => id.hashCode;
  bool operator ==(Object other) => (other is Wrap) && id == other.id;
}
