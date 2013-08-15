// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.async;

import 'dart:async';
import 'package:observe/observe.dart';

class StreamBinding<T> extends ObservableBox {
  final Stream<T> stream;

  StreamBinding(this.stream) {
    stream.listen((T i) { value = i; });
  }

}
