// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Check that metadata constructor invocations can have type arguments.

@A<int>(0)
library generic_metadata_test;

@A<int>(0)
import "dart:core";

@A<int>(0)
export "dart:core";

// The annotation to use.
class A<T> {
  final T value;

  const A(this.value);
}

// Annotations on various declarations.

// Library declarations.
@A<int>(0)
const c = 0;

@A<int>(0)
final f = 0;

@A<int>(0)
void mp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

@A<int>(0)
void mn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

@A<int>(0)
int get g => 0;

@A<int>(0)
void set s(@A<int>(0) int x) {}

// Class declaration and members.
@A<int>(0)
class C<@A<int>(0) T> {
  final value;

  // Constructor and initializing formal.
  @A<int>(0)
  const C(@A<int>(0) this.value);

  @A<int>(0)
  C.genRed(@A<int>(0) int x) : this(x);

  @A<int>(0)
  factory C.fac(@A<int>(0) int x) => C(x);

  @A<int>(0)
  factory C.facRed(@A<int>(0) int x) = C;

  // Instance (virtual) declartions.
  @A<int>(0)
  final f = 0;

  @A<int>(0)
  void mp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

  @A<int>(0)
  void mn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

  @A<int>(0)
  int get g => 0;

  @A<int>(0)
  void set s(@A<int>(0) int x) {}

  @A<int>(0)
  int operator +(@A<int>(0) int x) => x;

  // Static declartions.
  @A<int>(0)
  static const sc = C<int>(0);

  @A<int>(0)
  static final sf = C<int>(0);

  @A<int>(0)
  static void smp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

  @A<int>(0)
  static void smn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

  @A<int>(0)
  static int get sg => 0;

  @A<int>(0)
  static void set ss(@A<int>(0) int x) {}
}

@A<int>(0)
abstract class AC<@A<int>(0) T> {
  // Instance (virtual) declartions.
  @A<int>(0)
  abstract final f;

  @A<int>(0)
  void mp(@A<int>(0) Object x, [@A<int>(0) int y = 0]);

  @A<int>(0)
  void mn(@A<int>(0) Object x, {@A<int>(0) int y = 0});

  @A<int>(0)
  int get g;

  @A<int>(0)
  void set s(@A<int>(0) int x);

  @A<int>(0)
  int operator +(@A<int>(0) int x);
}

@A<int>(0)
extension E<@A<int>(0) T> on T {
  // Instance extension member declartions.
  @A<int>(0)
  void mp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

  @A<int>(0)
  void mn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

  @A<int>(0)
  int get g => 0;

  @A<int>(0)
  void set s(@A<int>(0) int x) {}

  @A<int>(0)
  int operator +(@A<int>(0) int x) => x;

  // Static declartions.
  @A<int>(0)
  static const sc = C<int>(0);

  @A<int>(0)
  static final sf = C<int>(0);

  @A<int>(0)
  static void smp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

  @A<int>(0)
  static void smn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

  @A<int>(0)
  static int get sg => 0;

  @A<int>(0)
  static void set ss(@A<int>(0) int x) {}
}

@A<int>(0)
mixin M<@A<int>(0) T> {
  // Instance member declartions.
  @A<int>(0)
  final f = 0;

  @A<int>(0)
  void mp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

  @A<int>(0)
  void mn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

  @A<int>(0)
  int get g => 0;

  @A<int>(0)
  void set s(@A<int>(0) int x) {}

  @A<int>(0)
  int operator +(@A<int>(0) int x) => x;

  // Static declartions.
  @A<int>(0)
  static const sc = C<int>(0);

  @A<int>(0)
  static final sf = C<int>(0);

  @A<int>(0)
  static void smp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

  @A<int>(0)
  static void smn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

  @A<int>(0)
  static int get sg => 0;

  @A<int>(0)
  static void set ss(@A<int>(0) int x) {}
}

@A<int>(0)
enum En {
 @A<int>(0)
 foo
}

@A<int>(0)
typedef F<@A<int>(0) T> = int Function<@A<int>(0) X>(@A<int>(0) int);

void main() {
  // Function body declarations.
  @A<int>(0)
  const c = 0;

  @A<int>(0)
  final f = 0;

  @A<int>(0)
  void mp(@A<int>(0) Object x, [@A<int>(0) int y = 0]) {}

  @A<int>(0)
  void mn(@A<int>(0) Object x, {@A<int>(0) int y = 0}) {}

  @A<int>(0)
  void Function<@A<int>(0) X>(@A<int>(0) int y)? fv = null;

  // Recursive annotations.
  @A<void Function(@A<int>(0) int)?>(null)
  var x = 0;

  mn(c);
  mp(f);
  fv?.call(x);
}
