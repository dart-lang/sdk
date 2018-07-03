// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

/*kernel.class: global#Event:checkedTypeArgument,checks=[$isEvent],instance,typeArgument*/
/*strong.class: global#Event:checkedInstance,checkedTypeArgument,checks=[$isEvent],instance,typeArgument*/

/*class: global#MouseEvent:checks=[],instance*/
/*class: global#KeyboardEvent:checks=[],instance*/

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
