// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class Tracer {
  final String expected;
  final String name;
  int counter = 0;

  Tracer(this.expected, [this.name]);

  void trace(msg) {
    if (name != null) {
      // Commented out, see https://github.com/dart-lang/dev_compiler/issues/278
      //print("Tracing $name: $msg");
    }
    Expect.equals(expected[counter], msg);
    counter++;
  }

  void done() {
    Expect.equals(expected.length, counter, "Received too few traces");
  }
}

foo1(Tracer tracer) async {
  try {
    tracer.trace("a");
    // This await forces dart2js to rewrite the try into a state machine
    // instead of relying on the existing structure.
    await new Future.value(3); //# forceAwait: ok
    tracer.trace("b");
    throw "Error";
  } catch (error) {
    tracer.trace("c");
    Expect.equals("Error", error);
    throw "Error2";
    tracer.trace("d");
  } finally {
    tracer.trace("e");
  }
  tracer.trace("f");
}

foo2(Tracer tracer) async {
  try {
    tracer.trace("a");
    await new Future.value(3); //# forceAwait: continued
    tracer.trace("b");
    throw "Error";
    tracer.trace("c");
  } catch (error) {
    tracer.trace("d");
    Expect.equals("Error", error);
    await new Future.error("Error2");
  } finally {
    tracer.trace("e");
  }
  tracer.trace("f");
}

foo3(Tracer tracer) async {
  try {
    tracer.trace("a");
    await new Future.value(3); //# forceAwait: continued
    tracer.trace("b");
    throw "Error";
    tracer.trace("c");
  } catch (error) {
    Expect.equals("Error", error);
    tracer.trace("d");
    return;
  } finally {
    tracer.trace("e");
  }
  tracer.trace("f");
}

foo4(Tracer tracer) async {
  try {
    try {
      await new Future.value(3); //# forceAwait: continued
      tracer.trace("a");
      throw "Error";
    } catch (error) {
      tracer.trace("b");
      Expect.equals("Error", error);
      throw "Error2";
    }
  } catch (error) {
    Expect.equals("Error2", error);
    tracer.trace("c");
  }
  tracer.trace("d");
}

foo5(Tracer tracer) async {
  try {
    tracer.trace("a");
    try {
      await new Future.value(3); //# forceAwait: continued
      tracer.trace("b");
      throw "Error";
    } catch (error) {
      tracer.trace("c");
      Expect.equals("Error", error);
      throw "Error2";
    }
  } finally {
    tracer.trace("d");
  }
  tracer.trace("e");
}

foo6(Tracer tracer) async {
  try {
    try {
      await new Future.value(3); //# forceAwait: continued
      tracer.trace("a");
      throw "Error";
    } catch (error) {
      tracer.trace("b");
      Expect.equals("Error", error);
      throw "Error2";
    } finally {
      tracer.trace("c");
      throw "Error3";
    }
  } catch (error) {
    tracer.trace("d");
    Expect.equals("Error3", error);
  }
  tracer.trace("e");
}

foo7(Tracer tracer) async {
  try {
    try {
      await new Future.value(3); //# forceAwait: continued
      tracer.trace("a");
      throw "Error";
    } catch (error) {
      Expect.equals("Error", error);
      tracer.trace("b");
      throw "Error2";
    } finally {
      tracer.trace("c");
      throw "Error3";
    }
  } finally {
    tracer.trace("d");
  }
  tracer.trace("e");
}

foo8(Tracer tracer) async {
  try {
    try {
      await new Future.value(3); //# forceAwait: continued
      tracer.trace("a");
      throw "Error";
    } catch (error) {
      Expect.equals("Error", error);
      tracer.trace("b");
      return;
    } finally {
      tracer.trace("c");
      throw "Error3";
    }
  } finally {
    tracer.trace("d");
  }
  tracer.trace("e");
}

foo9(Tracer tracer) async {
  try {
    while (true) {
      try {
        await new Future.value(3); //# forceAwait: continued
        tracer.trace("a");
        throw "Error";
      } catch (error) {
        Expect.equals("Error", error);
        tracer.trace("b");
        return;
      } finally {
        tracer.trace("c");
        break;
      }
      tracer.trace("d");
    }
  } finally {
    tracer.trace("e");
  }
  tracer.trace("f");
}

foo10(Tracer tracer) async {
  try {
    int i = 0;
    while (true) {
      try {
        try {
          tracer.trace("a");
          throw "Error";
        } catch (error) {
          tracer.trace("b");
          try {
            await new Future.value(3); // //# forceAwait: continued
            throw "Error2";
          } catch (error) {
            tracer.trace("c");
          } finally {
            tracer.trace("d");
          }
          tracer.trace("e");
          throw "Error3";
        } finally {
          tracer.trace("f");
          // Continue and breaks 'eats' Error3.
          if (i == 0) continue;
          if (i == 1) break;
        }
      } finally {
        tracer.trace("g");
        i++;
      }
    }
  } finally {
    tracer.trace("h");
  }
  tracer.trace("i");
}

foo11(Tracer tracer) async {
  try {
    bool firstTime = true;
    while (true) {
      tracer.trace("a");
      if (firstTime) {
        try {
          await new Future.value(3); //# forceAwait: continued
          tracer.trace("b");
          throw "Error";
        } catch (error) {
          Expect.equals("Error", error);
          tracer.trace("c");
          firstTime = false;
          continue;
        } finally {
          tracer.trace("d");
        }
      } else {
        tracer.trace("e");
        return;
      }
    }
  } finally {
    tracer.trace("f");
  }
  tracer.trace("g");
}

foo12(Tracer tracer) async {
  try {
    bool firstTime = true;
    while (true) {
      tracer.trace("a");
      if (firstTime) {
        try {
          await new Future.value(3); //# forceAwait: continued
          tracer.trace("b");
          throw "Error";
        } catch (error) {
          Expect.equals("Error", error);
          tracer.trace("c");
          firstTime = false;
          continue;
        } finally {
          tracer.trace("d");
          break;
        }
      } else {
        tracer.trace("e");
        return;
      }
    }
  } finally {
    tracer.trace("f");
  }
  tracer.trace("g");
}

foo13(Tracer tracer) async {
  try {
    try {
      tracer.trace("a");
      return;
    } catch (error) {
      tracer.trace("b");
    } finally {
      tracer.trace("c");
      try {
        try {
          await new Future.value(3); // //# forceAwait: continued
          tracer.trace("d");
          throw "Error";
        } finally {
          tracer.trace("e");
        }
      } finally {
        tracer.trace("f");
      }
    }
  } finally {
    tracer.trace("g");
  }
  tracer.trace("h");
}

foo14(Tracer tracer) async {
  try {
    try {
      tracer.trace("a");
      throw "Error";
    } catch (error) {
      tracer.trace("b");
      try {
        await new Future.value(3); // //# forceAwait: continued
        throw "Error2";
      } catch (error) {
        tracer.trace("c");
      } finally {
        tracer.trace("d");
      }
      tracer.trace("e");
      throw "Error3";
    } finally {
      tracer.trace("f");
    }
  } finally {
    tracer.trace("g");
  }
  tracer.trace("h");
}

foo15(Tracer tracer) async {
  try {
    try {
      tracer.trace("a");
      throw "Error";
    } catch (error) {
      tracer.trace("b");
      try {
        await new Future.value(3); // //# forceAwait: continued
        throw "Error2";
      } catch (error) {
        tracer.trace("c");
      } finally {
        tracer.trace("d");
      }
      tracer.trace("e");
      throw "Error3";
    } finally {
      tracer.trace("f");
      return;
    }
  } finally {
    tracer.trace("g");
  }
  tracer.trace("h");
}

foo16(Tracer tracer) async {
  try {
    try {
      tracer.trace("a");
      throw "Error";
    } catch (error) {
      tracer.trace("b");
      try {
        await new Future.value(3); // //# forceAwait: continued
        throw "Error2";
      } catch (error) {
        tracer.trace("c");
      } finally {
        tracer.trace("d");
        return;
      }
      tracer.trace("e");
      throw "Error3";
    } finally {
      tracer.trace("f");
    }
  } finally {
    tracer.trace("g");
  }
  tracer.trace("h");
}

foo17(Tracer tracer) async {
  try {
    tracer.trace("a");
  } finally {
    try {
      tracer.trace("b");
      throw "Error";
    } catch (error) {
      await new Future.value(3); // //# forceAwait: continued
      Expect.equals("Error", error);
      tracer.trace("c");
    } finally {
      tracer.trace("d");
    }
    tracer.trace("e");
  }
  tracer.trace("f");
}

foo18(Tracer tracer) async {
  try {
    tracer.trace("a");
  } finally {
    try {
      tracer.trace("b");
    } finally {
      await new Future.value(3); // //# forceAwait: continued
      tracer.trace("c");
    }
    tracer.trace("d");
  }
  tracer.trace("e");
}

runTest(expectedTrace, fun, [expectedError]) async {
  Tracer tracer = new Tracer(expectedTrace, expectedTrace);
  try {
    await fun(tracer);
  } catch (error) {
    Expect.equals(expectedError, error);
    tracer.trace("X");
  }
  tracer.done();
}

test() async {
  await runTest("abceX", foo1, "Error2");
  await runTest("abdeX", foo2, "Error2");
  await runTest("abde", foo3);
  await runTest("abcd", foo4);
  await runTest("abcdX", foo5, "Error2");
  await runTest("abcde", foo6);
  await runTest("abcdX", foo7, "Error3");
  await runTest("abcdX", foo8, "Error3");
  await runTest("abcef", foo9);
  await runTest("abcdefgabcdefghi", foo10);
  await runTest("abcdaef", foo11);
  await runTest("abcdfg", foo12);
  await runTest("acdefgX", foo13, "Error");
  await runTest("abcdefgX", foo14, "Error3");
  await runTest("abcdefgX", foo14, "Error3");
  await runTest("abcdefg", foo15);
  await runTest("abcdfg", foo16);
  await runTest("abcdef", foo17);
  await runTest("abcde", foo18);
}

void main() {
  asyncTest(test);
}
