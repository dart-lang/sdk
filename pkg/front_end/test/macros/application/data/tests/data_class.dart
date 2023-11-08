// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Foo:DataClass.new()
Definition Order:
 Foo:DataClass.new()
Definitions:
import 'dart:core' as prefix0;

augment class Foo {
augment prefix0.int get hashCode {
    return this.bar.hashCode ^ this.baz.hashCode;
  }
augment prefix0.bool operator ==(prefix0.Object other, ) {
    if (prefix0.identical(this, other)) return true;
    return other is Foo && this.bar == other.bar && this.baz == other.baz;
  }
augment prefix0.String toString() {
    return "Foo(bar=${this.bar},baz=${this.baz})";
  }
}*/

import 'package:macro/data_class.dart';

@DataClass()
/*class: Foo:
declarations:
import 'dart:core' as prefix0;

augment class Foo {
const Foo({required this.bar, required this.baz});
external prefix0.int get hashCode;
external prefix0.bool operator ==(prefix0.Object other);
external prefix0.String toString();
}
definitions:
augment class Foo {
augment int get hashCode {
    return bar.hashCode ^ baz.hashCode;
  }
augment bool operator ==(Object other, ) {
    if (identical(this, other)) return true;
    return other is Foo && bar == other.bar && baz == other.baz;
  }
augment String toString() {
    return "Foo(bar=${bar},baz=${baz})";
  }
}*/
class Foo {
  final int bar;
  final String baz;
}
