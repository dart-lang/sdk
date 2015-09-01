// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:observatory/debugger.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';

void testFunction() {
  int i = 0;
  while (i == 0) {
    debugger();
    print('loop');
    print('loop');
  }
}

class TestDebugger extends Debugger {
  TestDebugger(this.isolate, this.stack);

  VM get vm => isolate.vm;
  Isolate isolate;
  ServiceMap stack;
  int currentFrame = 0;
}

void debugger_location_dummy_function() {
}

class DebuggerLocationTestFoo {
  DebuggerLocationTestFoo(this.field);
  DebuggerLocationTestFoo.named();

  void method() {}
  void madness() {}

  int field;
}

class DebuggerLocationTestBar {
}

Future<Debugger> initDebugger(Isolate isolate) {
  return isolate.getStack().then((stack) {
    return new TestDebugger(isolate, stack);
  });
}

var tests = [

hasStoppedAtBreakpoint,

// Parse '' => current position
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, '').then((DebuggerLocation loc) {
      expect(loc.valid, isTrue);
      expect(loc.toString(), equals('debugger_location_test.dart:17'));
    });
  });
},

// Parse line
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, '18').then((DebuggerLocation loc) {
      expect(loc.valid, isTrue);
      expect(loc.toString(), equals('debugger_location_test.dart:18'));
    });
  });
},

// Parse line + col
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, '16:11').then((DebuggerLocation loc) {
      expect(loc.valid, isTrue);
      expect(loc.toString(), equals('debugger_location_test.dart:16:11'));
    });
  });
},

// Parse script + line
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'unittest.dart:15')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('unittest.dart:15'));
      });
  });
},

// Parse script + line + col
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'unittest.dart:15:10')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('unittest.dart:15:10'));
      });
  });
},

// Parse bad script
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'bad.dart:15')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isFalse);
        expect(loc.toString(), equals(
            'invalid source location (Script \'bad.dart\' not found)'));
      });
  });
},

// Parse function
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'testFunction')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('testFunction'));
      });
  });
},

// Parse bad function
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'doesNotReallyExit')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isFalse);
        expect(loc.toString(), equals(
            'invalid source location (Function \'doesNotReallyExit\' not found)'));
      });
  });
},

// Parse constructor
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isTrue);
        // TODO(turnidge): Printing a constructor currently adds
        // another class qualifier at the front.  Do we want to change
        // this to be more consistent?
        expect(loc.toString(), equals(
            'DebuggerLocationTestFoo.DebuggerLocationTestFoo'));
      });
  });
},

// Parse named constructor
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.named')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isTrue);
        // TODO(turnidge): Printing a constructor currently adds
        // another class qualifier at the front.  Do we want to change
        // this to be more consistent?
        expect(loc.toString(), equals(
            'DebuggerLocationTestFoo.DebuggerLocationTestFoo.named'));
      });
  });
},

// Parse method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.method')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('DebuggerLocationTestFoo.method'));
      });
  });
},

// Parse method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.field=')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('DebuggerLocationTestFoo.field='));
      });
  });
},

// Parse bad method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.parse(debugger, 'DebuggerLocationTestFoo.missing')
      .then((DebuggerLocation loc) {
        expect(loc.valid, isFalse);
        expect(loc.toString(), equals(
            'invalid source location '
            '(Function \'DebuggerLocationTestFoo.missing\' not found)'));
      });
  });
},

// Complete function + script
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.complete(debugger, 'debugger_loc')
      .then((List<String> completions) {
        expect(completions.toString(), equals(
            '[debugger_location_dummy_function, '
             'debugger_location.dart:, debugger_location_test.dart:]'));
      });
  });
},

// Complete class
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.complete(debugger, 'DebuggerLocationTe')
      .then((List<String> completions) {
        expect(completions.toString(), equals(
            '[DebuggerLocationTestBar, DebuggerLocationTestFoo]'));
      });
  });
},

// No completions: unqualified name
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.complete(debugger, 'debugger_locXYZZY')
      .then((List<String> completions) {
        expect(completions.toString(), equals('[]'));
      });
  });
},

// Complete method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.complete(debugger, 'DebuggerLocationTestFoo.m')
      .then((List<String> completions) {
        expect(completions.toString(), equals(
          '[DebuggerLocationTestFoo.madness, DebuggerLocationTestFoo.method]'));
      });
  });
},

// No completions: qualified name
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return DebuggerLocation.complete(debugger, 'DebuggerLocationTestFoo.q')
      .then((List<String> completions) {
        expect(completions.toString(), equals('[]'));
      });
  });
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
