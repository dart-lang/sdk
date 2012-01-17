// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackCue {

  String get alignment();

  void set alignment(String value);

  String get direction();

  void set direction(String value);

  num get endTime();

  void set endTime(num value);

  String get id();

  void set id(String value);

  int get linePosition();

  void set linePosition(int value);

  EventListener get onenter();

  void set onenter(EventListener value);

  EventListener get onexit();

  void set onexit(EventListener value);

  bool get pauseOnExit();

  void set pauseOnExit(bool value);

  int get size();

  void set size(int value);

  bool get snapToLines();

  void set snapToLines(bool value);

  num get startTime();

  void set startTime(num value);

  String get text();

  void set text(String value);

  int get textPosition();

  void set textPosition(int value);

  TextTrack get track();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  DocumentFragment getCueAsHTML();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
