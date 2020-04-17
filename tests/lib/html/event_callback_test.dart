// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 33627.

import 'dart:html';
import 'package:expect/expect.dart';

void main() {
  try {
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
  } catch (e, s) {
    print('$e\n$s');
    Expect.fail("Unexpected exception: $e");
  }
}

void onEvent(Event e) {
  print(e);
}
