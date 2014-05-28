// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.aggregate_many_to_one;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'mock_aggregate.dart';

/// An [AggregateTransformer] that applies to all assets with a given extension.
/// For each directory containing any of these assets, it produces an output
/// file that contains the concatenation of all matched assets in that
/// directory in alphabetic order by name.
class AggregateManyToOneTransformer extends MockAggregateTransformer {
  /// The extension of assets to combine.
  final String extension;

  /// The basename of the output asset.
  ///
  /// The output asset's path will contain the directory name of the inputs as
  /// well.
  final String output;

  AggregateManyToOneTransformer(this.extension, this.output);

  String doClassifyPrimary(AssetId id) {
    if (id.extension != ".$extension") return null;
    return path.url.dirname(id.path);
  }

  Future doApply(AggregateTransform transform) {
    return getPrimaryInputs(transform).toList().then((assets) {
      assets.sort((asset1, asset2) => asset1.id.path.compareTo(asset2.id.path));
      return Future.wait(assets.map((asset) => asset.readAsString()));
    }).then((contents) {
      var id = new AssetId(transform.package,
          path.url.join(transform.key, output));
      transform.addOutput(new Asset.fromString(id, contents.join('\n')));
    });
  }

  String toString() => "aggregate $extension->$output";
}
