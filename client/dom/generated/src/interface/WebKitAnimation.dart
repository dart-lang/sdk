// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitAnimation {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  num get delay();

  int get direction();

  num get duration();

  num get elapsedTime();

  void set elapsedTime(num value);

  bool get ended();

  int get fillMode();

  int get iterationCount();

  String get name();

  bool get paused();

  void pause();

  void play();
}
