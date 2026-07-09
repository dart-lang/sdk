// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Callback = void Function();

class Foo {
  late final Callback? _koCallback;
  final Callback? _okCallback;

  Foo({Callback? okCallback, Callback? koCallback}) : _okCallback = okCallback {
    _koCallback = koCallback;
  }

  void thisWorks() {
    _okCallback == null ? null : (value) => _okCallback();
  }

  void thisDoesNot() {
    _koCallback == null ? null : (value) => _koCallback();
  }
}
