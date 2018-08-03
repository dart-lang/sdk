// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class TargetChangeEventMock implements M.TargetChangeEvent {
  final TargetRepositoryMock repository;
  const TargetChangeEventMock({this.repository});
}

typedef void TargetRepositoryMockStringCallback(String notification);
typedef void TargetRepositoryMockTargetCallback(M.Target notification);

class TargetRepositoryMock implements M.TargetRepository {
  final StreamController<M.TargetChangeEvent> _onChange =
      new StreamController<M.TargetChangeEvent>.broadcast();
  Stream<M.TargetChangeEvent> get onChange => _onChange.stream;

  bool get hasListeners => _onChange.hasListener;

  final M.Target _current;
  final Iterable<M.Target> _list;
  final TargetRepositoryMockStringCallback _add;
  final TargetRepositoryMockTargetCallback _setCurrent;
  final TargetRepositoryMockTargetCallback _delete;

  bool currentInvoked = false;
  bool addInvoked = false;
  bool listInvoked = false;
  bool setCurrentInvoked = false;
  bool deleteInvoked = false;

  M.Target get current {
    currentInvoked = true;
    return _current;
  }

  void add(String val) {
    addInvoked = true;
    if (_add != null) _add(val);
  }

  Iterable<M.Target> list() {
    listInvoked = true;
    return _list;
  }

  void setCurrent(M.Target target) {
    setCurrentInvoked = true;
    if (_setCurrent != null) _setCurrent(target);
  }

  void delete(M.Target target) {
    deleteInvoked = true;
    if (_delete != null) _delete(target);
  }

  void triggerChangeEvent() {
    _onChange.add(new TargetChangeEventMock(repository: this));
  }

  M.Target find(String networkAddress) {
    return const TargetMock();
  }

  @override
  bool isConnectedVMTarget(M.Target target) {
    return false;
  }

  TargetRepositoryMock(
      {M.Target current,
      Iterable<M.Target> list: const [],
      TargetRepositoryMockStringCallback add,
      TargetRepositoryMockTargetCallback setCurrent,
      TargetRepositoryMockTargetCallback delete})
      : _current = current,
        _list = list,
        _add = add,
        _setCurrent = setCurrent,
        _delete = delete;
}
