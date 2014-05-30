// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.aggregate_many_to_many;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'mock_aggregate.dart';

/// An [AggregateTransformer] that takes all assets with a given extension,
/// grouped by directory, adds to their contents.
class AggregateManyToManyTransformer extends MockAggregateTransformer {
  /// The extension of assets to combine.
  final String extension;

  AggregateManyToManyTransformer(this.extension);

  String doClassifyPrimary(AssetId id) {
    if (id.extension != ".$extension") return null;
    return path.url.dirname(id.path);
  }

  Future doApply(AggregateTransform transform) {
    return getPrimaryInputs(transform).asyncMap((asset) {
      return asset.readAsString().then((contents) {
        transform.addOutput(new Asset.fromString(
            asset.id, "modified $contents"));
      });
    }).toList();
  }

  String toString() => "aggregate $extension->many";
}
