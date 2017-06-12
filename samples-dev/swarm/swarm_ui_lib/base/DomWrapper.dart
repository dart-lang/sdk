// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of base;

/**
 * Embedded DSL for generating DOM elements.
 */
class Dom {
  static void ready(void f()) {
    if (document.readyState == 'interactive' ||
        document.readyState == 'complete') {
      Timer.run(f);
    } else {
      // TODO(jacobr): give this event a named property.
      window.onContentLoaded.listen((Event e) {
        f();
      });
    }
  }

  /** Adds the given <style> text to the page. */
  static void addStyle(String cssText) {
    StyleElement style = new Element.tag('style');
    style.type = 'text/css';
    style.text = cssText;
    document.head.nodes.add(style);
  }
}
