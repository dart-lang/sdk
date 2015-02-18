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
      asyncHelper: new VariableUse("thenHelper"),
      newCompleter: new VariableUse("Completer"),
      endOfIteration: new VariableUse("endOfIteration"),
      newIterable: new VariableUse("Iterator"),
      safeVariableName: (String name) => "__$name").rewrite(fun);

  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions();
  SimpleJavaScriptPrintingContext context =
      new SimpleJavaScriptPrintingContext();
  Printer printer = new Printer(options, context);
  printer.visit(rewritten);
  Expect.stringEquals(expected, context.getText());
}

main() {
  testTransform("""
function(a) async {
  print(this.x); // Ensure `this` is translated in the helper function.
  await foo();
}""", """
function(a) {
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError, __self = this;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            print(__self.x);
            __goto = 2;
            return thenHelper(foo(), __body, __completer);
          case 2:
            // returning from await.
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(b) async {
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
function(b) {
  var __goto = 0, __completer = new Completer(), __handler = 2, __currentError, __next, __returnValue, __helper;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        __outer1:
          switch (__goto) {
            case 0:
              // Function start
              __handler = 3;
            case 7:
              // continue __outer
            case 8:
              // while condition
              __handler = 10;
              inner: {
                while (true) {
                  __next = [6];
                  // goto finally
                  __goto = 11;
                  break __outer1;
                  break;
                }
              }
              while (true) {
                __next = [1, 4];
                // goto finally
                __goto = 11;
                break __outer1;
              }
              __goto = 13;
              return thenHelper(foo(), __body, __completer);
            case 13:
              // returning from await.
              __helper = __result;
              __next = [12];
              // goto finally
              __goto = 11;
              break;
            case 10:
              // uncaught
              __next = [3];
            case 11:
              // finally
              __handler = 3;
              foo();
              // goto while condition
              __goto = 8;
              break;
              __returnValue = 2;
              __next = [1];
              // goto finally
              __goto = 4;
              break;
              // goto the next finally handler
              __goto = __next.pop();
              break;
            case 12:
              // after finally
              // goto while condition
              __goto = 8;
              break;
            case 9:
              // after while
            case 6:
              // break __outer
              __next = [5];
              // goto finally
              __goto = 4;
              break;
            case 3:
              // uncaught
              __next = [2];
            case 4:
              // finally
              __handler = 2;
              __returnValue = 3;
              // goto return
              __goto = 1;
              break;
              // goto the next finally handler
              __goto = __next.pop();
              break;
            case 5:
              // after finally
              __returnValue = 4;
              // goto return
              __goto = 1;
              break;
            case 1:
              // return
              return thenHelper(__returnValue, 0, __completer, null);
            case 2:
              // rethrow
              return thenHelper(__currentError, 1, __completer);
          }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(c) async {
  var a, b, c, d, e, f;
  a = b++; // post- and preincrements.
  b = --b;
  c = (await foo()).a++;
  d = ++(await foo()).a;
  e = foo1()[await foo2()]--;
  f = --foo1()[await foo2()];
}""", """
function(c) {
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError, a, b, c, d, e, f, __temp1;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            a = b++;
            b = --b;
            __goto = 2;
            return thenHelper(foo(), __body, __completer);
          case 2:
            // returning from await.
            c = __result.a++;
            __goto = 3;
            return thenHelper(foo(), __body, __completer);
          case 3:
            // returning from await.
            d = ++__result.a;
            __temp1 = foo1();
            __goto = 4;
            return thenHelper(foo2(), __body, __completer);
          case 4:
            // returning from await.
            e = __temp1[__result]--;
            __temp1 = foo1();
            __goto = 5;
            return thenHelper(foo2(), __body, __completer);
          case 5:
            // returning from await.
            f = --__temp1[__result];
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(d2) async {
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
function(d2) {
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError, a, b, c, d, e, f, g, h, __temp1;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            __temp1 = foo1();
            if (__temp1) {
              // goto then
              __goto = 2;
              break;
            } else
              __result = __temp1;
            // goto join
            __goto = 3;
            break;
          case 2:
            // then
            __goto = 4;
            return thenHelper(foo2(), __body, __completer);
          case 4:
            // returning from await.
          case 3:
            // join
            a = __result;
            __goto = 5;
            return thenHelper(foo1(), __body, __completer);
          case 5:
            // returning from await.
            b = __result || foo2();
            __goto = 8;
            return thenHelper(foo1(), __body, __completer);
          case 8:
            // returning from await.
            __temp1 = __result;
            if (__temp1) {
              // goto then
              __goto = 6;
              break;
            } else
              __result = __temp1;
            // goto join
            __goto = 7;
            break;
          case 6:
            // then
            __temp1 = foo3;
            __goto = 9;
            return thenHelper(foo2(), __body, __completer);
          case 9:
            // returning from await.
            __result = __temp1(__result);
          case 7:
            // join
            c = __result;
            d = foo1() || foo2();
            __temp1 = foo1();
            if (__temp1)
              __result = __temp1;
            else {
              // goto then
              __goto = 10;
              break;
            }
            // goto join
            __goto = 11;
            break;
          case 10:
            // then
            __goto = 12;
            return thenHelper(foo2(), __body, __completer);
          case 12:
            // returning from await.
          case 11:
            // join
            e = __result;
            __goto = 13;
            return thenHelper(foo1(), __body, __completer);
          case 13:
            // returning from await.
            f = __result && foo2();
            __goto = 16;
            return thenHelper(foo1(), __body, __completer);
          case 16:
            // returning from await.
            __temp1 = __result;
            if (__temp1)
              __result = __temp1;
            else {
              // goto then
              __goto = 14;
              break;
            }
            // goto join
            __goto = 15;
            break;
          case 14:
            // then
            __goto = 17;
            return thenHelper(foo2(), __body, __completer);
          case 17:
            // returning from await.
          case 15:
            // join
            g = __result;
            h = foo1() && foo2();
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
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
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
          case 2:
            // while condition
          case 4:
            // switch
            switch (y) {
              case 0:
                // goto case
                __goto = 6;
                break;
              case 1:
                // goto case
                __goto = 7;
                break;
              case 1:
                // goto case
                __goto = 8;
                break;
              case 2:
                // goto case
                __goto = 9;
                break;
            }
            // goto after switch
            __goto = 5;
            break;
          case 6:
            // case
          case 7:
            // case
            __goto = 10;
            return thenHelper(foo(), __body, __completer);
          case 10:
            // returning from await.
            // goto while condition
            __goto = 2;
            break;
          case 8:
            // case
            __goto = 11;
            return thenHelper(foo(), __body, __completer);
          case 11:
            // returning from await.
            // goto after switch
            __goto = 5;
            break;
          case 9:
            // case
            foo();
          case 5:
            // after switch
            // goto while condition
            __goto = 2;
            break;
          case 3:
            // after while
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(f) async {
  do {
    var a = await foo();
    if (a) // If with no awaits in body
      break;
    else
      continue;
  } while (await foo());
}
""", """
function(f) {
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError, a;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
          case 2:
            // do body
            __goto = 5;
            return thenHelper(foo(), __body, __completer);
          case 5:
            // returning from await.
            a = __result;
            if (a) {
              // goto after do
              __goto = 4;
              break;
            } else {
              // goto do condition
              __goto = 3;
              break;
            }
          case 3:
            // do condition
            __goto = 6;
            return thenHelper(foo(), __body, __completer);
          case 6:
            // returning from await.
            if (__result) {
              // goto do body
              __goto = 2;
              break;
            }
          case 4:
            // after do
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(g) async {
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
function(g) {
  var __goto = 0, __completer = new Completer(), __handler = 2, __currentError, __returnValue, i, __temp1;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            i = 0;
          case 3:
            // for condition
            __temp1 = i;
            __goto = 6;
            return thenHelper(foo1(), __body, __completer);
          case 6:
            // returning from await.
            if (!(__temp1 < __result)) {
              // goto after for
              __goto = 5;
              break;
            }
            if (foo(i)) {
              // goto for update
              __goto = 4;
              break;
            } else {
              // goto after for
              __goto = 5;
              break;
            }
            __goto = !foo(i) ? 7 : 8;
            break;
          case 7:
            // then
            __goto = 9;
            return thenHelper(foo(), __body, __completer);
          case 9:
            // returning from await.
            // goto return
            __goto = 1;
            break;
          case 8:
            // join
            __temp1 = print;
            __goto = 10;
            return thenHelper(foo(i), __body, __completer);
          case 10:
            // returning from await.
            __temp1(__result);
          case 4:
            // for update
            __goto = 11;
            return thenHelper(foo2(), __body, __completer);
          case 11:
            // returning from await.
            i = __result;
            // goto for condition
            __goto = 3;
            break;
          case 5:
            // after for
          case 1:
            // return
            return thenHelper(__returnValue, 0, __completer, null);
          case 2:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(a, h) async {
  var x = {"a": foo1(), "b": await foo2(), "c": foo3()};
  x["a"] = 2; // Different assignments
  (await foo()).a = 3;
  x[await foo()] = 4;
  x[(await foo1()).a = await foo2()] = 5;
  (await foo1())[await foo2()] = await foo3(6);
}
""", """
function(a, h) {
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError, x, __temp1, __temp2;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            __temp1 = foo1();
            __goto = 2;
            return thenHelper(foo2(), __body, __completer);
          case 2:
            // returning from await.
            x = {a: __temp1, b: __result, c: foo3()};
            x.a = 2;
            __goto = 3;
            return thenHelper(foo(), __body, __completer);
          case 3:
            // returning from await.
            __result.a = 3;
            __temp1 = x;
            __goto = 4;
            return thenHelper(foo(), __body, __completer);
          case 4:
            // returning from await.
            __temp1[__result] = 4;
            __temp1 = x;
            __goto = 5;
            return thenHelper(foo1(), __body, __completer);
          case 5:
            // returning from await.
            __temp2 = __result;
            __goto = 6;
            return thenHelper(foo2(), __body, __completer);
          case 6:
            // returning from await.
            __temp1[__temp2.a = __result] = 5;
            __goto = 7;
            return thenHelper(foo1(), __body, __completer);
          case 7:
            // returning from await.
            __temp1 = __result;
            __goto = 8;
            return thenHelper(foo2(), __body, __completer);
          case 8:
            // returning from await.
            __temp2 = __result;
            __goto = 9;
            return thenHelper(foo3(6), __body, __completer);
          case 9:
            // returning from await.
            __temp1[__temp2] = __result;
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(c, i) async {
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
function(c, i) {
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError, x, y, __error1, __error2;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            __handler = 3;
            __goto = c ? 6 : 8;
            break;
          case 6:
            // then
            __goto = 9;
            return thenHelper(foo(), __body, __completer);
          case 9:
            // returning from await.
            // goto join
            __goto = 7;
            break;
          case 8:
            // else
            __result = foo();
          case 7:
            // join
            x = __result;
            y = {};
            __handler = 1;
            // goto after finally
            __goto = 5;
            break;
          case 3:
            // catch
            __handler = 2;
            __error1 = __currentError;
            __handler = 11;
            __goto = c ? 14 : 16;
            break;
          case 14:
            // then
            __goto = 17;
            return thenHelper(fooError(__error1), __body, __completer);
          case 17:
            // returning from await.
            // goto join
            __goto = 15;
            break;
          case 16:
            // else
            __result = fooError(__error1);
          case 15:
            // join
            x = __result;
            __next = [13];
            // goto finally
            __goto = 12;
            break;
          case 11:
            // catch
            __handler = 10;
            __error2 = __currentError;
            y.x = foo(__error2);
            __next = [13];
            // goto finally
            __goto = 12;
            break;
          case 10:
            // uncaught
            __next = [2];
          case 12:
            // finally
            __handler = 2;
            foo(x);
            // goto the next finally handler
            __goto = __next.pop();
            break;
          case 13:
            // after finally
            // goto after finally
            __goto = 5;
            break;
          case 2:
            // uncaught
            // goto rethrow
            __goto = 1;
            break;
          case 5:
            // after finally
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(x, y, j) async {
  print(await(foo(x))); // calls
  (await print)(foo(x));
  print(foo(await x));
  await (print(foo(await x)));
  print(foo(x, await y, z));
}
""", """
function(x, y, j) {
  var __goto = 0, __completer = new Completer(), __handler = 1, __currentError, __temp1, __temp2, __temp3;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
            __temp1 = print;
            __goto = 2;
            return thenHelper(foo(x), __body, __completer);
          case 2:
            // returning from await.
            __temp1(__result);
            __goto = 3;
            return thenHelper(print, __body, __completer);
          case 3:
            // returning from await.
            __result(foo(x));
            __temp1 = print;
            __temp2 = foo;
            __goto = 4;
            return thenHelper(x, __body, __completer);
          case 4:
            // returning from await.
            __temp1(__temp2(__result));
            __temp1 = print;
            __temp2 = foo;
            __goto = 6;
            return thenHelper(x, __body, __completer);
          case 6:
            // returning from await.
            __goto = 5;
            return thenHelper(__temp1(__temp2(__result)), __body, __completer);
          case 5:
            // returning from await.
            __temp1 = print;
            __temp2 = foo;
            __temp3 = x;
            __goto = 7;
            return thenHelper(y, __body, __completer);
          case 7:
            // returning from await.
            __temp1(__temp2(__temp3, __result, z));
            // implicit return
            return thenHelper(null, 0, __completer, null);
          case 1:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");

  testTransform("""
function(x, y, k) async {
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
function(x, y, k) {
  var __goto = 0, __completer = new Completer(), __handler = 2, __currentError, __returnValue, __temp1;
  function __body(__errorCode, __result) {
    if (__errorCode == 1) {
      __currentError = __result;
      __goto = __handler;
    }
    while (true)
      try {
        switch (__goto) {
          case 0:
            // Function start
          case 3:
            // while condition
            __goto = 5;
            return thenHelper(foo(), __body, __completer);
          case 5:
            // returning from await.
            if (!__result) {
              // goto after while
              __goto = 4;
              break;
            }
          case 7:
            // continue lab
          case 8:
            // switch
            __temp1 = y;
            if (__temp1 === 0) {
              // goto case
              __goto = 10;
              break;
            }
            if (__temp1 === 0) {
              // goto case
              __goto = 11;
              break;
            }
            __goto = 13;
            return thenHelper(bar(), __body, __completer);
          case 13:
            // returning from await.
            if (__temp1 === __result) {
              // goto case
              __goto = 12;
              break;
            }
            if (__temp1 === x) {
              // goto case
              __goto = 14;
              break;
            }
            // goto default
            __goto = 15;
            break;
          case 10:
            // case
            foo();
          case 11:
            // case
            __temp1 = print;
            __goto = 16;
            return thenHelper(foo1(x), __body, __completer);
          case 16:
            // returning from await.
            __temp1(__result);
            __returnValue = y;
            // goto return
            __goto = 1;
            break;
          case 12:
            // case
            __temp1 = print;
            __goto = 17;
            return thenHelper(foobar(x), __body, __completer);
          case 17:
            // returning from await.
            __temp1(__result);
            __returnValue = y;
            // goto return
            __goto = 1;
            break;
          case 14:
            // case
            if (a) {
              throw new Error();
            } else {
              // goto while condition
              __goto = 3;
              break;
            }
          case 15:
            // default
            // goto break lab
            __goto = 6;
            break;
          case 9:
            // after switch
            foo();
          case 6:
            // break lab
            // goto while condition
            __goto = 3;
            break;
          case 4:
            // after while
          case 1:
            // return
            return thenHelper(__returnValue, 0, __completer, null);
          case 2:
            // rethrow
            return thenHelper(__currentError, 1, __completer);
        }
      } catch (__error) {
        __currentError = __error;
        __goto = __handler;
      }

  }
  return thenHelper(null, __body, __completer, null);
}""");
}
