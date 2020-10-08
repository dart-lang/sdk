// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class InboundReferences {
  Iterable<InboundReference> get elements;
}

abstract class InboundReference {
  ObjectRef get source;

  /// [optional]
  ObjectRef get parentField;

  /// [optional]
  int get parentListIndex;

  /// [optional]
  int get parentWordOffset;
}
