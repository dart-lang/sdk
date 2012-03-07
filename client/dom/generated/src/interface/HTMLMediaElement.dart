// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLMediaElement extends HTMLElement {

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

  bool autoplay;

  final TimeRanges buffered;

  MediaController controller;

  bool controls;

  final String currentSrc;

  num currentTime;

  bool defaultMuted;

  num defaultPlaybackRate;

  final num duration;

  final bool ended;

  final MediaError error;

  final num initialTime;

  bool loop;

  String mediaGroup;

  bool muted;

  final int networkState;

  final bool paused;

  num playbackRate;

  final TimeRanges played;

  String preload;

  final int readyState;

  final TimeRanges seekable;

  final bool seeking;

  String src;

  final num startTime;

  final TextTrackList textTracks;

  num volume;

  final int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  final bool webkitHasClosedCaptions;

  final String webkitMediaSourceURL;

  bool webkitPreservesPitch;

  final int webkitSourceState;

  final int webkitVideoDecodedByteCount;

  TextTrack addTextTrack(String kind, [String label, String language]);

  String canPlayType(String type);

  void load();

  void pause();

  void play();

  void webkitSourceAppend(Uint8Array data);

  void webkitSourceEndOfStream(int status);
}
