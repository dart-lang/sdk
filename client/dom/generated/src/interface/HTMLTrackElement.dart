// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTrackElement extends HTMLElement {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool get isDefault();

  void set isDefault(bool value);

  String get kind();

  void set kind(String value);

  String get label();

  void set label(String value);

  int get readyState();

  String get src();

  void set src(String value);

  String get srclang();

  void set srclang(String value);

  TextTrack get track();
}
