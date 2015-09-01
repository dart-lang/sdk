// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

doThrow() {
  throw "TheException"; // Line 13.
  return "end of doThrow";
}

doCaught() {
  try {
    doThrow();
  } catch (e) {}
  return "end of doCaught";
}

doUncaught() {
  doThrow();
  return "end of doUncaught";
}

var tests = [

(Isolate isolate) async {
  var lib = await isolate.rootLibrary.reload();

  var onPaused = null;
  var onResume = null;

  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  var subscription;
  subscription = stream.listen((ServiceEvent event) {
    print("Event $event");
    if (event.kind == ServiceEvent.kPauseException) {
      if (onPaused == null) throw "Unexpected pause event $event";
      var t = onPaused;
      onPaused = null;
      t.complete(event);
    }
    if (event.kind == ServiceEvent.kResume) {
      if (onResume == null) throw "Unexpected resume event $event";
      var t = onResume;
      onResume = null;
      t.complete(event);
    }
  });

  test(String pauseInfo,
       String expression,
       bool shouldPause,
       bool shouldBeCaught) async {
    print("Evaluating $expression with pause on $pauseInfo exception");

    expect((await isolate.setExceptionPauseInfo(pauseInfo)) is DartError,
           isFalse);

    var t;
    if (shouldPause) {
      t = new Completer();
      onPaused = t;
    }
    var fres = lib.evaluate(expression);
    if (shouldPause) {
      await t.future;

      var stack = await isolate.getStack();
      expect(stack['frames'][0].function.name, equals('doThrow'));
      // Ugh, no .line. expect(stack['frames'][0].location.line, equals(17));

      t = new Completer();
      onResume = t;
      isolate.resume();
      await t.future;
    }

    var res = await fres;
    print(res);
    if (shouldBeCaught) {
      expect(res.isInstance, isTrue);
      expect(res.isString, isTrue);
      expect(res.valueAsString, equals("end of doCaught"));
    } else {
      expect(res.isError, isTrue);
      await res.load(); // Weird?
      expect(res.exception.isInstance, isTrue);
      expect(res.exception.isString, isTrue);
      expect(res.exception.valueAsString, equals("TheException"));
    }
  }

  await test("all", "doCaught()", true, true);
  await test("all", "doUncaught()", true, false);

  await test("unhandled", "doCaught()", false, true);
  await test("unhandled", "doUncaught()", true, false);

  await test("none", "doCaught()", false, true);
  await test("none", "doUncaught()", false, false);

  subscription.cancel();
},

];

main(args) => runIsolateTests(args, tests);
