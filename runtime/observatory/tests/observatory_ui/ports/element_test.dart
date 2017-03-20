// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/ports.dart';
import '../mocks.dart';

main() {
  PortsElement.tag.ensureRegistration();

  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notifs = new NotificationRepositoryMock();
  final ports = new PortsRepositoryMock();
  final instances = new InstanceRepositoryMock();
  test('instantiation', () {
    final e = new PortsElement(vm, isolate, events, notifs, ports, instances);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.ports, equals(ports));
  });
  test('elements created after attachment', () async {
    const elements = const [
      const PortMock(name: 'port-1'),
      const PortMock(name: 'port-2'),
      const PortMock(name: 'port-3')
    ];
    const isolatePorts = const PortsMock(elements: elements);
    final ports = new PortsRepositoryMock(
      getter: expectAsync((i) async {
        expect(i, equals(isolate));
        return isolatePorts;
      }, count: 1)
    );
    final instances = new InstanceRepositoryMock();
    final e = new PortsElement(vm, isolate, events, notifs, ports, instances);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll('.port-number').length, equals(elements.length));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
