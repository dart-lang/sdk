// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:developer library.

import 'dart:_js_helper' show patch, ForceInline;
import 'dart:_foreign_helper' show JS;
import 'dart:async';
import 'dart:isolate';

@patch
@ForceInline()
bool debugger({bool when = true, String message}) {
  if (when) {
    JS('', 'debugger');
  }
  return when;
}

@patch
Object inspect(Object object) {
  // Note: this log level does not show up by default in Chrome.
  // This is used for communication with the debugger service.
  JS('', 'console.debug("dart.developer.inspect", #)', object);
  return object;
}

@patch
void log(String message,
    {DateTime time,
    int sequenceNumber,
    int level = 0,
    String name = '',
    Zone zone,
    Object error,
    StackTrace stackTrace}) {
  Object items =
      JS('!', '{ message: #, name: #, level: # }', message, name, level);
  if (time != null) JS('', '#.time = #', items, time);
  if (sequenceNumber != null) {
    JS('', '#.sequenceNumber = #', items, sequenceNumber);
  }
  if (zone != null) JS('', '#.zone = #', items, zone);
  if (error != null) JS('', '#.error = #', items, error);
  if (stackTrace != null) JS('', '#.stackTrace = #', items, stackTrace);

  JS('', 'console.debug("dart.developer.log", #)', items);
}

final _extensions = Map<String, ServiceExtensionHandler>();

@patch
ServiceExtensionHandler _lookupExtension(String method) {
  return _extensions[method];
}

@patch
_registerExtension(String method, ServiceExtensionHandler handler) {
  _extensions[method] = handler;
  JS('', 'console.debug("dart.developer.registerExtension", #)', method);
}

@patch
void _postEvent(String eventKind, String eventData) {
  JS('', 'console.debug("dart.developer.postEvent", #, #)', eventKind,
      eventData);
}

@patch
bool _isDartStreamEnabled() {
  return false;
}

@patch
int _getTraceClock() {
  // TODO.
  return _clockValue++;
}

int _clockValue = 0;

@patch
int _getThreadCpuClock() {
  return -1;
}

@patch
void _reportCompleteEvent(int start, int startCpu, String category, String name,
    String argumentsAsJson) {
  // TODO.
}

@patch
void _reportFlowEvent(int start, int startCpu, String category, String name,
    int type, int id, String argumentsAsJson) {
  // TODO.
}

@patch
void _reportInstantEvent(
    int start, String category, String name, String argumentsAsJson) {
  // TODO.
}

@patch
int _getNextAsyncId() {
  return 0;
}

@patch
void _reportTaskEvent(int start, int taskId, String phase, String category,
    String name, String argumentsAsJson) {
  // TODO.
}

@patch
int _getServiceMajorVersion() {
  return 0;
}

@patch
int _getServiceMinorVersion() {
  return 0;
}

@patch
void _getServerInfo(SendPort sendPort) {
  sendPort.send(null);
}

@patch
void _webServerControl(SendPort sendPort, bool enable) {
  sendPort.send(null);
}

@patch
String _getIsolateIDFromSendPort(SendPort sendPort) {
  return null;
}

@patch
class UserTag {
  @patch
  factory UserTag(String label) = _FakeUserTag;

  @patch
  static UserTag get defaultTag => _FakeUserTag._defaultTag;
}

class _FakeUserTag implements UserTag {
  static Map _instances = {};

  _FakeUserTag.real(this.label);

  factory _FakeUserTag(String label) {
    // Canonicalize by name.
    var existingTag = _instances[label];
    if (existingTag != null) {
      return existingTag;
    }
    // Throw an exception if we've reached the maximum number of user tags.
    if (_instances.length == UserTag.MAX_USER_TAGS) {
      throw UnsupportedError(
          'UserTag instance limit (${UserTag.MAX_USER_TAGS}) reached.');
    }
    // Create a new instance and add it to the instance map.
    var instance = _FakeUserTag.real(label);
    _instances[label] = instance;
    return instance;
  }

  final String label;

  UserTag makeCurrent() {
    var old = _currentTag;
    _currentTag = this;
    return old;
  }

  static final UserTag _defaultTag = _FakeUserTag('Default');
}

var _currentTag = _FakeUserTag._defaultTag;

@patch
UserTag getCurrentTag() => _currentTag;
