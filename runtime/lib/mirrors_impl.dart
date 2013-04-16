// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

// These values are allowed to be passed directly over the wire.
bool _isSimpleValue(var value) {
  return (value == null || value is num || value is String || value is bool);
}

Map _filterMap(Map<Symbol, dynamic> old_map, bool filter(Symbol key, value)) {
  Map new_map = new Map<Symbol, dynamic>();
  old_map.forEach((key, value) {
    if (filter(key, value)) {
      new_map[key] = value;
    }
  });
  return new_map;
}

String _n(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

Symbol _s(String name) {
  if (name == null) return null;
  return new _symbol_dev.Symbol.unvalidated(name);
}

Symbol _computeQualifiedName(DeclarationMirror owner, Symbol simpleName) {
  if (owner == null) return simpleName;
  return _s('${_n(owner.qualifiedName)}.${_n(simpleName)}');
}

Map<Symbol, dynamic> _convertStringToSymbolMap(Map<String, dynamic> map) {
  if (map == null) return null;
  Map<Symbol, dynamic> result = new Map<Symbol, dynamic>();
  map.forEach((name, value) => result[_s(name)] = value);
  return result;
}

String _makeSignatureString(TypeMirror returnType,
                            List<ParameterMirror> parameters) {
  StringBuffer buf = new StringBuffer();
  buf.write(_n(returnType.qualifiedName));
  buf.write(' (');
  bool found_optional_param = false;
  for (int i = 0; i < parameters.length; i++) {
    var param = parameters[i];
    if (param.isOptional && !found_optional_param) {
      buf.write('[');
      found_optional_param = true;
    }
    buf.write(_n(param.type.qualifiedName));
    if (i < (parameters.length - 1)) {
      buf.write(', ');
    }
  }
  if (found_optional_param) {
    buf.write(']');
  }
  buf.write(')');
  return buf.toString();
}

class _LocalMirrorSystemImpl implements MirrorSystem {
  // TODO(ahe): [libraries] should be Map<Uri, LibraryMirror>.
  // Change parameter back to "this.libraries" when native code is changed.
  _LocalMirrorSystemImpl(Map<String, LibraryMirror> libraries, this.isolate)
      : _functionTypes = new Map<String, FunctionTypeMirror>(),
        this.libraries = _convertStringToSymbolMap(libraries);

  final Map<Symbol, LibraryMirror> libraries;
  final IsolateMirror isolate;

  TypeMirror _dynamicType = null;

  TypeMirror get dynamicType {
    if (_dynamicType == null) {
      _dynamicType =
          new _LocalClassMirrorImpl(
              null, 'dynamic', false, null, null, [], null,
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

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null) {
      throw new UnimplementedError(
          'named argument support is not implemented');
    }
    return _invoke(this, _n(memberName), positionalArguments, false); 
  }

  InstanceMirror getField(Symbol fieldName) {
    return _getField(this, _n(fieldName)); 
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    return _setField(this, _n(fieldName), arg, false); 
  }

  Future<InstanceMirror> invokeAsync(Symbol memberName,
                                     List positionalArguments,
                                     [Map<Symbol, dynamic> namedArguments]) {
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
          _invoke(this, _n(memberName), positionalArguments, true));
    } catch (exception, s) {
      completer.completeError(exception, s);
    }
    return completer.future;
  }

  Future<InstanceMirror> getFieldAsync(Symbol fieldName) {
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(_getField(this, _n(fieldName)));
    } catch (exception, s) {
      completer.completeError(exception, s);
    }
    return completer.future;
  }

  Future<InstanceMirror> setFieldAsync(Symbol fieldName, Object arg) {
    _validateArgument(0, arg);

    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(_setField(this, _n(fieldName), arg, true));
    } catch (exception, s) {
      completer.completeError(exception, s);
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

  static _invoke(ref, memberName, positionalArguments, async)
      native 'LocalObjectMirrorImpl_invoke';

  static _getField(ref, fieldName) // same for sync and async versions
      native 'LocalObjectMirrorImpl_getField';

  static _setField(ref, fieldName, value, async)
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
        // TODO(lrn): Someone decide if this should combine surrogate pairs.
        int code = input.codeUnitAt(0);
        if (isNice(code)) {
          output = input;
        } else {
          output = '\\u{${code.toRadixString(16)}}';
        }
        break;
    }
    buf.write(output);
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

  InstanceMirror apply(List<Object> positionalArguments,
                       [Map<Symbol, Object> namedArguments]) {
    if (namedArguments != null) {
      throw new UnimplementedError(
          'named argument support is not implemented');
    }
    return _apply(this, positionalArguments, false);
  }

  Future<InstanceMirror> applyAsync(List<Object> positionalArguments,
                                    [Map<Symbol, Object> namedArguments]) {
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
          _apply(this, positionalArguments, true));
    } catch (exception) {
      completer.completeError(exception);
    }
    return completer.future;
  }

  Future<InstanceMirror> findInContext(Symbol name) {
    throw new UnimplementedError(
        'ClosureMirror.findInContext() is not implemented');
  }

  static _apply(ref, positionalArguments, async)
      native 'LocalClosureMirrorImpl_apply';
}

class _LazyTypeMirror {
  _LazyTypeMirror(String libraryName, String typeName)
      : this.libraryName = _s(libraryName),
        this.typeName = _s(typeName);

  TypeMirror resolve(MirrorSystem mirrors) {
    if (libraryName == null) {
      if (typeName == const Symbol('dynamic')) {
        return mirrors.dynamicType;
      } else if (typeName == const Symbol('void')) {
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

  final Symbol libraryName;
  final Symbol typeName;
}

class _LocalClassMirrorImpl extends _LocalObjectMirrorImpl
    implements ClassMirror {
  _LocalClassMirrorImpl(ref,
                        String simpleName,
                        this.isClass,
                        this._owner,
                        this._superclass,
                        this._superinterfaces,
                        this._defaultFactory,
                        Map<String, Mirror> members,
                        Map<String, Mirror> constructors,
                        Map<String, Mirror> typeVariables)
      : this.simpleName = _s(simpleName),
        this.members = _convertStringToSymbolMap(members),
        this.constructors = _convertStringToSymbolMap(constructors),
        this.typeVariables = _convertStringToSymbolMap(typeVariables),
        super(ref);

  final Symbol simpleName;

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
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

  bool get isPrivate => _n(simpleName).startsWith('_');

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

  final Map<Symbol, Mirror> members;

  Map<Symbol, MethodMirror> _methods = null;
  Map<Symbol, MethodMirror> _getters = null;
  Map<Symbol, MethodMirror> _setters = null;
  Map<Symbol, VariableMirror> _variables = null;

  Map<Symbol, MethodMirror> get methods {
    if (_methods == null) {
      _methods = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isRegularMethod));
    }
    return _methods;
  }

  Map<Symbol, MethodMirror> get getters {
    if (_getters == null) {
      _getters = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isGetter));
    }
    return _getters;
  }

  Map<Symbol, MethodMirror> get setters {
    if (_setters == null) {
      _setters = _filterMap(
          members,
          (key, value) => (value is MethodMirror && value.isSetter));
    }
    return _setters;
  }

  Map<Symbol, VariableMirror> get variables {
    if (_variables == null) {
      _variables = _filterMap(
          members,
          (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  Map<Symbol, MethodMirror> constructors;
  Map<Symbol, TypeVariableMirror> typeVariables;

  Map<Symbol, TypeMirror> get typeArguments {
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

  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null) {
      throw new UnimplementedError(
          'named argument support is not implemented');
    }
    return _invokeConstructor(this,
                              _n(constructorName),
                              positionalArguments,
                              false);
  }

  Future<InstanceMirror> newInstanceAsync(Symbol constructorName,
                                          List positionalArguments,
                                          [Map<Symbol, dynamic> namedArguments]) {
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
          _invokeConstructor(this,
                             _n(constructorName),
                             positionalArguments,
                             true));
    } catch (exception) {
      completer.completeError(exception);
    }
    return completer.future;
  }

  static _invokeConstructor(ref, constructorName, positionalArguments, async)
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
  _LazyTypeVariableMirror(String variableName, this._owner)
      : this._variableName = _s(variableName);

  TypeVariableMirror resolve(MirrorSystem mirrors) {
    ClassMirror owner = _owner.resolve(mirrors);
    return owner.typeVariables[_variableName];
  }

  final Symbol _variableName;
  final _LazyTypeMirror _owner;
}

class _LocalTypeVariableMirrorImpl extends _LocalMirrorImpl
    implements TypeVariableMirror {
  _LocalTypeVariableMirrorImpl(String simpleName,
                               this._owner,
                               this._upperBound)
      : this.simpleName = _s(simpleName);

  final Symbol simpleName;

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
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
  _LocalTypedefMirrorImpl(String simpleName,
                          this._owner,
                          this._referent)
      : this.simpleName = _s(simpleName);

  final Symbol simpleName;

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
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
  _LazyLibraryMirror(String libraryName)
      : this.libraryName = _s(libraryName);

  LibraryMirror resolve(MirrorSystem mirrors) {
    return mirrors.libraries[libraryName];
  }

  final Symbol libraryName;
}

class _LocalLibraryMirrorImpl extends _LocalObjectMirrorImpl
    implements LibraryMirror {
  _LocalLibraryMirrorImpl(ref,
                          String simpleName,
                          this.url,
                          Map<String, Mirror> members)
      : this.simpleName = _s(simpleName),
        this.members = _convertStringToSymbolMap(members),
        super(ref);

  final Symbol simpleName;

  // The simple name and the qualified name are the same for a library.
  Symbol get qualifiedName => simpleName;

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
  final Map<Symbol, Mirror> members;

  Map<Symbol, ClassMirror> _classes = null;
  Map<Symbol, MethodMirror> _functions = null;
  Map<Symbol, MethodMirror> _getters = null;
  Map<Symbol, MethodMirror> _setters = null;
  Map<Symbol, VariableMirror> _variables = null;

  Map<Symbol, ClassMirror> get classes {
    if (_classes == null) {
      _classes = _filterMap(members,
                            (key, value) => (value is ClassMirror));
    }
    return _classes;
  }

  Map<Symbol, MethodMirror> get functions {
    if (_functions == null) {
      _functions = _filterMap(members,
                              (key, value) => (value is MethodMirror));
    }
    return _functions;
  }

  Map<Symbol, MethodMirror> get getters {
    if (_getters == null) {
      _getters = _filterMap(functions,
                            (key, value) => (value.isGetter));
    }
    return _getters;
  }

  Map<Symbol, MethodMirror> get setters {
    if (_setters == null) {
      _setters = _filterMap(functions,
                            (key, value) => (value.isSetter));
    }
    return _setters;
  }

  Map<Symbol, VariableMirror> get variables {
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
  _LocalMethodMirrorImpl(String simpleName,
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
                         this.isFactoryConstructor)
      : this.simpleName = _s(simpleName);

  final Symbol simpleName;

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
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
    return _n(simpleName).startsWith('_') ||
        _n(constructorName).startsWith('_');
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

  Symbol _constructorName = null;
  Symbol get constructorName {
    if (_constructorName == null) {
      if (!isConstructor) {
        _constructorName = _s('');
      } else {
        var parts = _n(simpleName).split('.');
        if (parts.length > 2) {
          throw new MirrorException(
              'Internal error in MethodMirror.constructorName: '
              'malformed name <$simpleName>');
        } else if (parts.length == 2) {
          _constructorName = _s(parts[1]);
        } else {
          _constructorName = _s('');
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
  _LocalVariableMirrorImpl(String simpleName,
                           this._owner,
                           this._type,
                           this.isStatic,
                           this.isFinal)
      : this.simpleName = _s(simpleName);

  final Symbol simpleName;

  Symbol _qualifiedName = null;
  Symbol get qualifiedName {
    if (_qualifiedName == null) {
      _qualifiedName = _computeQualifiedName(owner, simpleName);
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
    return _n(simpleName).startsWith('_');
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
        completer.completeError(exception);
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

  static ClassMirror reflectClass(Type reflectee) {
    throw new UnimplementedError('reflectClass is not implemented');
  }
}
