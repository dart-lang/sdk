// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _InvocationMirror implements InvocationMirror {
  static final int METHOD = 0;
  static final int GETTER = 1;
  static final int SETTER = 2;

  final String methodName;
  final List positionalArguments;
  final Map<String,dynamic> namedArguments = null;

  final int _type;

  _InvocationMirror(this.methodName, this._type, this.positionalArguments);

  bool get isMethod => _type == METHOD;
  bool get isAccessor => _type != METHOD;
  bool get isGetter => _type == GETTER;
  bool get isSetter => _type == SETTER;

  invokeOn(Object receiver) {
    throw new UnsupportedOperation("invokeOn not implemented yet");
  }
}

