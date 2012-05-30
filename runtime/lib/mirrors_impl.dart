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
  IsolateMirror get isolate() { return Mirrors.localIsolateMirror(); }
}

class _LocalIsolateMirrorImpl extends _LocalMirrorImpl
    implements IsolateMirror {
  _LocalIsolateMirrorImpl(this.debugName, this.rootLibrary, this.libraries) {}

  final String debugName;
  final LibraryMirror rootLibrary;
  final Map<String, LibraryMirror> libraries;
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
        throw new MirrorException(
            'positional argument $i ($arg) was not an InstanceMirror');
      }
      if (!isSimpleValue(arg)) {
        throw new MirrorException(
            'positional argument $i ($arg) was not a simple value');
      }
    }
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    completer.complete(
        _invoke(this, memberName, positionalArguments));
    return completer.future;
  }

  static _invoke(ref, memberName, positionalArguments)
      native 'LocalObjectMirrorImpl_invoke';
}

class _LocalInstanceMirrorImpl extends _LocalObjectMirrorImpl
    implements InstanceMirror {
  _LocalInstanceMirrorImpl(ref, this.simpleValue) : super(ref) {}

  final simpleValue;
}

class _LocalLibraryMirrorImpl extends _LocalObjectMirrorImpl
    implements LibraryMirror {
  _LocalLibraryMirrorImpl(ref, this.simpleName, this.url) : super(ref) {}

  final String simpleName;
  final String url;
}

class _Mirrors {
  // Does a port refer to our local isolate?
  static bool isLocalPort(SendPort port) native 'Mirrors_isLocalPort';

  static IsolateMirror _localIsolateMirror;

  // The IsolateMirror for the current isolate.
  static IsolateMirror localIsolateMirror() {
    if (_localIsolateMirror === null) {
      _localIsolateMirror = makeLocalIsolateMirror();
    }
    return _localIsolateMirror;
  }

  // Creates a new local IsolateMirror.
  static bool makeLocalIsolateMirror()
      native 'Mirrors_makeLocalIsolateMirror';

  static Future<IsolateMirror> isolateMirrorOf(SendPort port) {
    Completer<IsolateMirror> completer = new Completer<IsolateMirror>();
    if (isLocalPort(port)) {
      // Make a local isolate mirror.
      completer.complete(localIsolateMirror());
    } else {
      // Make a remote isolate mirror.
      throw new NotImplementedException('Remote mirrors not yet implemented');
    }
    return completer.future;
  }
}
