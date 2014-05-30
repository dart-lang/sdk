// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.declaring_aggregate_many_to_one;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

import 'aggregate_many_to_one.dart';

/// Like [AggregateManyToOneTransformer], but declares its assets ahead of time.
class DeclaringAggregateManyToOneTransformer
    extends AggregateManyToOneTransformer
    implements DeclaringAggregateTransformer {
  DeclaringAggregateManyToOneTransformer(String extension, String output)
      : super(extension, output);

  void declareOutputs(DeclaringAggregateTransform transform) {
    transform.declareOutput(new AssetId(transform.package,
        path.url.join(transform.key, output)));
  }
}
