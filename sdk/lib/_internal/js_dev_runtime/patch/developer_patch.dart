// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:developer library.

import 'dart:_js_helper' show ForceInline, ReifyFunctionTypes;
import 'dart:_foreign_helper' show JS, JSExportName;
import 'dart:_internal' show patch;
import 'dart:_runtime' as dart;
import 'dart:async';
import 'dart:convert' show json;
import 'dart:isolate';

var _issuedRegisterExtensionWarning = false;
var _issuedPostEventWarning = false;
final _developerSupportWarning = 'from dart:developer is only supported in '
    'build/run/test environments where the developer event method hooks have '
    'been set by package:dwds v11.1.0 or higher.';

/// Returns `true` if the debugger service has been attached to the app.
// TODO(46377) Update this check when we have a documented API for DDC apps.
bool get _debuggerAttached => JS<bool>('!', r'!!#.$dwdsVersion', dart.global_);

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

@patch
int get reachabilityBarrier => 0;

final _extensions = <String, ServiceExtensionHandler>{};

@patch
ServiceExtensionHandler? _lookupExtension(String method) {
  return _extensions[method];
}

@patch
_registerExtension(String method, ServiceExtensionHandler handler) {
  if (!_debuggerAttached) {
    if (!_issuedRegisterExtensionWarning) {
      var message = 'registerExtension() $_developerSupportWarning';
      JS('', 'console.warn(#)', message);
      _issuedRegisterExtensionWarning = true;
    }
    return;
  }
  // TODO(46377) Update this check when we have a documented API for DDC apps.
  if (JS<bool>('!', r'!!#.$emitRegisterEvent', dart.global_)) {
    _extensions[method] = handler;
    // See hooks assigned by package:dwds:
    // https://github.com/dart-lang/webdev/blob/de05cf9fbbfe088be74bb61df4a138289a94d902/dwds/web/client.dart#L223
    JS('', r'#.$emitRegisterEvent(#)', dart.global_, method);
  }
}

/// Returns a JS `Promise` that resolves with the result of invoking
/// [methodName] with an [encodedJson] map as its parameters.
///
/// This is used by the VM Service Protocol to invoke extensions registered
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
bool get extensionStreamHasListener => _debuggerAttached;

@patch
void _postEvent(String eventKind, String eventData) {
  if (!_debuggerAttached) {
    if (!_issuedPostEventWarning) {
      var message = 'postEvent() $_developerSupportWarning';
      JS('', 'console.warn(#)', message);
      _issuedPostEventWarning = true;
    }
    return;
  }
  // TODO(46377) Update this check when we have a documented API for DDC apps.
  if (JS<bool>('!', r'!!#.$emitDebugEvent', dart.global_)) {
    // See hooks assigned by package:dwds:
    // https://github.com/dart-lang/webdev/blob/de05cf9fbbfe088be74bb61df4a138289a94d902/dwds/web/client.dart#L220
    JS('', r'#.$emitDebugEvent(#, #)', dart.global_, eventKind, eventData);
  }
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
int _getNextTaskId() {
  return 0;
}

@patch
void _reportTaskEvent(
    int taskId, int type, String name, String argumentsAsJson) {
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

final class _FakeUserTag implements UserTag {
  static final _instances = <String, _FakeUserTag>{};

  _FakeUserTag.real(this.label);

  factory _FakeUserTag(String label) {
    // Canonicalize by name.
    var existingTag = _instances[label];
    if (existingTag != null) {
      return existingTag;
    }
    // Throw an exception if we've reached the maximum number of user tags.
    if (_instances.length == UserTag.maxUserTags) {
      throw UnsupportedError(
          'UserTag instance limit (${UserTag.maxUserTags}) reached.');
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

@patch
abstract final class NativeRuntime {
  @patch
  static void writeHeapSnapshotToFile(String filepath) =>
      throw UnsupportedError(
          "Generating heap snapshots is not supported on the web.");
}
