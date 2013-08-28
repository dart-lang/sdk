// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests the layout test functionality of test.dart. There is a .png image with
 * the same name as this file. The existence of the .png file indicates to the
 * test framework that we want to compare the final state of this application
 * against an image file.
 */
library layouttest;

import 'dart:html';

main() {
  var div1 = new DivElement();
  div1.attributes['style'] = _style('blue', 20, 10, 40, 10);
  var div2 = new DivElement();
  div2.attributes['style'] = _style('red', 25, 30, 40, 10);
  document.body.children.add(div1);
  document.body.children.add(div2);
}

_style(String color, int top, int left, int width, int height) {
  return ('background-color:$color; position:absolute; '
          'top:${top}px; left:${left}px; '
          'width:${width}px; height:${height}px;');
}
