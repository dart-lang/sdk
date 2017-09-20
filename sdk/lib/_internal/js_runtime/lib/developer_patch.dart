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
void _postEvent(String eventKind, String eventData) {
  // TODO.
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
      throw new UnsupportedError(
          'UserTag instance limit (${UserTag.MAX_USER_TAGS}) reached.');
    }
    // Create a new instance and add it to the instance map.
    var instance = new _FakeUserTag.real(label);
    _instances[label] = instance;
    return instance;
  }

  final String label;

  UserTag makeCurrent() {
    var old = _currentTag;
    _currentTag = this;
    return old;
  }

  static final UserTag _defaultTag = new _FakeUserTag('Default');
}

var _currentTag = _FakeUserTag._defaultTag;

@patch
UserTag getCurrentTag() => _currentTag;
