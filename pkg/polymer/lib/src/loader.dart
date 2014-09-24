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
///   * if running in development mode, set up a dirty-checking zone that polls
///     for observable changes
///   * initialize template binding and polymer-element
///   * for each library included transitively from HTML and HTML imports,
///   register custom elements declared there (labeled with [CustomTag]) and
///   invoke the initialization method on it (top-level functions annotated with
///   [initMethod]).
Zone initPolymer() {
  _initializeLogging();
  if (loader.deployMode) {
    startPolymer(loader.initializers, loader.deployMode);
    return Zone.current;
  }
  return dirtyCheckZone()..run(
      () => startPolymer(loader.initializers, loader.deployMode));
}

/// True if we're in deployment mode.
bool _deployMode = false;

bool _startPolymerCalled = false;

/// Starts polymer by running all [initializers] and hooking the polymer.js
/// code. **Note**: this function is not meant to be invoked directly by
/// application developers. It is invoked either by [initPolymer] or, if you are
/// using the experimental bootstrap API, this would be invoked by an entry
/// point that is automatically generated somehow. In particular, during
/// development, the entry point would be generated dynamically in `boot.js`.
/// Similarly, pub-build would generate the entry point for deployment.
void startPolymer(List<Function> initializers, [bool deployMode = true]) {
  if (_startPolymerCalled) throw 'Initialization was already done.';
  _startPolymerCalled = true;
  _hookJsPolymer();
  _deployMode = deployMode;

  if (initializers == null) {
    throw 'Missing initialization of polymer elements. '
        'Please check that the list of entry points in your pubspec.yaml '
        'is correct. If you are using pub-serve, you may need to restart it.';
  }

  Polymer.registerSync('auto-binding-dart', AutoBindingElement,
      extendsTag: 'template');

  for (var initializer in initializers) {
    initializer();
  }

  _watchWaitingFor();
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
        ' http://www.polymer-project.org.');
  }

  // TODO(jmesserly): dart:js appears to not callback in the correct zone:
  // https://code.google.com/p/dart/issues/detail?id=17301
  var zone = Zone.current;

  polymerJs.callMethod('whenPolymerReady',
      [zone.bindCallback(() => Polymer._onReady.complete())]);

  JsFunction originalRegister = _polymerElementProto['register'];
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

  _polymerElementProto['register'] = new JsFunction.withThis(registerDart);
}

// Note: we cache this so we can use it later to look up 'init'.
// See registerSync.
JsObject _polymerElementProto = () {
  var polyElem = document.createElement('polymer-element');
  var proto = new JsObject.fromBrowserObject(polyElem)['__proto__'];
  if (proto is Node) proto = new JsObject.fromBrowserObject(proto);
  return proto;
}();

// Add support for the polymer js style of enabling logging. The global logging
// level is respected for specified loggers (see http://goo.gl/btfDe1). All
// other loggers will be set to [Level.OFF]. Logs will also be printed to the
// console automatically if any are supplied.
void _initializeLogging() {
  hierarchicalLoggingEnabled = true;
  var logFlags = js.context['logFlags'];
  if (logFlags == null) logFlags = {};
  var loggers =
      [_observeLog, _eventsLog, _unbindLog, _bindLog, _watchLog, _readyLog];
  var polymerLogger = new Logger('polymer');

  // If no loggers specified then disable globally and return.
  if (!loggers.any((logger) => logFlags[logger.name] == true)) {
    polymerLogger.level = Level.OFF;
    return;
  }

  // Disable the loggers that were not specified.
  loggers.where((logger) => logFlags[logger.name] != true)
      .forEach((logger) {logger.level = Level.OFF;});

  // Listen to the polymer logs and print them to the console.
  polymerLogger.onRecord.listen((rec) {print(rec);});
}

/// Watches the waitingFor queue and if it fails to make progress then prints
/// a message to the console.
void _watchWaitingFor() {
  int lastWaiting = Polymer.waitingFor.length;
  int lastAlert;
  new Timer.periodic(new Duration(seconds: 1), (Timer timer) {
    var waiting = Polymer.waitingFor;
    // Done, cancel timer.
    if (waiting.isEmpty) {
      timer.cancel();
      return;
    }
    // Made progress, don't alert.
    if (waiting.length != lastWaiting) {
      lastWaiting = waiting.length;
      return;
    }
    // Only alert once per waiting state.
    if (lastAlert == lastWaiting) return;
    lastAlert = lastWaiting;

    print('No elements registered in a while, but still waiting on '
        '${waiting.length} elements to be registered. Check that you have a '
        'class with an @CustomTag annotation for each of the following tags: '
        '${waiting.map((e) => "'${e.attributes['name']}'").join(', ')}');
  });
}
