// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

void main() {
  checkClass();
  checkExtensionType();
}

class AssertIdentical {
  // The "message" of the assert is not a valid constant string expression,
  // but it is only evaluated if the assertion fails,
  // and the CFE helpfully prints a string representation of the value
  // that can't be converted to a string by the potentially constant expression.
  const AssertIdentical(Object? v1, Object? v2)
      : assert(identical(v1, v2), "${(v1, v2)}");
  const AssertIdentical.not(Object? v1, Object? v2)
      : assert(!identical(v1, v2), "${(v1, v2)}");
}

class C<T> {
  final T value;
  C(this.value);
  C.named(this.value);
  C.redirect(T value) : this.named(value);
  factory C.factory(T value) => C<T>(value);
  factory C.factoryRedirect(T value) = C<T>;
}

// Non-generic (always instantiated) alias.
typedef ACI = C<int>;
// Renaming generic alias.
typedef ACR<T> = C<T>;
// Non-renaming generic alias.
typedef ACN<T extends num> = C<T>;

void checkClass() {
  // Generic class constructor tear-offs are constant and canonicalized if:
  // * Uninstantiated.
  // * Instantiated with constant type.
  const AssertIdentical(C.new, C.new);
  const AssertIdentical(C.named, C.named);
  const AssertIdentical(C.redirect, C.redirect);
  const AssertIdentical(C.factory, C.factory);
  const AssertIdentical(C.factoryRedirect, C.factoryRedirect);
  const AssertIdentical(C<int>.new, C<int>.new);
  const AssertIdentical(C<int>.named, C<int>.named);
  const AssertIdentical(C<int>.redirect, C<int>.redirect);
  const AssertIdentical(C<int>.factory, C<int>.factory);
  const AssertIdentical(C<int>.factoryRedirect, C<int>.factoryRedirect);

  // Generic class constructor tear-off through a non-generic or
  // instantiated alias is canonicalized to same constructor
  // as tear-off from the alias-expanded type.
  const AssertIdentical(ACI.new, C<int>.new);
  const AssertIdentical(ACI.named, C<int>.named);
  const AssertIdentical(ACI.redirect, C<int>.redirect);
  const AssertIdentical(ACI.factory, C<int>.factory);
  const AssertIdentical(ACI.factoryRedirect, C<int>.factoryRedirect);

  const AssertIdentical(ACR<int>.new, C<int>.new);
  const AssertIdentical(ACR<int>.named, C<int>.named);
  const AssertIdentical(ACR<int>.redirect, C<int>.redirect);
  const AssertIdentical(ACR<int>.factory, C<int>.factory);
  const AssertIdentical(ACR<int>.factoryRedirect, C<int>.factoryRedirect);

  const AssertIdentical(ACN<int>.new, C<int>.new);
  const AssertIdentical(ACN<int>.named, C<int>.named);
  const AssertIdentical(ACN<int>.redirect, C<int>.redirect);
  const AssertIdentical(ACN<int>.factory, C<int>.factory);
  const AssertIdentical(ACN<int>.factoryRedirect, C<int>.factoryRedirect);

  // Generic class constructor tear-off through uninstantiated
  // alias is canonicalized to same constructor as tear-off from
  // the uninitialized aliased class *if and only if* the alias is
  // a "proper rename" for that class declaration:
  // same type parameters, same order, same bounds, forwarded directly.
  const AssertIdentical(ACR.new, C.new);
  const AssertIdentical(ACR.named, C.named);
  const AssertIdentical(ACR.redirect, C.redirect);
  const AssertIdentical(ACR.factory, C.factory);
  const AssertIdentical(ACR.factoryRedirect, C.factoryRedirect);

  const AssertIdentical.not(ACN.new, C.new);
  const AssertIdentical.not(ACN.named, C.named);
  const AssertIdentical.not(ACN.redirect, C.redirect);
  const AssertIdentical.not(ACN.factory, C.factory);
  const AssertIdentical.not(ACN.factoryRedirect, C.factoryRedirect);
}

extension type E<T>(T value) {
  E.named(this.value);
  E.redirect(T value) : this.named(value);
  factory E.factory(T value) => E<T>(value);
  factory E.factoryRedirect(T value) = E<T>;
}

// Non-generic (always instantiated) alias.
typedef AEI = E<int>;
// Renaming generic alias.
typedef AER<T> = E<T>;
// Non-renaming generic alias.
typedef AEN<T extends num> = E<T>;

void checkExtensionType() {
  // Extension type constructor-tear-offs should work the same as classes.

  // Generic extension type tear-offs are constant and canonicalized if:
  // * Uninstantiated.
  // * Instantiated with constant type.
  const AssertIdentical(E.new, E.new);
  const AssertIdentical(E.named, E.named);
  const AssertIdentical(E.redirect, E.redirect);
  const AssertIdentical(E.factory, E.factory);
  const AssertIdentical(E.factoryRedirect, E.factoryRedirect);
  const AssertIdentical(E<int>.new, E<int>.new);
  const AssertIdentical(E<int>.named, E<int>.named);
  const AssertIdentical(E<int>.redirect, E<int>.redirect);
  const AssertIdentical(E<int>.factory, E<int>.factory);
  const AssertIdentical(E<int>.factoryRedirect, E<int>.factoryRedirect);

  // Generic extension-type constructor tear-off through a non-generic or
  // instantiated alias is canonicalized to same constructor
  // as tear-off from the alias-expanded type.
  const AssertIdentical(AEI.new, E<int>.new);
  const AssertIdentical(AEI.named, E<int>.named);
  const AssertIdentical(AEI.redirect, E<int>.redirect);
  const AssertIdentical(AEI.factory, E<int>.factory);
  const AssertIdentical(AEI.factoryRedirect, E<int>.factoryRedirect);

  const AssertIdentical(AER<int>.new, E<int>.new);
  const AssertIdentical(AER<int>.named, E<int>.named);
  const AssertIdentical(AER<int>.redirect, E<int>.redirect);
  const AssertIdentical(AER<int>.factory, E<int>.factory);
  const AssertIdentical(AER<int>.factoryRedirect, E<int>.factoryRedirect);

  const AssertIdentical(AEN<int>.new, E<int>.new);
  const AssertIdentical(AEN<int>.named, E<int>.named);
  const AssertIdentical(AEN<int>.redirect, E<int>.redirect);
  const AssertIdentical(AEN<int>.factory, E<int>.factory);
  const AssertIdentical(AEN<int>.factoryRedirect, E<int>.factoryRedirect);

  // Generic extension type constructor tear-off through uninstantiated
  // alias is canonicalized to same constructor as tear-off from
  // the uninitialized aliased class *if and only if* the alias is
  // a "proper rename" for that extension type declaration:
  // same type parameters, same order, same bounds, forwarded directly.
  const AssertIdentical(AER.new, E.new); // CFE Error
  const AssertIdentical(AER.named, E.named); // CFE Error
  const AssertIdentical(AER.redirect, E.redirect); // CFE Error
  const AssertIdentical(AER.factory, E.factory); // CFE Error
  const AssertIdentical(AER.factoryRedirect, E.factoryRedirect); // CFE Error

  // Added to see if the non-identical value is itself consistent. (It is.)
  // Redundant if the tests above were successful.
  const AssertIdentical(AER.new, AER.new);
  const AssertIdentical(AER.named, AER.named);
  const AssertIdentical(AER.redirect, AER.redirect);
  const AssertIdentical(AER.factory, AER.factory);
  const AssertIdentical(AER.factoryRedirect, AER.factoryRedirect);

  const AssertIdentical.not(AEN.new, E.new);
  const AssertIdentical.not(AEN.named, E.named);
  const AssertIdentical.not(AEN.redirect, E.redirect);
  const AssertIdentical.not(AEN.factory, E.factory);
  const AssertIdentical.not(AEN.factoryRedirect, E.factoryRedirect);
}