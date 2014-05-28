// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.lazy_aggregate_many_to_many;

import 'package:barback/barback.dart';

import 'declaring_aggregate_many_to_many.dart';

/// An [AggregateTransformer] that takes all assets in each directory with a
/// given extension and adds to their contents.
class LazyAggregateManyToManyTransformer
    extends DeclaringAggregateManyToManyTransformer
    implements LazyAggregateTransformer {
  LazyAggregateManyToManyTransformer(String extension)
      : super(extension);
}
