// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:telemetry/telemetry.dart';

/// An implementation of [Analytics] that's appropriate to use when analytics
/// have not been enabled.
class NoopAnalytics extends Analytics {
  @override
  String? get applicationName => null;

  @override
  String? get applicationVersion => null;

  @override
  bool get enabled => false;

  @override
  set enabled(bool value) {
    // Ignored
  }

  @override
  Stream<Map<String, dynamic>> get onSend async* {
    // Ignored
  }

  @override
  void close() {
    // Ignored
  }

  @override
  getSessionValue(String param) {
    // Ignored
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }

  @override
  Future sendEvent(String category, String action,
      {String? label, int? value, Map<String, String>? parameters}) async {
    // Ignored
  }

  @override
  Future sendException(String description, {bool? fatal}) async {
    // Ignored
  }

  @override
  Future sendScreenView(String viewName,
      {Map<String, String>? parameters}) async {
    // Ignored
  }

  @override
  Future sendSocial(String network, String action, String target) async {
    // Ignored
  }

  @override
  Future sendTiming(String variableName, int time,
      {String? category, String? label}) async {
    // Ignored
  }

  @override
  void setSessionValue(String param, value) {
    // Ignored
  }

  @override
  Future waitForLastPing({Duration? timeout}) async {
    // Ignored
  }
}
