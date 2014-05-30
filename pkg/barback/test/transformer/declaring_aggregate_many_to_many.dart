// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.declaring_aggregate_many_to_many;

import 'dart:async';

import 'package:barback/barback.dart';

import 'aggregate_many_to_many.dart';

/// Like [AggregateManyToManyTransformer], but declares its assets ahead of
/// time.
class DeclaringAggregateManyToManyTransformer
    extends AggregateManyToManyTransformer
    implements DeclaringAggregateTransformer {
  DeclaringAggregateManyToManyTransformer(String extension)
      : super(extension);

  Future declareOutputs(DeclaringAggregateTransform transform) =>
      transform.primaryIds.asyncMap(transform.declareOutput).toList();
}
