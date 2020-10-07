// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int? field;
  int? method() => field;
  Class operator +(Class other) => new Class();
}

main() {
  Class? c = new Class() as Class?;
  c!;
  c!.field;
  c!.field = 42;
  c!.method;
  c!.method();
  c!.field!.toString();
  c!.method()!.toString();
  c! + c;
  c! + c!;
  c + c!;
  (c + c)!;

  bool? o = true as bool?;
  !o! ? !o! : !!o!!;
  !(o!) ? (!o)! : (!(!o)!)!;
}
