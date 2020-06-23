// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

enum FrameKind { regular, asyncCausal, asyncSuspensionMarker, asyncActivation }

abstract class Frame {
  FrameKind? get kind;
  String? get marker;
  FunctionRef? get function;
  SourceLocation? get location;
}
