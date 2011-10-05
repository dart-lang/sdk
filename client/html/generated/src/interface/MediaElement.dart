// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaElement extends Element {

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

  bool get autoplay();

  void set autoplay(bool value);

  TimeRanges get buffered();

  bool get controls();

  void set controls(bool value);

  String get currentSrc();

  num get currentTime();

  void set currentTime(num value);

  num get defaultPlaybackRate();

  void set defaultPlaybackRate(num value);

  num get duration();

  bool get ended();

  MediaError get error();

  bool get loop();

  void set loop(bool value);

  bool get muted();

  void set muted(bool value);

  int get networkState();

  bool get paused();

  num get playbackRate();

  void set playbackRate(num value);

  TimeRanges get played();

  String get preload();

  void set preload(String value);

  int get readyState();

  TimeRanges get seekable();

  bool get seeking();

  String get src();

  void set src(String value);

  num get startTime();

  num get volume();

  void set volume(num value);

  int get webkitAudioDecodedByteCount();

  bool get webkitClosedCaptionsVisible();

  void set webkitClosedCaptionsVisible(bool value);

  bool get webkitHasClosedCaptions();

  bool get webkitPreservesPitch();

  void set webkitPreservesPitch(bool value);

  int get webkitVideoDecodedByteCount();

  String canPlayType(String type);

  void load();

  void pause();

  void play();
}
