// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.asset_set_test;

import 'package:barback/barback.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();

  var fooId = new AssetId.parse("app|foo.txt");
  var barId = new AssetId.parse("app|bar.txt");
  var bazId = new AssetId.parse("app|baz.txt");

  group(".from()", () {
    test("creates a set from an iterable", () {
      var set = new AssetSet.from([
        new Asset.fromString(fooId, "foo"),
        new Asset.fromString(barId, "bar")
      ]);

      expect(set.containsId(fooId), isTrue);
      expect(set.containsId(barId), isTrue);
      expect(set.containsId(bazId), isFalse);
    });
  });

  group("[] operator", () {
    test("gets an asset with the given ID", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      set.add(foo);

      expect(set[fooId], equals(foo));
    });

    test("returns null if no asset with the ID is in the set", () {
      var set = new AssetSet();
      expect(set[fooId], isNull);
    });
  });

  group(".add()", () {
    test("adds the asset to the set", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      set.add(foo);
      expect(set.contains(foo), isTrue);
    });

    test("replaces a previously added asset with that ID", () {
      var set = new AssetSet();
      set.add(new Asset.fromString(fooId, "before"));
      set.add(new Asset.fromString(fooId, "after"));
      expect(set[fooId].readAsString(), completion(equals("after")));
    });

    test("returns the added item", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      expect(set.add(foo), equals(foo));
    });
  });

  group(".addAll()", () {
    test("adds the assets to the set", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      var bar = new Asset.fromString(barId, "bar");
      set.addAll([foo, bar]);
      expect(set.contains(foo), isTrue);
      expect(set.contains(bar), isTrue);
    });

    test("replaces assets earlier in the sequence with later ones", () {
      var set = new AssetSet();
      var foo1 = new Asset.fromString(fooId, "before");
      var foo2 = new Asset.fromString(fooId, "after");
      set.addAll([foo1, foo2]);
      expect(set[fooId].readAsString(), completion(equals("after")));
    });
  });

  group(".clear()", () {
    test("empties the set", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      set.add(foo);
      set.clear();

      expect(set.length, equals(0));
      expect(set.contains(foo), isFalse);
    });
  });

  group(".contains()", () {
    test("returns true if the asset is in the set", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      var bar = new Asset.fromString(barId, "bar");
      set.add(foo);

      expect(set.contains(foo), isTrue);
      expect(set.contains(bar), isFalse);
    });
  });

  group(".containsId()", () {
    test("returns true if an asset with the ID is in the set", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      set.add(foo);

      expect(set.containsId(fooId), isTrue);
      expect(set.containsId(barId), isFalse);
    });
  });

  group(".removeId()", () {
    test("removes the asset with the ID from the set", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      set.add(foo);

      set.removeId(fooId);
      expect(set.containsId(fooId), isFalse);
    });

    test("returns the removed asset", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      set.add(foo);

      expect(set.removeId(fooId).readAsString(), completion(equals("foo")));
    });

    test("returns null when removing an asset not in the set", () {
      var set = new AssetSet();
      var foo = new Asset.fromString(fooId, "foo");
      set.add(foo);

      expect(set.removeId(barId), isNull);
    });
  });
}
