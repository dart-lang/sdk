// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'private_members_part.dart';

main() {
  _Class c = new _Class();
  c._privateField1 = c._privateField1;
  c._privateField2 = c._privateField2;
  c._privateFinalField1;
  c._privateFinalField2;
  _Extension._privateField1 = _Extension._privateField1;
  _Extension._privateField2 = _Extension._privateField2;
  _Extension._privateFinalField1;
  _Extension._privateFinalField2;
}
