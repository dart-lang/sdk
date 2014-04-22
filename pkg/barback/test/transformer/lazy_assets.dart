// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.lazy_assets;

import 'package:barback/barback.dart';

import 'declare_assets.dart';

/// Like [DeclareAssetsTransformer], but lazy.
class LazyAssetsTransformer extends DeclareAssetsTransformer
    implements LazyTransformer {
  LazyAssetsTransformer(Iterable<String> declared, [Iterable<String> emitted])
      : super(declared, emitted);
}
