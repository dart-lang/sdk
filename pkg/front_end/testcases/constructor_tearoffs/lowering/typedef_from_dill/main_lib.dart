// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  A();
  A.named(T a, [int? b]);
  factory A.fact(T a, {int? b, int c = 42}) => new A();
  factory A.redirect() = A;
}

typedef F<X, Y> = A<Y>;
typedef G<X, Y> = A<Y>;

dynamic F_new_lib = F.new;
dynamic F_named_lib = F.named;
dynamic F_fact_lib = F.fact;
dynamic F_redirect_lib = F.redirect;

dynamic G_new_lib = G.new;
dynamic G_named_lib = G.named;
dynamic G_fact_lib = G.fact;
dynamic G_redirect_lib = G.redirect;