// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer_test;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();

  group("isPrimary", () {
    test("defaults to allowedExtensions", () {
      var transformer = new ExtensionTransformer(".txt .bin");
      expect(transformer.isPrimary(makeAsset("foo.txt")),
          completion(isTrue));

      expect(transformer.isPrimary(makeAsset("foo.bin")),
          completion(isTrue));

      expect(transformer.isPrimary(makeAsset("foo.nottxt")),
          completion(isFalse));
    });

    test("allows all files if allowedExtensions is not overridden", () {
      var transformer = new MockTransformer();
      expect(transformer.isPrimary(makeAsset("foo.txt")),
          completion(isTrue));

      expect(transformer.isPrimary(makeAsset("foo.bin")),
          completion(isTrue));

      expect(transformer.isPrimary(makeAsset("anything")),
          completion(isTrue));
    });
  });
}

Asset makeAsset(String path) =>
    new Asset.fromString(new AssetId.parse("app|$path"), "");

class MockTransformer extends Transformer {
  MockTransformer();

  Future apply(Transform transform) => new Future.value();
}

class ExtensionTransformer extends Transformer {
  final String allowedExtensions;

  ExtensionTransformer(this.allowedExtensions);

  Future apply(Transform transform) => new Future.value();
}