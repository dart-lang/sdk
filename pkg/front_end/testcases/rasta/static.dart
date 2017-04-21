// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Foo {
  static const staticConstant = 42;
  static var staticField = 42;
  static staticFunction() {}

  static get staticGetter => null;
  static set staticSetter(_) {}
}

use(x) {
  if (x == new DateTime.now().millisecondsSinceEpoch) throw "Shouldn't happen";
}

main() {
  try {
    Foo.staticConstant;
    use(Foo.staticConstant);
    Foo.staticField;
    use(Foo.staticField);
    Foo.staticFunction;
    use(Foo.staticFunction);
    Foo.staticGetter;
    use(Foo.staticGetter);
    Foo.staticSetter;
    use(Foo.staticSetter);

    Foo.staticConstant++;
    use(Foo.staticConstant++);
    Foo.staticField++;
    use(Foo.staticField++);
    Foo.staticFunction++;
    use(Foo.staticFunction++);
    Foo.staticGetter++;
    use(Foo.staticGetter++);
    Foo.staticSetter++;
    use(Foo.staticSetter++);

    ++Foo.staticConstant;
    use(++Foo.staticConstant);
    ++Foo.staticField;
    use(++Foo.staticField);
    ++Foo.staticFunction;
    use(++Foo.staticFunction);
    ++Foo.staticGetter;
    use(++Foo.staticGetter);
    ++Foo.staticSetter;
    use(++Foo.staticSetter);

    Foo.staticConstant();
    use(Foo.staticConstant());
    Foo.staticField();
    use(Foo.staticField());
    Foo.staticFunction();
    use(Foo.staticFunction());
    Foo.staticGetter();
    use(Foo.staticGetter());
    Foo.staticSetter();
    use(Foo.staticSetter());

    Foo.staticConstant = 87;
    use(Foo.staticConstant = 87);
    Foo.staticField = 87;
    use(Foo.staticField = 87);
    Foo.staticFunction = 87;
    use(Foo.staticFunction = 87);
    Foo.staticGetter = 87;
    use(Foo.staticGetter = 87);
    Foo.staticSetter = 87;
    use(Foo.staticSetter = 87);

    Foo.staticConstant ??= 87;
    use(Foo.staticConstant ??= 87);
    Foo.staticField ??= 87;
    use(Foo.staticField ??= 87);
    Foo.staticFunction ??= 87;
    use(Foo.staticFunction ??= 87);
    Foo.staticGetter ??= 87;
    use(Foo.staticGetter ??= 87);
    Foo.staticSetter ??= 87;
    use(Foo.staticSetter ??= 87);
  } on NoSuchMethodError {
    // Expected.
  }
}
