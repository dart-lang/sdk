// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class LoadElements {
  List call() => [];
}

class ViewModel {
  ViewModel(this._loadElements);

  final LoadElements _loadElements;

  void init() {
    final elements = _loadElements();
    for (final element in elements) {
      Expect.identical(element, element);
    }
  }
}

void main() {
  ViewModel(LoadElements()).init();
}
