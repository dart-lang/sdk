// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// #library("mirrors");

// The dart:mirrors library provides reflective access for Dart program.
//
// TODO(turnidge): Complete this api.  This is a placeholder.

interface IsolateMirror {
  // A name used to refer to an isolate in debugging messages.
  final String debugName;
}

Future<IsolateMirror> isolateMirrorOf(SendPort port) {
  return _Mirrors.isolateMirrorOf(port);
}
