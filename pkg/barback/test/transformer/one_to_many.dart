// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.one_to_many;

import 'dart:async';

import 'package:barback/barback.dart';

import 'mock.dart';

/// A [Transformer] that takes an input asset that contains a comma-separated
/// list of paths and outputs a file for each path.
class OneToManyTransformer extends MockTransformer {
  final String extension;

  /// Creates a transformer that consumes assets with [extension].
  ///
  /// That file contains a comma-separated list of paths and it will output
  /// files at each of those paths.
  OneToManyTransformer(this.extension);

  Future<bool> doIsPrimary(AssetId id) =>
    new Future.value(id.extension == ".$extension");

  Future doApply(Transform transform) {
    return getPrimary(transform)
        .then((input) => input.readAsString())
        .then((lines) {
      for (var line in lines.split(",")) {
        var id = new AssetId(transform.primaryInput.id.package, line);
        transform.addOutput(new Asset.fromString(id, "spread $extension"));
      }
    });
  }

  String toString() => "1->many $extension";
}
