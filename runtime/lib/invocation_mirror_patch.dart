// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _InvocationMirror implements InvocationMirror {
  static final int METHOD = 0;
  static final int GETTER = 1;
  static final int SETTER = 2;

  // TODO(regis): Compute lazily the value of these fields, and save the
  // arguments passed into _allocateInvocationMirror.

  final String memberName;
  final List positionalArguments;
  final Map<String, dynamic> namedArguments;

  final int _type;

  _InvocationMirror(this.memberName,
                    this._type,
                    this.positionalArguments,
                    this.namedArguments);

  static _allocateInvocationMirror(String name,
                                   List argumentsDescriptor,
                                   List arguments) {
    var memberName;
    var type;
    if (name.startsWith("get:")) {
      type = GETTER;
      memberName = name.substring(4);
    } else if (name.startsWith("set:")) {
      type = SETTER;
      memberName = name.substring(4).concat("=");
    } else {
      type = METHOD;
      memberName = name;
    }
    // Exclude receiver.
    int numArguments = argumentsDescriptor[0] - 1;
    int numPositionalArguments = argumentsDescriptor[1] - 1;
    int numNamedArguments = numArguments - numPositionalArguments;
    List positionalArguments = arguments.getRange(1, numPositionalArguments);
    Map<String, dynamic> namedArguments;
    if (numNamedArguments > 0) {
      namedArguments = new Map<String, dynamic>();
      for (int i = 0; i < numNamedArguments; i++) {
        String arg_name = argumentsDescriptor[2 + 2*i];
        var arg_value = arguments[argumentsDescriptor[3 + 2*i]];
        namedArguments[arg_name] = arg_value;
      }
    }
    return new _InvocationMirror(memberName, type,
                                 positionalArguments, namedArguments);
  }

  bool get isMethod => _type == METHOD;
  bool get isAccessor => _type != METHOD;
  bool get isGetter => _type == GETTER;
  bool get isSetter => _type == SETTER;

  invokeOn(Object receiver) {
    throw new UnsupportedError("invokeOn not implemented yet");
  }
}

