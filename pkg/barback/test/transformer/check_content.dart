// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:barback/barback.dart';

import 'mock.dart';

/// A transformer that modifies assets with the given content.
class CheckContentTransformer extends MockTransformer {
  final String content;
  final String addition;

  CheckContentTransformer(this.content, this.addition);

  Future<bool> doIsPrimary(Asset asset) =>
    asset.readAsString().then((value) => value == content);

  Future doApply(Transform transform) {
    return getPrimary(transform).then((primary) {
      return primary.readAsString().then((value) {
        transform.addOutput(
            new Asset.fromString(primary.id, "$value$addition"));
      });
    });
  }
}
