// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ShadowDOMTest;

import 'dart:html';

// Test that children of a shadow host get distributed properly to the
// insertion points of a shadow subtree. Output should be three boxes,
// ordered blue, red, green down the page.
main() {
  var div = new DivElement();
  document.body.children.add(div);

  // build some DOM elements
  var bluebox = _colorBox('blue', 40, 20);
  bluebox.classes.add('foo');
  var redbox = _colorBox('red', 30, 30);
  var greenbox = _colorBox('green', 60, 10);

  // assemble DOM
  var sRoot = new ShadowRoot(div);
  sRoot.nodes.add(new Element.html('<content select=".foo"></content>'));
  sRoot.nodes.add(redbox);
  sRoot.nodes.add(new Element.tag('content'));

  div.nodes.add(bluebox);
  div.nodes.add(greenbox);
}

DivElement _colorBox(String color, int width, int height) {
  var style = ('background-color:$color; '
      'width:${width}px; height:${height}px;');
  return new Element.html('<div style="$style"></div>');
}
