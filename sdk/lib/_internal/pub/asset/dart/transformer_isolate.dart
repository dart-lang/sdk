// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.transformer_isolate;

import 'dart:convert';
import 'dart:isolate';
import 'dart:mirrors';

import 'package:barback/barback.dart';

import 'serialize.dart';

/// Sets up the initial communication with the host isolate.
void loadTransformers(SendPort replyTo) {
  var port = new ReceivePort();
  replyTo.send(port.sendPort);
  port.listen((wrappedMessage) {
    // TODO(nweiz): When issue 19228 is fixed, spin up a separate isolate for
    // libraries loaded beyond the first so they can run in parallel.
    respond(wrappedMessage, (message) {
      var library = Uri.parse(message['library']);
      var configuration = JSON.decode(message['configuration']);
      var mode = new BarbackMode(message['mode']);
      return _initialize(library, configuration, mode).
          map(serializeTransformerLike).toList();
    });
  });
}

/// Loads all the transformers and groups defined in [uri].
///
/// Loads the library, finds any [Transformer] or [TransformerGroup] subclasses
/// in it, instantiates them with [configuration] and [mode], and returns them.
List _initialize(Uri uri, Map configuration, BarbackMode mode) {
  var mirrors = currentMirrorSystem();
  var transformerClass = reflectClass(Transformer);
  var aggregateClass = _aggregateTransformerClass;
  var groupClass = reflectClass(TransformerGroup);

  var seen = new Set();
  var transformers = [];

  loadFromLibrary(library) {
    if (seen.contains(library)) return;
    seen.add(library);

    // Load transformers from libraries exported by [library].
    for (var dependency in library.libraryDependencies) {
      if (!dependency.isExport) continue;
      loadFromLibrary(dependency.targetLibrary);
    }

    // TODO(nweiz): if no valid transformers are found, throw an error message
    // describing candidates and why they were rejected.
    transformers.addAll(library.declarations.values.map((declaration) {
      if (declaration is! ClassMirror) return null;
      var classMirror = declaration;
      if (classMirror.isPrivate) return null;
      if (classMirror.isAbstract) return null;
      if (!classMirror.isSubtypeOf(transformerClass) &&
          !classMirror.isSubtypeOf(groupClass) &&
          (aggregateClass == null ||
              !classMirror.isSubtypeOf(aggregateClass))) {
        return null;
      }

      var constructor = _getConstructor(classMirror, 'asPlugin');
      if (constructor == null) return null;
      if (constructor.parameters.isEmpty) {
        if (configuration.isNotEmpty) return null;
        return classMirror.newInstance(const Symbol('asPlugin'), []).reflectee;
      }
      if (constructor.parameters.length != 1) return null;

      return classMirror.newInstance(const Symbol('asPlugin'),
          [new BarbackSettings(configuration, mode)]).reflectee;
    }).where((classMirror) => classMirror != null));
  }

  loadFromLibrary(mirrors.libraries[uri]);
  return transformers;
}

// TODO(nweiz): clean this up when issue 13248 is fixed.
MethodMirror _getConstructor(ClassMirror classMirror, String constructor) {
  var name = new Symbol("${MirrorSystem.getName(classMirror.simpleName)}"
      ".$constructor");
  var candidate = classMirror.declarations[name];
  if (candidate is MethodMirror && candidate.isConstructor) return candidate;
  return null;
}

// Older barbacks don't support [AggregateTransformer], and calling
// [reflectClass] on an undefined class will throw an error, so we just define a
// null getter for them.
//# if barback >=0.14.1
ClassMirror get _aggregateTransformerClass =>
    reflectClass(AggregateTransformer);
//# else
//>   ClassMirror get _aggregateTransformerClass => null;
//# end
