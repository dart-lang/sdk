// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:html';

/*spec.class: global#Event:checkedInstance,checkedTypeArgument,checks=[$isEvent],instance,typeArgument*/
/*prod.class: global#Event:checkedTypeArgument,checks=[$isEvent],instance,typeArgument*/
/*class: global#MouseEvent:checks=[$isMouseEvent],instance,typeArgument*/
/*class: global#KeyboardEvent:checks=[$isKeyboardEvent],instance,typeArgument*/

void main() {
  print('InputElement');
  var i = new InputElement();
  print('> onKeyPress');
  i.onKeyPress.listen(onEvent);
  print('> onClick');
  i.onClick.listen(onEvent);
  print('TextAreaElement');
  var e = new TextAreaElement();
  print('> onKeyPress');
  e.onKeyPress.listen(onEvent);
  print('> onClick');
  e.onClick.listen(onEvent);
  print('Done!');
}

void onEvent(Event e) {
  print(e);
}
