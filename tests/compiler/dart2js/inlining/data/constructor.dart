// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  forceInlineConstructor();
  forceInlineConstructorBody();
  forceInlineGenericConstructor();
  forceInlineGenericFactory();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a constructor call.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*member: Class1.:[forceInlineConstructor:Class1]*/
  @pragma('dart2js:tryInline')
  Class1();
}

/*member: forceInlineConstructor:[]*/
@pragma('dart2js:noInline')
forceInlineConstructor() {
  new Class1();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a constructor call with non-empty constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.:[forceInlineConstructorBody+,forceInlineConstructorBody:Class2]*/
  @pragma('dart2js:tryInline')
  Class2() {
    print('foo');
  }
}

/*member: forceInlineConstructorBody:[]*/
@pragma('dart2js:noInline')
forceInlineConstructorBody() {
  new Class2();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a generic constructor call.
////////////////////////////////////////////////////////////////////////////////

class Class3<T> {
  /*spec:nnbd-off|prod:nnbd-off.member: Class3.:[forceInlineGenericConstructor:Class3<int>]*/
  /*spec:nnbd-sdk|prod:nnbd-sdk.member: Class3.:[forceInlineGenericConstructor:Class3<int*>]*/
  @pragma('dart2js:tryInline')
  Class3();
}

/*member: forceInlineGenericConstructor:[]*/
@pragma('dart2js:noInline')
forceInlineGenericConstructor() {
  new Class3<int>();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a generic factory call.
////////////////////////////////////////////////////////////////////////////////

class Class4a<T> implements Class4b<T> {
  /*spec:nnbd-off|prod:nnbd-off.member: Class4a.:[forceInlineGenericFactory:Class4a<int>]*/
  /*spec:nnbd-sdk|prod:nnbd-sdk.member: Class4a.:[forceInlineGenericFactory:Class4a<int*>]*/
  @pragma('dart2js:tryInline')
  Class4a();
}

class Class4b<T> {
  /*spec:nnbd-off|prod:nnbd-off.member: Class4b.:[forceInlineGenericFactory:Class4b<int>]*/
  /*spec:nnbd-sdk|prod:nnbd-sdk.member: Class4b.:[forceInlineGenericFactory:Class4b<int*>]*/
  @pragma('dart2js:tryInline')
  factory Class4b() => new Class4a<T>();
}

/*member: forceInlineGenericFactory:[]*/
@pragma('dart2js:noInline')
forceInlineGenericFactory() {
  new Class4b<int>();
}
