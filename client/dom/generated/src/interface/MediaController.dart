// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaController {

  TimeRanges get buffered();

  num get currentTime();

  void set currentTime(num value);

  num get defaultPlaybackRate();

  void set defaultPlaybackRate(num value);

  num get duration();

  bool get muted();

  void set muted(bool value);

  bool get paused();

  num get playbackRate();

  void set playbackRate(num value);

  TimeRanges get played();

  TimeRanges get seekable();

  num get volume();

  void set volume(num value);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void pause();

  void play();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
