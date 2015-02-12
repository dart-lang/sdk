// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:observatory/debugger.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {  // line 14
      print(i);
    }
  }
}

class TestDebugger extends Debugger {
  TestDebugger(this.isolate, this.stack);

  Isolate isolate;
  ServiceMap stack;
}

void source_location_dummy_function() {
}

class SourceLocationTestFoo {
  SourceLocationTestFoo(this.field);
  SourceLocationTestFoo.named();

  void method() {}
  void madness() {}

  int field;
}

class SourceLocationTestBar {
}

Future<Debugger> initDebugger(Isolate isolate) {
  return isolate.getStack().then((stack) {
    return new TestDebugger(isolate, stack);
  });
}

var tests = [

// Bring the isolate to a breakpoint at line 14.
(Isolate isolate) {
  return isolate.rootLib.load().then((_) {
      // Listen for breakpoint event.
      Completer completer = new Completer();
      isolate.vm.events.stream.listen((ServiceEvent event) {
        if (event.eventType == 'BreakpointReached') {
          completer.complete();
        }
      });

      // Add the breakpoint.
      var script = isolate.rootLib.scripts[0];
      return isolate.addBreakpoint(script, 14).then((ServiceObject bpt) {
          return completer.future;  // Wait for breakpoint events.
      });
    });
},

// Parse '' => current position
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, '').then((SourceLocation loc) {
      expect(loc.valid, isTrue);
      expect(loc.toString(), equals('source_location_test.dart:14'));
    });
  });
},

// Parse line
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, '15').then((SourceLocation loc) {
      expect(loc.valid, isTrue);
      expect(loc.toString(), equals('source_location_test.dart:15'));
    });
  });
},

// Parse line + col
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, '15:11').then((SourceLocation loc) {
      expect(loc.valid, isTrue);
      expect(loc.toString(), equals('source_location_test.dart:15:11'));
    });
  });
},

// Parse script + line
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'unittest.dart:15')
      .then((SourceLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('unittest.dart:15'));
      });
  });
},

// Parse script + line + col
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'unittest.dart:15:10')
      .then((SourceLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('unittest.dart:15:10'));
      });
  });
},

// Parse bad script
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'bad.dart:15')
      .then((SourceLocation loc) {
        expect(loc.valid, isFalse);
        expect(loc.toString(), equals(
            'invalid source location (Script \'bad.dart\' not found)'));
      });
  });
},

// Parse function
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'testFunction')
      .then((SourceLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('testFunction'));
      });
  });
},

// Parse bad function
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'doesNotReallyExit')
      .then((SourceLocation loc) {
        expect(loc.valid, isFalse);
        expect(loc.toString(), equals(
            'invalid source location (Function \'doesNotReallyExit\' not found)'));
      });
  });
},

// Parse constructor
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'SourceLocationTestFoo')
      .then((SourceLocation loc) {
        expect(loc.valid, isTrue);
        // TODO(turnidge): Printing a constructor currently adds
        // another class qualifier at the front.  Do we want to change
        // this to be more consistent?
        expect(loc.toString(), equals(
            'SourceLocationTestFoo.SourceLocationTestFoo'));
      });
  });
},

// Parse named constructor
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'SourceLocationTestFoo.named')
      .then((SourceLocation loc) {
        expect(loc.valid, isTrue);
        // TODO(turnidge): Printing a constructor currently adds
        // another class qualifier at the front.  Do we want to change
        // this to be more consistent?
        expect(loc.toString(), equals(
            'SourceLocationTestFoo.SourceLocationTestFoo.named'));
      });
  });
},

// Parse method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'SourceLocationTestFoo.method')
      .then((SourceLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('SourceLocationTestFoo.method'));
      });
  });
},

// Parse method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'SourceLocationTestFoo.field=')
      .then((SourceLocation loc) {
        expect(loc.valid, isTrue);
        expect(loc.toString(), equals('SourceLocationTestFoo.field='));
      });
  });
},

// Parse bad method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.parse(debugger, 'SourceLocationTestFoo.missing')
      .then((SourceLocation loc) {
        expect(loc.valid, isFalse);
        expect(loc.toString(), equals(
            'invalid source location '
            '(Function \'SourceLocationTestFoo.missing\' not found)'));
      });
  });
},

// Complete function + script
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.complete(debugger, 'source_loc')
      .then((List<String> completions) {
        expect(completions.toString(), equals(
            '[source_location_dummy_function, '
             'source_location.dart:, source_location_test.dart:]'));
      });
  });
},

// Complete class
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.complete(debugger, 'SourceLocationTe')
      .then((List<String> completions) {
        expect(completions.toString(), equals(
            '[SourceLocationTestBar, SourceLocationTestFoo]'));
      });
  });
},

// No completions: unqualified name
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.complete(debugger, 'source_locXYZZY')
      .then((List<String> completions) {
        expect(completions.toString(), equals('[]'));
      });
  });
},

// Complete method
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.complete(debugger, 'SourceLocationTestFoo.m')
      .then((List<String> completions) {
        expect(completions.toString(), equals(
            '[SourceLocationTestFoo.madness, SourceLocationTestFoo.method]'));
      });
  });
},

// No completions: qualified name
(Isolate isolate) {
  return initDebugger(isolate).then((debugger) {
    return SourceLocation.complete(debugger, 'SourceLocationTestFoo.q')
      .then((List<String> completions) {
        expect(completions.toString(), equals('[]'));
      });
  });
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
