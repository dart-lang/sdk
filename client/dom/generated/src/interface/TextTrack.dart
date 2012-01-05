// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrack {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  TextTrackCueList get activeCues();

  TextTrackCueList get cues();

  String get kind();

  String get label();

  String get language();

  int get mode();

  void set mode(int value);

  EventListener get oncuechange();

  void set oncuechange(EventListener value);

  void addCue(TextTrackCue cue);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeCue(TextTrackCue cue);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
