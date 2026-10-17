// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension NullableObjectExtension on Object? {
  /// If the target is [T], return it, otherwise `null`.
  T? ifTypeOrNull<T>() {
    return this is T ? this : null;
  }
}
