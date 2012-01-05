// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackList {

  int get length();

  EventListener get onaddtrack();

  void set onaddtrack(EventListener value);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  TextTrack item(int index);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
