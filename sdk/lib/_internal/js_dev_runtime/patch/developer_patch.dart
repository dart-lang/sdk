// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:developer library.

import 'dart:_js_helper' show patch, ForceInline, ReifyFunctionTypes;
import 'dart:_foreign_helper' show JS, JSExportName;
import 'dart:_runtime' as dart;
import 'dart:async';
import 'dart:convert' show json;
import 'dart:isolate';

@patch
@ForceInline()
bool debugger({bool when = true, String? message}) {
  if (when) {
    JS('', 'debugger');
  }
  return when;
}

@patch
Object? inspect(Object? object) {
  // Note: this log level does not show up by default in Chrome.
  // This is used for communication with the debugger service.
  JS('', 'console.debug("dart.developer.inspect", #)', object);
  return object;
}

@patch
void log(String message,
    {DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Zone? zone,
    Object? error,
    StackTrace? stackTrace}) {
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

final _extensions = <String, ServiceExtensionHandler>{};

@patch
ServiceExtensionHandler? _lookupExtension(String method) {
  return _extensions[method];
}

@patch
_registerExtension(String method, ServiceExtensionHandler handler) {
  _extensions[method] = handler;
  JS('', 'console.debug("dart.developer.registerExtension", #)', method);
}

/// Returns a JS `Promise` that resolves with the result of invoking
/// [methodName] with an [encodedJson] map as its parameters.
///
/// This is used by the VM Service Prototcol to invoke extensions registered
/// with [registerExtension]. For example, in JS:
///
///     await sdk.developer.invokeExtension(
/// .         "ext.flutter.inspector.getRootWidget", '{"objectGroup":""}');
///
@JSExportName('invokeExtension')
@ReifyFunctionTypes(false)
_invokeExtension(String methodName, String encodedJson) {
  // TODO(vsm): We should factor this out as future<->promise.
  return JS('', 'new #.Promise(#)', dart.global_,
      (Function(Object) resolve, Function(Object) reject) async {
    try {
      var method = _lookupExtension(methodName)!;
      var parameters = (json.decode(encodedJson) as Map).cast<String, String>();
      var result = await method(methodName, parameters);
      resolve(result._toString());
    } catch (e) {
      // TODO(vsm): Reject or encode in result?
      reject('$e');
    }
  });
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
void _reportFlowEvent(
    String category, String name, int type, int id, String argumentsAsJson) {
  // TODO.
}

@patch
void _reportInstantEvent(String category, String name, String argumentsAsJson) {
  // TODO.
}

@patch
int _getNextAsyncId() {
  return 0;
}

@patch
void _reportTaskEvent(int taskId, String phase, String category, String name,
    String argumentsAsJson) {
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
void _webServerControl(SendPort sendPort, bool enable, bool? silenceOutput) {
  sendPort.send(null);
}

@patch
String? _getIsolateIDFromSendPort(SendPort sendPort) {
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
  static final _instances = <String, _FakeUserTag>{};

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
    return _instances[label] = _FakeUserTag.real(label);
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
