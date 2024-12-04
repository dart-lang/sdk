// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';

void main() async {
  asyncStart();

  var completer = Completer<void>();
  completer.complete(completer.future);
  await asyncExpectThrows(completer.future);

  completer = Completer<void>();
  completer.complete(Future.delayed(Duration.zero, () => completer.future));
  await asyncExpectThrows(completer.future);

  // Being a `sync` completer makes no difference when completing with a Future.
  // It does not complete synchronously with the error.
  completer = Completer<void>.sync();
  completer.complete(completer.future);
  await asyncExpectThrows(completer.future);

  completer = Completer<void>.sync();
  completer.complete(Future.delayed(Duration.zero, () => completer.future));
  await asyncExpectThrows(completer.future);
  asyncEnd();
}
