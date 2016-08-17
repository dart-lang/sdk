// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class InstanceRefMock implements M.InstanceRef {
  final String id;
  final String name;
  final M.InstanceKind kind;
  final M.ClassRef clazz;
  final String valueAsString;
  final bool valueAsStringIsTruncated;
  final int length;
  final M.ClassRef typeClass;
  final M.ClassRef parameterizedClass;
  final M.InstanceRef pattern;
  final M.FunctionRef closureFunction;

  const InstanceRefMock({this.id: 'instance-id', this.name: 'instance-name',
                         this.kind: M.InstanceKind.vNull, this.clazz,
                         this.valueAsString: 'null',
                         this.valueAsStringIsTruncated, this.length,
                         this.typeClass, this.parameterizedClass, this.pattern,
                        this.closureFunction});
}

class InstanceMock implements M.Instance {
  final String id;
  final String name;
  final M.InstanceKind kind;
  final M.ClassRef clazz;
  final int size;
  final String valueAsString;
  final bool valueAsStringIsTruncated;
  final int length;
  final M.ClassRef typeClass;
  final M.ClassRef parameterizedClass;
  final M.InstanceRef pattern;
  final M.FunctionRef closureFunction;
  final int offset;
  final int count;
  final Iterable<dynamic> typedElements;
  final Iterable<M.BoundField> fields;
  final Iterable<M.Guarded<M.ObjectRef>> elements;
  final Iterable<M.MapAssociation> associations;
  final M.InstanceRef key;
  final M.InstanceRef value;
  final M.InstanceRef referent;

  const InstanceMock({this.id: 'instance-id', this.name: 'instance-name',
                      this.kind: M.InstanceKind.vNull, this.clazz, this.size,
                      this.valueAsString: 'null', this.valueAsStringIsTruncated,
                      this.length, this.typeClass, this.parameterizedClass,
                      this.pattern, this.closureFunction, this.offset,
                      this.count, this.typedElements, this.fields,
                      this.elements, this.associations, this.key, this.value,
                      this.referent});
}
