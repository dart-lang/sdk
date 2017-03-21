// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class InboundReferencesMock implements M.InboundReferences {
  final Iterable<M.InboundReference> elements;

  const InboundReferencesMock({this.elements: const []});
}

class InboundReferenceMock implements M.InboundReference {
  final M.ObjectRef source;
  final M.ObjectRef parentField;
  final int parentListIndex;
  final int parentWordOffset;

  const InboundReferenceMock({this.source: const InstanceRefMock(),
                              this.parentField, this.parentListIndex,
                              this.parentWordOffset});
}
