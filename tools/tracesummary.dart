// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Print a summary of a profile trace.

import 'dart:convert';
import 'dart:io';

class TraceSymbol {
  final String name;
  int exclusive = 0;
  int inclusive = 0;
  TraceSymbol(this.name);
}

class TraceSummary {
  Map<String, TraceSymbol> _symbols = {};
  List _events = [];
  List<TraceSymbol> _stack = [];
  List<TraceSymbol> _topExclusive = [];
  List<TraceSymbol> _topInclusive = [];

  void _processEventsFromFile(String name) {
    var file = new File(name);
    var events = [];
    try {
      var contents = file.readAsStringSync();
      events = JSON.decode(contents);
    } catch (e) {
      print('Exception for $name $e');
    }
    _processEvents(events);
  }

  void _processBegin(Map event) {
    var name = event['name'];
    if (name == '<no frame>') {
      return;
    }
    var symbol = _symbols[name];
    if (symbol == null) {
      symbol = new TraceSymbol(name);
      _symbols[name] = symbol;
    }
    // Start at 1 because 0 will always be the isolate.
    for (var i = 1; i < _stack.length; i++) {
      // Bump inclusive count for all frames.
      symbol.inclusive++;
    }
    _stack.add(symbol);
    if (_stack.length > 1) {
      // Only if we aren't the isolate.
      symbol.exclusive++;
    }
  }

  void _processEnd(Map event) {
    var name = event['name'];
    if (name == '<no frame>') {
      return;
    }
    var symbol = _stack.last;
    if (symbol.name != name) {
      throw new StateError('$name not found at top of stack.');
    }
    _stack.removeLast();
  }

  void _processEvents(List events) {
    for (var i = 0; i < events.length; i++) {
      Map event = events[i];
      if (event['ph'] == 'M') {
        // Ignore.
      } else if (event['ph'] == 'B') {
        _processBegin(event);
      } else if (event['ph'] == 'E') {
        _processEnd(event);
      }
    }
  }


  static const NUM_SYMBOLS = 10;

  void _findTopExclusive() {
    _topExclusive = _symbols.values.toList();
    _topExclusive.sort((a, b) {
      return b.exclusive - a.exclusive;
    });
  }


  void _findTopInclusive() {
    _topInclusive = _symbols.values.toList();
    _topInclusive.sort((a, b) {
      return b.inclusive - a.inclusive;
    });
  }

  void summarize(String input) {
    _processEventsFromFile(input);
    _findTopExclusive();
    _findTopInclusive();
    _print();
  }

  void _print() {
    print('Top ${NUM_SYMBOLS} exlusive symbols:');
    _topExclusive.getRange(0, NUM_SYMBOLS).forEach((a) {
      print('${a.exclusive} ${a.name}');
    });
    print('');
    print('Top ${NUM_SYMBOLS} inclusive symbols:');
    _topInclusive.getRange(0, NUM_SYMBOLS).forEach((a) {
      print('${a.inclusive} ${a.name}');
    });
  }
}

main(List<String> arguments) {
  if (arguments.length < 1) {
    print('${Platform.executable} ${Platform.script} <input>');
    return;
  }
  String input = arguments[0];
  TraceSummary ts = new TraceSummary();
  ts.summarize(input);
}
