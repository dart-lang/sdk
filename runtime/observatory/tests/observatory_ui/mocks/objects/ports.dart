// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class PortsMock implements M.Ports {
  final Iterable<M.Port> elements;

  const PortsMock({this.elements: const []});
}

class PortMock implements M.Port {
  final String name;
  final M.ObjectRef handler;

  const PortMock({this.name: 'port-name',
                  this.handler: const InstanceRefMock()});
}
