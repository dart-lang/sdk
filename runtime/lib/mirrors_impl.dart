// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

// These values are allowed to be passed directly over the wire.
bool isSimpleValue(var value) {
  return (value === null || value is num || value is String || value is bool);
}

Map filterMap(Map old_map, bool filter(key, value)) {
  Map new_map = new Map();
  old_map.forEach((key, value) {
      if (filter(key, value)) {
        new_map[key] = value;
      }
    });
  return new_map;
}

class _LocalMirrorSystemImpl implements MirrorSystem {
  _LocalMirrorSystemImpl(this.libraries, this.isolate) {}

  final Map<String, LibraryMirror> libraries;
  final IsolateMirror isolate;

  TypeMirror _dynamicType = null;

  TypeMirror get dynamicType {
    if (_dynamicType === null) {
      _dynamicType =
          new _LocalClassMirrorImpl(
              null, 'Dynamic', false, null, null, [], null, const {});
    }
    return _dynamicType;
  }

  TypeMirror _voidType = null;

  TypeMirror get voidType {
    if (_voidType === null) {
      _voidType =
          new _LocalClassMirrorImpl(
              null, 'void', false, null, null, [], null, const {});
    }
    return _voidType;
  }

  String toString() => "MirrorSystem for isolate '${isolate.debugName}'";
}

abstract class _LocalMirrorImpl implements Mirror {
  int hashCode() {
    throw new NotImplementedException('Mirror.hashCode() not yet implemented');
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
    if (namedArguments !== null) {
      throw new NotImplementedException('named arguments not implemented');
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
      } else if (!isSimpleValue(arg)) {
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
        output = @'\\';
        break;
      case "\'" :
        output = @"\'";
        break;
      case '\n' :
        output = @'\n';
        break;
      case '\r' :
        output = @'\r';
        break;
      case '\f' :
        output = @'\f';
        break;
      case '\b' :
        output = @'\b';
        break;
      case '\t' :
        output = @'\t';
        break;
      case '\v' :
        output = @'\v';
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
    if (_type is _LazyClassMirror) {
      _type = _type.resolve(mirrors);
    }
    return _type;
  }

  // LocalInstanceMirrors always reflect local instances
  bool hasReflectee = true;

  var _reflectee;
  get reflectee => _reflectee;

  String toString() {
    if (isSimpleValue(_reflectee)) {
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
                          klass,
                          reflectee) : super(ref, klass, reflectee) {}

  MethodMirror _function;
  MethodMirror function() => _function;

  String get source {
    throw new NotImplementedException('ClosureMirror.source not implemented');
  }

  Future<ObjectMirror> apply(List<Object> positionalArguments,
                             [Map<String,Object> namedArguments]) {
    if (namedArguments !== null) {
      throw new NotImplementedException('named arguments not implemented');
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

  Future<ObjectMirror> findInContext(String name) {
    throw new NotImplementedException(
        'ClosureMirror.findInContext() not implemented');
  }

  static _apply(ref, positionalArguments)
      native 'LocalClosureMirrorImpl_apply';
}

class _LazyClassMirror {
  _LazyClassMirror(this.libraryName, this.interfaceName) {}

  ClassMirror resolve(MirrorSystem mirrors) {
    if (libraryName === null) {
      if (interfaceName == 'Dynamic') {
        return mirrors.dynamicType();
      } else if (interfaceName == 'void') {
        return mirrors.voidType();
      } else {
        throw new NotImplementedException(
            "Mirror for type '$interfaceName' not implemented");
      }
    }
    return mirrors.libraries[libraryName].members[interfaceName];
  }

  final String libraryName;
  final String interfaceName;
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
                        this.members) : super(ref) {}

  final String simpleName;

  String _qualifiedName = null;
  String get qualifiedName {
    if (_qualifiedName === null) {
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

  bool get isPrivate => simpleName.startsWith('_');

  final bool isTopLevel = true;

  SourceLocation get location {
    throw new NotImplementedException(
        'ClassMirror.location not yet implemented');
  }

  final bool isClass;

  var _superclass;
  ClassMirror get superclass {
    if (_superclass is _LazyClassMirror) {
      _superclass = _superclass.resolve(mirrors);
    }
    return _superclass;
  }

  var _superinterfaces;
  List<ClassMirror> get superinterfaces {
    if (_superinterfaces.length > 0 &&
        _superinterfaces[0] is _LazyClassMirror) {
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
    if (_defaultFactory is _LazyClassMirror) {
      _defaultFactory = _defaultFactory.resolve(mirrors);
    }
    return _defaultFactory;
  }

  final Map<String, Mirror> members;

  Map<String, MethodMirror> _methods = null;
  Map<String, MethodMirror> _constructors = null;
  Map<String, MethodMirror> _getters = null;
  Map<String, MethodMirror> _setters = null;
  Map<String, VariableMirror> _variables = null;

  Map<String, MethodMirror> get methods {
    if (_methods == null) {
      _methods = filterMap(members,
                           (key, value) => (value is MethodMirror));
    }
    return _methods;
  }

  Map<String, MethodMirror> get constructors {
    if (_constructors == null) {
      _constructors = filterMap(methods,
                                (key, value) => (value.isConstructor));
    }
    return _constructors;
  }

  Map<String, MethodMirror> get getters {
    if (_getters == null) {
      _getters = filterMap(methods,
                           (key, value) => (value.isGetter));
    }
    return _getters;
  }

  Map<String, MethodMirror> get setters {
    if (_setters == null) {
      _setters = filterMap(methods,
                           (key, value) => (value.isSetter));
    }
    return _setters;
  }

  Map<String, VariableMirror> get variables {
    if (_variables == null) {
      _variables = filterMap(members,
                             (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  List<TypeVariableMirror> get typeVariables {
    throw new NotImplementedException(
        'ClassMirror.typeVariables not yet implemented');
  }

  List<TypeMirror> get typeArguments {
    throw new NotImplementedException(
        'ClassMirror.typeArguments not yet implemented');
  }

  bool isGenericDeclaration() {
    throw new NotImplementedException(
        'ClassMirror.isGenericDeclaration not yet implemented');
  }

  ClassMirror genericDeclaration() {
    throw new NotImplementedException(
        'ClassMirror.genericDeclaration not yet implemented');
  }

  String toString() => "ClassMirror on '$simpleName'";

  Future<InstanceMirror> newInstance(String constructorName,
                                     List positionalArguments,
                                     [Map<String,Dynamic> namedArguments]) {
    if (namedArguments !== null) {
      throw new NotImplementedException('named arguments not implemented');
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
    throw new NotImplementedException(
        'LibraryMirror.location not yet implemented');
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
      _classes = filterMap(members,
                           (key, value) => (value is ClassMirror));
    }
    return _classes;
  }

  Map<String, MethodMirror> get functions {
    if (_functions == null) {
      _functions = filterMap(members,
                             (key, value) => (value is MethodMirror));
    }
    return _functions;
  }

  Map<String, MethodMirror> get getters {
    if (_getters == null) {
      _getters = filterMap(functions,
                           (key, value) => (value.isGetter));
    }
    return _getters;
  }

  Map<String, MethodMirror> get setters {
    if (_setters == null) {
      _setters = filterMap(functions,
                           (key, value) => (value.isSetter));
    }
    return _setters;
  }

  Map<String, VariableMirror> get variables {
    if (_variables == null) {
      _variables = filterMap(members,
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
    if (_qualifiedName === null) {
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
    throw new NotImplementedException(
        'MethodMirror.location not yet implemented');
  }

  TypeMirror get returnType {
    throw new NotImplementedException(
        'MethodMirror.returnType not yet implemented');
  }

  final List<ParameterMirror> parameters;

  final bool isStatic;
  final bool isAbstract;

  bool get isRegularMethod => !isGetter && !isSetter && !isConstructor;

  TypeMirror get isOperator {
    throw new NotImplementedException(
        'MethodMirror.isOperator not yet implemented');
  }

  final bool isGetter;
  final bool isSetter;
  final bool isConstructor;

  var _constructorName = null;
  String get constructorName {
    if (_constructorName === null) {
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
                           this.isStatic,
                           this.isFinal) {}

  final String simpleName;

  String _qualifiedName = null;
  String get qualifiedName {
    if (_qualifiedName === null) {
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
    throw new NotImplementedException(
        'VariableMirror.location not yet implemented');
  }

  TypeMirror get type {
    throw new NotImplementedException(
        'VariableMirror.type not yet implemented');
  }

  final bool isStatic;
  final bool isFinal;

  String toString() => "VariableMirror on '$simpleName'";
}

class _LocalParameterMirrorImpl extends _LocalVariableMirrorImpl
    implements ParameterMirror {
  // TODO(rmacnak): Fill these mirrors will real information
  _LocalParameterMirrorImpl(this.isOptional)
    : super(null, null, false, false) {}

  final bool isOptional;

  TypeMirror get type  {
    throw new NotImplementedException(
        'ParameterMirror.type not yet implemented');
  }

  String get defaultValue {
    throw new NotImplementedException(
        'ParameterMirror.defaultValue not yet implemented');
  }

  bool get hasDefaultValue {
    throw new NotImplementedException(
        'ParameterMirror.hasDefaultValue not yet implemented');
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
    if (_currentMirrorSystem === null) {
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
      throw new NotImplementedException('Remote mirrors not yet implemented');
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
