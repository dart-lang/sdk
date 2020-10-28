// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

enum InstanceKind {
  /// A general instance of the Dart class Object.
  plainInstance,

  /// null instance.
  vNull,

  /// true or false.
  bool,

  /// An instance of the Dart class double.
  double,

  /// An instance of the Dart class int.
  int,

  /// An instance of the Dart class String.
  string,

  /// An instance of the built-in VM List implementation. User-defined
  /// Lists will be PlainInstance.
  list,

  /// An instance of the built-in VM Map implementation. User-defined
  /// Maps will be PlainInstance.
  map,

  /// Vector instance kinds.
  float32x4,

  /// Vector instance kinds.
  float64x2,

  /// Vector instance kinds.
  int32x4,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  uint8ClampedList,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  uint8List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  uint16List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  uint32List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  uint64List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  int8List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  int16List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  int32List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  int64List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  float32List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  float64List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  int32x4List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  float32x4List,

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  float64x2List,

  /// An instance of the Dart class StackTrace.
  stackTrace,

  /// An instance of the built-in VM Closure implementation. User-defined
  /// Closures will be PlainInstance.
  closure,

  /// An instance of the Dart class MirrorReference.
  mirrorReference,

  /// An instance of the Dart class RegExp.
  regExp,

  /// An instance of the Dart class WeakProperty.
  weakProperty,

  /// An instance of the Dart class Type.
  type,

  /// An instance of the Dart class TypeParameter.
  typeParameter,

  /// An instance of the Dart class TypeRef.
  typeRef,

  /// An instance of the Dart class RawReceivePort
  receivePort,
}

bool isTypedData(InstanceKind? kind) {
  if (kind == null) {
    return false;
  }
  switch (kind) {
    case InstanceKind.uint8ClampedList:
    case InstanceKind.uint8List:
    case InstanceKind.uint16List:
    case InstanceKind.uint32List:
    case InstanceKind.uint64List:
    case InstanceKind.int8List:
    case InstanceKind.int16List:
    case InstanceKind.int32List:
    case InstanceKind.int64List:
    case InstanceKind.float32List:
    case InstanceKind.float64List:
    case InstanceKind.int32x4List:
    case InstanceKind.float32x4List:
    case InstanceKind.float64x2List:
      return true;
    default:
      return false;
  }
}

bool isSimdValue(InstanceKind? kind) {
  if (kind == null) {
    return false;
  }
  switch (kind) {
    case InstanceKind.float32x4:
    case InstanceKind.float64x2:
    case InstanceKind.int32x4:
      return true;
    default:
      return false;
  }
}

bool isAbstractType(InstanceKind? kind) {
  if (kind == null) {
    return false;
  }
  switch (kind) {
    case InstanceKind.type:
    case InstanceKind.typeRef:
    case InstanceKind.typeParameter:
      return true;
    default:
      return false;
  }
}

abstract class InstanceRef extends ObjectRef {
  /// What kind of instance is this?
  InstanceKind? get kind;

  /// Instance references always include their class.
  ClassRef? get clazz;

  /// [optional] The value of this instance as a string.
  ///
  /// Provided for the instance kinds:
  ///   Null (null)
  ///   Bool (true or false)
  ///   Double (suitable for passing to Double.parse())
  ///   Int (suitable for passing to int.parse())
  ///   String (value may be truncated)
  ///   Float32x4
  ///   Float64x2
  ///   Int32x4
  ///   StackTrace
  String? get valueAsString;

  /// [optional] The valueAsString for String references may be truncated. If so,
  /// this property is added with the value 'true'.
  ///
  /// New code should use 'length' and 'count' instead.
  bool? get valueAsStringIsTruncated;

  /// [optional] The length of a List or the number of associations in a Map or
  /// the number of codeunits in a String.
  ///
  /// Provided for instance kinds:
  ///   String
  ///   List
  ///   Map
  ///   Uint8ClampedList
  ///   Uint8List
  ///   Uint16List
  ///   Uint32List
  ///   Uint64List
  ///   Int8List
  ///   Int16List
  ///   Int32List
  ///   Int64List
  ///   Float32List
  ///   Float64List
  ///   Int32x4List
  ///   Float32x4List
  ///   Float64x2List
  int? get length;

  /// [optional] The name of a Type instance.
  ///
  /// Provided for instance kinds:
  ///   Type
  String? get name;

  /// [optional] The corresponding Class if this Type is canonical.
  ///
  /// Provided for instance kinds:
  ///   Type
  ClassRef? get typeClass;

  /// [optional] The parameterized class of a type parameter:
  ///
  /// Provided for instance kinds:
  ///   TypeParameter
  ClassRef? get parameterizedClass;

  /// [optional] The pattern of a RegExp instance.
  ///
  /// The pattern is always an instance of kind String.
  ///
  /// Provided for instance kinds:
  ///   RegExp
  InstanceRef? get pattern;

  /// [optional] The function associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///   Closure
  FunctionRef? get closureFunction;

  /// [optional] The context associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///   Closure
  ContextRef? get closureContext;
}

abstract class Instance extends Object implements InstanceRef {
  /// [optional] The index of the first element or association or codeunit
  /// returned. This is only provided when it is non-zero.
  ///
  /// Provided for instance kinds:
  ///   String
  ///   List
  ///   Map
  ///   Uint8ClampedList
  ///   Uint8List
  ///   Uint16List
  ///   Uint32List
  ///   Uint64List
  ///   Int8List
  ///   Int16List
  ///   Int32List
  ///   Int64List
  ///   Float32List
  ///   Float64List
  ///   Int32x4List
  ///   Float32x4List
  ///   Float64x2List
  int? get offset;

  /// [optional] The number of elements or associations or codeunits returned.
  /// This is only provided when it is less than length.
  ///
  /// Provided for instance kinds:
  ///   String
  ///   List
  ///   Map
  ///   Uint8ClampedList
  ///   Uint8List
  ///   Uint16List
  ///   Uint32List
  ///   Uint64List
  ///   Int8List
  ///   Int16List
  ///   Int32List
  ///   Int64List
  ///   Float32List
  ///   Float64List
  ///   Int32x4List
  ///   Float32x4List
  ///   Float64x2List
  int? get count;

  /// [optional] The elements of a TypedData instance.
  ///
  /// Provided for instance kinds:
  ///   Uint8ClampedList
  ///   Uint8List
  ///   Uint16List
  ///   Uint32List
  ///   Uint64List
  ///   Int8List
  ///   Int16List
  ///   Int32List
  ///   Int64List
  ///   Float32List
  ///   Float64List
  ///   Int32x4List
  ///   Float32x4List
  ///   Float64x2List
  List<dynamic>? get typedElements;

  /// [optional] The native fields of this Instance.
  Iterable<NativeField>? get nativeFields;

  /// [optional] The fields of this Instance.
  Iterable<BoundField>? get fields;

  /// [optional] The elements of a List instance.
  ///
  /// Provided for instance kinds:
  ///   List
  Iterable<Guarded<ObjectRef>>? get elements;
  // It should be:
  // Iterable<Guarded<InstanceRef>> get elements;
  // In some situations we obtain lists of non Instances

  /// [optional] The elements of a Map instance.
  ///
  /// Provided for instance kinds:
  ///   Map
  Iterable<MapAssociation>? get associations;

  /// [optional] The key for a WeakProperty instance.
  ///
  /// Provided for instance kinds:
  ///   WeakProperty
  InstanceRef? get key;

  /// [optional] The key for a WeakProperty instance.
  ///
  /// Provided for instance kinds:
  ///   WeakProperty
  InstanceRef? get value;

  /// [optional] The referent of a MirrorReference instance.
  ///
  /// Provided for instance kinds:
  ///   MirrorReference
  ObjectRef? get referent;

  /// [optional] The type arguments for this type.
  ///
  /// Provided for instance kinds:
  ///   Type
  TypeArgumentsRef? get typeArguments;

  /// [optional] The index of a TypeParameter instance.
  ///
  /// Provided for instance kinds:
  ///   TypeParameter
  int? get parameterIndex;

  /// [optional] The referent of a TypeRef instance.
  ///
  /// The value will always be of one of the kinds:
  /// Type, TypeRef, TypeParameter.
  ///
  /// Provided for instance kinds:
  ///   TypeRef
  InstanceRef? get targetType;

  /// [optional] The bound of a TypeParameter.
  ///
  /// The value will always be of one of the kinds:
  /// Type, TypeRef, TypeParameter.
  ///
  /// Provided for instance kinds:
  ///   TypeParameter
  InstanceRef? get bound;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   Closure
  Breakpoint? get activationBreakpoint;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  bool? get isCaseSensitive;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  bool? get isMultiLine;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  FunctionRef? get oneByteFunction;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  FunctionRef? get twoByteFunction;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  FunctionRef? get externalOneByteFunction;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  FunctionRef? get externalTwoByteFunction;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  InstanceRef? get oneByteBytecode;

  /// [optional]
  ///
  /// Provided for instance kinds:
  ///   RegExp
  InstanceRef? get twoByteBytecode;
}

abstract class BoundField {
  FieldRef? get decl;
  Guarded<InstanceRef>? get value;
}

abstract class NativeField {
  int get value;
}
