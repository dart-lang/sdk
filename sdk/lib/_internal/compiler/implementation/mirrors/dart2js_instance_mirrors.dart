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
    Dart2JsMirrorSystem mirrorSystem, Constant constant) {
  if (constant is BoolConstant) {
    return new Dart2JsBoolConstantMirror(mirrorSystem, constant);
  } else if (constant is NumConstant) {
    return new Dart2JsNumConstantMirror(mirrorSystem, constant);
  } else if (constant is StringConstant) {
    return new Dart2JsStringConstantMirror(mirrorSystem, constant);
  } else if (constant is ListConstant) {
    return new Dart2JsListConstantMirror(mirrorSystem, constant);
  } else if (constant is MapConstant) {
    return new Dart2JsMapConstantMirror(mirrorSystem, constant);
  } else if (constant is TypeConstant) {
    return new Dart2JsTypeConstantMirror(mirrorSystem, constant);
  } else if (constant is FunctionConstant) {
    return new Dart2JsConstantMirror(mirrorSystem, constant);
  } else if (constant is NullConstant) {
    return new Dart2JsNullConstantMirror(mirrorSystem, constant);
  } else if (constant is ConstructedConstant) {
    return new Dart2JsConstructedConstantMirror(mirrorSystem, constant);
  }
  mirrorSystem.compiler.internalError(NO_LOCATION_SPANNABLE,
      "Unexpected constant $constant");
  return null;
}


////////////////////////////////////////////////////////////////////////////////
// Mirrors on constant values used for metadata.
////////////////////////////////////////////////////////////////////////////////

class Dart2JsConstantMirror extends Object
    with ObjectMirrorMixin, InstanceMirrorMixin {
  final Dart2JsMirrorSystem mirrorSystem;
  final Constant _constant;

  Dart2JsConstantMirror(this.mirrorSystem, this._constant);

  // TODO(johnniwinther): Improve the quality of this method.
  String toString() => '$_constant';

  ClassMirror get type {
    return mirrorSystem._getTypeDeclarationMirror(
        _constant.computeType(mirrorSystem.compiler).element);
  }

  int get hashCode => 13 * _constant.hashCode;

  bool operator ==(var other) {
    if (other is! Dart2JsConstantMirror) return false;
    return _constant == other._constant;
  }
}

class Dart2JsNullConstantMirror extends Dart2JsConstantMirror {
  Dart2JsNullConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            NullConstant constant)
      : super(mirrorSystem, constant);

  NullConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => null;
}

class Dart2JsBoolConstantMirror extends Dart2JsConstantMirror {
  Dart2JsBoolConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            BoolConstant constant)
      : super(mirrorSystem, constant);

  Dart2JsBoolConstantMirror.fromBool(Dart2JsMirrorSystem mirrorSystem,
                                     bool value)
      : super(mirrorSystem, value ? new TrueConstant() : new FalseConstant());

  BoolConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => _constant is TrueConstant;
}

class Dart2JsStringConstantMirror extends Dart2JsConstantMirror {
  Dart2JsStringConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                              StringConstant constant)
      : super(mirrorSystem, constant);

  Dart2JsStringConstantMirror.fromString(Dart2JsMirrorSystem mirrorSystem,
                                         String text)
      : super(mirrorSystem, new StringConstant(new DartString.literal(text)));

  StringConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => _constant.value.slowToString();
}

class Dart2JsNumConstantMirror extends Dart2JsConstantMirror {
  Dart2JsNumConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                           NumConstant constant)
      : super(mirrorSystem, constant);

  NumConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => _constant.value;
}

class Dart2JsListConstantMirror extends Dart2JsConstantMirror
    implements ListInstanceMirror {
  Dart2JsListConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            ListConstant constant)
      : super(mirrorSystem, constant);

  ListConstant get _constant => super._constant;

  int get length => _constant.length;

  InstanceMirror getElement(int index) {
    if (index < 0) throw new RangeError('Negative index');
    if (index >= _constant.length) throw new RangeError('Index out of bounds');
    return _convertConstantToInstanceMirror(mirrorSystem,
                                            _constant.entries[index]);
  }
}

class Dart2JsMapConstantMirror extends Dart2JsConstantMirror
    implements MapInstanceMirror {
  List<String> _listCache;

  Dart2JsMapConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                           MapConstant constant)
      : super(mirrorSystem, constant);

  MapConstant get _constant => super._constant;

  List<String> get _list {
    if (_listCache == null) {
      _listCache = new List<String>(_constant.keys.entries.length);
      int index = 0;
      for (StringConstant keyConstant in _constant.keys.entries) {
        _listCache[index] = keyConstant.value.slowToString();
        index++;
      }
      _listCache = new UnmodifiableListView<String>(_listCache);
    }
    return _listCache;
  }

  int get length => _constant.length;

  Iterable<String> get keys {
    return _list;
  }

  InstanceMirror getValue(String key) {
    int index = _list.indexOf(key);
    if (index == -1) return null;
    return _convertConstantToInstanceMirror(mirrorSystem,
                                            _constant.values[index]);
  }
}

class Dart2JsTypeConstantMirror extends Dart2JsConstantMirror
    implements TypeInstanceMirror {

  Dart2JsTypeConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                            TypeConstant constant)
      : super(mirrorSystem, constant);

  TypeConstant get _constant => super._constant;

  TypeMirror get representedType =>
      mirrorSystem._convertTypeToTypeMirror(_constant.representedType);
}

class Dart2JsConstructedConstantMirror extends Dart2JsConstantMirror {
  Map<String,Constant> _fieldMapCache;

  Dart2JsConstructedConstantMirror(Dart2JsMirrorSystem mirrorSystem,
                                   ConstructedConstant constant)
      : super(mirrorSystem, constant);

  ConstructedConstant get _constant => super._constant;

  Map<String,Constant> get _fieldMap {
    if (_fieldMapCache == null) {
      _fieldMapCache = new Map<String,Constant>();
      if (identical(_constant.type.element.kind, ElementKind.CLASS)) {
        var index = 0;
        ClassElement element = _constant.type.element;
        element.forEachInstanceField((_, Element field) {
          String fieldName = field.name;
          _fieldMapCache.putIfAbsent(fieldName, () => _constant.fields[index]);
          index++;
        }, includeSuperAndInjectedMembers: true);
      }
    }
    return _fieldMapCache;
  }

  InstanceMirror getField(Symbol fieldName) {
    Constant fieldConstant = _fieldMap[MirrorSystem.getName(fieldName)];
    if (fieldConstant != null) {
      return _convertConstantToInstanceMirror(mirrorSystem, fieldConstant);
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
