// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'private_members_part.dart';

test(_AbstractClass c) {
  c._privateAbstractField = c._privateAbstractField;
}

main() {
  _Class c = new _Class._privateConstructor();
  c = new _Class._privateRedirectingFactory();
  c._privateMethod();
  c._privateSetter = c._privateGetter;
  c._privateField = c._privateField;
  c._privateFinalField;
  0._privateMethod();
  (0._privateMethod)();
  0._privateSetter = 0._privateGetter;
  _Extension._privateField = _Extension._privateField;
  _Extension._privateFinalField;
}
