// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.conditionally_consume_primary;

import 'dart:async';

import 'package:barback/barback.dart';

import 'rewrite.dart';

/// A transformer that consumes its primary input only if its contents match a
/// given pattern.
class ConditionallyConsumePrimaryTransformer extends RewriteTransformer {
  final Pattern content;

  ConditionallyConsumePrimaryTransformer(String from, String to, this.content)
      : super(from, to);

  Future doApply(Transform transform) {
    return getPrimary(transform).then((primary) {
      return primary.readAsString().then((value) {
        if (value.contains(content)) transform.consumePrimary();
        return super.doApply(transform);
      });
    });
  }
}
