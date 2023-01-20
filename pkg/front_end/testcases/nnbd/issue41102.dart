// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'dart:async';

void main() {}

final t = StreamTransformer.fromHandlers(
    handleData: (data, sink) => Future.microtask(() => sink.add(data)),
    handleDone: (sink) => Future.microtask(() => sink.close()));

final s1 = [];

final s2 = s1?.length;

final s3 = new List<int>.filled(2, null);

final s4 = () {
  var e = 0;
  switch (e) {
    case 0:
      print('fallthrough');
    case 1:
    case '':
  }
}();

int? s5;

final s6 = s5 + 0;

List? s7;

final s8 = s7[0];

final s9 = s7[0] = 0;

final s10 = s7.length;

final s11 = s7.length = 0;

final s12 = -s5;

int Function()? s13;

final s14 = (s13)();

final s15 = throw null;
