// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.mirrors;

abstract class ObjectMirrorMixin implements ObjectMirror {
  InstanceMirror getField(Symbol fieldName) {
    throw new UnsupportedError('ObjectMirror.getField unsupported.');
  }

  InstanceMirror setField(Symbol fieldName, Object value) {
    throw new UnsupportedError('ObjectMirror.setField unsupported.');
  }

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol, dynamic> namedArguments]) {
    throw new UnsupportedError('ObjectMirror.invoke unsupported.');
  }
}

abstract class InstanceMirrorMixin implements InstanceMirror {
  bool get hasReflectee => false;

  get reflectee {
    throw new UnsupportedError('InstanceMirror.reflectee unsupported.');
  }

  delegate(Invocation invocation) {
    throw new UnsupportedError('InstanceMirror.delegate unsupported');
  }
}

InstanceMirror _convertConstantToInstanceMirror(
    Dart2JsMirrorSystem mirrorSystem, ConstExp constant, Constant value) {
  if (value is BoolConstant) {
    return new Dart2JsBoolConstantMirror(mirrorSystem, constant, value);
  } else if (value is NumConstant) {
    return new Dart2JsNumConstantMirror(mirrorSystem, constant, value);
  } else if (value is StringConstant) {
    return new Dart2JsStringConstantMirror(mirrorSystem, constant, value);
  } else if (value is ListConstant) {
    return new Dart2JsListConstantMirror(mirrorSystem, constant, value);
  } else if (value is MapConstant) {
    return new Dart2JsMapConstantMirror(mirrorSystem, constant, value);
  } else if (value is TypeConstant) {
    return new Dart2JsTypeConstantMirror(mirrorSystem, constant, value);
  } else if (value is FunctionConstant) {
    return new Dart2JsConstantMirror(mirrorSystem, constant, value);
  } else if (value is NullConstant) {
    return new Dart2JsNullConstantMirror(mirrorSystem, constant, value);
  } else if (value is ConstructedConstant) {
    return new Dart2JsConstructedConstantMirror(mirrorSystem, constant, value);
  }
  mirrorSystem.compiler.internalError(NO_LOCATION_SPANNABLE,
      "Unexpected constant value $value");
  return null;
}


////////////////////////////////////////////////////////////////////////////////
// Mirrors on constant values used for metadata.
////////////////////////////////////////////////////////////////////////////////

class Dart2JsConstantMirror extends Object
    with ObjectMirrorMixin, InstanceMirrorMixin {
  final Dart2JsMirrorSystem mirrorSystem;
  final ConstExp _constant;
  final Constant _value;

  Dart2JsConstantMirror(this.mirrorSystem, this._constant, this._value);

  String toString() => _constant != null ? '$_constant' : '$_value';

  ClassMirror get type {
    return mirrorSystem._getTypeDeclarationMirror(
        _value.computeType(mirrorSystem.compiler).element);
  }

  int get hashCode => 13 * _constant.hashCode;

  bool operator ==(var other) {
    if (other is! Dart2JsConstantMirror) return false;
    return _value == other._value;
  }
}

class Dart2JsNullConstantMirror extends Dart2JsConstantMirror {
  Dart2JsNullConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            ConstExp constant, NullConstant value)
      : super(mirrorSystem, constant, value);

  NullConstant get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => null;
}

class Dart2JsBoolConstantMirror extends Dart2JsConstantMirror {
  Dart2JsBoolConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            ConstExp constant,
                            BoolConstant value)
      : super(mirrorSystem, constant, value);

  Dart2JsBoolConstantMirror.fromBool(Dart2JsMirrorSystem mirrorSystem,
                                     bool value)
      : super(mirrorSystem, null,
              value ? new TrueConstant() : new FalseConstant());

  BoolConstant get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => _value is TrueConstant;
}

class Dart2JsStringConstantMirror extends Dart2JsConstantMirror {
  Dart2JsStringConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                              ConstExp constant,
                              StringConstant value)
      : super(mirrorSystem, constant, value);

  Dart2JsStringConstantMirror.fromString(Dart2JsMirrorSystem mirrorSystem,
                                         String text)
      : super(mirrorSystem, null,
              new StringConstant(new DartString.literal(text)));

  StringConstant get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => _value.value.slowToString();
}

class Dart2JsNumConstantMirror extends Dart2JsConstantMirror {
  Dart2JsNumConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                           ConstExp constant,
                           NumConstant value)
      : super(mirrorSystem, constant, value);

  NumConstant get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => _value.value;
}

class Dart2JsListConstantMirror extends Dart2JsConstantMirror
    implements ListInstanceMirror {
  Dart2JsListConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            ConstExp constant,
                            ListConstant value)
      : super(mirrorSystem, constant, value);

  ListConstant get _value => super._value;

  int get length => _value.length;

  InstanceMirror getElement(int index) {
    if (index < 0) throw new RangeError('Negative index');
    if (index >= _value.length) throw new RangeError('Index out of bounds');
    return _convertConstantToInstanceMirror(
        mirrorSystem, null, _value.entries[index]);
  }
}

class Dart2JsMapConstantMirror extends Dart2JsConstantMirror
    implements MapInstanceMirror {
  List<String> _listCache;

  Dart2JsMapConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                           ConstExp constant,
                           MapConstant value)
      : super(mirrorSystem, constant, value);

  MapConstant get _value => super._value;

  List<String> get _list {
    if (_listCache == null) {
      _listCache = new List<String>(_value.length);
      int index = 0;
      for (StringConstant keyConstant in _value.keys) {
        _listCache[index] = keyConstant.value.slowToString();
        index++;
      }
      _listCache = new UnmodifiableListView<String>(_listCache);
    }
    return _listCache;
  }

  int get length => _value.length;

  Iterable<String> get keys {
    return _list;
  }

  InstanceMirror getValue(String key) {
    int index = _list.indexOf(key);
    if (index == -1) return null;
    return _convertConstantToInstanceMirror(
        mirrorSystem, null, _value.values[index]);
  }
}

class Dart2JsTypeConstantMirror extends Dart2JsConstantMirror
    implements TypeInstanceMirror {

  Dart2JsTypeConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            ConstExp constant,
                            TypeConstant value)
      : super(mirrorSystem, constant, value);

  TypeConstant get _value => super._value;

  TypeMirror get representedType =>
      mirrorSystem._convertTypeToTypeMirror(_value.representedType);
}

class Dart2JsConstructedConstantMirror extends Dart2JsConstantMirror {
  Map<String,Constant> _fieldMapCache;

  Dart2JsConstructedConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                                   ConstExp constant,
                                   ConstructedConstant value)
      : super(mirrorSystem, constant, value);

  ConstructedConstant get _value => super._value;

  Map<String,Constant> get _fieldMap {
    if (_fieldMapCache == null) {
      _fieldMapCache = new Map<String,Constant>();
      if (identical(_value.type.element.kind, ElementKind.CLASS)) {
        var index = 0;
        ClassElement element = _value.type.element;
        element.forEachInstanceField((_, Element field) {
          String fieldName = field.name;
          _fieldMapCache.putIfAbsent(fieldName, () => _value.fields[index]);
          index++;
        }, includeSuperAndInjectedMembers: true);
      }
    }
    return _fieldMapCache;
  }

  InstanceMirror getField(Symbol fieldName) {
    String name = MirrorSystem.getName(fieldName);
    Constant fieldConstant = _fieldMap[name];
    if (fieldConstant != null) {
      return _convertConstantToInstanceMirror(
          mirrorSystem, null, fieldConstant);
    }
    return super.getField(fieldName);
  }
}

class Dart2JsCommentInstanceMirror extends Object
  with ObjectMirrorMixin, InstanceMirrorMixin
  implements CommentInstanceMirror {
  final Dart2JsMirrorSystem mirrorSystem;
  final String text;
  String _trimmedText;

  Dart2JsCommentInstanceMirror(this.mirrorSystem, this.text);

  ClassMirror get type {
    return mirrorSystem._getTypeDeclarationMirror(
        mirrorSystem.compiler.documentClass);
  }

  bool get isDocComment => text.startsWith('/**') || text.startsWith('///');

  String get trimmedText {
    if (_trimmedText == null) {
      _trimmedText = stripComment(text);
    }
    return _trimmedText;
  }

  InstanceMirror getField(Symbol fieldName) {
    if (fieldName == #isDocComment) {
      return new Dart2JsBoolConstantMirror.fromBool(mirrorSystem, isDocComment);
    } else if (fieldName == #text) {
      return new Dart2JsStringConstantMirror.fromString(mirrorSystem, text);
    } else if (fieldName == #trimmedText) {
      return new Dart2JsStringConstantMirror.fromString(mirrorSystem,
                                                        trimmedText);
    }
    return super.getField(fieldName);
  }
}
