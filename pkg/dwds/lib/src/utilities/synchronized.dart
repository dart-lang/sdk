// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pool/pool.dart';

class AtomicQueue {
  final _pool = Pool(1);

  AtomicQueue();

  // Executes tasks sequentially.
  Future<T> run<T>(FutureOr<T> Function() task) => _pool.withResource(task);
}
