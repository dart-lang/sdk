// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void _dispatchEvent(String receiver, var message) {
  var event = document.$dom_createEvent('TextEvent');
  event.initTextEvent(receiver, false, false, window, JSON.stringify(message));
  window.$dom_dispatchEvent(event);
}
