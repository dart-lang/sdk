// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SyntaxTest {
  // "this" cannot be used as a field name.
  SyntaxTest this; //# 01: syntax error

  // Syntax error.
  foo {} //# 02: syntax error

  // Syntax error.
  static foo {} //# 03: syntax error

  // Syntax error.
  operator +=() {} //# 04: syntax error

  // Syntax error.
  operator -=() {} //# 05: syntax error

  // Syntax error.
  operator *=() {} //# 06: syntax error

  // Syntax error.
  operator /=() {} //# 07: syntax error

  // Syntax error.
  operator ~/=() {} //# 08: syntax error

  // Syntax error.
  operator %=() {} //# 09: syntax error

  // Syntax error.
  operator <<=() {} //# 10: syntax error

  // Syntax error.
  operator >>=() {} //# 11: syntax error

  // Syntax error.
  operator >>>=() {} //# 12: syntax error

  // Syntax error.
  operator &=() {} //# 13: syntax error

  // Syntax error.
  operator ^=() {} //# 14: syntax error

  // Syntax error.
  operator |=() {} //# 15: syntax error

  // Syntax error.
  operator ?() {} //# 16: syntax error

  // Syntax error.
  operator ||() {} //# 17: syntax error

  // Syntax error.
  operator &&() {} //# 18: syntax error

  // Syntax error.
  operator !=() {} //# 19: syntax error

  // Syntax error.
  operator ===() {} //# 20: syntax error

  // Syntax error.
  operator !==() {} //# 21: syntax error

  // Syntax error.
  operator is() {} //# 22: syntax error

  // Syntax error.
  operator !() {} //# 23: syntax error

  // Syntax error.
  operator ++() {} //# 24: syntax error

  // Syntax error.
  operator --() {} //# 25: syntax error

  // Syntax error.
  bool operator ===(A other) { return true; } //# 26: syntax error

  int sample;
}

fisk {} //# 27: syntax error

class DOMWindow {}

class Window extends DOMWindow
native "*Window" //# 28: syntax error
{}

class Console
native "=(typeof console == 'undefined' ? {} : console)" //# 29: syntax error
{}

class NativeClass
native "FooBar" //# 30: syntax error
{}

abstract class Fisk {}

class BoolImplementation implements Fisk
native "Boolean" //# 31: syntax error
{}

class _JSON
native 'JSON' //# 32: syntax error
{}

class ListFactory<E> implements List<E>
native "Array" //# 33: syntax error
{}

abstract class I implements UNKNOWN; //# 34: syntax error

class XWindow extends DOMWindow
hest "*Window" //# 35: syntax error
{}

class XConsole
hest "=(typeof console == 'undefined' ? {} : console)" //# 36: syntax error
{}

class XNativeClass
hest "FooBar" //# 37: syntax error
{}

class XBoolImplementation implements Fisk
hest "Boolean" //# 38: syntax error
{}

class _JSONX
hest 'JSON' //# 39: syntax error
{}

class XListFactory<E> implements List<E>
hest "Array" //# 40: syntax error
{}

class YWindow extends DOMWindow
for "*Window" //# 41: syntax error
{}

class YConsole
for "=(typeof console == 'undefined' ? {} : console)" //# 42: syntax error
{}

class YNativeClass
for "FooBar" //# 43: syntax error
{}

class YBoolImplementation implements Fisk
for "Boolean" //# 44: syntax error
{}

class _JSONY
for 'JSON' //# 45: syntax error
{}

class YListFactory<E> implements List<E>
for "Array" //# 46: syntax error
{}

class A {
  const A()
  {} //# 47: syntax error
  ;
}

abstract class G<T> {}

typedef <T>(); //# 48: syntax error

class B
extends void //# 49: syntax error
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
    if (!(fisk futureOf(false))) {} //# 50: syntax error
    if (!(await futureOf(false))) {} //# 51: compile-time error

    void f{} //# 52: syntax error
    G<int double> g; //# 53: syntax error
    f(void) {}; //# 54: syntax error

    optionalArg([x]) {}
    optionalArg(
      void (var i) {} //# 55: syntax error
        );

    function __PROTO__$(...args) { return 12; } //# 56: syntax error
    G<> t; //# 57: syntax error
    G<null> t; //# 58: syntax error
    A<void> a = null;
    void v;
    void v = null;
    print(null is void); //# 59: syntax error
    new A();
    new B();

    new Bad();

    1 + 2 = 1; //# 60: syntax error
    new SyntaxTest() = 1; //# 61: syntax error
    futureOf(null) = 1; //# 62: syntax error

    new C();
  } catch (ex) {
    // Swallowing exceptions. Any error should be a compile-time error
    // which kills the current isolate.
  }
}

class Bad {
  factory Bad<Bad(String type) { return null; } //# 63: syntax error
}

class C {
  void f;
  static void g;
}
