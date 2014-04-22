// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.rewrite;

import 'dart:async';

import 'package:barback/barback.dart';

import 'mock.dart';

/// A [Transformer] that takes assets ending with one extension and generates
/// assets with a given extension.
///
/// Appends the output extension to the contents of the input file.
class RewriteTransformer extends MockTransformer {
  final String from;
  final String to;

  /// Creates a transformer that rewrites assets whose extension is [from] to
  /// one whose extension is [to].
  ///
  /// [to] may be a space-separated list in which case multiple outputs will be
  /// created for each input.
  RewriteTransformer(this.from, this.to);

  bool doIsPrimary(AssetId id) => id.extension == ".$from";

  Future doApply(Transform transform) {
    return getPrimary(transform).then((input) {
      return Future.wait(to.split(" ").map((extension) {
        var id = input.id.changeExtension(".$extension");
        return input.readAsString().then((content) {
          transform.addOutput(new Asset.fromString(id, "$content.$extension"));
        });
      }));
    });
  }

  String toString() => "$from->$to";
}
