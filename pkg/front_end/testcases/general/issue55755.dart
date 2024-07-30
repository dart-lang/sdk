// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  const Class([a]);
  const Class.named({a, b});
}

class GenericClass<X, Y> {
  const GenericClass();
  const GenericClass.named({a, b});
}

typedef Alias = Class;
typedef ComplexAlias<X> = Class;
typedef GenericAlias<X, Y> = GenericClass<X, Y>;

@Class(Alias.named())
@Class(ComplexAlias())
@Class(ComplexAlias.named())
@Class(GenericAlias())
@Class(GenericAlias.named())
void type() {}
