// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.lazy_rewrite;

import 'dart:async';

import 'package:barback/barback.dart';

import 'rewrite.dart';

/// Like [RewriteTransformer], but returns a lazy asset that doesn't perform the
/// rewrite until it's materialized.
class LazyRewriteTransformer extends RewriteTransformer
    implements LazyTransformer {
  LazyRewriteTransformer(String from, String to)
      : super(from, to);

  Future declareOutputs(DeclaringTransform transform) {
    if (consumePrimary) transform.consumePrimary();
    for (var extension in to.split(" ")) {
      var id = transform.primaryId.changeExtension(".$extension");
      transform.declareOutput(id);
    }
  }
}
