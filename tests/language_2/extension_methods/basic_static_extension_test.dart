// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests the syntax of extension methods, and that the extensions are
// invocable, and that type variables are bound correctly.

// There are no extension *conflicts*.
// For each invocation,  there is exactly one extension member in scope
// which applies.

// Target types.
class Unnamed {}

class Named {}

class UnnamedGeneric<T> {}

class NamedGeneric<T> {}

String str(String name, Object object) =>
    "$name(${object == null ? "null" : "non-null"})";

// Unnamed local extension.
extension on Unnamed {
  String get name => str("unnamed", this);
}

extension NamedExt on Named {
  String get name => str("named", this);
}

extension<T> on UnnamedGeneric<T> {
  String get name => str("unnamed generic", this);
  List<T> get list => <T>[];
}

extension NamedGenericExt<T> on NamedGeneric<T> {
  String get name => str("named generic", this);
  List<T> get list => <T>[];
}

extension General on Object {
  String get generalName => str("general", this);
}

extension GeneralGeneric<T> on T {
  String get generalGenericName => str("general generic", this);
  List<T> get generalList => <T>[];
}

main() {
  // Unnamed.
  Unnamed unnamed = Unnamed();
  Unnamed unnamedNull = null;

  Expect.equals("unnamed(non-null)", unnamed.name);
  Expect.equals("unnamed(null)", unnamedNull.name);

  Expect.equals("general(non-null)", unnamed.generalName);
  Expect.equals("general(null)", unnamedNull.generalName);

  Expect.equals("general generic(non-null)", unnamed.generalGenericName);
  Expect.equals("general generic(null)", unnamedNull.generalGenericName);
  Expect.type<List<Unnamed>>(unnamed.generalList);
  Expect.type<List<Unnamed>>(unnamedNull.generalList);

  // Named.
  Named named = Named();
  Named namedNull = null;

  Expect.equals("named(non-null)", named.name);
  Expect.equals("named(null)", namedNull.name);

  Expect.equals("general(non-null)", named.generalName);
  Expect.equals("general(null)", namedNull.generalName);

  Expect.equals("general generic(non-null)", named.generalGenericName);
  Expect.equals("general generic(null)", namedNull.generalGenericName);
  Expect.type<List<Named>>(named.generalList);
  Expect.type<List<Named>>(namedNull.generalList);

  // Unnamed Generic.
  UnnamedGeneric<num> unnamedGeneric = UnnamedGeneric<int>();
  UnnamedGeneric<num> unnamedGenericNull = null;

  Expect.equals("unnamed generic(non-null)", unnamedGeneric.name);
  Expect.equals("unnamed generic(null)", unnamedGenericNull.name);
  Expect.type<List<num>>(unnamedGeneric.list);
  Expect.notType<List<int>>(unnamedGeneric.list);
  Expect.type<List<num>>(unnamedGenericNull.list);
  Expect.notType<List<int>>(unnamedGenericNull.list);

  Expect.equals("general(non-null)", unnamedGeneric.generalName);
  Expect.equals("general(null)", unnamedGenericNull.generalName);

  Expect.equals("general generic(non-null)", unnamedGeneric.generalGenericName);
  Expect.equals("general generic(null)", unnamedGenericNull.generalGenericName);
  Expect.type<List<UnnamedGeneric<num>>>(unnamedGeneric.generalList);
  Expect.type<List<UnnamedGeneric<num>>>(unnamedGenericNull.generalList);

  // Named Generic.
  NamedGeneric<num> namedGeneric = NamedGeneric<int>();
  NamedGeneric<num> namedGenericNull = null;

  Expect.equals("named generic(non-null)", namedGeneric.name);
  Expect.equals("named generic(null)", namedGenericNull.name);
  Expect.type<List<num>>(namedGeneric.list);
  Expect.notType<List<int>>(namedGeneric.list);
  Expect.type<List<num>>(namedGenericNull.list);
  Expect.notType<List<int>>(namedGenericNull.list);

  Expect.equals("general(non-null)", namedGeneric.generalName);
  Expect.equals("general(null)", namedGenericNull.generalName);

  Expect.equals("general generic(non-null)", namedGeneric.generalGenericName);
  Expect.equals("general generic(null)", namedGenericNull.generalGenericName);
  Expect.type<List<NamedGeneric<num>>>(namedGeneric.generalList);
  Expect.type<List<NamedGeneric<num>>>(namedGenericNull.generalList);
}
