// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class IsolateGroupRef {
  /// The id which is passed to the getIsolateGroup RPC to reload this
  /// isolate group.
  String get id;

  /// A numeric id for this isolate group, represented as a string. Unique.
  int get number;

  /// A name identifying this isolate group. Not guaranteed to be unique.
  String get name;

  bool get isSystemIsolateGroup;
}

abstract class IsolateGroup extends IsolateGroupRef {
  /// A list of all isolates in this isolate group.
  Iterable<IsolateRef> get isolates;
}
