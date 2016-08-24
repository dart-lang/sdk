// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class RetainingPathMock implements M.RetainingPath {
  final Iterable<M.RetainingPathItem> elements;

  const RetainingPathMock({this.elements: const []});
}

class RetainingPathItemMock implements M.RetainingPathItem {
  final M.ObjectRef source;
  final M.ObjectRef parentField;
  final int parentListIndex;
  final int parentWordOffset;

  const RetainingPathItemMock({this.source: const InstanceRefMock(),
                               this.parentField, this.parentListIndex,
                               this.parentWordOffset});
}
