// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStream default _MediaStreamFactoryProvider {

  MediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks);

  static final int ENDED = 2;

  static final int LIVE = 1;

  final MediaStreamTrackList audioTracks;

  final String label;

  EventListener onended;

  final int readyState;

  final MediaStreamTrackList videoTracks;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event event);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
