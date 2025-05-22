// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

abstract class EditorRepository {
  bool get isAvailable;

  Future openClass(IsolateRef isolate, ClassRef clazz);
  Future openField(IsolateRef isolate, FieldRef clazz);
  Future openFunction(IsolateRef isolate, FunctionRef clazz);
  Future openObject(IsolateRef isolate, ObjectRef clazz);
  Future openSourceLocation(IsolateRef isolate, SourceLocation location);
}
