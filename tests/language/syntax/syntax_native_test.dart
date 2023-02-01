// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
{
  noSuchMethod(_) => null; // Allow unimplemented methods
}

main() {
  try {
    new Window();
    new Console();
    new NativeClass();
    new BoolImplementation();
    new _JSON();
    new ListFactory();
    new ListFactory<Object>();
  } catch (ex) {
    // Swallowing exceptions. Any error should be a compile-time error
    // which kills the current isolate.
  }
}
