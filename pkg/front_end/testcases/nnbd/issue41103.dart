// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void main() {}

final t = StreamTransformer.fromHandlers(
    handleData: (data, sink) => Future.microtask(() => sink.add(data)),
    handleDone: (sink) => Future.microtask(() => sink.close()));
