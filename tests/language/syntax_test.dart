// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SyntaxTest {
  // "this" cannot be used as a field name.
  SyntaxTest this; //# 01: compile-time error

  // Syntax error.
  foo {} //# 02: compile-time error

  // Syntax error.
  static foo {} //# 03: compile-time error

  // Syntax error.
  operator +=() {} //# 04: compile-time error

  // Syntax error.
  operator -=() {} //# 05: compile-time error

  // Syntax error.
  operator *=() {} //# 06: compile-time error

  // Syntax error.
  operator /=() {} //# 07: compile-time error

  // Syntax error.
  operator ~/=() {} //# 08: compile-time error

  // Syntax error.
  operator %=() {} //# 09: compile-time error

  // Syntax error.
  operator <<=() {} //# 10: compile-time error

  // Syntax error.
  operator >>=() {} //# 11: compile-time error

  // Syntax error.
  operator >>>=() {} //# 12: compile-time error

  // Syntax error.
  operator &=() {} //# 13: compile-time error

  // Syntax error.
  operator ^=() {} //# 14: compile-time error

  // Syntax error.
  operator |=() {} //# 15: compile-time error

  // Syntax error.
  operator ?() {} //# 16: compile-time error

  // Syntax error.
  operator ||() {} //# 17: compile-time error

  // Syntax error.
  operator &&() {} //# 18: compile-time error

  // Syntax error.
  operator !=() {} //# 19: compile-time error

  // Syntax error.
  operator ===() {} //# 20: compile-time error

  // Syntax error.
  operator !==() {} //# 21: compile-time error

  // Syntax error.
  operator is() {} //# 22: compile-time error

  // Syntax error.
  operator !() {} //# 23: compile-time error

  // Syntax error.
  operator ++() {} //# 24: compile-time error

  // Syntax error.
  operator --() {} //# 25: compile-time error

  // Syntax error.
  bool operator ===(A other) { return true; } //# 26: compile-time error

  int sample;
}

fisk {} //# 27: compile-time error

class DOMWindow {}

class Window extends DOMWindow
native "*Window" //# 28: compile-time error
{}

class Console
native "=(typeof console == 'undefined' ? {} : console)" //# 29: compile-time error
{}

class NativeClass
native "FooBar" //# 30: compile-time error
{}

abstract class Fisk {}

class BoolImplementation implements Fisk
native "Boolean" //# 31: compile-time error
{}

class _JSON
native 'JSON' //# 32: compile-time error
{}

class ListFactory<E> implements List<E>
native "Array" //# 33: compile-time error
{}

abstract class I implements UNKNOWN; //# 34: compile-time error

class XWindow extends DOMWindow
hest "*Window" //# 35: compile-time error
{}

class XConsole
hest "=(typeof console == 'undefined' ? {} : console)" //# 36: compile-time error
{}

class XNativeClass
hest "FooBar" //# 37: compile-time error
{}

class XBoolImplementation implements Fisk
hest "Boolean" //# 38: compile-time error
{}

class _JSONX
hest 'JSON' //# 39: compile-time error
{}

class XListFactory<E> implements List<E>
hest "Array" //# 40: compile-time error
{}

class YWindow extends DOMWindow
for "*Window" //# 41: compile-time error
{}

class YConsole
for "=(typeof console == 'undefined' ? {} : console)" //# 42: compile-time error
{}

class YNativeClass
for "FooBar" //# 43: compile-time error
{}

class YBoolImplementation implements Fisk
for "Boolean" //# 44: compile-time error
{}

class _JSONY
for 'JSON' //# 45: compile-time error
{}

class YListFactory<E> implements List<E>
for "Array" //# 46: compile-time error
{}

class A {
  const A()
  {} //# 47: compile-time error
  ;
}

abstract class G<T> {}

typedef <T>(); //# 48: compile-time error

class B
extends void //# 49: compile-time error
{}

main() {
  try {
    new SyntaxTest();
    new SyntaxTest().foo(); //# 02: continued
    SyntaxTest.foo(); //# 03: continued
    fisk(); //# 27: continued

    new Window();
    new Console();
    new NativeClass();
    new BoolImplementation();
    new _JSON();
    new ListFactory();
    new ListFactory<Object>();
    var x = null;
    x is I; //# 34: continued

    new XConsole();
    new XNativeClass();
    new XBoolImplementation();
    new _JSONX();
    new XListFactory();
    new XListFactory<Object>();

    new YConsole();
    new YNativeClass();
    new YBoolImplementation();
    new _JSONY();
    new YListFactory();
    new YListFactory<Object>();

    futureOf(x) {}
    if (!(fisk futureOf(false))) {} //# 50: compile-time error
    if (!(await futureOf(false))) {} //# 51: compile-time error

    void f{} //# 52: compile-time error
    G<int double> g; //# 53: compile-time error
    f(void) {}; //# 54: compile-time error

    optionalArg([x]) {}
    optionalArg(
      void (var i) {} //# 55: compile-time error
        );

    function __PROTO__$(...args) { return 12; } //# 56: compile-time error
    G<> t; //# 57: compile-time error
    G<null> t; //# 58: compile-time error
    A<void> a = null; //# 59: compile-time error
    void v; //# 60: compile-time error
    void v = null; //# 61: compile-time error
    print(null is void); //# 62: compile-time error
    new A();
    new B();

    new Bad();

    1 + 2 = 1; //# 63: compile-time error
    new SyntaxTest() = 1; //# 64: compile-time error
    futureOf(null) = 1; //# 65: compile-time error

    new C();
  } catch (ex) {
    // Swallowing exceptions. Any error should be a compile-time error
    // which kills the current isolate.
  }
}

class Bad {
  factory Bad<Bad(String type) { return null; } //# 63: compile-time error
}

class C {
  void f; // //# 66: compile-time error
  static void g; // //# 67: compile-time error
}
