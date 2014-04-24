// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.sync_rewrite;

import 'dart:async';

import 'package:barback/barback.dart';

/// Like [DeclaringRewriteTransformer], but with no methods returning Futures.
class SyncRewriteTransformer extends Transformer
    implements DeclaringTransformer {
  final String from;
  final String to;

  SyncRewriteTransformer(this.from, this.to);

  bool isPrimary(AssetId id) => id.extension == ".$from";

  void apply(Transform transform) {
    for (var extension in to.split(" ")) {
      var id = transform.primaryInput.id.changeExtension(".$extension");
      transform.addOutput(new Asset.fromString(id, "new.$extension"));
    }
  }

  void declareOutputs(DeclaringTransform transform) {
    for (var extension in to.split(" ")) {
      var id = transform.primaryId.changeExtension(".$extension");
      transform.declareOutput(id);
    }
  }

  String toString() => "$from->$to";
}
