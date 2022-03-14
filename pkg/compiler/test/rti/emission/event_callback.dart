// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:html';
import 'package:compiler/src/util/testing.dart';

/*spec.class: global#Event:checkedInstance,checkedTypeArgument,checks=[$isEvent],instance,typeArgument*/
/*prod.class: global#Event:checkedTypeArgument,checks=[$isEvent],instance,typeArgument*/
/*spec.class: global#MouseEvent:checkedInstance,checks=[$isMouseEvent],instance,typeArgument*/
/*prod.class: global#MouseEvent:checks=[$isMouseEvent],instance,typeArgument*/
/*spec.class: global#KeyboardEvent:checkedInstance,checks=[$isKeyboardEvent],instance,typeArgument*/
/*prod.class: global#KeyboardEvent:checks=[$isKeyboardEvent],instance,typeArgument*/

void main() {
  var i = new InputElement();
  i.onKeyPress.listen(onEvent);
  i.onClick.listen(onEvent);
  var e = new TextAreaElement();
  e.onKeyPress.listen(onEvent);
  e.onClick.listen(onEvent);
}

void onEvent(Event e) {
  makeLive(e);
}
