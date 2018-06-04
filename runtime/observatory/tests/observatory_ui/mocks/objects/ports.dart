// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class PortsAndHandlesMock implements M.Ports, M.PersistentHandles {
  final Iterable<PortMock> elements;

  const PortsAndHandlesMock({this.elements: const []});

  @override
  Iterable<M.WeakPersistentHandle> get weakElements =>
      throw new UnimplementedError();
}

class PortMock implements M.Port, M.PersistentHandle {
  final String name;
  final M.ObjectRef handler;

  const PortMock(
      {this.name: 'port-name', this.handler: const InstanceRefMock()});

  @override
  M.ObjectRef get object => throw new UnimplementedError();
}
