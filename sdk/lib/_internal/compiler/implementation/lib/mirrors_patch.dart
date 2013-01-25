// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch library for dart:mirrors.

import 'dart:_foreign_helper' show JS;

// Yeah, seriously: mirrors in dart2js are experimental...
const String _MIRROR_OPT_IN_MESSAGE = """

This program is using an experimental feature called \"mirrors\".  As
currently implemented, mirrors do not work with minification, and will
cause spurious errors depending on how code was optimized.

The authors of this program are aware of these problems and have
decided the thrill of using an experimental feature is outweighing the
risks.  Furthermore, the authors of this program understand that
long-term, to fix the problems mentioned above, mirrors may have
negative impact on size and performance of Dart programs compiled to
JavaScript.
""";

bool _mirrorsEnabled = false;

/**
 * Stub class for the mirror system.
 */
patch MirrorSystem currentMirrorSystem() {
  _ensureEnabled();
  throw new UnsupportedError("MirrorSystem not implemented");
}

patch Future<MirrorSystem> mirrorSystemOf(SendPort port) {
  _ensureEnabled();
  throw new UnsupportedError("MirrorSystem not implemented");
}

patch InstanceMirror reflect(Object reflectee) {
  if (!_mirrorsEnabled && (_MIRROR_OPT_IN_MESSAGE == reflectee)) {
    // Turn on mirrors and warn that it is an experimental feature.
    _mirrorsEnabled = true;
    print(reflectee);
  }
  _ensureEnabled();
  return new _InstanceMirror(reflectee);
}

class _InstanceMirror extends InstanceMirror {
  static final Expando<ClassMirror> classMirrors = new Expando<ClassMirror>();

  final reflectee;

  _InstanceMirror(this.reflectee) {
    _ensureEnabled();
  }

  bool get hasReflectee => true;

  ClassMirror get type {
    String className = Primitives.objectTypeName(reflectee);
    var constructor = Primitives.getConstructor(className);
    var mirror = classMirrors[constructor];
    if (mirror == null) {
      mirror = new _ClassMirror(className, constructor);
      classMirrors[constructor] = mirror;
    }
    return mirror;
  }

  Future<InstanceMirror> invoke(String memberName,
                                List<Object> positionalArguments,
                                [Map<String,Object> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented');
    }
    // Copy the list to ensure that it can safely be passed to
    // JavaScript.
    var jsList = new List.from(positionalArguments);
    var mangledName = '${memberName}\$${positionalArguments.length}';
    var method = JS('var', '#[#]', reflectee, mangledName);
    var completer = new Completer<InstanceMirror>();
    // TODO(ahe): [Completer] or [Future] should have API to create a
    // delayed action.  Simulating with a [Timer].
    new Timer(0, (timer) {
      if (JS('String', 'typeof #', method) == 'function') {
        var result =
            JS('var', '#.apply(#, #)', method, reflectee, jsList);
        completer.complete(new _InstanceMirror(result));
      } else {
        completer.completeError('not a method $memberName');
      }
    });
    return completer.future;
  }

  String toString() => 'InstanceMirror($reflectee)';
}

class _ClassMirror extends ClassMirror {
  final String _name;
  final _jsConstructor;

  _ClassMirror(this._name, this._jsConstructor) {
    _ensureEnabled();
  }

  String toString() => 'ClassMirror($_name)';
}

_ensureEnabled() {
  if (_mirrorsEnabled) return;
  throw new UnsupportedError('dart:mirrors is an experimental feature');
}
