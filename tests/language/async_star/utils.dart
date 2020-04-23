// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

const ms = const Duration(milliseconds: 1);

/// Allows two asynchronous executions to synchronize.
///
/// Calling [wait] and waiting for the returned future to complete will wait for
/// the other executions to call [wait] again. At that point, the waiting
/// execution is allowed to continue (the returned future completes), and the
/// more resent call to [wait] is now the waiting execution.
class Sync {
  Completer? _completer = null;
  // Release whoever is currently waiting and start waiting yourself.
  Future wait([v]) {
    _completer?.complete(v);
    _completer = Completer();
    return _completer!.future;
  }

  // Release whoever is currently waiting.
  void release([v]) {
    _completer?.complete(v);
    _completer = null;
  }
}

expectList(stream, list) {
  return stream.toList().then((v) {
    expect(v, equals(list));
  });
}

Stream<int> mkStream(int n) async* {
  for (int i = 0; i < n; i++) yield i;
}
