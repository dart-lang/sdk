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
const initMethod = const _InitMethodAnnotation();

/// Initializes a polymer application as follows:
///   * set up up polling for observable changes
///   * initialize Model-Driven Views
///   * Include some style to prevent flash of unstyled content (FOUC)
///   * for each library included transitively from HTML and HTML imports,
///   register custom elements declared there (labeled with [CustomTag]) and
///   invoke the initialization method on it (top-level functions annotated with
///   [initMethod]).
Zone initPolymer() {
  // We use this pattern, and not the inline lazy initialization pattern, so we
  // can help dart2js detect that _discoverInitializers can be tree-shaken for
  // deployment (and hence all uses of dart:mirrors from this loading logic).
  // TODO(sigmund): fix polymer's transformers so they can replace initPolymer
  // by initPolymerOptimized.
  if (_initializers == null) _initializers = _discoverInitializers();

  // In deployment mode, we rely on change notifiers instead of dirty checking.
  if (!_deployMode) {
    return dirtyCheckZone()..run(initPolymerOptimized);
  }

  return initPolymerOptimized();
}

/// Same as [initPolymer], but runs the version that is optimized for deployment
/// to the internet. The biggest difference is it omits the [Zone] that
/// automatically invokes [Observable.dirtyCheck], and the list of initializers
/// must be supplied instead of being dynamically searched for at runtime using
/// mirrors.
Zone initPolymerOptimized() {
  // TODO(sigmund): refactor this so we can replace it by codegen.
  smoke.useMirrors();
  // TODO(jmesserly): there is some code in src/declaration/polymer-element.js,
  // git version 37eea00e13b9f86ab21c85a955585e8e4237e3d2, right before
  // it registers polymer-element, which uses Platform.deliverDeclarations to
  // coordinate with HTML Imports. I don't think we need it so skipping.
  document.register(PolymerDeclaration._TAG, PolymerDeclaration);

  for (var initializer in _initializers) {
    initializer();
  }

  // Run this after user code so they can add to Polymer.veiledElements
  _preventFlashOfUnstyledContent();

  customElementsReady.then((_) => Polymer._ready.complete());
  return Zone.current;
}

/// Configures [initPolymer] making it optimized for deployment to the internet.
/// With this setup the initializer list is supplied instead of searched for
/// at runtime. Additionally, after this method is called [initPolymer] omits
/// the [Zone] that automatically invokes [Observable.dirtyCheck].
void configureForDeployment(List<Function> initializers) {
  _initializers = initializers;
  _deployMode = true;
}

/// List of initializers that by default will be executed when calling
/// initPolymer. If null, initPolymer will compute the list of initializers by
/// crawling HTML imports, searchfing for script tags, and including an
/// initializer for each type tagged with a [CustomTag] annotation and for each
/// top-level method annotated with [initMethod]. The value of this field is
/// assigned programatically by the code generated from the polymer deploy
/// scripts.
List<Function> _initializers;

/// True if we're in deployment mode.
bool _deployMode = false;

List<Function> _discoverInitializers() {
  var initializers = [];
  var librariesToLoad = _discoverScripts(document, window.location.href);
  for (var lib in librariesToLoad) {
    try {
      _loadLibrary(lib, initializers);
    } catch (e, s) {
      // Deliver errors async, so if a single library fails it doesn't prevent
      // other things from loading.
      new Completer().completeError(e, s);
    }
  }
  return initializers;
}

/// Walks the HTML import structure to discover all script tags that are
/// implicitly loaded. This code is only used in Dartium and should only be
/// called after all HTML imports are resolved. Polymer ensures this by asking
/// users to put their Dart script tags after all HTML imports (this is checked
/// by the linter, and Dartium will otherwise show an error message).
List<String> _discoverScripts(Document doc, String baseUri,
    [Set<Document> seen, List<String> scripts]) {
  if (seen == null) seen = new Set<Document>();
  if (scripts == null) scripts = <String>[];
  if (doc == null) {
    print('warning: $baseUri not found.');
    return scripts;
  }
  if (seen.contains(doc)) return scripts;
  seen.add(doc);

  bool scriptSeen = false;
  for (var node in doc.querySelectorAll('script,link[rel="import"]')) {
    if (node is LinkElement) {
      _discoverScripts(node.import, node.href, seen, scripts);
    } else if (node is ScriptElement && node.type == 'application/dart') {
      if (!scriptSeen) {
        var url = node.src;
        scripts.add(url == '' ? baseUri : url);
        scriptSeen = true;
      } else {
        print('warning: more than one Dart script tag in $baseUri. Dartium '
            'currently only allows a single Dart script tag per document.');
      }
    }
  }
  return scripts;
}

/// All libraries in the current isolate.
final _libs = currentMirrorSystem().libraries;

// TODO(sigmund): explore other (cheaper) ways to resolve URIs relative to the
// root library (see dartbug.com/12612)
final _rootUri = currentMirrorSystem().isolate.rootLibrary.uri;

final Logger _loaderLog = new Logger('polymer.loader');

bool _isHttpStylePackageUrl(Uri uri) {
  var uriPath = uri.path;
  return uri.scheme == _rootUri.scheme &&
      // Don't process cross-domain uris.
      uri.authority == _rootUri.authority &&
      uriPath.endsWith('.dart') &&
      (uriPath.contains('/packages/') || uriPath.startsWith('packages/'));
}

/// Reads the library at [uriString] (which can be an absolute URI or a relative
/// URI from the root library), and:
///
///   * If present, invokes any top-level and static functions marked
///     with the [initMethod] annotation (in the order they appear).
///
///   * Registers any [PolymerElement] that is marked with the [CustomTag]
///     annotation.
void _loadLibrary(String uriString, List<Function> initializers) {
  var uri = _rootUri.resolve(uriString);
  var lib = _libs[uri];
  if (_isHttpStylePackageUrl(uri)) {
    // Use package: urls if available. This rule here is more permissive than
    // how we translate urls in polymer-build, but we expect Dartium to limit
    // the cases where there are differences. The polymer-build issues an error
    // when using packages/ inside lib without properly stepping out all the way
    // to the packages folder. If users don't create symlinks in the source
    // tree, then Dartium will also complain because it won't find the file seen
    // in an HTML import.
    var packagePath = uri.path.substring(
        uri.path.lastIndexOf('packages/') + 'packages/'.length);
    var canonicalLib = _libs[Uri.parse('package:$packagePath')];
    if (canonicalLib != null) {
      lib = canonicalLib;
    }
  }

  if (lib == null) {
    _loaderLog.info('$uri library not found');
    return;
  }

  // Search top-level functions marked with @initMethod
  for (var f in lib.declarations.values.where((d) => d is MethodMirror)) {
    _addInitMethod(lib, f, initializers);
  }

  for (var c in lib.declarations.values.where((d) => d is ClassMirror)) {
    // Search for @CustomTag on classes
    for (var m in c.metadata) {
      var meta = m.reflectee;
      if (meta is CustomTag) {
        initializers.add(() => Polymer.register(meta.tagName, c.reflectedType));
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

void _addInitMethod(ObjectMirror obj, MethodMirror method,
    List<Function> initializers) {
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
  initializers.add(() => obj.invoke(method.simpleName, const []));
}

class _InitMethodAnnotation {
  const _InitMethodAnnotation();
}
