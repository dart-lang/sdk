// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.asset_test;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();

  var id = new AssetId.parse("package|path/to/asset.txt");

  group("Asset.fromFile", () {
    test("returns an asset with the given ID", () {
      var asset = new Asset.fromFile(id, new File("asset.txt"));
      expect(asset.id, equals(id));
    });
  });

  group("Asset.fromPath", () {
    test("returns an asset with the given ID", () {
      var asset = new Asset.fromPath(id, "asset.txt");
      expect(asset.id, equals(id));
    });
  });

  group("Asset.fromString", () {
    test("returns an asset with the given ID", () {
      var asset = new Asset.fromString(id, "content");
      expect(asset.id, equals(id));
    });
  });
}
