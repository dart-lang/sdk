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

/// This method is deprecated. It used to be where polymer initialization
/// happens, now this is done automatically from bootstrap.dart.
@deprecated
Zone initPolymer() {
  window.console.error(_ERROR);
  return Zone.current;
}

const _ERROR = '''
initPolymer is now deprecated. To initialize a polymer app:
  * add to your page: <link rel="import" href="packages/polymer/polymer.html">
  * replace "application/dart" mime-types with "application/dart;component=1"
  * if you use "init.dart", remove it
  * if you have a main, change it into a method annotated with @initMethod
''';

/// True if we're in deployment mode.
bool _deployMode = false;

/// Starts polymer by running all [initializers] and hooking the polymer.js
/// code. **Note**: this function is not meant to be invoked directly by
/// application developers. It is invoked by a bootstrap entry point that is
/// automatically generated. During development, this entry point is generated
/// dynamically in `boot.js`. Similarly, pub-build generates this entry point
/// for deployment.
void startPolymer(List<Function> initializers, [bool deployMode = true]) {
  _hookJsPolymer();
  _deployMode = deployMode;

  for (var initializer in initializers) {
    initializer();
  }
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

  var polyElem = document.createElement('polymer-element');
  var proto = new JsObject.fromBrowserObject(polyElem)['__proto__'];
  if (proto is Node) proto = new JsObject.fromBrowserObject(proto);

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
