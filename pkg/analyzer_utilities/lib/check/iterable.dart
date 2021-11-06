// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';

extension IterableExtension<T> on CheckTarget<Iterable<T>> {
  void get isEmpty {
    if (value.isNotEmpty) {
      fail('is not empty');
    }
  }
}
