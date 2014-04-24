// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.declaring_rewrite;

import 'package:barback/barback.dart';

import 'rewrite.dart';

/// Like [RewriteTransformer], but declares its assets ahead of time.
class DeclaringRewriteTransformer extends RewriteTransformer
    implements DeclaringTransformer {
  DeclaringRewriteTransformer(String from, String to)
      : super(from, to);

  void declareOutputs(DeclaringTransform transform) {
    if (consumePrimary) transform.consumePrimary();
    for (var extension in to.split(" ")) {
      var id = transform.primaryId.changeExtension(".$extension");
      transform.declareOutput(id);
    }
  }
}
