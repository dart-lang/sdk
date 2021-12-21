// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';

extension NullabilityExtension<T> on CheckTarget<T?> {
  CheckTarget<T> get isNotNull {
    final value = this.value;
    if (value == null) {
      fail('is null');
    }
    return nest(value, (value) => 'is not null');
  }

  void get isNull {
    if (value != null) {
      fail('is not null');
    }
  }
}
