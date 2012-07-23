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
  _LocalMirrorSystemImpl(this.rootLibrary, this._libraries, this.isolate) {}

  final LibraryMirror rootLibrary;
  final Map<String, LibraryMirror> _libraries;
  final IsolateMirror isolate;

  Map<String, LibraryMirror> libraries() { return _libraries; }

  Mirror mirrorOf(Object reflectee) {
    return _Mirrors.mirrorOf(reflectee);
  }

  InterfaceMirror _sharedDynamic = null;

  InterfaceMirror _dynamicMirror() {
    if (_sharedDynamic === null) {
      _sharedDynamic =
          new _LocalInterfaceMirrorImpl(
              null, 'Dynamic', false, null, null, [], null, const {});
    }
    return _sharedDynamic;
  }

  InterfaceMirror _sharedVoid = null;

  InterfaceMirror _voidMirror() {
    if (_sharedVoid === null) {
      _sharedVoid =
          new _LocalInterfaceMirrorImpl(
              null, 'void', false, null, null, [], null, const {});
    }
    return _sharedVoid;
  }

  String toString() {
    return "MirrorSystem for isolate '$debugName'";
  }
}

abstract class _LocalMirrorImpl implements Mirror {
  // Local mirrors always return the same MirrorSystem.  This field
  // is more interesting once we implement remote mirrors.
  MirrorSystem get mirrors() { return _Mirrors.currentMirrorSystem(); }
}

class _LocalIsolateMirrorImpl extends _LocalMirrorImpl
    implements IsolateMirror {
  _LocalIsolateMirrorImpl(this.debugName) {}

  final String debugName;
  final bool isCurrent = true;

  String toString() {
    return "IsolateMirror on '$debugName'";
  }
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
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    try {
      completer.complete(
          _invoke(this, memberName, positionalArguments));
    } catch (var exception) {
      completer.completeException(exception);
    }
    return completer.future;
  }

  static _invoke(ref, memberName, positionalArguments)
      native 'LocalObjectMirrorImpl_invoke';
}

// Prints a string as it might appear in dart program text.
// TODO(turnidge): Consider truncating.
String _dartEscape(String str) {
  bool isNice(int code) {
    return (code >= 32 && code <= 126);
  }

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
                           this._class,
                           this._reflectee) : super(ref) {}

  var _class;
  InterfaceMirror getClass() {
    if (_class is _LazyInterfaceMirror) {
      _class = _class.resolve(mirrors);
    }
    return _class;
  }

  // LocalInstanceMirrors always reflect local instances
  bool hasReflectee = true; 

  var _reflectee;
  get reflectee() => _reflectee;

  String toString() {
    if (isSimpleValue(_reflectee)) {
      if (_reflectee is String) {
        return "InstanceMirror on <'${_dartEscape(_reflectee)}'>";
      } else {
        return "InstanceMirror on <$_reflectee>";
      }
    } else {
      return "InstanceMirror on instance of '${getClass().simpleName}'";
    }
  }
}

class _LazyInterfaceMirror {
  _LazyInterfaceMirror(this.libraryName, this.interfaceName) {}

  InterfaceMirror resolve(MirrorSystem mirrors) {
    if (libraryName === null) {
      if (interfaceName == 'Dynamic') {
        return mirrors._dynamicMirror();
      } else if (interfaceName == 'void') {
        return mirrors._dynamicMirror();
      } else {
        throw new NotImplementedException(
            "Mirror for type '$interfaceName' not implemented");
      }
    }
    return mirrors.libraries()[libraryName].members()[interfaceName];
  }

  final String libraryName;
  final String interfaceName;
}

class _LocalInterfaceMirrorImpl extends _LocalObjectMirrorImpl
    implements InterfaceMirror {
  _LocalInterfaceMirrorImpl(ref,
                            this.simpleName,
                            this.isClass,
                            this._library,
                            this._superclass,
                            this._superinterfaces,
                            this._defaultFactory,
                            this._members) : super(ref) {}

  final String simpleName;
  final bool isClass;

  var _library;
  LibraryMirror get library() {
    if (_library is _LazyLibraryMirror) {
      _library = _library.resolve(mirrors);
    }
    return _library;
  }

  var _superclass;
  InterfaceMirror superclass() {
    if (_superclass is _LazyInterfaceMirror) {
      _superclass = _superclass.resolve(mirrors);
    }
    return _superclass;
  }

  var _superinterfaces;
  List<InterfaceMirror> superinterfaces() {
    if (_superinterfaces.length > 0 &&
        _superinterfaces[0] is _LazyInterfaceMirror) {
      List<InterfaceMirror> resolved = new List<InterfaceMirror>();
      for (int i = 0; i < _superinterfaces.length; i++) {
        resolved.add(_superinterfaces[i].resolve(mirrors));
      }
      _superinterfaces = resolved;
    }
    return _superinterfaces;
  }

  var _defaultFactory;
  InterfaceMirror defaultFactory() {
    if (_defaultFactory is _LazyInterfaceMirror) {
      _defaultFactory = _defaultFactory.resolve(mirrors);
    }
    return _defaultFactory;
  }

  Map<String, InterfaceMirror> _members;
  Map<String, InterfaceMirror> _methods = null;
  Map<String, InterfaceMirror> _variables = null;

  Map<String, Mirror> members() { return _members; }

  Map<String, MethodMirror> methods() {
    if (_methods == null) {
      _methods = filterMap(members(),
                           (key, value) => (value is MethodMirror));
    }
    return _methods;
  }

  Map<String, VariableMirror> variables() {
    if (_variables == null) {
      _variables = filterMap(members(),
                             (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  String toString() {
    return "InterfaceMirror on '$simpleName'";
  }
}

class _LazyLibraryMirror {
  _LazyLibraryMirror(this.libraryName) {}

  LibraryMirror resolve(MirrorSystem mirrors) {
    return mirrors.libraries()[libraryName];
  }

  final String libraryName;
}

class _LocalLibraryMirrorImpl extends _LocalObjectMirrorImpl
    implements LibraryMirror {
  _LocalLibraryMirrorImpl(ref,
                          this.simpleName,
                          this.url,
                          this._members) : super(ref) {}

  final String simpleName;
  final String url;
  Map<String, InterfaceMirror> _members;
  Map<String, InterfaceMirror> _classes = null;
  Map<String, InterfaceMirror> _functions = null;
  Map<String, InterfaceMirror> _variables = null;

  Map<String, Mirror> members() { return _members; }

  Map<String, InterfaceMirror> classes() {
    if (_classes == null) {
      _classes = filterMap(members(),
                           (key, value) => (value is InterfaceMirror));
    }
    return _classes;
  }

  Map<String, MethodMirror> functions() {
    if (_functions == null) {
      _functions = filterMap(members(),
                             (key, value) => (value is MethodMirror));
    }
    return _functions;
  }

  Map<String, VariableMirror> variables() {
    if (_variables == null) {
      _variables = filterMap(members(),
                             (key, value) => (value is VariableMirror));
    }
    return _variables;
  }

  String toString() {
    return "LibraryMirror on '$simpleName'";
  }
}

class _LocalMethodMirrorImpl extends _LocalMirrorImpl
    implements MethodMirror {
  _LocalMethodMirrorImpl(this.simpleName,
                         this._owner,
                         this._parameters,
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

  var _owner;
  Mirror get owner() {
    if (_owner is! Mirror) {
      _owner = _owner.resolve(mirrors);
    }
    return _owner;
  }

  bool get isTopLevel() {
    return owner is LibraryMirror;
  }

  final bool isStatic;

  bool get isMethod() {
    return !isGetter && !isSetter && !isConstructor;
  }

  final bool isAbstract;
  final bool isGetter;
  final bool isSetter;
  final bool isConstructor;

  final bool isConstConstructor;
  final bool isGenerativeConstructor;
  final bool isRedirectingConstructor;
  final bool isFactoryConstructor;

  List<ParameterMirror> _parameters;
  List<ParameterMirror> parameters() => _parameters;

  String toString() {
    return "MethodMirror on '$simpleName'";
  }
}

class _LocalParameterMirrorImpl extends _LocalVariableMirrorImpl
    implements ParameterMirror {
  // TODO(rmacnak): Fill these mirrors will real information
  _LocalParameterMirrorImpl(this.isOptional) 
    : super(null, null, false, false) {}
  
  final bool isOptional;

  TypeMirror get type() => null;
  String get defaultValue() => null;
  bool get hasDefaultValue() => null;
}

class _LocalVariableMirrorImpl extends _LocalMirrorImpl
    implements VariableMirror {
  _LocalVariableMirrorImpl(this.simpleName,
                           this._owner,
                           this.isStatic,
                           this.isFinal) {}

  final String simpleName;

  var _owner;
  Mirror get owner() {
    if (_owner is! Mirror) {
      _owner = _owner.resolve(mirrors);
    }
    return _owner;
  }

  bool get isTopLevel() {
    return owner is LibraryMirror;
  }

  final bool isStatic;
  final bool isFinal;

  String toString() {
    return "VariableMirror on '$simpleName'";
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
      } catch (var exception) {
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
  static InstanceMirror mirrorOf(Object reflectee) {
    return makeLocalInstanceMirror(reflectee);
  }
}
