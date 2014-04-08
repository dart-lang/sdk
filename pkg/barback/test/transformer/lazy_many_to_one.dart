// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.lazy_many_to_one;

import 'dart:async';

import 'package:barback/barback.dart';

import 'many_to_one.dart';

/// Like [ManyToOneTransformer], but returns a lazy asset that doesn't perform
/// the conglomeration until it's materialized.
class LazyManyToOneTransformer extends ManyToOneTransformer
    implements LazyTransformer {
  LazyManyToOneTransformer(String extension)
      : super(extension);

  Future declareOutputs(DeclaringTransform transform) {
    transform.declareOutput(transform.primaryId.changeExtension(".out"));
  }
}
