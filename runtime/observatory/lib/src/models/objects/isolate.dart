// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class IsolateRef {
  String get id;
  int get number;
  String get name;
}

abstract class Isolate extends IsolateRef {
  DateTime get startTime;
  bool get runnable;
}
