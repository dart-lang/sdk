// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class FieldRefMock implements M.FieldRef {
  final String id;
  final String name;
  final M.ObjectRef dartOwner;
  final M.InstanceRef declaredType;
  final bool isConst;
  final bool isFinal;
  final bool isStatic;

  const FieldRefMock({this.id: 'field-id', this.name: 'field-name',
                      this.dartOwner,
                      this.declaredType: const InstanceRefMock(name: 'dynamic'),
                      this.isConst: false,
                      this.isFinal: false, this.isStatic: false});
}
