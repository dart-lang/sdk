// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class PersistentHandlesMock implements M.PersistentHandles {
  final Iterable<M.PersistentHandle> elements;
  final Iterable<M.WeakPersistentHandle> weakElements;

  const PersistentHandlesMock({this.elements: const [],
                               this.weakElements: const []});
}

class PersistentHandleMock implements M.PersistentHandle {
  final M.ObjectRef object;

  const PersistentHandleMock({this.object: const InstanceRefMock()});
}

class WeakPersistentHandleMock implements M.WeakPersistentHandle {
  final M.ObjectRef object;
  final int externalSize;
  final String peer;
  final String callbackSymbolName;
  final String callbackAddress;

  const WeakPersistentHandleMock({this.object: const InstanceRefMock(),
                                  this.externalSize: 0, this.peer: '0x0',
                                  this.callbackSymbolName: 'dart::Something()',
                                  this.callbackAddress: '0x123456'});
}
