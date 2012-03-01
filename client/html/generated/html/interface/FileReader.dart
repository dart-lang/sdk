// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileReader {

  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  final FileError error;

  EventListener onabort;

  EventListener onerror;

  EventListener onload;

  EventListener onloadend;

  EventListener onloadstart;

  EventListener onprogress;

  final int readyState;

  final Object result;

  void abort();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void readAsArrayBuffer(Blob blob);

  void readAsBinaryString(Blob blob);

  void readAsDataURL(Blob blob);

  void readAsText(Blob blob, [String encoding]);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
