// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/type_arguments_lib1.dart' deferred as lib1;
import '../libs/type_arguments_lib2.dart' as lib2;
import '../libs/type_arguments_lib3.dart' deferred as lib3;

/*strong.member: main:OutputUnit(main, {})*/
/*strongConst.member: main:
 OutputUnit(main, {}),
 constants=[
  ConstructedConstant(A<B>())=OutputUnit(1, {lib1}),
  ConstructedConstant(A<F>())=OutputUnit(1, {lib1}),
  ConstructedConstant(C<D>())=OutputUnit(main, {}),
  ConstructedConstant(E<F>())=OutputUnit(3, {lib3})]
*/
main() async {
  await lib1.loadLibrary();
  lib1.field1;
  lib1.field2;
  lib2.field;
  lib3.field;
}
