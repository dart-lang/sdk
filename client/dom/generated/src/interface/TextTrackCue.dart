// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackCue default _TextTrackCueFactoryProvider {

  TextTrackCue(String id, num startTime, num endTime, String text, [String settings, bool pauseOnExit]);

  String align;

  num endTime;

  String id;

  int line;

  EventListener onenter;

  EventListener onexit;

  bool pauseOnExit;

  int position;

  int size;

  bool snapToLines;

  num startTime;

  String text;

  final TextTrack track;

  String vertical;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  DocumentFragment getCueAsHTML();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
