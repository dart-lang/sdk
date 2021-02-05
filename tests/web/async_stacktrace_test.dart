// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class Tracer {
  final String expected;
  final String? name;
  String _trace = "";

  Tracer(this.expected, [this.name]);

  void trace(msg) {
    if (name != null) {
      print("Tracing $name: $msg");
    }
    _trace += msg;
  }

  void done() {
    Expect.equals(expected, _trace);
  }
}

Future<void> test1(Tracer tracer) {
  Future<void> foo() async {
    var savedStackTrace;
    try {
      try {
        tracer.trace("a");
        throw "Error";
      } catch (e, st) {
        tracer.trace("b");
        savedStackTrace = st;
      }
      tracer.trace("c");
      await new Future.error("Error 2", savedStackTrace);
      tracer.trace("d");
    } catch (e, st) {
      tracer.trace("e");
      Expect.equals(savedStackTrace.toString(), st.toString());
    }
    tracer.trace("f");
  }

  return foo();
}

Future<List<void>> test1star(Tracer tracer) {
  Stream<void> foo() async* {
    var savedStackTrace;
    try {
      try {
        tracer.trace("a");
        throw "Error";
      } catch (e, st) {
        tracer.trace("b");
        savedStackTrace = st;
      }
      tracer.trace("c");
      await new Future.error("Error 2", savedStackTrace);
      tracer.trace("d");
    } catch (e, st) {
      tracer.trace("e");
      Expect.equals(savedStackTrace.toString(), st.toString());
    }
    tracer.trace("f");
  }

  return foo().toList();
}

Future<void> test2(Tracer tracer) {
  var savedStackTrace;
  Future<void> foo() async {
    try {
      tracer.trace("a");
      throw "Error";
    } catch (e, st) {
      tracer.trace("b");
      savedStackTrace = st;
    }
    tracer.trace("c");
    await new Future.error("Error 2", savedStackTrace);
    tracer.trace("d");
  }

  return foo().catchError((e, st) {
    tracer.trace("e");
    Expect.equals(savedStackTrace.toString(), st.toString());
  });
}

Future<List<void>> test2star(Tracer tracer) {
  var savedStackTrace;
  Stream<void> foo() async* {
    try {
      tracer.trace("a");
      throw "Error";
    } catch (e, st) {
      tracer.trace("b");
      savedStackTrace = st;
    }
    tracer.trace("c");
    await new Future.error("Error 2", savedStackTrace);
    tracer.trace("d");
  }

  return foo().toList().catchError((e, st) {
    tracer.trace("e");
    Expect.equals(savedStackTrace.toString(), st.toString());
    return [];
  });
}

Future<void> test3(Tracer tracer) {
  var savedStackTrace;
  Future<void> foo() async {
    try {
      tracer.trace("a");
      throw "Error";
    } catch (e, st) {
      tracer.trace("b");
      savedStackTrace = st;
      rethrow;
    }
  }

  return foo().catchError((e, st) {
    tracer.trace("c");
    Expect.equals(savedStackTrace.toString(), st.toString());
  });
}

Future<List<void>> test3star(Tracer tracer) {
  var savedStackTrace;
  Stream<void> foo() async* {
    try {
      tracer.trace("a");
      throw "Error";
    } catch (e, st) {
      tracer.trace("b");
      savedStackTrace = st;
      rethrow;
    }
  }

  return foo().toList().catchError((e, st) {
    tracer.trace("c");
    Expect.equals(savedStackTrace.toString(), st.toString());
    return [];
  });
}

runTest(String expectedTrace, Future test(Tracer tracer)) async {
  Tracer tracer = new Tracer(expectedTrace);
  await test(tracer);
  tracer.done();
}

runTests() async {
  await runTest("abcef", test1);
  await runTest("abcef", test1star);
  await runTest("abce", test2);
  await runTest("abce", test2star);
  await runTest("abc", test3);
  await runTest("abc", test3star);
}

main() {
  asyncTest(runTests);
}
