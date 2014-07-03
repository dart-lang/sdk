// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.engine.src.index.store_single_source_container;

import 'package:analyzer/src/generated/source.dart';


/**
 * A [SourceContainer] with a single [Source].
 */
class SingleSourceContainer implements SourceContainer {
  final Source _source;

  SingleSourceContainer(this._source);

  @override
  bool contains(Source source) => source == _source;
}
