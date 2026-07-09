// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These test cases verify that the identifier `new` can be used anywhere a
// constructor name might appear.
//
// Unless otherwise noted, these tests cases should not result in a parse error.

/// See [C.new].
class C {
  C.new();

  // This should be result in a parse error--even though `C() : this.new();` is
  // allowed, `C() : this.new = ...;` should not be.
  C.constructor_field_initializer() : this.new = null;
}

class D {
  factory D.new() => C();
  factory D.factory_redirection() = C.new;
  factory D.factory_redirection_generic() = C<int>.new;
  factory D.factory_redirection_prefixed() = prefix.C.new;
  factory D.factory_redirection_prefixed_generic() = prefix.C<int>.new;
  D.super_invocation() : super.new();
  D.this_redirection() : this.new();
}

var constructor_invocation_const = const C.new();
var constructor_invocation_const_generic = const C<int>.new();
var constructor_invocation_const_prefixed = const prefix.C.new();
var constructor_invocation_const_prefixed_generic = const prefix.C<int>.new();
var constructor_invocation_explicit = new C.new();
var constructor_invocation_explicit_generic = new C<int>.new();
var constructor_invocation_explicit_prefixed = new prefix.C.new();
var constructor_invocation_explicit_prefixed_generic = new prefix.C<int>.new();
var constructor_invocation_implicit = C.new();
var constructor_invocation_implicit_generic = C<int>.new();
var constructor_invocation_implicit_prefixed = prefix.C.new();
var constructor_invocation_implicit_prefixed_generic = prefix.C<int>.new();
var constructor_tearoff = C.new;
var constructor_tearoff_generic = C<int>.new;
var constructor_tearoff_generic_method_invocation = C<int>.new.toString();
var constructor_tearoff_method_invocation = C.new.toString();
var constructor_tearoff_prefixed = prefix.C.new;
var constructor_tearoff_prefixed_generic = prefix.C<int>.new;
var constructor_tearoff_prefixed_generic_method_invocation =
    prefix.C<int>.new.toString();
var constructor_tearoff_prefixed_method_invocation = prefix.C.new.toString();
