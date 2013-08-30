// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library exports all of the commonly used functions and types for
 * building UI's.
 *
 * See this article for more information:
 * <http://www.dartlang.org/articles/dart-web-components/>.
 */
library polymer;

import 'dart:async';
import 'dart:mirrors';

import 'package:mdv/mdv.dart' as mdv;
import 'package:observe/src/microtask.dart';
import 'package:path/path.dart' as path;
import 'polymer_element.dart' show registerPolymerElement;

export 'package:custom_element/custom_element.dart';
export 'package:observe/observe.dart';
export 'package:observe/html.dart';
export 'package:observe/src/microtask.dart';

export 'polymer_element.dart';


/** Annotation used to automatically register polymer elements. */
class CustomTag {
  final String tagName;
  const CustomTag(this.tagName);
}

/**
 * Metadata used to label static or top-level methods that are called
 * automatically when loading the library of a custom element.
 */
const initMethod = const _InitMethodAnnotation();

/**
 * Initializes a polymer application as follows:
 *   * set up up polling for observable changes
 *   *  initialize MDV
 *   *  for each library in [libraries], register custom elements labeled with
 *      [CustomTag] and invoke the initialization method on it.
 *
 * The initialization on each library is either a method named `main` or
 * a top-level function and annotated with [initMethod].
 *
 * The urls in [libraries] can be absolute or relative to [srcUrl].
 */
void initPolymer(List<String> libraries, [String srcUrl]) {
  wrapMicrotask(() {
    // DOM events don't yet go through microtasks, so we catch those here.
    new Timer.periodic(new Duration(milliseconds: 125),
        (_) => performMicrotaskCheckpoint());

    // TODO(jmesserly): mdv should use initMdv instead of mdv.initialize.
    mdv.initialize();
    for (var lib in libraries) {
      _loadLibrary(lib, srcUrl);
    }
  })();
}

/** All libraries in the current isolate. */
final _libs = currentMirrorSystem().libraries;

/**
 * Reads the library at [uriString] (which can be an absolute URI or a relative
 * URI from [srcUrl]), and:
 *
 *   * If present, invokes `main`.
 *
 *   * If present, invokes any top-level and static functions marked
 *     with the [initMethod] annotation (in the order they appear).
 *
 *   * Registers any [PolymerElement] that is marked with the [CustomTag]
 *     annotation.
 */
void _loadLibrary(String uriString, [String srcUrl]) {
  var uri = Uri.parse(uriString);
  if (uri.scheme == '' && srcUrl != null) {
    uri = Uri.parse(path.normalize(path.join(path.dirname(srcUrl), uriString)));
  }
  var lib = _libs[uri];
  if (lib == null) {
    print('warning: $uri library not found');
    return;
  }

  // Invoke `main`, if present.
  if (lib.functions[const Symbol('main')] != null) {
    lib.invoke(const Symbol('main'), const []);
  }

  // Search top-level functions marked with @initMethod
  for (var f in lib.functions.values) {
    _maybeInvoke(lib, f);
  }

  for (var c in lib.classes.values) {
    // Search for @CustomTag on classes
    for (var m in c.metadata) {
      var meta = m.reflectee;
      if (meta is CustomTag) {
        registerPolymerElement(meta.tagName,
            () => c.newInstance(const Symbol(''), const []).reflectee);
      }
    }

    // TODO(sigmund): check also static methods marked with @initMethod.
    // This is blocked on two bugs:
    //  - dartbug.com/12133 (static methods are incorrectly listed as top-level
    //    in dart2js, so they end up being called twice)
    //  - dartbug.com/12134 (sometimes "method.metadata" throws an exception,
    //    we could wrap and hide those exceptions, but it's not ideal).
  }
}

void _maybeInvoke(ObjectMirror obj, MethodMirror method) {
  var annotationFound = false;
  for (var meta in method.metadata) {
    if (identical(meta.reflectee, initMethod)) {
      annotationFound = true;
      break;
    }
  }
  if (!annotationFound) return;
  if (!method.isStatic) {
    print("warning: methods marked with @initMethod should be static,"
        " ${method.simpleName} is not.");
    return;
  }
  if (!method.parameters.where((p) => !p.isOptional).isEmpty) {
    print("warning: methods marked with @initMethod should take no "
        "arguments, ${method.simpleName} expects some.");
    return;
  }
  obj.invoke(method.simpleName, const []);
}

class _InitMethodAnnotation {
  const _InitMethodAnnotation();
}
