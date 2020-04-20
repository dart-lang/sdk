// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import "opt_out.dart";

/*class: A_dynamic:A<dynamic>,A_dynamic,Object*/
class A_dynamic implements A<dynamic> {}

/*class: A_void:A<void>,A_void,Object*/
class A_void implements A<void> {}

/*class: B1:A<Object?>,A_Object,A_dynamic,B1,Object*/
class B1 extends A_Object implements A_dynamic {}

/*cfe|cfe:builder.class: B2:A<void>,A_Object,A_void,B2,Object*/
/*analyzer.class: B2:A<Object?>,A_Object,A_void,B2,Object*/
class B2 extends A_Object implements A_void {}

main() {}
