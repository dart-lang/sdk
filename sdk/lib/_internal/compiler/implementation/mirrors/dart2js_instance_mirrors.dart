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
    Dart2JsMirrorSystem mirrorSystem,
    ConstantExpression constant,
    ConstantValue value) {

  if (value.isBool) {
    return new Dart2JsBoolConstantMirror(mirrorSystem, constant, value);
  } else if (value.isNum) {
    return new Dart2JsNumConstantMirror(mirrorSystem, constant, value);
  } else if (value.isString) {
    return new Dart2JsStringConstantMirror(mirrorSystem, constant, value);
  } else if (value.isList) {
    return new Dart2JsListConstantMirror(mirrorSystem, constant, value);
  } else if (value.isMap) {
    return new Dart2JsMapConstantMirror(mirrorSystem, constant, value);
  } else if (value.isType) {
    return new Dart2JsTypeConstantMirror(mirrorSystem, constant, value);
  } else if (value.isFunction) {
    return new Dart2JsConstantMirror(mirrorSystem, constant, value);
  } else if (value.isNull) {
    return new Dart2JsNullConstantMirror(mirrorSystem, constant, value);
  } else if (value.isConstructedObject) {
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
  final ConstantExpression _constant;
  final ConstantValue _value;

  Dart2JsConstantMirror(this.mirrorSystem, this._constant, this._value);

  String toString() {
    if (_constant != null) {
      return _constant.getText();
    } else {
      return _value.unparse();
    }
  }

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
                            ConstantExpression constant,
                            NullConstantValue value)
      : super(mirrorSystem, constant, value);

  NullConstantValue get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => null;
}

class Dart2JsBoolConstantMirror extends Dart2JsConstantMirror {
  Dart2JsBoolConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            ConstantExpression constant,
                            BoolConstantValue value)
      : super(mirrorSystem, constant, value);

  Dart2JsBoolConstantMirror.fromBool(Dart2JsMirrorSystem mirrorSystem,
                                     bool value)
      : super(mirrorSystem, null,
              value ? new TrueConstantValue() : new FalseConstantValue());

  BoolConstantValue get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => _value is TrueConstantValue;
}

class Dart2JsStringConstantMirror extends Dart2JsConstantMirror {
  Dart2JsStringConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                              ConstantExpression constant,
                              StringConstantValue value)
      : super(mirrorSystem, constant, value);

  Dart2JsStringConstantMirror.fromString(Dart2JsMirrorSystem mirrorSystem,
                                         String text)
      : super(mirrorSystem, null,
              new StringConstantValue(new DartString.literal(text)));

  StringConstantValue get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => _value.primitiveValue.slowToString();
}

class Dart2JsNumConstantMirror extends Dart2JsConstantMirror {
  Dart2JsNumConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                           ConstantExpression constant,
                           NumConstantValue value)
      : super(mirrorSystem, constant, value);

  NumConstantValue get _value => super._value;

  bool get hasReflectee => true;

  get reflectee => _value.primitiveValue;
}

class Dart2JsListConstantMirror extends Dart2JsConstantMirror
    implements ListInstanceMirror {
  Dart2JsListConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            ConstantExpression constant,
                            ListConstantValue value)
      : super(mirrorSystem, constant, value);

  ListConstantValue get _value => super._value;

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
                           ConstantExpression constant,
                           MapConstantValue value)
      : super(mirrorSystem, constant, value);

  MapConstantValue get _value => super._value;

  List<String> get _list {
    if (_listCache == null) {
      _listCache = new List<String>(_value.length);
      int index = 0;
      for (StringConstantValue keyConstant in _value.keys) {
        _listCache[index] = keyConstant.primitiveValue.slowToString();
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
                            ConstantExpression constant,
                            TypeConstantValue value)
      : super(mirrorSystem, constant, value);

  TypeConstantValue get _value => super._value;

  TypeMirror get representedType =>
      mirrorSystem._convertTypeToTypeMirror(_value.representedType);
}

class Dart2JsConstructedConstantMirror extends Dart2JsConstantMirror {
  Map<String,ConstantValue> _fieldMapCache;

  Dart2JsConstructedConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                                   ConstantExpression constant,
                                   ConstructedConstantValue value)
      : super(mirrorSystem, constant, value);

  ConstructedConstantValue get _value => super._value;

  Map<String,ConstantValue> get _fieldMap {
    if (_fieldMapCache == null) {
      _fieldMapCache = new Map<String,ConstantValue>();
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
    ConstantValue fieldConstant = _fieldMap[name];
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
