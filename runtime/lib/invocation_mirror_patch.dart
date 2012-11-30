// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _InvocationMirror implements InvocationMirror {
  static final int METHOD = 0;
  static final int GETTER = 1;
  static final int SETTER = 2;

  final String memberName;
  final List positionalArguments;
  final Map<String,dynamic> namedArguments = null;

  final int _type;

  _InvocationMirror(this.memberName, this._type, this.positionalArguments);

  static _allocateInvocationMirror(name, arguments) {
    return new _InvocationMirror(name, METHOD, arguments);
  }

  bool get isMethod => _type == METHOD;
  bool get isAccessor => _type != METHOD;
  bool get isGetter => _type == GETTER;
  bool get isSetter => _type == SETTER;

  invokeOn(Object receiver) {
    throw new UnsupportedError("invokeOn not implemented yet");
  }
}

