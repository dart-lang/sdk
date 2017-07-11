// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class TargetChangeEvent {
  TargetRepository get repository;
}

abstract class TargetRepository {
  Stream<TargetChangeEvent> get onChange;

  Target get current;
  Iterable<Target> list();
  void add(String);
  void setCurrent(Target);
  void delete(Target);
  Target find(String networkAddress);
  bool isConnectedVMTarget(Target target);
}
