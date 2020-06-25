// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  nestedGenericInlining();
  nestedGenericFactoryInlining();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a generic constructor calls.
////////////////////////////////////////////////////////////////////////////////

class Class1<T> {
  @pragma('dart2js:tryInline')
  /*member: Class1.:[nestedGenericInlining:Class1<int*>]*/
  Class1();

  /*member: Class1.method:[nestedGenericInlining]*/
  @pragma('dart2js:tryInline')
  method() {
    new Class2<List<T>>().method();
  }
}

class Class2<T> {
  // TODO(johnniwinther): Should the type have been Class<List<int>>?
  // Similarly below.
  @pragma('dart2js:tryInline')
  /*member: Class2.:[nestedGenericInlining:Class2<List<Class1.T*>*>]*/
  Class2();

  /*member: Class2.method:[nestedGenericInlining]*/
  @pragma('dart2js:tryInline')
  method() {}
}

/*member: nestedGenericInlining:[]*/
@pragma('dart2js:noInline')
nestedGenericInlining() {
  new Class1<int>().method();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline of generic factories.
////////////////////////////////////////////////////////////////////////////////

class Class3a<T> implements Class3b<T> {
  @pragma('dart2js:tryInline')
  /*member: Class3a.:[nestedGenericFactoryInlining:Class3a<int*>]*/
  Class3a();

  /*member: Class3a.method:[nestedGenericFactoryInlining]*/
  @pragma('dart2js:tryInline')
  method() {
    new Class4b<List<T>>().method();
  }
}

abstract class Class3b<T> {
  @pragma('dart2js:tryInline')
  /*member: Class3b.:[nestedGenericFactoryInlining:Class3b<int*>]*/
  factory Class3b() => new Class3a<T>();

  method();
}

class Class4a<T> implements Class4b<T> {
  @pragma('dart2js:tryInline')
  /*member: Class4a.:[nestedGenericFactoryInlining:Class4a<Class4b.T*>]*/
  Class4a();

  /*member: Class4a.method:[nestedGenericFactoryInlining]*/
  @pragma('dart2js:tryInline')
  method() {}
}

abstract class Class4b<T> {
  @pragma('dart2js:tryInline')
  /*member: Class4b.:[nestedGenericFactoryInlining:Class4b<List<Class3a.T*>*>]*/
  factory Class4b() => new Class4a<T>();

  method();
}

/*member: nestedGenericFactoryInlining:[]*/
@pragma('dart2js:noInline')
nestedGenericFactoryInlining() {
  new Class3b<int>().method();
}
