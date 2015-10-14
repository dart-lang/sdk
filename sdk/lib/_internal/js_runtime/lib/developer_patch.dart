// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:developer library.

import 'dart:_js_helper' show patch, ForceInline;
import 'dart:_foreign_helper' show JS;

@patch
@ForceInline()
bool debugger({bool when: true, String message}) {
  if (when) {
    JS('', 'debugger');
  }
  return when;
}

@patch
Object inspect(Object object) {
  return object;
}

@patch
void log(String message,
         {DateTime time,
          int sequenceNumber,
          int level: 0,
          String name: '',
          Zone zone,
          Object error,
          StackTrace stackTrace}) {
  // TODO.
}

final _extensions = new Map<String, ServiceExtensionHandler>();

@patch
ServiceExtensionHandler _lookupExtension(String method) {
  return _extensions[method];
}

@patch
_registerExtension(String method, ServiceExtensionHandler handler) {
  _extensions[method] = handler;
}

@patch
int _getTraceClock() {
  // TODO.
  return _clockValue++;
}
int _clockValue = 0;

@patch
void _reportCompleteEvent(int start,
                          int end,
                          String category,
                          String name,
                          String argumentsAsJson) {
  // TODO.
}

@patch
int _getNextAsyncId() {
  return 0;
}

@patch
void _reportTaskEvent(int start,
                      int taskId,
                      String phase,
                      String category,
                      String name,
                      String argumentsAsJson) {
 // TODO.
}
