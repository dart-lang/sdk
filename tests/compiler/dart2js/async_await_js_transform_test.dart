// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:compiler/src/js/js.dart";
import "package:compiler/src/js/rewrite_async.dart";

import "backend_dart/dart_printer_test.dart" show PrintDiagnosticListener;

void testTransform(String source, String expected) {
  Fun fun = js(source);
  Fun rewritten = new AsyncRewriter(
      null, // The diagnostic helper should not be used in these tests.
      null,
      thenHelper: new VariableUse("thenHelper"),
      newCompleter: new VariableUse("Completer"),
      endOfIteration: new VariableUse("endOfIteration"),
      newIterable: new VariableUse("Iterator"),
      safeVariableName: (String name) => "__$name").rewrite(fun);
  Printer printer = new Printer(new PrintDiagnosticListener(), null);
  printer.visit(rewritten);
  Expect.stringEquals(expected, printer.outBuffer.getText());
}

main() {
  testTransform("""
function() async {
  print(this.x); // Ensure `this` is translated in the helper function.
  await foo();
}""", """
function() {
  var __goto = 0, __completer = new Completer(), __self = this;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
          print(__self.x);
          __goto = 1;
          return thenHelper(foo(), __helper, __completer, null);
        case 1:
          // returning from await.
          // implicit return
          return thenHelper(null, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");

  testTransform("""
function() async {
  try {
    __outer: while (true) { // Overlapping label name.
      try {
        inner: while (true) {
          break __outer; // Break from untranslated loop to translated target.
          break; // break to untranslated target.
        }
        while (true) {
          return; // Return via finallies.
        }
        var __helper = await foo(); // Overlapping variable name.
      } finally {
        foo();
        continue; // Continue from finally with pending finally.
        return 2; // Return from finally with pending finally.
      }
    }
  } finally {
    return 3; // Return from finally with no pending finally.
  }
  return 4;
}""", """
function() {
  var __goto = 0, __completer = new Completer(), __handler = null, __next, __returnValue, __helper;
  function __helper1(__result) {
    while (true)
      try {
        __outer1:
          switch (__goto) {
            case 0:
              // Function start
              __handler = 2;
            case 6:
              // continue __outer
            case 7:
              // while condition
              __handler = 9;
              inner: {
                while (true) {
                  __next = [5];
                  // goto finally
                  __goto = 10;
                  break __outer1;
                  break;
                }
              }
              while (true) {
                __next = [1, 3];
                // goto finally
                __goto = 10;
                break __outer1;
              }
              __goto = 12;
              return thenHelper(foo(), __helper1, __completer, function(__error) {
                __goto = 9;
                __helper1(__error);
              });
            case 12:
              // returning from await.
              __helper = __result;
              __next = [11];
              // goto finally
              __goto = 10;
              break;
            case 9:
              // catch
              __handler = 2;
              __next = [11];
            case 10:
              // finally
              __handler = 2;
              foo();
              // goto while condition
              __goto = 7;
              break;
              __returnValue = 2;
              __next = [1];
              // goto finally
              __goto = 3;
              break;
              // goto the next finally handler
              __goto = __next.pop();
              break;
            case 11:
              // after finally
              // goto while condition
              __goto = 7;
              break;
            case 8:
              // after while
            case 5:
              // break __outer
              __next = [4];
              // goto finally
              __goto = 3;
              break;
            case 2:
              // catch
              __handler = null;
              __next = [4];
            case 3:
              // finally
              __handler = null;
              __returnValue = 3;
              // goto return
              __goto = 1;
              break;
              // goto the next finally handler
              __goto = __next.pop();
              break;
            case 4:
              // after finally
              __returnValue = 4;
              // goto return
              __goto = 1;
              break;
            case 1:
              // return
              return thenHelper(__returnValue, null, __completer, null);
          }
      } catch (__error) {
        if (__handler === null)
          throw __error;
        __result = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __helper1, __completer, null);
}""");
  testTransform("""
function() async {
  var a, b, c, d, e, f;
  a = b++; // post- and preincrements.
  b = --b;
  c = (await foo()).a++;
  d = ++(await foo()).a;
  e = foo1()[await foo2()]--;
  f = --foo1()[await foo2()];
}""", """
function() {
  var __goto = 0, __completer = new Completer(), a, b, c, d, e, f, __temp1;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
          a = b++;
          b = --b;
          __goto = 1;
          return thenHelper(foo(), __helper, __completer, null);
        case 1:
          // returning from await.
          c = __result.a++;
          __goto = 2;
          return thenHelper(foo(), __helper, __completer, null);
        case 2:
          // returning from await.
          d = ++__result.a;
          __temp1 = foo1();
          __goto = 3;
          return thenHelper(foo2(), __helper, __completer, null);
        case 3:
          // returning from await.
          e = __temp1[__result]--;
          __temp1 = foo1();
          __goto = 4;
          return thenHelper(foo2(), __helper, __completer, null);
        case 4:
          // returning from await.
          f = --__temp1[__result];
          // implicit return
          return thenHelper(null, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");
  testTransform("""
function() async {
  var a, b, c, d, e, f, g, h; // empty initializer
  a = foo1() || await foo2(); // short circuiting operators
  b = await foo1() || foo2();
  c = await foo1() || foo3(await foo2());
  d = foo1() || foo2();
  e = foo1() && await foo2();
  f = await foo1() && foo2();
  g = await foo1() && await foo2();
  h = foo1() && foo2();
}""", """
function() {
  var __goto = 0, __completer = new Completer(), a, b, c, d, e, f, g, h, __temp1;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
          __temp1 = foo1();
          if (__temp1) {
            // goto then
            __goto = 1;
            break;
          } else
            __result = __temp1;
          // goto join
          __goto = 2;
          break;
        case 1:
          // then
          __goto = 3;
          return thenHelper(foo2(), __helper, __completer, null);
        case 3:
          // returning from await.
        case 2:
          // join
          a = __result;
          __goto = 4;
          return thenHelper(foo1(), __helper, __completer, null);
        case 4:
          // returning from await.
          b = __result || foo2();
          __goto = 7;
          return thenHelper(foo1(), __helper, __completer, null);
        case 7:
          // returning from await.
          __temp1 = __result;
          if (__temp1) {
            // goto then
            __goto = 5;
            break;
          } else
            __result = __temp1;
          // goto join
          __goto = 6;
          break;
        case 5:
          // then
          __temp1 = foo3;
          __goto = 8;
          return thenHelper(foo2(), __helper, __completer, null);
        case 8:
          // returning from await.
          __result = __temp1(__result);
        case 6:
          // join
          c = __result;
          d = foo1() || foo2();
          __temp1 = foo1();
          if (__temp1)
            __result = __temp1;
          else {
            // goto then
            __goto = 9;
            break;
          }
          // goto join
          __goto = 10;
          break;
        case 9:
          // then
          __goto = 11;
          return thenHelper(foo2(), __helper, __completer, null);
        case 11:
          // returning from await.
        case 10:
          // join
          e = __result;
          __goto = 12;
          return thenHelper(foo1(), __helper, __completer, null);
        case 12:
          // returning from await.
          f = __result && foo2();
          __goto = 15;
          return thenHelper(foo1(), __helper, __completer, null);
        case 15:
          // returning from await.
          __temp1 = __result;
          if (__temp1)
            __result = __temp1;
          else {
            // goto then
            __goto = 13;
            break;
          }
          // goto join
          __goto = 14;
          break;
        case 13:
          // then
          __goto = 16;
          return thenHelper(foo2(), __helper, __completer, null);
        case 16:
          // returning from await.
        case 14:
          // join
          g = __result;
          h = foo1() && foo2();
          // implicit return
          return thenHelper(null, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");
  testTransform("""
function(x, y) async {
  while (true) {
    switch(y) { // Switch with no awaits in case key expressions
      case 0:
      case 1: 
        await foo();
        continue; // Continue the loop, not the switch
      case 1: // Duplicate case
        await foo();
        break; // Break the switch
      case 2:
        foo(); // No default
    }
  }
}""", """
function(x, y) {
  var __goto = 0, __completer = new Completer();
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
        case 1:
          // while condition
        case 3:
          // switch
          switch (y) {
            case 0:
              // goto case
              __goto = 5;
              break;
            case 1:
              // goto case
              __goto = 6;
              break;
            case 1:
              // goto case
              __goto = 7;
              break;
            case 2:
              // goto case
              __goto = 8;
              break;
          }
          // goto after switch
          __goto = 4;
          break;
        case 5:
          // case
        case 6:
          // case
          __goto = 9;
          return thenHelper(foo(), __helper, __completer, null);
        case 9:
          // returning from await.
          // goto while condition
          __goto = 1;
          break;
        case 7:
          // case
          __goto = 10;
          return thenHelper(foo(), __helper, __completer, null);
        case 10:
          // returning from await.
          // goto after switch
          __goto = 4;
          break;
        case 8:
          // case
          foo();
        case 4:
          // after switch
          // goto while condition
          __goto = 1;
          break;
        case 2:
          // after while
          // implicit return
          return thenHelper(null, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");
  testTransform("""
function() async {
  do {
    var a = await foo();
    if (a) // If with no awaits in body
      break;
    else
      continue;
  } while (await foo());
}
""", """
function() {
  var __goto = 0, __completer = new Completer(), a;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
        case 1:
          // do body
          __goto = 4;
          return thenHelper(foo(), __helper, __completer, null);
        case 4:
          // returning from await.
          a = __result;
          if (a) {
            // goto after do
            __goto = 3;
            break;
          } else {
            // goto do condition
            __goto = 2;
            break;
          }
        case 2:
          // do condition
          __goto = 5;
          return thenHelper(foo(), __helper, __completer, null);
        case 5:
          // returning from await.
          if (__result) {
            // goto do body
            __goto = 1;
            break;
          }
        case 3:
          // after do
          // implicit return
          return thenHelper(null, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");

  testTransform("""
function() async {
  for (var i = 0; i < await foo1(); i += await foo2()) {
    if (foo(i))
      continue;
    else
      break;
    if (!foo(i)) { // If with no else and await in body.
      await foo();
      return;
    }
    print(await(foo(i)));
  } 
}
""", """
function() {
  var __goto = 0, __completer = new Completer(), __returnValue, i, __temp1;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
          i = 0;
        case 2:
          // for condition
          __temp1 = i;
          __goto = 5;
          return thenHelper(foo1(), __helper, __completer, null);
        case 5:
          // returning from await.
          if (!(__temp1 < __result)) {
            // goto after for
            __goto = 4;
            break;
          }
          if (foo(i)) {
            // goto for update
            __goto = 3;
            break;
          } else {
            // goto after for
            __goto = 4;
            break;
          }
          __goto = !foo(i) ? 6 : 7;
          break;
        case 6:
          // then
          __goto = 8;
          return thenHelper(foo(), __helper, __completer, null);
        case 8:
          // returning from await.
          // goto return
          __goto = 1;
          break;
        case 7:
          // join
          __temp1 = print;
          __goto = 9;
          return thenHelper(foo(i), __helper, __completer, null);
        case 9:
          // returning from await.
          __temp1(__result);
        case 3:
          // for update
          __goto = 10;
          return thenHelper(foo2(), __helper, __completer, null);
        case 10:
          // returning from await.
          i = __result;
          // goto for condition
          __goto = 2;
          break;
        case 4:
          // after for
        case 1:
          // return
          return thenHelper(__returnValue, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");

  testTransform("""
function(a) async {
  var x = {"a": foo1(), "b": await foo2(), "c": foo3()};
  x["a"] = 2; // Different assignments
  (await foo()).a = 3;
  x[await foo()] = 4;
  x[(await foo1()).a = await foo2()] = 5;
  (await foo1())[await foo2()] = await foo3(6);
}
""", """
function(a) {
  var __goto = 0, __completer = new Completer(), x, __temp1, __temp2;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
          __temp1 = foo1();
          __goto = 1;
          return thenHelper(foo2(), __helper, __completer, null);
        case 1:
          // returning from await.
          x = {a: __temp1, b: __result, c: foo3()};
          x.a = 2;
          __goto = 2;
          return thenHelper(foo(), __helper, __completer, null);
        case 2:
          // returning from await.
          __result.a = 3;
          __temp1 = x;
          __goto = 3;
          return thenHelper(foo(), __helper, __completer, null);
        case 3:
          // returning from await.
          __temp1[__result] = 4;
          __temp1 = x;
          __goto = 4;
          return thenHelper(foo1(), __helper, __completer, null);
        case 4:
          // returning from await.
          __temp2 = __result;
          __goto = 5;
          return thenHelper(foo2(), __helper, __completer, null);
        case 5:
          // returning from await.
          __temp1[__temp2.a = __result] = 5;
          __goto = 6;
          return thenHelper(foo1(), __helper, __completer, null);
        case 6:
          // returning from await.
          __temp1 = __result;
          __goto = 7;
          return thenHelper(foo2(), __helper, __completer, null);
        case 7:
          // returning from await.
          __temp2 = __result;
          __goto = 8;
          return thenHelper(foo3(6), __helper, __completer, null);
        case 8:
          // returning from await.
          __temp1[__temp2] = __result;
          // implicit return
          return thenHelper(null, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");
  testTransform("""
function(c) async {
  try {
    var x = c ? await foo() : foo(); // conditional
    var y = {};
  } catch (error) {
    try {
      x = c ? await fooError(error) : fooError(error);
    } catch (error) { // nested error handler with overlapping name
      y.x = foo(error);
    } finally {
      foo(x);
    }
  }
}
""", """
function(c) {
  var __goto = 0, __completer = new Completer(), __handler = null, x, y, __error1, __error2;
  function __helper(__result) {
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            __handler = 1;
            __goto = c ? 4 : 6;
            break;
          case 4:
            // then
            __goto = 7;
            return thenHelper(foo(), __helper, __completer, function(__error) {
              __goto = 1;
              __helper(__error);
            });
          case 7:
            // returning from await.
            // goto join
            __goto = 5;
            break;
          case 6:
            // else
            __result = foo();
          case 5:
            // join
            x = __result;
            y = {};
            __next = [3];
            __handler = null;
            // goto after finally
            __goto = 3;
            break;
          case 1:
            // catch
            __handler = null;
            __error1 = __result;
            __handler = 8;
            __goto = c ? 11 : 13;
            break;
          case 11:
            // then
            __goto = 14;
            return thenHelper(fooError(__error1), __helper, __completer, function(__error) {
              __goto = 8;
              __helper(__error);
            });
          case 14:
            // returning from await.
            // goto join
            __goto = 12;
            break;
          case 13:
            // else
            __result = fooError(__error1);
          case 12:
            // join
            x = __result;
            __next = [10];
            // goto finally
            __goto = 9;
            break;
          case 8:
            // catch
            __handler = null;
            __error2 = __result;
            y.x = foo(__error2);
            __handler = null;
            __next = [10];
          case 9:
            // finally
            __handler = null;
            foo(x);
            // goto the next finally handler
            __goto = __next.pop();
            break;
          case 10:
            // after finally
          case 3:
            // after finally
            // implicit return
            return thenHelper(null, null, __completer, null);
        }
      } catch (__error) {
        if (__handler === null)
          throw __error;
        __result = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __helper, __completer, null);
}""");
  testTransform("""
function(x, y) async {
  print(await(foo(x))); // calls
  (await print)(foo(x));
  print(foo(await x));
  await (print(foo(await x)));
  print(foo(x, await y, z));
}
""", """
function(x, y) {
  var __goto = 0, __completer = new Completer(), __temp1, __temp2, __temp3;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
          __temp1 = print;
          __goto = 1;
          return thenHelper(foo(x), __helper, __completer, null);
        case 1:
          // returning from await.
          __temp1(__result);
          __goto = 2;
          return thenHelper(print, __helper, __completer, null);
        case 2:
          // returning from await.
          __result(foo(x));
          __temp1 = print;
          __temp2 = foo;
          __goto = 3;
          return thenHelper(x, __helper, __completer, null);
        case 3:
          // returning from await.
          __temp1(__temp2(__result));
          __temp1 = print;
          __temp2 = foo;
          __goto = 5;
          return thenHelper(x, __helper, __completer, null);
        case 5:
          // returning from await.
          __goto = 4;
          return thenHelper(__temp1(__temp2(__result)), __helper, __completer, null);
        case 4:
          // returning from await.
          __temp1 = print;
          __temp2 = foo;
          __temp3 = x;
          __goto = 6;
          return thenHelper(y, __helper, __completer, null);
        case 6:
          // returning from await.
          __temp1(__temp2(__temp3, __result, z));
          // implicit return
          return thenHelper(null, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");
  testTransform("""
function(x, y) async {
  while (await(foo())) {
    lab: { // labelled statement
      switch(y) {
      case 0:
        foo();
      case 0: // Duplicate case
        print(await foo1(x));
        return y;
      case await bar(): // await in case
        print(await foobar(x));
        return y;
      case x:
        if (a) {
          throw new Error();
        } else {
          continue;
        }
      default: // defaul case
        break lab; // break to label
      }
      foo();
    }
  }
}""", """
function(x, y) {
  var __goto = 0, __completer = new Completer(), __returnValue, __temp1;
  function __helper(__result) {
    while (true)
      switch (__goto) {
        case 0:
          // Function start
        case 2:
          // while condition
          __goto = 4;
          return thenHelper(foo(), __helper, __completer, null);
        case 4:
          // returning from await.
          if (!__result) {
            // goto after while
            __goto = 3;
            break;
          }
        case 6:
          // continue lab
        case 7:
          // switch
          __temp1 = y;
          if (__temp1 === 0) {
            // goto case
            __goto = 9;
            break;
          }
          if (__temp1 === 0) {
            // goto case
            __goto = 10;
            break;
          }
          __goto = 12;
          return thenHelper(bar(), __helper, __completer, null);
        case 12:
          // returning from await.
          if (__temp1 === __result) {
            // goto case
            __goto = 11;
            break;
          }
          if (__temp1 === x) {
            // goto case
            __goto = 13;
            break;
          }
          // goto default
          __goto = 14;
          break;
        case 9:
          // case
          foo();
        case 10:
          // case
          __temp1 = print;
          __goto = 15;
          return thenHelper(foo1(x), __helper, __completer, null);
        case 15:
          // returning from await.
          __temp1(__result);
          __returnValue = y;
          // goto return
          __goto = 1;
          break;
        case 11:
          // case
          __temp1 = print;
          __goto = 16;
          return thenHelper(foobar(x), __helper, __completer, null);
        case 16:
          // returning from await.
          __temp1(__result);
          __returnValue = y;
          // goto return
          __goto = 1;
          break;
        case 13:
          // case
          if (a) {
            throw new Error();
          } else {
            // goto while condition
            __goto = 2;
            break;
          }
        case 14:
          // default
          // goto break lab
          __goto = 5;
          break;
        case 8:
          // after switch
          foo();
        case 5:
          // break lab
          // goto while condition
          __goto = 2;
          break;
        case 3:
          // after while
        case 1:
          // return
          return thenHelper(__returnValue, null, __completer, null);
      }
  }
  return thenHelper(null, __helper, __completer, null);
}""");
}