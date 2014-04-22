// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.many_to_one;

import 'dart:async';

import 'package:barback/barback.dart';

import 'mock.dart';

/// A transformer that uses the contents of a file to define the other inputs.
///
/// Outputs a file with the same name as the primary but with an "out"
/// extension containing the concatenated contents of all non-primary inputs.
class ManyToOneTransformer extends MockTransformer {
  final String extension;

  /// Creates a transformer that consumes assets with [extension].
  ///
  /// That file contains a comma-separated list of paths and it will input
  /// files at each of those paths.
  ManyToOneTransformer(this.extension);

  bool doIsPrimary(AssetId id) => id.extension == ".$extension";

  Future doApply(Transform transform) {
    return getPrimary(transform)
        .then((primary) => primary.readAsString())
        .then((contents) {
      // Get all of the included inputs.
      return Future.wait(contents.split(",").map((path) {
        var id;
        if (path.contains("|")) {
          id = new AssetId.parse(path);
        } else {
          id = new AssetId(transform.primaryInput.id.package, path);
        }
        return getInput(transform, id).then((input) => input.readAsString());
      }));
    }).then((outputs) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, outputs.join()));
    });
  }

  String toString() => "many->1 $extension";
}
