// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _InvocationMirror implements InvocationMirror {
  // Constants describing the invocation type.
  static final int _METHOD = 0;
  static final int _GETTER = 1;
  static final int _SETTER = 2;

  // Internal representation of the invocation mirror.
  final String _functionName;
  final List _argumentsDescriptor;
  final List _arguments;

  // External representation of the invocation mirror; populated on demand.
  String _memberName;
  int _type;
  List _positionalArguments;
  Map<String, dynamic> _namedArguments;

  void _setMemberNameAndType() {
    if (_functionName.startsWith("get:")) {
      _type = _GETTER;
      _memberName = _functionName.substring(4);
    } else if (_functionName.startsWith("set:")) {
      _type = _SETTER;
      _memberName = _functionName.substring(4).concat("=");
    } else {
      _type = _METHOD;
      _memberName = _functionName;
    }
  }

  String get memberName {
    if (_memberName == null) {
      _setMemberNameAndType();
    }
    return _memberName;
  }

  List get positionalArguments {
    if (_positionalArguments == null) {
      // Exclude receiver.
      int numPositionalArguments = _argumentsDescriptor[1] - 1;
      _positionalArguments = _arguments.getRange(1, numPositionalArguments);
    }
    return _positionalArguments;
  }

  Map<String, dynamic> get namedArguments {
    if (_namedArguments == null) {
      _namedArguments = new Map<String, dynamic>();
      int numArguments = _argumentsDescriptor[0] - 1;  // Exclude receiver.
      int numPositionalArguments = _argumentsDescriptor[1] - 1;
      int numNamedArguments = numArguments - numPositionalArguments;
      for (int i = 0; i < numNamedArguments; i++) {
        String arg_name = _argumentsDescriptor[2 + 2*i];
        var arg_value = _arguments[_argumentsDescriptor[3 + 2*i]];
        _namedArguments[arg_name] = arg_value;
      }
    }
    return _namedArguments;
  }

  bool get isMethod {
    if (_type == null) {
      _setMemberNameAndType();
    }
    return _type == _METHOD;
  }

  bool get isAccessor {
    if (_type == null) {
      _setMemberNameAndType();
    }
    return _type != _METHOD;
  }

  bool get isGetter {
    if (_type == null) {
      _setMemberNameAndType();
    }
    return _type == _GETTER;
  }

  bool get isSetter {
    if (_type == null) {
      _setMemberNameAndType();
    }
    return _type == _SETTER;
  }

  _InvocationMirror(this._functionName,
                    this._argumentsDescriptor,
                    this._arguments);

  static _allocateInvocationMirror(String functionName,
                                   List argumentsDescriptor,
                                   List arguments) {
    return new _InvocationMirror(functionName, argumentsDescriptor, arguments);
  }

  static _invoke(Object receiver,
                 String functionName,
                 List argumentsDescriptor,
                 List arguments)
      native "InvocationMirror_invoke";

  invokeOn(Object receiver) {
    return _invoke(receiver, _functionName, _argumentsDescriptor, _arguments);
  }
}

