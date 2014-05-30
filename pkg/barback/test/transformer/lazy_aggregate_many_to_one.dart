// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.lazy_aggregate_many_to_one;

import 'package:barback/barback.dart';

import 'declaring_aggregate_many_to_one.dart';

/// Like [AggregateManyToOneTransformer], but returns a lazy asset that doesn't
/// perform the rewrite until it's materialized.
class LazyAggregateManyToOneTransformer
    extends DeclaringAggregateManyToOneTransformer
    implements LazyAggregateTransformer {
  LazyAggregateManyToOneTransformer(String extension, String output)
      : super(extension, output);
}
