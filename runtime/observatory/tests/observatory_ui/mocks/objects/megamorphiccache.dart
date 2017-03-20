// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class MegamorphicCacheRefMock implements M.MegamorphicCacheRef {
  final String id;
  final String selector;

  const MegamorphicCacheRefMock({this.id : 'megamorphiccache-id',
                                 this.selector: 'selector'});
}

class MegamorphicCacheMock implements M.MegamorphicCache {
  final String id;
  final M.ClassRef clazz;
  final String vmName;
  final int size;
  final String selector;
  final int mask;
  final M.InstanceRef buckets;
  final M.InstanceRef argumentsDescriptor;

  const MegamorphicCacheMock({this.id : 'megamorphiccache-id',
                              this.vmName: 'megamorphiccache-vmName',
                              this.clazz: const ClassRefMock(),
                              this.size: 1, this.selector: 'selector',
                              this.mask: 0,
                              this.buckets: const InstanceRefMock(),
                              this.argumentsDescriptor: const InstanceRefMock()
                             });
}
