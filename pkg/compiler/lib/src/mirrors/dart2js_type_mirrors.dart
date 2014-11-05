// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.mirrors;

abstract class ClassMirrorMixin implements ClassSourceMirror {
  bool get hasReflectedType => false;
  Type get reflectedType {
    throw new UnsupportedError("ClassMirror.reflectedType is not supported.");
  }
  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol, dynamic> namedArguments]) {
    throw new UnsupportedError("ClassMirror.newInstance is not supported.");
  }
}

abstract class Dart2JsTypeMirror
    implements Dart2JsDeclarationMirror, TypeSourceMirror {
  DartType get _type;

  String get _simpleNameString => _type.name;

  Dart2JsDeclarationMirror get owner => library;

  Dart2JsLibraryMirror get library;

  bool get hasReflectedType => throw new UnimplementedError();

  Type get reflectedType => throw new UnimplementedError();

  bool get isOriginalDeclaration => true;

  TypeMirror get originalDeclaration => this;

  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  List<TypeVariableMirror> get typeVariables => const <TypeVariableMirror>[];

  TypeMirror createInstantiation(List<TypeMirror> typeArguments) {
    if (typeArguments.isEmpty) return this;
    throw new ArgumentError('Cannot create generic instantiation of $_type.');
  }

  bool get isVoid => false;

  bool get isDynamic => false;

  bool isSubtypeOf(TypeMirror other) {
    if (other is Dart2JsTypeMirror) {
      return mirrorSystem.compiler.types.isSubtype(this._type, other._type);
    } else {
      throw new ArgumentError(other);
    }
  }

  bool isAssignableTo(TypeMirror other) {
    if (other is Dart2JsTypeMirror) {
      return mirrorSystem.compiler.types.isAssignable(this._type, other._type);
    } else {
      throw new ArgumentError(other);
    }
  }

  String toString() => _type.toString();

}

/// Base implementations for mirrors on element based types.
abstract class Dart2JsTypeElementMirror
    extends Dart2JsElementMirror
    with Dart2JsTypeMirror
    implements TypeSourceMirror {
  final DartType _type;

  Dart2JsTypeElementMirror(Dart2JsMirrorSystem system, DartType type)
    : super(system, type.element),
      this._type = type;

  Dart2JsLibraryMirror get library {
    return mirrorSystem._getLibrary(_type.element.library);
  }
}

abstract class DeclarationMixin implements TypeMirror {

  bool get isOriginalDeclaration => true;

  TypeMirror get originalDeclaration => this;

  List<TypeMirror> get typeArguments => const <TypeMirror>[];
}

abstract class Dart2JsGenericTypeMirror extends Dart2JsTypeElementMirror {
  List<TypeMirror> _typeArguments;
  List<TypeVariableMirror> _typeVariables;

  Dart2JsGenericTypeMirror(Dart2JsMirrorSystem system, GenericType type)
      : super(system, type);

  TypeDeclarationElement get _element => super._element;

  GenericType get _type => super._type;

  bool get isOriginalDeclaration => false;

  TypeMirror get originalDeclaration =>
      mirrorSystem._getTypeDeclarationMirror(_element);

  List<TypeMirror> get typeArguments {
    if (_typeArguments == null) {
      _typeArguments = <TypeMirror>[];
      if (!_type.isRaw) {
        for (DartType type in _type.typeArguments) {
          _typeArguments.add(_getTypeMirror(type));
        }
      }
    }
    return _typeArguments;
  }

  List<TypeVariableMirror> get typeVariables {
    if (_typeVariables == null) {
      _typeVariables = <TypeVariableMirror>[];
      for (TypeVariableType typeVariable in _element.typeVariables) {
        _typeVariables.add(
            new Dart2JsTypeVariableMirror(mirrorSystem, typeVariable));
      }
    }
    return _typeVariables;
  }

  Iterable<Dart2JsMemberMirror> _getDeclarationMirrors(Element element) {
    if (element.isTypeVariable) {
      assert(invariant(_element, _element == element.enclosingElement,
          message: 'Foreigned type variable element $element.'));
      for (Dart2JsTypeVariableMirror mirror in typeVariables) {
        if (mirror._element == element) return [mirror];
      }
    }
    return super._getDeclarationMirrors(element);
  }

  TypeMirror _getTypeMirror(DartType type) {
    return super._getTypeMirror(
        type.subst(_type.typeArguments, _type.element.typeVariables));
  }

  TypeSourceMirror createInstantiation(
      List<TypeSourceMirror> newTypeArguments) {
    if (newTypeArguments.isEmpty) return owner._getTypeMirror(_type.asRaw());
    if (newTypeArguments.length != typeVariables.length) {
      throw new ArgumentError('Cannot create generic instantiation of $_type '
                              'with ${newTypeArguments.length} arguments, '
                              'expect ${typeVariables.length} arguments.');
    }
    List<DartType> builder = <DartType>[];
    for (TypeSourceMirror newTypeArgument in newTypeArguments) {
      if (newTypeArgument.isVoid) {
        throw new ArgumentError('Cannot use void as type argument.');
      }
      if (newTypeArgument is Dart2JsTypeMirror) {
        builder.add(newTypeArgument._type);
      } else {
        throw new UnsupportedError(
            'Cannot create instantiation using a type '
            'mirror from a different mirrorSystem implementation.');
      }
    }
    return owner._getTypeMirror(_type.createInstantiation(builder));
  }
}

class Dart2JsInterfaceTypeMirror
    extends Dart2JsGenericTypeMirror
    with ObjectMirrorMixin, ClassMirrorMixin, ContainerMixin
    implements ClassMirror {
  Dart2JsInterfaceTypeMirror(Dart2JsMirrorSystem system,
                             InterfaceType interfaceType)
      : super(system, interfaceType);

  ClassElement get _element => super._element;

  InterfaceType get _type => super._type;

  bool get isNameSynthetic  {
    if (_element.isMixinApplication) {
      MixinApplicationElement mixinApplication = _element;
      return mixinApplication.isUnnamedMixinApplication;
    }
    return false;
  }

  void _forEachElement(f(Element element)) {
    _element.forEachMember((_, element) => f(element));
  }

  ClassMirror get superclass {
    if (_element.supertype != null) {
      return _getTypeMirror(_element.supertype);
    }
    return null;
  }

  bool isSubclassOf(Mirror other) {
    if (other is Dart2JsTypeMirror) {
      return other._type.element != null &&
             _element.isSubclassOf(other._type.element);
    } else {
      throw new ArgumentError(other);
    }
  }

  ClassMirror get mixin {
    if (_element.isMixinApplication) {
      MixinApplicationElement mixinApplication = _element;
      return _getTypeMirror(mixinApplication.mixinType);
    }
    return this;
  }

  List<ClassMirror> get superinterfaces {
    var list = <ClassMirror>[];
    Link<DartType> link = _element.interfaces;
    while (!link.isEmpty) {
      var type = _getTypeMirror(link.head);
      list.add(type);
      link = link.tail;
    }
    return list;
  }

  Map<Symbol, MethodMirror> get instanceMembers => null;
  Map<Symbol, MethodMirror> get staticMembers => null;

  bool get isAbstract => _element.isAbstract;

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ClassMirror) {
      return false;
    }
    return _type == other._type;
  }

  String toString() => 'Mirror on interface type $_type';
}

class Dart2JsClassDeclarationMirror
    extends Dart2JsInterfaceTypeMirror
    with DeclarationMixin {

  Dart2JsClassDeclarationMirror(Dart2JsMirrorSystem system,
                                InterfaceType type)
      : super(system, type);

  bool isSubclassOf(ClassMirror other) {
    if (other is Dart2JsClassDeclarationMirror) {
      Dart2JsClassDeclarationMirror otherDeclaration =
          other.originalDeclaration;
      return _element.isSubclassOf(otherDeclaration._element);
    } else if (other is FunctionTypeMirror) {
      return false;
    }
    throw new ArgumentError(other);
  }

  String toString() => 'Mirror on class ${_type.name}';
}

class Dart2JsTypedefMirror
    extends Dart2JsGenericTypeMirror
    implements TypedefMirror {
  final Dart2JsLibraryMirror _library;
  List<TypeVariableMirror> _typeVariables;
  var _definition;

  Dart2JsTypedefMirror(Dart2JsMirrorSystem system, TypedefType _typedef)
      : this._library = system._getLibrary(_typedef.element.library),
        super(system, _typedef);

  Dart2JsTypedefMirror.fromLibrary(Dart2JsLibraryMirror library,
                                   TypedefType _typedef)
      : this._library = library,
        super(library.mirrorSystem, _typedef);

  TypedefType get _typedef => _type;

  LibraryMirror get library => _library;

  bool get isTypedef => true;

  FunctionTypeMirror get referent {
    if (_definition == null) {
      _definition = _getTypeMirror(_typedef.element.alias);
    }
    return _definition;
  }

  bool get isClass => false;

  bool get isAbstract => false;

  String toString() => 'Mirror on typedef $_type';
}

class Dart2JsTypedefDeclarationMirror
    extends Dart2JsTypedefMirror
    with DeclarationMixin {
  Dart2JsTypedefDeclarationMirror(Dart2JsMirrorSystem system,
                                  TypedefType type)
      : super(system, type);

  String toString() => 'Mirror on typedef ${_type.name}';
}

class Dart2JsTypeVariableMirror extends Dart2JsTypeElementMirror
    implements TypeVariableMirror {
  Dart2JsDeclarationMirror _owner;

  Dart2JsTypeVariableMirror(Dart2JsMirrorSystem system,
                            TypeVariableType typeVariableType)
    : super(system, typeVariableType);

  TypeVariableType get _type => super._type;

  Dart2JsDeclarationMirror get owner {
    if (_owner == null) {
      _owner = mirrorSystem._getTypeDeclarationMirror(
          _type.element.typeDeclaration);
    }
    return _owner;
  }

  bool get isStatic => false;

  TypeMirror get upperBound => owner._getTypeMirror(_type.element.bound);

  bool operator ==(var other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TypeVariableMirror) {
      return false;
    }
    if (owner != other.owner) {
      return false;
    }
    return qualifiedName == other.qualifiedName;
  }

  String toString() => 'Mirror on type variable $_type';
}

class Dart2JsFunctionTypeMirror extends Dart2JsTypeElementMirror
    with ObjectMirrorMixin, ClassMirrorMixin, DeclarationMixin
    implements FunctionTypeMirror {
  List<ParameterMirror> _parameters;

  Dart2JsFunctionTypeMirror(Dart2JsMirrorSystem system,
                            FunctionType functionType)
      : super(system, functionType) {
    assert (functionType.element != null);
  }

  FunctionType get _type => super._type;

  // TODO(johnniwinther): Is this the qualified name of a function type?
  Symbol get qualifiedName => originalDeclaration.qualifiedName;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Symbol, DeclarationMirror> get declarations {
    var method = callMethod;
    if (method != null) {
      var map = new Map<Symbol, DeclarationMirror>.from(
          originalDeclaration.declarations);
      var name = method.qualifiedName;
      assert(!map.containsKey(name));
      map[name] = method;
      return new UnmodifiableMapView<Symbol, DeclarationMirror>(map);
    }
    return originalDeclaration.declarations;
  }

  bool get isFunction => true;

  MethodMirror get callMethod => _convertElementMethodToMethodMirror(
      mirrorSystem._getLibrary(_type.element.library),
      _type.element);

  ClassMirror get originalDeclaration =>
      mirrorSystem._getTypeDeclarationMirror(
          mirrorSystem.compiler.functionClass);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  ClassMirror get superclass => originalDeclaration.superclass;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  List<ClassMirror> get superinterfaces => originalDeclaration.superinterfaces;

  Map<Symbol, MethodMirror> get instanceMembers => null;
  Map<Symbol, MethodMirror> get staticMembers => null;

  ClassMirror get mixin => this;

  bool get isPrivate => false;

  bool get isAbstract => false;

  List<TypeVariableMirror> get typeVariables =>
      originalDeclaration.typeVariables;

  TypeMirror get returnType => owner._getTypeMirror(_type.returnType);

  List<ParameterMirror> get parameters {
    if (_parameters == null) {
      _parameters = _parametersFromFunctionSignature(
          owner, _type.element.functionSignature);
    }
    return _parameters;
  }

  String toString() => 'Mirror on function type $_type';

  bool isSubclassOf(ClassMirror other) => false;
}

/// Common superclass for mirrors on `dynamic` and `void`.
abstract class Dart2JsBuiltinTypeMirror extends Dart2JsDeclarationMirror
    with Dart2JsTypeMirror
    implements TypeSourceMirror {
  final Dart2JsMirrorSystem mirrorSystem;
  final DartType _type;

  Dart2JsBuiltinTypeMirror(Dart2JsMirrorSystem this.mirrorSystem,
                           DartType this._type);

  Symbol get qualifiedName => simpleName;

  /**
   * The builtin types have has no location.
   */
  SourceLocation get location => null;

  /**
   * The builtin types have has no owner.
   */
  Dart2JsDeclarationMirror get owner => null;

  /**
   * The builtin types have no library.
   */
  Dart2JsLibraryMirror get library => null;

  /**
   * The builtin types have no metadata.
   */
  List<InstanceMirror> get metadata => const <InstanceMirror>[];
}

class Dart2JsVoidMirror extends Dart2JsBuiltinTypeMirror {
  Dart2JsVoidMirror(Dart2JsMirrorSystem mirrorSystem, VoidType type)
      : super(mirrorSystem, type);

  bool get isVoid => true;

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TypeMirror) {
      return false;
    }
    return other.isVoid;
  }

  int get hashCode => 13 * _type.hashCode;

  String toString() => 'Mirror on void';
}

class Dart2JsDynamicMirror extends Dart2JsBuiltinTypeMirror {
  Dart2JsDynamicMirror(Dart2JsMirrorSystem mirrorSystem, DynamicType type)
      : super(mirrorSystem, type);

  bool get isDynamic => true;

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TypeMirror) {
      return false;
    }
    return other.isDynamic;
  }

  int get hashCode => 13 * _type.hashCode;

  String toString() => 'Mirror on dynamic';
}
