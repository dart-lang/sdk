// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class get getter1 => this;
  Class? get getter2 => field;
  Class? field;

  Class([this.field]);
}

main() {
  Class? c = new Class() as Class?;
  c?.getter1.getter2?.getter1.getter2?.field = c;
}
