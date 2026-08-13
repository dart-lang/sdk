// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0(var this.str) {
  var str;
}

class C1(final this.str) {
  final str;
}

class C2(const this.str) {
  final str;
}

class S3(var str);
class C3(var super.str) extends S3;

class S4(final str);
class C4(final super.str) extends S4;


class S5(final str);
class C5(const super.str) extends S5;
