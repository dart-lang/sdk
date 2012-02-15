// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PeerConnection {

  static final int ACTIVE = 2;

  static final int CLOSED = 3;

  static final int NEGOTIATING = 1;

  static final int NEW = 0;

  final MediaStreamList localStreams;

  EventListener onaddstream;

  EventListener onconnecting;

  EventListener onmessage;

  EventListener onopen;

  EventListener onremovestream;

  final int readyState;

  final MediaStreamList remoteStreams;

  void addEventListener(String type, EventListener listener, bool useCapture);

  void addStream(MediaStream stream);

  void close();

  bool dispatchEvent(Event event);

  void processSignalingMessage(String message);

  void removeEventListener(String type, EventListener listener, bool useCapture);

  void removeStream(MediaStream stream);

  void send(String text);
}
