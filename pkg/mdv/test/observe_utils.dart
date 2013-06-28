// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe_utils;

import 'package:observe/observe.dart';

toSymbolMap(Map map) {
  var result = new ObservableMap.linked();
  map.forEach((key, value) {
    if (value is Map) value = toSymbolMap(value);
    result[new Symbol(key)] = value;
  });
  return result;
}
