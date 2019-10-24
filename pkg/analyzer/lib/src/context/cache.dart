// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';

class AnalysisCache {
  AnalysisCache(List<CachePartition> partitions);
}

abstract class CachePartition {
  final InternalAnalysisContext context;
  CachePartition(this.context);
}

class SdkCachePartition extends CachePartition {
  SdkCachePartition(InternalAnalysisContext context) : super(context);
}
