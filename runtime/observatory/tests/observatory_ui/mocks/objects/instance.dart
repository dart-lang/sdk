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
  final M.ContextRef closureContext;

  const InstanceRefMock(
      {this.id: 'instance-id',
      this.name: 'instance-name',
      this.kind: M.InstanceKind.vNull,
      this.clazz,
      this.valueAsString: 'null',
      this.valueAsStringIsTruncated,
      this.length,
      this.typeClass,
      this.parameterizedClass,
      this.pattern,
      this.closureFunction,
      this.closureContext});
}

class InstanceMock implements M.Instance {
  final String id;
  final String name;
  final String vmName;
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
  final M.ContextRef closureContext;
  final int offset;
  final int count;
  final List<dynamic> typedElements;
  final Iterable<M.BoundField> fields;
  final Iterable<M.NativeField> nativeFields;
  final Iterable<M.Guarded<M.ObjectRef>> elements;
  final Iterable<M.MapAssociation> associations;
  final M.InstanceRef key;
  final M.InstanceRef value;
  final M.InstanceRef referent;
  final M.TypeArguments typeArguments;
  final int parameterIndex;
  final M.InstanceRef targetType;
  final M.InstanceRef bound;
  final M.Breakpoint activationBreakpoint;
  final bool isCaseSensitive;
  final bool isMultiLine;
  final M.FunctionRef oneByteFunction;
  final M.FunctionRef twoByteFunction;
  final M.FunctionRef externalOneByteFunction;
  final M.FunctionRef externalTwoByteFunction;
  final M.InstanceRef oneByteBytecode;
  final M.InstanceRef twoByteBytecode;

  const InstanceMock(
      {this.id: 'instance-id',
      this.name: 'instance-name',
      this.vmName: 'instance-vmName',
      this.kind: M.InstanceKind.vNull,
      this.clazz: const ClassRefMock(),
      this.size: 0,
      this.valueAsString: 'null',
      this.valueAsStringIsTruncated,
      this.length,
      this.typeClass,
      this.parameterizedClass,
      this.pattern,
      this.closureFunction,
      this.closureContext,
      this.offset,
      this.count,
      this.typedElements,
      this.fields,
      this.nativeFields,
      this.elements,
      this.associations,
      this.key,
      this.value,
      this.referent,
      this.typeArguments,
      this.parameterIndex,
      this.targetType,
      this.bound,
      this.activationBreakpoint,
      this.isCaseSensitive,
      this.isMultiLine,
      this.oneByteFunction,
      this.twoByteFunction,
      this.externalOneByteFunction,
      this.externalTwoByteFunction,
      this.oneByteBytecode,
      this.twoByteBytecode});
}
