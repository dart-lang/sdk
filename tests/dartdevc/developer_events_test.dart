// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library developer_events_test;

import 'dart:developer'
    show postEvent, registerExtension, ServiceExtensionResponse;

import 'package:js/js.dart';
import 'package:expect/expect.dart';
import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

@JS(r'$emitDebugEvent')
external set emitDebugEvent(void Function(String, String)? func);

@JS(r'$emitDebugEvent')
external void Function(String, String)? get emitDebugEvent;

@JS(r'$emitRegisterEvent')
external set emitRegisterEvent(void Function(String)? func);

@JS(r'$emitRegisterEvent')
external void Function(String)? get emitRegisterEvent;

@JS(r'console.warn')
external set consoleWarn(void Function(String) func);

@JS(r'console.warn')
external void Function(String) get consoleWarn;

@JS(r'console.debug')
external set consoleDebug(void Function(String) func);

@JS(r'console.debug')
external void Function(String) get consoleDebug;

@JS(r'$dwdsVersion')
external set dwdsVersion(String? s);

@JS(r'$dwdsVersion')
external String? get dwdsVersion;

class _TestDebugEvent {
  final String kind;
  final String eventData;
  _TestDebugEvent(this.kind, this.eventData);
}

void main() {
  testRegisterExtensionWarningMessage();
  testPostEvent();
  testRegisterExtension();
}

/// Verify that warning messages are printed on the first call of
/// `registerExtension()` when the hooks are undefined.
///
/// Calls to `postEvent()` are always a no-op when no extension has been
/// registered to listen which can never happen if the hook is undefined.
void testRegisterExtensionWarningMessage() {
  final consoleWarnLog = <String>[];
  var savedConsoleWarn = consoleWarn;
  try {
    // Patch our own console.warn function for testing.
    consoleWarn = allowInterop((String s) => consoleWarnLog.add(s));
    expect(consoleWarnLog.isEmpty, true);

    var data0 = {'key0': 'value0'};
    postEvent('kind0', data0);

    // Nothing is listening, so this was a no-op.
    expect(consoleWarnLog.isEmpty, true);

    postEvent('kind0', data0);
    var data1 = {'key1': 'value1'};
    postEvent('kind1', data1);

    // No warnings should be issued because postEvent is a no-op when no
    // extensions have been registered to listen.
    expect(consoleWarnLog.isEmpty, true);

    consoleWarnLog.clear();

    var testHandler = (String s, Map<String, String> m) async =>
        ServiceExtensionResponse.result('test result');

    expect(consoleWarnLog.isEmpty, true);

    registerExtension('ext.method0', testHandler);

    // A warning message was issued about calling `registerExtension()` from
    // dart:developer.
    expect(
        consoleWarnLog.single
            .contains('registerExtension() from dart:developer'),
        true);

    registerExtension('ext.method1', testHandler);
    registerExtension('ext.method2', testHandler);

    // A warning is only issued on the first call of `registerExtension()`.
    expect(consoleWarnLog.length, 1);

    consoleWarnLog.clear();

    // The earlier call to registerExtension() was a no-op and printed a warning
    // because no debugger hooks are defined. This means more calls to
    // `postEvent()` are still no ops.
    postEvent('kind0', data0);
    postEvent('kind1', data1);
    expect(consoleWarnLog.isEmpty, true);
  } finally {
    // Restore actual console.warn function.
    consoleWarn = savedConsoleWarn;
  }
}

void testPostEvent() {
  final debugEventLog = <_TestDebugEvent>[];
  var savedEmitDebugEvent = emitDebugEvent;
  var savedDwdsVersion = dwdsVersion;

  try {
    // Provide a test version of the $emitDebugEvent hook.
    emitDebugEvent = allowInterop((String kind, String eventData) {
      debugEventLog.add(_TestDebugEvent(kind, eventData));
    });
    // Provide a version to signal there is an attached debugger.
    dwdsVersion = '1.0.0-for-test';
    expect(debugEventLog.isEmpty, true);

    var data0 = {'key0': 'value0'};
    postEvent('kind0', data0);

    expect(debugEventLog.single.kind, 'kind0');
    Expect.contains('"key0":"value0"', debugEventLog.single.eventData);

    var data1 = {'key1': 'value1'};
    var data2 = {'key2': 'value2'};
    postEvent('kind1', data1);
    postEvent('kind2', data2);

    expect(debugEventLog.length, 3);
    expect(debugEventLog[0].kind, 'kind0');
    Expect.contains('"key0":"value0"', debugEventLog[0].eventData);
    expect(debugEventLog[1].kind, 'kind1');
    Expect.contains('"key1":"value1"', debugEventLog[1].eventData);
    expect(debugEventLog[2].kind, 'kind2');
    Expect.contains('"key2":"value2"', debugEventLog[2].eventData);
  } finally {
    emitDebugEvent = savedEmitDebugEvent;
    dwdsVersion = savedDwdsVersion;
  }
}

void testRegisterExtension() {
  final registerEventLog = <String>[];
  var savedEmitRegisterEvent = emitRegisterEvent;
  var savedDwdsVersion = dwdsVersion;

  try {
    // Provide a test version of the $emitRegisterEvent hook.
    emitRegisterEvent = allowInterop((String eventData) {
      registerEventLog.add(eventData);
    });
    // Provide a version to signal there is an attached debugger.
    dwdsVersion = '1.0.0-for-test';
    expect(registerEventLog.isEmpty, true);

    var testHandler = (String s, Map<String, String> m) async =>
        ServiceExtensionResponse.result('test result');
    registerExtension('ext.method0', testHandler);

    expect(registerEventLog.single, 'ext.method0');

    registerExtension('ext.method1', testHandler);
    registerExtension('ext.method2', testHandler);

    expect(registerEventLog.length, 3);
    expect(registerEventLog[0], 'ext.method0');
    expect(registerEventLog[1], 'ext.method1');
    expect(registerEventLog[2], 'ext.method2');
  } finally {
    emitRegisterEvent = savedEmitRegisterEvent;
    dwdsVersion = savedDwdsVersion;
  }
}
