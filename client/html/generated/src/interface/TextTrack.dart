// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrack {

  static final int Disabled = 0;

  static final int Error = 3;

  static final int Hidden = 1;

  static final int Loaded = 2;

  static final int Loading = 1;

  static final int None = 0;

  static final int Showing = 2;

  TextTrackCueList get activeCues();

  TextTrackCueList get cues();

  String get kind();

  String get label();

  String get language();

  int get mode();

  void set mode(int value);

  int get readyState();

  void addCue(TextTrackCue cue);

  void removeCue(TextTrackCue cue);
}
