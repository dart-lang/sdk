// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import "package:expect/expect.dart";
import "../static_type_helper.dart";

// Check that generic function types can be used as type arguments.

typedef F = T Function<T>(T);

class C<T> {
  final T value;
  const C(this.value);
}

T f<T>(T value) => value;

extension E<T> on T {
  T get extensionValue => this;
}

// A generic function type can be a type parameter bound.

// For a type alias:
typedef FB<T extends F> = S Function<S extends T>(S);

// For a class:
class CB<T extends FB<F>> {
  final T function;
  const CB(this.function);
}

// For a function:
T fb<T extends F>(T value) => value;

extension EB<T extends F> on T {
  T get boundExtensionValue => this;

  // Any function type has a `call` of its own type?
  T get boundCall => this.call;
}

// Can be used as arguments to metadata too.
@C<F>(f)
@CB<FB<F>>(fb)
void main() {
  // Sanity checks.
  Expect.type<F>(f);
  Expect.type<FB<F>>(fb);

  // A generic function type can be the argument to a generic class.
  var list = [f]; // Inferred from content.
  Expect.type<List<F>>(list);
  list = []; // Inferred from context.
  list.add(f);
  list = <F>[]; // Explicit.
  list.add(f);

  // Also if the type has a bound.
  var list2 = [fb];
  Expect.type<List<FB<F>>>(list2);

  // The instance is a subtype of its supertypes.
  Expect.type<List<Function>>(list);
  Expect.type<List<Object? Function<T>(Never)>>(list);
  Expect.notType<List<Object? Function(Never)>>(list);

  // A generic function type can be the argument to a generic function.
  var g1 = f(f); // inferred from argument.
  g1 = f(f); // Inferred from context.
  g1 = f<F>(f); // Explicit.
  g1.expectStaticType<Exactly<F>>();

  // Extensions can match generic function types.
  list.add(f.extensionValue);
  list.add(E(f).extensionValue);
  list.add(E<F>(f).extensionValue);
  list.add(f.boundExtensionValue);
  list.add(EB(f).boundExtensionValue);
  list.add(EB<F>(f).boundExtensionValue);
  list.add(f.boundCall);
  list.add(EB(f).boundCall);
  list.add(EB<F>(f).boundCall);
  list2.add(fb.extensionValue);
  list2.add(E(fb).extensionValue);
  list2.add(E<FB<F>>(fb).extensionValue);
}
