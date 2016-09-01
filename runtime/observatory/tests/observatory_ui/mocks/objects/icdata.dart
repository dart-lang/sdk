// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ICDataRefMock implements M.ICDataRef {
  final String id;
  final String selector;

  const ICDataRefMock({this.id: 'icdata-id', this.selector});
}

class ICDataMock implements M.ICData {
  final String id;
  final M.ClassRef clazz;
  final String vmName;
  final int size;
  final String selector;
  final M.ObjectRef dartOwner;
  final M.InstanceRef argumentsDescriptor;
  final M.InstanceRef entries;

  const ICDataMock({this.id: 'icdata-id', this.vmName: 'icdata-vmName',
                    this.clazz: const ClassRefMock(), this.size: 0,
                    this.selector, this.dartOwner, this.argumentsDescriptor,
                    this.entries});
}
