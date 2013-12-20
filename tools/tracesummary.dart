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
  final int numSymbols;

  Map<String, TraceSymbol> _symbols = {};
  List _events = [];
  List<TraceSymbol> _stack = [];
  List<TraceSymbol> _topExclusive = [];
  List<TraceSymbol> _topInclusive = [];
  bool _marked = false;
  int _totalSamples = 0;

  TraceSummary(this.numSymbols);

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
    _stack.add(symbol);
    _marked = false;
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
    if ((_stack.length > 1) && (_marked == false)) {
      // We are transitioning from the sequence of begins to the sequence
      // of ends. Mark the symbols on the stack.
      _marked = true;
      _totalSamples++;
      // Mark all symbols except the top with an inclusive tick.
      for (int i = 1; i < _stack.length; i++) {
        _stack[i].inclusive++;
      }
      _stack.last.exclusive++;
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

  String _pad(String input, int minLength) {
    int length = input.length;
    for (int i = 0; i < minLength - length; i++) {
      input = ' $input';
    }
    return input;
  }

  static const TICKS_LENGTH = 10;
  static const PERCENT_LENGTH = 7;

  void _printSymbol(int t, String name) {
    String ticks = t.toString();
    ticks = _pad(ticks, TICKS_LENGTH);
    double total = (t / _totalSamples);
    String percent = (total * 100.0).toStringAsFixed(2);
    percent = _pad(percent, PERCENT_LENGTH);
    print('$ticks  $percent  $name');
  }

  void _print() {
    print('Top ${numSymbols} inclusive symbols');
    print('--------------------------');
    print('     ticks  percent  name');
    _topInclusive.getRange(0, numSymbols).forEach((a) {
      _printSymbol(a.inclusive, a.name);
    });
    print('');
    print('Top ${numSymbols} exclusive symbols');
    print('--------------------------');
    print('     ticks  percent  name');
    _topExclusive.getRange(0, numSymbols).forEach((a) {
      _printSymbol(a.exclusive, a.name);
    });
  }
}

main(List<String> arguments) {
  if (arguments.length < 1) {
    print('${Platform.executable} ${Platform.script} <input> [symbol count]');
    return;
  }
  String input = arguments[0];
  int numSymbols = 10;
  if (arguments.length >= 2) {
    numSymbols = int.parse(arguments[1]);
  }
  TraceSummary ts = new TraceSummary(numSymbols);
  ts.summarize(input);
}
