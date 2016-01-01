// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library megamorphiccache_view;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('megamorphiccache-view')
class MegamorphicCacheViewElement extends ObservatoryElement {
  @published MegamorphicCache megamorphicCache;

  MegamorphicCacheViewElement.created() : super.created();

  Future refresh() {
    return megamorphicCache.reload();
  }
}
