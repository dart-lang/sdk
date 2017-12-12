// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  nestedGenericInlining();
  nestedGenericFactoryInlining();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a generic constructor calls.
////////////////////////////////////////////////////////////////////////////////

class Class1<T> {
  /*element: Class1.:[nestedGenericInlining:Class1<int>]*/
  @ForceInline()
  Class1();

  /*element: Class1.method:[nestedGenericInlining]*/
  @ForceInline()
  method() {
    new Class2<List<T>>().method();
  }
}

class Class2<T> {
  // TODO(johnniwinther): Should the type have been Class<List<int>>?
  // Similarly below.
  /*element: Class2.:[nestedGenericInlining:Class2<List<Class1.T>>]*/
  @ForceInline()
  Class2();

  /*element: Class2.method:[nestedGenericInlining]*/
  @ForceInline()
  method() {}
}

/*element: nestedGenericInlining:[]*/
@NoInline()
nestedGenericInlining() {
  new Class1<int>().method();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline of generic factories.
////////////////////////////////////////////////////////////////////////////////

class Class3a<T> implements Class3b<T> {
  /*element: Class3a.:[nestedGenericFactoryInlining:Class3a<int>]*/
  @ForceInline()
  Class3a();

  /*element: Class3a.method:[nestedGenericFactoryInlining]*/
  @ForceInline()
  method() {
    new Class4b<List<T>>().method();
  }
}

abstract class Class3b<T> {
  /*element: Class3b.:[nestedGenericFactoryInlining:Class3b<int>]*/
  @ForceInline()
  factory Class3b() => new Class3a<T>();

  method();
}

class Class4a<T> implements Class4b<T> {
  /*element: Class4a.:[nestedGenericFactoryInlining:Class4a<Class4b.T>]*/
  @ForceInline()
  Class4a();

  /*element: Class4a.method:[nestedGenericFactoryInlining]*/
  @ForceInline()
  method() {}
}

abstract class Class4b<T> {
  /*element: Class4b.:[nestedGenericFactoryInlining:Class4b<List<Class3a.T>>]*/
  @ForceInline()
  factory Class4b() => new Class4a<T>();

  method();
}

/*element: nestedGenericFactoryInlining:[]*/
@NoInline()
nestedGenericFactoryInlining() {
  new Class3b<int>().method();
}
