// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class D {
  StreamSubscription? _subscriptionD; // OK
  void init(Stream stream) {
    _subscriptionD = stream.listen((_) {});
  }
  void _cancel() {
    if (_subscriptionD != null) {
      _subscriptionD!.cancel();
      _subscriptionD = null;
    }
  }
}
