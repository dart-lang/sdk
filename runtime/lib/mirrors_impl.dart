// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

// These values are allowed to be passed directly over the wire.
bool _isSimpleValue(var value) {
  return (value == null || value is num || value is String || value is bool);
}

Map _filterMap(Map old_map, bool filter(key, value)) {
  Map new_map = new Map();
  old_map.forEach((key, value) {
      if (filter(key, value)) {
        new_map[key] = value;
      }
    });
  return new_map;
}

String _makeSignatureString(TypeMirror returnType,
                            List<ParameterMirror> parameters) {
  StringBuffer buf = new StringBuffer();
  buf.add(returnType.qualifiedName);
  buf.add(' (');
  bool found_optional_param = false;
  for (int i = 0; i < parameters.length; i++) {
    var param = parameters[i];
    if (param.isOptional && !found_optional_param) {
      buf.add('[');
      found_optional_param = true;
    }
    buf.add(param.type.qualifiedName);
    if (i < (parameters.length - 1)) {
      buf.add(', ');
    }
  }
  if (found_optional_param) {
    buf.add(']');
  }
  buf.add(')');
  return buf.toString();
}

class _LocalMirrorSystemImpl implements MirrorSystem {
  _LocalMirrorSystemImpl(this.libraries, this.isolate)
      : _functionTypes = new Map<String, FunctionTypeMirror>() {}

  final Map<String, LibraryMirror> libraries;
  final IsolateMirror isolate;

  TypeMirror _dynamicType = null;

  TypeMirror get dynamicType {
    if (_dynamicType == null) {
      _dynamicType =
          new _LocalClassMirrorImpl(
              null, 'Dynamic', false, null, null, [], null,
              const {}, const {}, const {});
    }
    return _dynamicType;
  }

  TypeMirror _voidType = null;

  TypeMirror get voidType {
    if (_voidType == null) {
      _voidType =
          new _LocalClassMirrorImpl(
              null, 'void', false, null, null, [], null,
              const {}, const {}, const {});
    }
    return _voidType;
  }

  final Map<String, FunctionTypeMirror> _functionTypes;
  FunctionTypeMirror _lookupFunctionTypeMirror(
      TypeMirror returnType,
      List<ParameterMirror> parameters) {
    var sigString = _makeSignatureString(returnType, parameters);
    var mirror = _functionTypes[sigString];
    if (mirror == null) {
      mirror = new _LocalFunctionTypeMirrorImpl(null,
                                                sigString,
                                                returnType,
                                                parameters);
      _functionTypes[sigString] = mirror;
    }
    return mirror;
  }

  String toString() => "MirrorSystem for isolate '${isolate.debugName}'";
}

abstract class _LocalMirrorImpl implements Mirror {
  int get hashCode {
    throw new UnimplementedError('Mirror.hashCode is not implemented');
  }

  // Local mirrors always return the same MirrorSystem.  This field
  // is more interesting once we implement remote mirrors.
  MirrorSystem get mirrors => _Mirrors.currentMirrorSystem();
}

class _LocalIsolateMirrorImpl extends _LocalMirrorImpl
    implements IsolateMirror {
  _LocalIsolateMirrorImpl(this.debugName, this._rootLibrary) {}

  final String debugName;
  final bool isCurrent = true;

  var _rootLibrary;
  LibraryMirror get rootLibrary {
    if (_rootLibrary is _LazyLibraryMirror) {
      _rootLibrary = _rootLibrary.resolve(mirrors);
    }
    return _rootLibrary;
  }

  String toString() => "IsolateMirror on '$debugName'";
}

// A VMReference is used to hold a reference to a VM-internal object,
// which can include things like libraries, classes, etc.
class VMReference extends NativeFieldWrapperClass1 {
}

abstract class _LocalVMObjectMirrorImpl extends _LocalMirrorImpl {
  _LocalVMObjectMirrorImpl(this._reference) {}

  // For now, all VMObjects hold a VMReference.  We could consider
  // storing the Object reference itself here if the object is a Dart
  // language objects (except for objects of type VMReference, of
  // course).
  VMReference _reference;
}

abstract class _LocalObjectMirrorImpl extends _LocalVMObjectMirrorImpl
    implements ObjectMirror {
  _LocalObjectMirrorImpl(ref) : super(ref) {}

  Future<InstanceMirror> invoke(String memberName,
                                List positionalArguments,
                                [Map<String,Dynamic> namedArguments]) {
    if (namedArguments != null) {
      throw new UnimplementedError(
          'named argument support is not implemented');
    }
    // Walk the arguments and make sure they are legal.
    for (int i = 0; i < positionalArguments.length; i++) {
      var arg = positionalArguments[i];
      _validateArgument(i, arg);
    }
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(
          _invoke(this, memberName, positionalArguments));
    } catch (exception) {
      completer.completeException(exception);
    }
    return completer.future;
  }

  Future<InstanceMirror> getField(String fieldName)
  {
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(_getField(this, fieldName));
    } catch (exception) {
      completer.completeException(exception);
    }
    return completer.future;
  }

  Future<InstanceMirror> setField(String fieldName, Object arg)
  {
    _validateArgument(0, arg);

    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(_setField(this, fieldName, arg));
    } catch (exception) {
      completer.completeException(exception);
    }
    return completer.future;
  }

  static _validateArgument(int i, Object arg)
  {
    if (arg is Mirror) {
        if (arg is! InstanceMirror) {
          throw new MirrorException(
              'positional argument $i ($arg) was not an InstanceMirror');
        }
      } else if (!_isSimpleValue(arg)) {
        throw new MirrorException(
            'positional argument $i ($arg) was not a simple value');
      }
  }

  static _invoke(ref, memberName, positionalArguments)
      native 'LocalObjectMirrorImpl_invoke';

  static _getField(ref, fieldName)
      native 'LocalObjectMirrorImpl_getField';

  static _setField(ref, fieldName, value)
      native 'LocalObjectMirrorImpl_setField';
}

// Prints a string as it might appear in dart program text.
// TODO(turnidge): Consider truncating.
String _dartEscape(String str) {
  bool isNice(int code) => (code >= 32 && code <= 126);

  StringBuffer buf = new StringBuffer();
  for (int i = 0; i < str.length; i++) {
    var input = str[i];
    String output;
    switch (input) {
      case '\\' :
        output = r'\\';
        break;
      case "\'" :
        output = r"\'";
        break;
      case '\n' :
        output = r'\n';
        break;
      case '\r' :
        output = r'\r';
        break;
      case '\f' :
        output = r'\f';
        break;
      case '\b' :
        output = r'\b';
        break;
      case '\t' :
        output = r'\t';
        break;
      case '\v' :
        output = r'\v';
        break;
      default:
        int code = input.charCodeAt(0);
        if (isNice(code)) {
          output = input;
        } else {
          output = '\\u{${code.toRadixString(16)}}';
        }
        break;
    }
    buf.add(output);
  }
  return buf.toString();
}

class _LocalInstanceMirrorImpl extends _LocalObjectMirrorImpl
    implements InstanceMirror {
  _LocalInstanceMirrorImpl(ref,
                           this._type,
                           this._reflectee) : super(ref) {}

  var _type;
  ClassMirror get type {
    if (_type is! Mirror) {
      _type = _type.resolve(mirrors);
    }
    return _type;
  }

  // LocalInstanceMirrors always reflect local instances
  bool hasReflectee = true;

  var _reflectee;
  get reflectee => _reflectee;

  String toString() {
    if (_isSimpleValue(_reflectee)) {
      if (_reflectee is String) {
        return "InstanceMirror on <'${_dartEscape(_reflectee)}'>";
      } else {
        return "InstanceMirror on <$_reflectee>";
      }
    } else {
      return "InstanceMirror on instance of '${type.simpleName}'";
    }
  }
}

class _LocalClosureMirrorImpl extends _LocalInstanceMirrorImpl
    implements ClosureMirror {
  _LocalClosureMirrorImpl(ref,
                          type,
                          reflectee,
                          this.function) : super(ref, type, reflectee) {}

  final MethodMirror function;

  String get source {
    throw new UnimplementedError(
        'ClosureMirror.source is not implemented');
  }

  Future<InstanceMirror> apply(List<Object> positionalArguments,
                               [Map<String,Object> namedArguments]) {
    if (namedArguments != null) {
      throw new UnimplementedError(
          'named argument support is not implemented');
    }
    // Walk the arguments and make sure they are legal.
    for (int i = 0; i < positionalArguments.length; i++) {
      var arg = positionalArguments[i];
      _LocalObjectMirrorImpl._validateArgument(i, arg);
    }
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(
          _apply(this, positionalArguments));
    } catch (exception) {
      completer.completeException(exception);
    }
    return completer.future;
  }

  Future<InstanceMirror> findInContext(String name) {
    throw new UnimplementedError(
        'ClosureMirror.findInContext() is not implemented');
  }

  static _apply(ref, positionalArguments)
      native 'LocalClosureMirrorImpl_apply';
}

class _LazyTypeMirror {
  _LazyTypeMirror(this.libraryName, this.typeName) {}

  TypeMirror resolve(MirrorSystem mirrors) {
    if (libraryName == null) {
      // TODO(turnidge): Remove support for 'Dynamic'.
      if ((typeName == 'dynamic') || (typeName == 'Dynamic')) {
        return mirrors.dynamicType;
      } else if (typeName == 'void') {
        return mirrors.voidType;
      } else {
        throw new UnimplementedError(
            "Mirror for type '$typeName' is not implemented");
      }
    }
    var resolved = mirrors.libraries[libraryName].members[typeName];
    if (resolved == null) {
      throw new UnimplementedError(
          "Mirror for type '$typeName' is not implemented");
    }
    return resolved;
  }

  final String libraryName;
  final String typeName;
}

class _LocalClassMirrorImpl extends _LocalObjectMirrorImpl
    implements ClassMirror {
  _LocalClassMirrorImpl(ref,
                        this.simpleName,
                        this.isClass,
                        this._owner,
                        this._superclass,
                        this._superinterfaces,
                        this._defaultFactory,
                        this.members,
                        this.constructors,
                        this.typeVariables) : super(ref) {}

  final String simpleName;

  String _qualifiedName = null;
  String get qualifiedName {
    if (_owner != null) {
      if (_qualifiedName == null) {
        _qualifiedName = '${owner.qualifiedName}.${simpleName}';
      }
    } else {
      // The owner of a ClassMirror is null in certain odd cases, like
      // 'void', 'Dynamic' and function type mirrors.
      _qualifiedName = simpleName;
    }
    return _qualifiedName;
  }

  var _owner;
  DeclarationMirror get owner {
    if (_owner != null && _owner is! Mirror) {
      _owner = _owner.resolve(mirrors);
    }
    return _owner;
  }

  bool get isPrivate => simpleName.startsWith('_');

  final bool isTopLevel = true;

  SourceLocation get location {
    throw new UnimplementedError(
        'ClassMirror.location is not implemented');
  }

  final bool isClass;

  var _superclass;
  ClassMirror get superclass {
    if (_superclass is! Mirror) {
      _superclass = _superclass.resolve(mirrors);
    }
    return _superclass;
  }

  var _superinterfaces;
  List<ClassMirror> get superinterfaces {
    if (_superinterfaces.length > 0 &&
        _superinterfaces[0] is! Mirror) {
      List<ClassMirror> resolved = new List<ClassMirror>();
      for (int i = 0; i < _superinterfaces.length; i++) {
        resolved.add(_superinterfaces[i].resolve(mirrors));
      }
      _superinterfaces = resolved;
    }
    return _superinterfaces;
  }

  var _defaultFactory;
  ClassMirror get defaultFactory {
    if (_defaultFactory != null && _defaultFactory is! Mirror) {
      _defaultFactory = _defaultFactory.resolve(mirrors);
    }
    return _defaultFactory;
  }

  final Map<String, Mirror> members;

  Map<String, MethodMirror> _methods = null;
  Map<String, MethodMirror> _getters = null;
  Map<String, MethodMirror> _setters = null;
  Map<String, VariableMirror> _variables = null;

  Map<String, MethodMirror> get methods {
    if (_methods == null) {
      _methods = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isRegularMethod));
    }
    return _methods;
  }

  Map<String, MethodMirror> get getters {
    if (_getters == null) {
      _getters = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isGetter));
    }
    return _getters;
  }

  Map<String, MethodMirror> get setters {
    if (_setters == null) {
      _setters = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isSetter));
    }
    return _setters;
  }

  Map<String, VariableMirror> get variables {
    if (_variables == null) {
      _variables = _filterMap(
          members,
          (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  Map<String, MethodMirror> constructors;
  Map<String, TypeVariableMirror> typeVariables;

  Map<String, TypeMirror> get typeArguments {
    throw new UnimplementedError(
        'ClassMirror.typeArguments is not implemented');
  }

  bool get isOriginalDeclaration {
    throw new UnimplementedError(
        'ClassMirror.isOriginalDeclaration is not implemented');
  }

  ClassMirror get genericDeclaration {
    throw new UnimplementedError(
        'ClassMirror.originalDeclaration is not implemented');
  }

  String toString() => "ClassMirror on '$simpleName'";

  Future<InstanceMirror> newInstance(String constructorName,
                                     List positionalArguments,
                                     [Map<String,Dynamic> namedArguments]) {
    if (namedArguments != null) {
      throw new UnimplementedError(
          'named argument support is not implemented');
    }
    // Walk the arguments and make sure they are legal.
    for (int i = 0; i < positionalArguments.length; i++) {
      var arg = positionalArguments[i];
      _LocalObjectMirrorImpl._validateArgument(i, arg);
    }
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(
          _invokeConstructor(this, constructorName, positionalArguments));
    } catch (exception) {
      completer.completeException(exception);
    }
    return completer.future;
  }

  static _invokeConstructor(ref, constructorName, positionalArguments)
      native 'LocalClassMirrorImpl_invokeConstructor';
}

class _LazyFunctionTypeMirror {
  _LazyFunctionTypeMirror(this.returnType, this.parameters) {}

  ClassMirror resolve(MirrorSystem mirrors) {
    return mirrors._lookupFunctionTypeMirror(returnType.resolve(mirrors),
                                             parameters);
  }

  final returnType;
  final List<ParameterMirror> parameters;
}

class _LocalFunctionTypeMirrorImpl extends _LocalClassMirrorImpl
    implements FunctionTypeMirror {
  _LocalFunctionTypeMirrorImpl(ref,
                               simpleName,
                               this._returnType,
                               this.parameters)
      : super(ref,
              simpleName,
              true,
              null,
              new _LazyTypeMirror('dart:core', 'Object'),
              [ new _LazyTypeMirror('dart:core', 'Function') ],
              null,
              const {},
              const {},
              const {});

  var _returnType;
  TypeMirror get returnType {
    if (_returnType is! Mirror) {
      _returnType = _returnType.resolve(mirrors);
    }
    return _returnType;
  }

  final List<ParameterMirror> parameters;

  String toString() => "FunctionTypeMirror on '$simpleName'";
}


class _LazyTypeVariableMirror {
  _LazyTypeVariableMirror(this._variableName, this._owner) {}

  TypeVariableMirror resolve(MirrorSystem mirrors) {
    ClassMirror owner = _owner.resolve(mirrors);
    return owner.typeVariables[_variableName];
  }

  final String _variableName;
  final _LazyTypeMirror _owner;
}

class _LocalTypeVariableMirrorImpl extends _LocalMirrorImpl
    implements TypeVariableMirror {
  _LocalTypeVariableMirrorImpl(this.simpleName,
                               this._owner,
                               this._upperBound) {}
  final String simpleName;

  String _qualifiedName = null;
  String get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = '${owner.qualifiedName}.${simpleName}';
    }
    return _qualifiedName;
  }

  var _owner;
  DeclarationMirror get owner {
    if (_owner is! Mirror) {
      _owner = _owner.resolve(mirrors);
    }
    return _owner;
  }

  bool get isPrivate => false;

  final bool isTopLevel = false;

  SourceLocation get location {
    throw new UnimplementedError(
        'TypeVariableMirror.location is not implemented');
  }

  var _upperBound;
  TypeMirror get upperBound {
    if (_upperBound is! Mirror) {
      _upperBound = _upperBound.resolve(mirrors);
    }
    return _upperBound;
  }

  String toString() => "TypeVariableMirror on '$simpleName'";
}


class _LocalTypedefMirrorImpl extends _LocalMirrorImpl
    implements TypedefMirror {
  _LocalTypedefMirrorImpl(this.simpleName,
                          this._owner,
                          this._referent) {}
  final String simpleName;

  String _qualifiedName = null;
  String get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = '${owner.qualifiedName}.${simpleName}';
    }
    return _qualifiedName;
  }

  var _owner;
  DeclarationMirror get owner {
    if (_owner is! Mirror) {
      _owner = _owner.resolve(mirrors);
    }
    return _owner;
  }

  bool get isPrivate => false;

  final bool isTopLevel = true;

  SourceLocation get location {
    throw new UnimplementedError(
        'TypedefMirror.location is not implemented');
  }

  var _referent;
  TypeMirror get referent {
    if (_referent is! Mirror) {
      _referent = _referent.resolve(mirrors);
    }
    return _referent;
  }

  String toString() => "TypedefMirror on '$simpleName'";
}


class _LazyLibraryMirror {
  _LazyLibraryMirror(this.libraryName) {}

  LibraryMirror resolve(MirrorSystem mirrors) {
    return mirrors.libraries[libraryName];
  }

  final String libraryName;
}

class _LocalLibraryMirrorImpl extends _LocalObjectMirrorImpl
    implements LibraryMirror {
  _LocalLibraryMirrorImpl(ref,
                          this.simpleName,
                          this.url,
                          this.members) : super(ref) {}

  final String simpleName;

  // The simple name and the qualified name are the same for a library.
  String get qualifiedName => simpleName;

  // Always null for libraries.
  final DeclarationMirror owner = null;

  // Always false for libraries.
  final bool isPrivate = false;

  // Always false for libraries.
  final bool isTopLevel = false;

  SourceLocation get location {
    throw new UnimplementedError(
        'LibraryMirror.location is not implemented');
  }

  final String url;
  final Map<String, Mirror> members;

  Map<String, ClassMirror> _classes = null;
  Map<String, MethodMirror> _functions = null;
  Map<String, MethodMirror> _getters = null;
  Map<String, MethodMirror> _setters = null;
  Map<String, VariableMirror> _variables = null;

  Map<String, ClassMirror> get classes {
    if (_classes == null) {
      _classes = _filterMap(members,
                            (key, value) => (value is ClassMirror));
    }
    return _classes;
  }

  Map<String, MethodMirror> get functions {
    if (_functions == null) {
      _functions = _filterMap(members,
                              (key, value) => (value is MethodMirror));
    }
    return _functions;
  }

  Map<String, MethodMirror> get getters {
    if (_getters == null) {
      _getters = _filterMap(functions,
                            (key, value) => (value.isGetter));
    }
    return _getters;
  }

  Map<String, MethodMirror> get setters {
    if (_setters == null) {
      _setters = _filterMap(functions,
                            (key, value) => (value.isSetter));
    }
    return _setters;
  }

  Map<String, VariableMirror> get variables {
    if (_variables == null) {
      _variables = _filterMap(members,
                              (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  String toString() => "LibraryMirror on '$simpleName'";
}

class _LocalMethodMirrorImpl extends _LocalMirrorImpl
    implements MethodMirror {
  _LocalMethodMirrorImpl(this.simpleName,
                         this._owner,
                         this.parameters,
                         this._returnType,
                         this.isStatic,
                         this.isAbstract,
                         this.isGetter,
                         this.isSetter,
                         this.isConstructor,
                         this.isConstConstructor,
                         this.isGenerativeConstructor,
                         this.isRedirectingConstructor,
                         this.isFactoryConstructor) {}

  final String simpleName;

  String _qualifiedName = null;
  String get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = '${owner.qualifiedName}.${simpleName}';
    }
    return _qualifiedName;
  }

  var _owner;
  DeclarationMirror get owner {
    if (_owner is! Mirror) {
      _owner = _owner.resolve(mirrors);
    }
    return _owner;
  }

  bool get isPrivate {
    return simpleName.startsWith('_') || constructorName.startsWith('_');
  }

  bool get isTopLevel =>  owner is LibraryMirror;

  SourceLocation get location {
    throw new UnimplementedError(
        'MethodMirror.location is not implemented');
  }

  var _returnType;
  TypeMirror get returnType {
    if (_returnType is! Mirror) {
      _returnType = _returnType.resolve(mirrors);
    }
    return _returnType;
  }

  final List<ParameterMirror> parameters;

  final bool isStatic;
  final bool isAbstract;

  bool get isRegularMethod => !isGetter && !isSetter && !isConstructor;

  TypeMirror get isOperator {
    throw new UnimplementedError(
        'MethodMirror.isOperator is not implemented');
  }

  final bool isGetter;
  final bool isSetter;
  final bool isConstructor;

  var _constructorName = null;
  String get constructorName {
    if (_constructorName == null) {
      if (!isConstructor) {
        _constructorName = '';
      } else {
        var parts = simpleName.split('.');
        if (parts.length > 2) {
          throw new MirrorException(
              'Internal error in MethodMirror.constructorName: '
              'malformed name <$simpleName>');
        } else if (parts.length == 2) {
          _constructorName = parts[1];
        } else {
          _constructorName = '';
        }
      }
    }
    return _constructorName;
  }

  final bool isConstConstructor;
  final bool isGenerativeConstructor;
  final bool isRedirectingConstructor;
  final bool isFactoryConstructor;

  String toString() => "MethodMirror on '$simpleName'";
}

class _LocalVariableMirrorImpl extends _LocalMirrorImpl
    implements VariableMirror {
  _LocalVariableMirrorImpl(this.simpleName,
                           this._owner,
                           this._type,
                           this.isStatic,
                           this.isFinal) {}

  final String simpleName;

  String _qualifiedName = null;
  String get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = '${owner.qualifiedName}.${simpleName}';
    }
    return _qualifiedName;
  }

  var _owner;
  DeclarationMirror get owner {
    if (_owner is! Mirror) {
      _owner = _owner.resolve(mirrors);
    }
    return _owner;
  }

  bool get isPrivate {
    return simpleName.startsWith('_');
  }

  bool get isTopLevel {
    return owner is LibraryMirror;
  }

  SourceLocation get location {
    throw new UnimplementedError(
        'VariableMirror.location is not implemented');
  }

  var _type;
  TypeMirror get type {
    if (_type is! Mirror) {
      _type = _type.resolve(mirrors);
    }
    return _type;
  }

  final bool isStatic;
  final bool isFinal;

  String toString() => "VariableMirror on '$simpleName'";
}

class _LocalParameterMirrorImpl extends _LocalVariableMirrorImpl
    implements ParameterMirror {
  _LocalParameterMirrorImpl(type, this.isOptional)
      : super('<TODO:unnamed>', null, type, false, false) {}

  final bool isOptional;

  String get defaultValue {
    throw new UnimplementedError(
        'ParameterMirror.defaultValue is not implemented');
  }

  bool get hasDefaultValue {
    throw new UnimplementedError(
        'ParameterMirror.hasDefaultValue is not implemented');
  }
}

class _Mirrors {
  // Does a port refer to our local isolate?
  static bool isLocalPort(SendPort port) native 'Mirrors_isLocalPort';

  static MirrorSystem _currentMirrorSystem = null;

  // Creates a new local MirrorSystem.
  static MirrorSystem makeLocalMirrorSystem()
      native 'Mirrors_makeLocalMirrorSystem';

  // The MirrorSystem for the current isolate.
  static MirrorSystem currentMirrorSystem() {
    if (_currentMirrorSystem == null) {
      _currentMirrorSystem = makeLocalMirrorSystem();
    }
    return _currentMirrorSystem;
  }

  static Future<MirrorSystem> mirrorSystemOf(SendPort port) {
    Completer<MirrorSystem> completer = new Completer<MirrorSystem>();
    if (isLocalPort(port)) {
      // Make a local mirror system.
      try {
        completer.complete(currentMirrorSystem());
      } catch (exception) {
        completer.completeException(exception);
      }
    } else {
      // Make a remote mirror system
      throw new UnimplementedError(
          'Remote mirror support is not implemented');
    }
    return completer.future;
  }

  // Creates a new local InstanceMirror
  static InstanceMirror makeLocalInstanceMirror(Object reflectee)
      native 'Mirrors_makeLocalInstanceMirror';

  // Creates a new local mirror for some Object.
  static InstanceMirror reflect(Object reflectee) {
    return makeLocalInstanceMirror(reflectee);
  }
}
