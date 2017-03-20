// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ObjectStoreMock implements M.ObjectStore {
  final Iterable<M.NamedField> fields;

  const ObjectStoreMock({this.fields: const []});
}

class NamedFieldMock implements M.NamedField {
  final String name;
  final M.ObjectRef value;

  const NamedFieldMock({this.name: 'field-name',
                        this.value: const InstanceRefMock()});
}
