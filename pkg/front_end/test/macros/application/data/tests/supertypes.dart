// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Definition Order:
 A:SupertypesMacro.new()
 B:SupertypesMacro.new()
 M:SupertypesMacro.new()
 C:SupertypesMacro.new()
Definitions:
import 'dart:core' as prefix0;

augment class A {
augment prefix0.String getSuperClass() {
    return "null";
  }
}
augment class B {
augment prefix0.String getSuperClass() {
    return "A";
  }
}
augment mixin M {
augment prefix0.String getSuperClass() {
    return "null";
  }
}
augment class C {
augment prefix0.String getSuperClass() {
    return "A";
  }
}*/

import 'package:macro/macro.dart';

/*class: A:
definitions:
augment class A {
augment String getSuperClass() {
    return "null";
  }
}*/
@SupertypesMacro()
class A {
  external String getSuperClass();
}

/*class: B:
definitions:
augment class B {
augment String getSuperClass() {
    return "A";
  }
}*/
@SupertypesMacro()
class B extends A {
  external String getSuperClass();
}

/*class: M:
definitions:
augment class M {
augment String getSuperClass() {
    return "null";
  }
}*/
@SupertypesMacro()
mixin M {
  external String getSuperClass();
}

/*class: C:
definitions:
augment class C {
augment String getSuperClass() {
    return "A";
  }
}*/
@SupertypesMacro()
class C extends A with M {
  external String getSuperClass();
}
