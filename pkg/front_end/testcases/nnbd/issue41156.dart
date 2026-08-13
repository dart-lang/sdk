// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Never throwing() => throw '';

void main() {
  String Function(int) x1 = (int v) => throw v; /* ok */
  String Function(int) x2 = (int v) /* ok */ {
    throw v;
  };
  String Function(int) x3 = (int v) /* ok */ {
    return throw v;
  };
  String Function(int) x4 = (int v) => throwing(); /* ok */
  String Function(int) x5 = (int v) /* ok */ {
    throwing();
  };
  String Function(int) x6 = (int v) /* ok */ {
    return throwing();
  };
  Future<String> Function(int) y1 = (int v) async => throw v; /* ok */
  Future<String> Function(int) y2 = (int v) async /* ok */ {
    throw v;
  };
  Future<String> Function(int) y3 = (int v) async /* ok */ {
    return throw v;
  };
  Future<String> Function(int) y4 = (int v) async => throwing(); /* ok */
  Future<String> Function(int) y5 = (int v) async /* ok */ {
    throwing();
  };
  Future<String> Function(int) y6 = (int v) async /* ok */ {
    return throwing();
  };
}

void errors() async {
  String Function(int) x2 = (int v) /* error */ {
    try {
      throw v;
    } catch (_) {}
  };
  String Function(int) x3 = (int v) /* error */ {
    try {
      return throw v;
    } catch (_) {}
  };
  String Function(int) x5 = (int v) /* error */ {
    try {
      throwing();
    } catch (_) {}
  };
  String Function(int) x6 = (int v) /* error */ {
    try {
      return throwing();
    } catch (_) {}
  };
  Future<String> Function(int) y2 = (int v) async /* error */ {
    try {
      throw v;
    } catch (_) {}
  };
  Future<String> Function(int) y3 = (int v) async /* error */ {
    try {
      return throw v;
    } catch (_) {}
  };
  Future<String> Function(int) y5 = (int v) async /* error */ {
    try {
      throwing();
    } catch (_) {}
  };
  Future<String> Function(int) y6 = (int v) async /* error */ {
    try {
      return throwing();
    } catch (_) {}
  };
}
