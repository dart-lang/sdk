// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// State for a running isolate.
class Isolate extends Observable {
  @observable final int id;
  @observable final String name;

  Isolate(this.id, this.name);

  String toString() => '$id $name';
}