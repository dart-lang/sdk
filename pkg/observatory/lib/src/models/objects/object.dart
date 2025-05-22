// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class ObjectRef {
  /// A unique identifier for an Object.
  String? get id;
}

abstract class Object implements ObjectRef {
  /// [optional] If an object is allocated in the Dart heap, it will have
  /// a corresponding class object.
  ///
  /// The class of a non-instance is not a Dart class, but is instead
  /// an internal vm object.
  ///
  /// Moving an Object into or out of the heap is considered a
  /// backwards compatible change for types other than Instance.
  ClassRef? get clazz;

  /// [optional] The size of this object in the heap.
  ///
  /// If an object is not heap-allocated, then this field is omitted.
  ///
  /// Note that the size can be zero for some objects. In the current
  /// VM implementation, this occurs for small integers, which are
  /// stored entirely within their object pointers.
  int? get size;

  String? get vmName;
}

abstract class RetainingObject {
  int get retainedSize;
  ObjectRef get object;
}
