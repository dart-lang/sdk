// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library debugger_page_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('debugger-page')
class DebuggerPageElement extends ObservatoryElement {
  @published Isolate isolate;
  @published bool showConsole = false;

  DebuggerPageElement.created() : super.created();

  @override
  void attached() {
    super.attached();

    // TODO(turnidge): Get these values from the DOM.
    // TODO(turnidge): splitterHeight is 0 until I implement it.
    const int navbarHeight = 56;
    const int splitterHeight = 0;
    const int cmdHeight = 22;

    var stack = $['stack'];
    int windowHeight = window.innerHeight;
    int available = windowHeight - (navbarHeight + splitterHeight);
    int stackHeight = available ~/ 1.3;
    if (showConsole) {
      stack.style.setProperty('height', '${stackHeight}px');
    } else {
      stack.style.setProperty('height', '${available}px');
    }
  }
}

@CustomTag('debugger-stack')
class DebuggerStackElement extends ObservatoryElement {
  @published Isolate isolate;
  @published ServiceMap stack;
  @published int activeFrame = 0;

  isolateChanged(oldValue) {
    isolate.get('stacktrace').then((result) {
        stack = result;
      });
  }

  DebuggerStackElement.created() : super.created();
}

@CustomTag('debugger-frame')
class DebuggerFrameElement extends ObservatoryElement {
  @published ObservableMap frame;

  // When true, the frame will start out expanded.
  @published bool expand = false;

  @observable String scriptHeight;
  @observable bool expanded = false;
  @observable bool busy = false;

  DebuggerFrameElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    int windowHeight = window.innerHeight;
    scriptHeight = '${windowHeight ~/ 1.6}px';
  }

  void expandChanged(oldValue) {
    if (expand != expanded) {
      toggleExpand(null, null, null);
    }
  }

  void toggleExpand(var a, var b, var c) {
    if (busy) {
      return;
    }
    busy = true;
    frame['function'].load().then((func) {
        expanded = !expanded;
        var frameOuter = $['frameOuter'];
        if (expanded) {
          frameOuter.classes.add('shadow');
        } else {
          frameOuter.classes.remove('shadow');
        }
        busy = false;
      });
  }
}

@CustomTag('debugger-console')
class DebuggerConsoleElement extends ObservatoryElement {
  @published Isolate isolate;

  DebuggerConsoleElement.created() : super.created();
}

@CustomTag('debugger-input')
class DebuggerInputElement extends ObservatoryElement {
  @published Isolate isolate;
  @published String text = '';

  @override
  void ready() {
    super.ready();
    var textBox = $['textBox'];
    textBox.select();
    textBox.onKeyDown.listen((KeyboardEvent e) {
	switch (e.keyCode) {
          case KeyCode.TAB:
            e.preventDefault();
            textBox.setRangeText('TAB');
            textBox.setSelectionRange(textBox.selectionStart + 3,
                                      textBox.selectionStart + 3);
            break;
          case KeyCode.ENTER:
            print('Debugger command (not implemented): $text');
            text = '';
            break;
	}
      });
  }

  DebuggerInputElement.created() : super.created();
}

