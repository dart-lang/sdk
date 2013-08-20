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
export 'package:observe/src/microtask.dart';

export 'observe.dart';
export 'observe_html.dart';
export 'polymer_element.dart';
export 'safe_html.dart';


/** Annotation used to automatically register polymer elements. */
class CustomTag {
  final String tagName;
  const CustomTag(this.tagName);
}

/**
 * Metadata used to label static or top-level methods that are called
 * automatically when loading the library of a custom element.
 */
const polymerInitMethod = const _InitPolymerAnnotation();

/**
 * Initializes a polymer application by: setting up polling for observable
 * changes, initializing MDV, registering and initializing custom elements from
 * each library in [elementLibraries], and finally invoking [userMain].
 *
 * There are two mechanisms by which custom elements can be initialized:
 * annotating the class that declares a custom element with [CustomTag] or
 * programatically registering the element in a static or top-level function and
 * annotating that function with [polymerInitMethod].
 *
 * The urls in [elementLibraries] can be absolute or relative to [srcUrl].
 */
void initPolymer(List<String> elementLibraries, void userMain(), [String srcUrl]) {
  wrapMicrotask(() {
    // DOM events don't yet go through microtasks, so we catch those here.
    new Timer.periodic(new Duration(milliseconds: 125),
        (_) => performMicrotaskCheckpoint());

    // TODO(jmesserly): mdv should use initMdv instead of mdv.initialize.
    mdv.initialize();
    for (var lib in elementLibraries) {
      _registerPolymerElementsOf(lib, srcUrl);
    }
    userMain();
  })();
}

/** All libraries in the current isolate. */
final _libs = currentMirrorSystem().libraries;

/**
 * Reads the library at [uriString] (which can be an absolute URI or a relative
 * URI from [srcUrl]), and:
 *
 *   * Invokes top-level and static functions marked with the
 *     [polymerInitMethod] annotation.
 *
 *   * Registers any [PolymerElement] that is marked with the [CustomTag]
 *     annotation.
 */
void _registerPolymerElementsOf(String uriString, [String srcUrl]) {
  var uri = Uri.parse(uriString);
  if (uri.scheme == '' && srcUrl != null) {
    uri = Uri.parse(path.normalize(path.join(path.dirname(srcUrl), uriString)));
  }
  var lib = _libs[uri];
  if (lib == null) {
    print('warning: $uri library not found');
    return;
  }

  // Search top-level functions marked with @polymerInitMethod
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

    // TODO(sigmund): check also static methods marked with @polymerInitMethod.
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
    if (identical(meta.reflectee, polymerInitMethod)) {
      annotationFound = true;
      break;
    }
  }
  if (!annotationFound) return;
  if (!method.isStatic) {
    print("warning: methods marked with @polymerInitMethod should be static,"
        " ${method.simpleName} is not.");
    return;
  }
  if (!method.parameters.where((p) => !p.isOptional).isEmpty) {
    print("warning: methods marked with @polymerInitMethod should take no "
        "arguments, ${method.simpleName} expects some.");
    return;
  }
  obj.invoke(method.simpleName, const []);
}

class _InitPolymerAnnotation {
  const _InitPolymerAnnotation();
}
