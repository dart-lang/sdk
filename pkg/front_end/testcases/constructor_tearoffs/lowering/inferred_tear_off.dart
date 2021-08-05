// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var A_new = A.new;
var B_new = B.new;
var F_new = F.new;
var G_new = G.new;

class A {
  int field1 = 0;

  A(this.field1);
  A.named(this.field1);
}

class B<T> implements A {
  var field1;
  T field2;

  B(this.field1, this.field2);
  B.named(this.field1, this.field2);
}

typedef F<T> = A;
typedef G<T extends num> = B;

var A_named = A.named;
var B_named = B<int>.named;
var F_named = F.named;
var G_named = G<int>.named;

main() {}
