// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EnumLike {
  final int value;

  const EnumLike._(this.value);

  @override
  bool operator ==(other);

  @override
  int get hashCode => value;

  static const EnumLike a = const EnumLike._(0);
  static const EnumLike b = const EnumLike._(1);

  static const List<EnumLike> values = [a, b];
}
