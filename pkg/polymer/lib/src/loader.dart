// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

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
 *   * initialize Model-Driven Views
 *   * Include some style to prevent flash of unstyled content (FOUC)
 *   * for each library in [libraries], register custom elements labeled with
 *      [CustomTag] and invoke the initialization method on it. If [libraries]
 *      is null, first find all libraries that need to be loaded by scanning for
 *      HTML imports in the main document.
 *
 * The initialization on each library is a top-level function and annotated with
 * [initMethod].
 *
 * The urls in [libraries] can be absolute or relative to
 * `currentMirrorSystem().isolate.rootLibrary.uri`.
 */
void initPolymer([List<String> libraries]) {
  // Note: we synchronously load all libraries because the script invoking
  // this is run after all HTML imports are resolved.
  if (libraries == null) {
    libraries = _discoverScripts(document, window.location.href);
  }
  dirtyCheckZone().run(() => initPolymerOptimized(libraries));
}

/**
 * Same as [initPolymer], but runs the version that is optimized for deployment
 * to the internet. The biggest difference is it omits the [Zone] that
 * automatically invokes [Observable.dirtyCheck], and the list of libraries must
 * be supplied instead of being dynamically searched for at runtime.
 */
// TODO(jmesserly): change the Polymer build step to call this directly.
void initPolymerOptimized(List<String> libraries) {
  preventFlashOfUnstyledContent();

  // TODO(jmesserly): mdv should use initMdv instead of mdv.initialize.
  mdv.initialize();
  document.register(PolymerDeclaration._TAG, PolymerDeclaration);

  _loadLibraries(libraries);
}

void _loadLibraries(libraries) {
  for (var lib in libraries) {
    try {
      _loadLibrary(lib);
    } catch (e, s) {
      // Deliver errors async, so if a single library fails it doesn't prevent
      // other things from loading.
      new Completer().completeError(e, s);
    }
  }

  customElementsReady.then((_) => Polymer._ready.complete());
}

/**
 * Walks the HTML import structure to discover all script tags that are
 * implicitly loaded.
 */
List<String> _discoverScripts(Document doc, String baseUri,
    [Set<Document> seen, List<String> scripts]) {
  if (seen == null) seen = new Set<Document>();
  if (scripts == null) scripts = <String>[];
  if (seen.contains(doc)) return scripts;
  seen.add(doc);

  var inlinedScriptCount = 0;
  for (var node in doc.queryAll('script,link[rel="import"]')) {
    if (node is LinkElement) {
      _discoverScripts(node.import, node.href, seen, scripts);
    } else if (node is ScriptElement && node.type == 'application/dart') {
      var url = node.src;
      if (url != '') {
        // TODO(sigmund): consider either normalizing package: urls or add a
        // warning to let users know about cannonicalization issues.
        scripts.add(url);
      } else {
        // We generate a unique identifier for inlined scripts which we later
        // translate to the unique identifiers used by Dartium. Dartium uses
        // line/column number information which we can't compute here.
        scripts.add('$baseUri:$inlinedScriptCount');
        inlinedScriptCount++;
      }
    }
  }
  return scripts;
}

/** All libraries in the current isolate. */
final _libs = currentMirrorSystem().libraries;

// TODO(sigmund): explore other (cheaper) ways to resolve URIs relative to the
// root library (see dartbug.com/12612)
final _rootUri = currentMirrorSystem().isolate.rootLibrary.uri;

/** Regex that matches urls used to represent inlined scripts. */
final RegExp _inlineScriptRegExp = new RegExp('\(.*\.html.*\):\([0-9]\+\)');

/**
 * Map URLs fabricated by polymer to URLs fabricated by Dartium to represent
 * inlined scripts. Polymer uses baseUri:script#, Dartium uses baseUri:line#
 */
// TODO(sigmund): figure out if we can generate the same URL and expose it.
final Map<Uri, List<Uri>> _inlinedScriptMapping = () {
  var map = {};
  for (var uri in _libs.keys) {
    var uriString = uri.toString();
    var match = _inlineScriptRegExp.firstMatch(uriString);
    if (match == null) continue;
    var baseUri = Uri.parse(match.group(1));
    if (map[baseUri] == null) map[baseUri] = [];
    map[baseUri].add(uri);
  }
  return map;
}();

/** Returns a new Uri that replaces [path] in [uri]. */
Uri _replacePath(Uri uri, String path) {
  return new Uri(scheme: uri.scheme, host: uri.host, port: uri.port,
      path: path, query: uri.query, fragment: uri.fragment);
}

/** Returns the Uri in [href] without query parameters or fragments. */
String _baseUri(String href) {
  var uri = Uri.parse(window.location.href);
  var trimUri = new Uri(scheme: uri.scheme, host: uri.host,
      port: uri.port, path: uri.path);
  return trimUri.toString();
}

/**
 * Reads the library at [uriString] (which can be an absolute URI or a relative
 * URI from the root library), and:
 *
 *   * If present, invokes any top-level and static functions marked
 *     with the [initMethod] annotation (in the order they appear).
 *
 *   * Registers any [PolymerElement] that is marked with the [CustomTag]
 *     annotation.
 */
void _loadLibrary(String uriString) {
  var uri = _rootUri.resolve(uriString);
  var lib;
  var match = _inlineScriptRegExp.firstMatch(uriString);
  if (match != null) {
    var baseUri = Uri.parse(match.group(1));
    var list = _inlinedScriptMapping[baseUri];
    var pos = int.parse(match.group(2), onError: (_) => -1);
    if (list != null && pos >= 0 && pos < list.length && list[pos] != null) {
      lib = _libs[list[pos]];
    }
  } else {
    lib = _libs[uri];
  }
  if (lib == null) {
    print('warning: $uri library not found');
    return;
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
        Polymer.register(meta.tagName, getReflectedTypeWorkaround(c));
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
