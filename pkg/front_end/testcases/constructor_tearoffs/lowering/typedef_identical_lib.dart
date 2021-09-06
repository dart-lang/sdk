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

var F_new_lib = F.new;
var F_named_lib = F.named;
var F_fact_lib = F.fact;
var F_redirect_lib = F.redirect;

var G_new_lib = G.new;
var G_named_lib = G.named;
var G_fact_lib = G.fact;
var G_redirect_lib = G.redirect;