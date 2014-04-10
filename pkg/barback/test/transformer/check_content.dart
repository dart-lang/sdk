// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.check_content;

import 'dart:async';

import 'package:barback/barback.dart';

import 'mock.dart';

/// A transformer that modifies assets that contains the given content.
class CheckContentTransformer extends MockTransformer {
  final Pattern content;
  final String addition;

  CheckContentTransformer(this.content, this.addition);

  Future<bool> doIsPrimary(AssetId id) => new Future.value(true);

  Future doApply(Transform transform) {
    return getPrimary(transform).then((primary) {
      return primary.readAsString().then((value) {
        if (!value.contains(content)) return;

        transform.addOutput(
            new Asset.fromString(primary.id, "$value$addition"));
      });
    });
  }
}
