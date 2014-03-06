// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/// Annotation used to automatically register polymer elements.
class CustomTag {
  final String tagName;
  const CustomTag(this.tagName);
}

/// Metadata used to label static or top-level methods that are called
/// automatically when loading the library of a custom element.
const initMethod = const InitMethodAnnotation();

/// Implementation behind [initMethod]. Only exposed for internal implementation
/// details
class InitMethodAnnotation {
  const InitMethodAnnotation();
}

/// Initializes a polymer application as follows:
///   * set up up polling for observable changes
///   * initialize Model-Driven Views
///   * Include some style to prevent flash of unstyled content (FOUC)
///   * for each library included transitively from HTML and HTML imports,
///   register custom elements declared there (labeled with [CustomTag]) and
///   invoke the initialization method on it (top-level functions annotated with
///   [initMethod]).
Zone initPolymer() => loader.deployMode
  // In deployment mode, we rely on change notifiers instead of dirty checking.
    ? _initPolymerOptimized() : (dirtyCheckZone()..run(_initPolymerOptimized));

/// Same as [initPolymer], but runs the version that is optimized for deployment
/// to the internet. The biggest difference is it omits the [Zone] that
/// automatically invokes [Observable.dirtyCheck], and the list of initializers
/// must be supplied instead of being dynamically searched for at runtime using
/// mirrors.
Zone _initPolymerOptimized() {
  _hookJsPolymer();

  for (var initializer in loader.initializers) {
    initializer();
  }

  return Zone.current;
}

/// Configures [initPolymer] making it optimized for deployment to the internet.
/// With this setup the initializer list is supplied instead of searched for
/// at runtime. Additionally, after this method is called [initPolymer] omits
/// the [Zone] that automatically invokes [Observable.dirtyCheck].
void configureForDeployment(List<Function> initializers) {
  loader.initializers = initializers;
  loader.deployMode = true;
}

/// To ensure Dart can interoperate with polymer-element registered by
/// polymer.js, we need to be able to execute Dart code if we are registering
/// a Dart class for that element. We trigger Dart logic by patching
/// polymer-element's register function and:
///
/// * if it has a Dart class, run PolymerDeclaration's register.
/// * otherwise it is a JS prototype, run polymer-element's normal register.
void _hookJsPolymer() {
  var polymerJs = js.context['Polymer'];
  if (polymerJs == null) {
    throw new StateError('polymer.js must be loaded before polymer.dart, please'
        ' add <link rel="import" href="packages/polymer/polymer.html"> to your'
        ' <head> before any Dart scripts. Alternatively you can get a different'
        ' version of polymer.js by following the instructions at'
        ' http://www.polymer-project.org; if you do that be sure to include'
        ' the platform polyfills.');
  }

  // TODO(jmesserly): dart:js appears to not callback in the correct zone:
  // https://code.google.com/p/dart/issues/detail?id=17301
  var zone = Zone.current;

  polymerJs.callMethod('whenPolymerReady',
      [zone.bindCallback(() => Polymer._ready.complete())]);

  var jsPolymer = new JsObject.fromBrowserObject(
      document.createElement('polymer-element'));

  var proto = js.context['Object'].callMethod('getPrototypeOf', [jsPolymer]);
  if (proto is Node) {
    proto = new JsObject.fromBrowserObject(proto);
  }

  JsFunction originalRegister = proto['register'];
  if (originalRegister == null) {
    throw new StateError('polymer.js must expose "register" function on '
        'polymer-element to enable polymer.dart to interoperate.');
  }

  registerDart(jsElem, String name, String extendee) {
    // By the time we get here, we'll know for sure if it is a Dart object
    // or not, because polymer-element will wait for us to notify that
    // the @CustomTag was found.
    final type = _getRegisteredType(name);
    if (type != null) {
      final extendsDecl = _getDeclaration(extendee);
      return zone.run(() =>
          new PolymerDeclaration(jsElem, name, type, extendsDecl).register());
    }
    // It's a JavaScript polymer element, fall back to the original register.
    return originalRegister.apply([name, extendee], thisArg: jsElem);
  }

  proto['register'] = new JsFunction.withThis(registerDart);
}
