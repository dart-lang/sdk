// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains logic to initialize polymer apps during development. This
/// implementation uses dart:mirrors to load each library as they are discovered
/// through HTML imports. This is only meant to be during development in
/// dartium, and the polymer transformers replace this implementation with
/// codege generation in the polymer-build steps.
library polymer.src.mirror_loader;

import 'dart:async';
import 'dart:html';
import 'dart:collection' show LinkedHashMap;

// Technically, we shouldn't need any @MirrorsUsed, since this is for
// development only, but our test bots don't yet run pub-build. See more details
// on the comments of the mirrors import in `lib/polymer.dart`.
@MirrorsUsed(metaTargets:
    const [CustomTag, InitMethodAnnotation],
    override: const ['smoke.mirrors', 'polymer.src.mirror_loader'])
import 'dart:mirrors';

import 'package:logging/logging.dart' show Logger;
import 'package:polymer/polymer.dart' show
    InitMethodAnnotation, CustomTag, initMethod, Polymer;


/// Set of initializers that are invoked by `initPolymer`.  This is computed the
/// list by crawling HTML imports, searching for script tags, and including an
/// initializer for each type tagged with a [CustomTag] annotation and for each
/// top-level method annotated with [initMethod].
List<Function> initializers = _discoverInitializers();

/// True if we're in deployment mode.
bool deployMode = false;

/// Discovers what script tags are loaded from HTML pages and collects the
/// initializers of their corresponding libraries.
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

final Logger _loaderLog = new Logger('polymer.src.mirror_loader');

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


  // Dart note: we don't get back @CustomTags in a reliable order from mirrors,
  // at least on Dart VM. So we need to sort them so base classes are registered
  // first, which ensures that document.register will work correctly for a
  // set of types within in the same library.
  var customTags = new LinkedHashMap<Type, Function>();
  for (var c in lib.declarations.values.where((d) => d is ClassMirror)) {
    _loadCustomTags(lib, c, customTags);
    // TODO(sigmund): check also static methods marked with @initMethod.
    // This is blocked on two bugs:
    //  - dartbug.com/12133 (static methods are incorrectly listed as top-level
    //    in dart2js, so they end up being called twice)
    //  - dartbug.com/12134 (sometimes "method.metadata" throws an exception,
    //    we could wrap and hide those exceptions, but it's not ideal).
  }

  initializers.addAll(customTags.values);
}

void _loadCustomTags(LibraryMirror lib, ClassMirror cls,
    LinkedHashMap registerFns) {
  if (cls == null || cls.reflectedType == HtmlElement) return;

  // Register superclass first.
  _loadCustomTags(lib, cls.superclass, registerFns);

  if (cls.owner != lib) {
    // Don't register classes from different libraries.
    // TODO(jmesserly): @CustomTag does not currently respect re-export, because
    // LibraryMirror.declarations doesn't include these.
    return;
  }

  var meta = _getCustomTagMetadata(cls);
  if (meta == null) return;

  registerFns.putIfAbsent(cls.reflectedType, () =>
      () => Polymer.register(meta.tagName, cls.reflectedType));
}

/// Search for @CustomTag on a classemirror
CustomTag _getCustomTagMetadata(ClassMirror c) {
  for (var m in c.metadata) {
    var meta = m.reflectee;
    if (meta is CustomTag) return meta;
  }
  return null;
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
