// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_implementing_value_types`

class Size { // OK
  final int inBytes;
  const Size(this.inBytes);

  @override
  bool operator ==(Object o) => o is Size && o.inBytes == inBytes;

  @override
  int get hashCode => inBytes.hashCode;
}

class SizeWithKilobytes extends Size { // OK
  SizeWithKilobytes(int inBytes) : super(inBytes);

  double get inKilobytes => inBytes / 1000;
}

class EmptyFileSize1 implements Size { // LINT
  @override
  int get inBytes => 0;
}

class EmptyFileSize2 implements SizeWithKilobytes { // LINT
  @override
  int get inBytes => 0;

  @override
  double get inKilobytes => 0.0;
}

abstract class SizeClassMixin { // OK
  int get inBytes => 0;

  @override
  bool operator ==(Object o) => o is Size && o.inBytes == o.inBytes;

  @override
  int get hashCode => inBytes.hashCode;
}

class UsesSizeClassMixin extends Object with SizeClassMixin {} // OK
