// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM-specific implementation of the dart:mirrors library.

// These values are allowed to be passed directly over the wire.
bool isSimpleValue(var value) {
  return (value === null || value is num || value is String || value is bool);
}

abstract class _LocalMirrorImpl implements Mirror {
  // Local mirrors always return the same IsolateMirror.  This field
  // is more interesting once we implement remote mirrors.
  IsolateMirror get isolate() { return _Mirrors.currentIsolateMirror(); }
}

class _LocalIsolateMirrorImpl extends _LocalMirrorImpl
    implements IsolateMirror {
  _LocalIsolateMirrorImpl(this.debugName, this.rootLibrary, this._libraries) {}

  final String debugName;
  final LibraryMirror rootLibrary;
  final Map<String, LibraryMirror> _libraries;

  Map<String, LibraryMirror> libraries() { return _libraries; }

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
                                List<Object> positionalArguments,
                                [Map<String,Object> namedArguments]) {
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
                           this.hasSimpleValue,
                           this._simpleValue) : super(ref) {}

  var _class;
  InterfaceMirror getClass() {
    if (_class is _LazyInterfaceMirror) {
      _class = _class.resolve(isolate);
    }
    return _class;
  }

  bool hasSimpleValue;

  var _simpleValue;
  get simpleValue() {
    if (!hasSimpleValue) {
      throw new MirrorException(
          "Before accesing simpleValue you must check that hasSimpleValue "
          "is true");
    }
    return _simpleValue;
  }

  String toString() {
    if (hasSimpleValue) {
      if (simpleValue is String) {
        return "InstanceMirror on <'${_dartEscape(simpleValue)}'>";
      } else {
        return "InstanceMirror on <$simpleValue>";
      }
    } else {
      return "InstanceMirror on instance of '${getClass().simpleName}'";
    }
  }
}

class _LazyInterfaceMirror {
  _LazyInterfaceMirror(this.libraryName, this.interfaceName) {}

  InterfaceMirror resolve(IsolateMirror isolate) {
    return isolate.libraries()[libraryName].members()[interfaceName];
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
                            this._defaultFactory) : super(ref) {}

  final String simpleName;
  final bool isClass;

  var _library;
  LibraryMirror get library() {
    if (_library is _LazyLibraryMirror) {
      _library = _library.resolve(isolate);
    }
    return _library;
  }

  var _superclass;
  InterfaceMirror superclass() {
    if (_superclass is _LazyInterfaceMirror) {
      _superclass = _superclass.resolve(isolate);
    }
    return _superclass;
  }

  var _superinterfaces;
  List<InterfaceMirror> superinterfaces() {
    if (_superinterfaces.length > 0 &&
        _superinterfaces[0] is _LazyInterfaceMirror) {
      List<InterfaceMirror> resolved = new List<InterfaceMirror>();
      for (int i = 0; i < _superinterfaces.length; i++) {
        resolved.add(_superinterfaces[i].resolve(isolate));
      }
      _superinterfaces = resolved;
    }
    return _superinterfaces;
  }

  var _defaultFactory;
  InterfaceMirror defaultFactory() {
    if (_defaultFactory is _LazyInterfaceMirror) {
      _defaultFactory = _defaultFactory.resolve(isolate);
    }
    return _defaultFactory;
  }

  String toString() {
    return "InterfaceMirror on '$simpleName'";
  }
}

class _LazyLibraryMirror {
  _LazyLibraryMirror(this.libraryName) {}

  LibraryMirror resolve(IsolateMirror isolate) {
    return isolate.libraries()[libraryName];
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

  Map<String, Mirror> members() { return _members; }

  String toString() {
    return "LibraryMirror on '$simpleName'";
  }
}

class _Mirrors {
  // Does a port refer to our local isolate?
  static bool isLocalPort(SendPort port) native 'Mirrors_isLocalPort';

  static IsolateMirror _currentIsolateMirror = null;

  // Creates a new local IsolateMirror.
  static IsolateMirror makeLocalIsolateMirror()
      native 'Mirrors_makeLocalIsolateMirror';

  // The IsolateMirror for the current isolate.
  static IsolateMirror currentIsolateMirror() {
    if (_currentIsolateMirror === null) {
      _currentIsolateMirror = makeLocalIsolateMirror();
    }
    return _currentIsolateMirror;
  }

  static Future<IsolateMirror> isolateMirrorOf(SendPort port) {
    Completer<IsolateMirror> completer = new Completer<IsolateMirror>();
    if (isLocalPort(port)) {
      // Make a local isolate mirror.
      try {
        completer.complete(currentIsolateMirror());
      } catch (var exception) {
        completer.completeException(exception);
      }
    } else {
      // Make a remote isolate mirror.
      throw new NotImplementedException('Remote mirrors not yet implemented');
    }
    return completer.future;
  }

  // Creates a new local InstanceMirror
  static InstanceMirror makeLocalInstanceMirror(Object reflectee)
      native 'Mirrors_makeLocalInstanceMirror';

  // The IsolateMirror for the current isolate.
  static InstanceMirror mirrorOf(Object reflectee) {
    return makeLocalInstanceMirror(reflectee);
  }
}
