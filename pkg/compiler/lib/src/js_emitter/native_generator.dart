// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class NativeGenerator {

  static bool needsIsolateAffinityTagInitialization(JavaScriptBackend backend) {
    return backend.needToInitializeIsolateAffinityTag;
  }

  /// Generates the code for isolate affinity tags.
  ///
  /// Independently Dart programs on the same page must not interfer and
  /// this code sets up the variables needed to guarantee that behavior.
  static jsAst.Statement generateIsolateAffinityTagInitialization(
      JavaScriptBackend backend,
      jsAst.Expression generateEmbeddedGlobalAccess(String global),
      jsAst.Expression convertToFastObject) {
    assert(backend.needToInitializeIsolateAffinityTag);

    jsAst.Expression getIsolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_ISOLATE_TAG);
    jsAst.Expression isolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ISOLATE_TAG);
    jsAst.Expression dispatchPropertyNameAccess =
        generateEmbeddedGlobalAccess(embeddedNames.DISPATCH_PROPERTY_NAME);

    return js.statement('''
      !function() {
        // On V8, the 'intern' function converts a string to a symbol, which
        // makes property access much faster.
        function intern(s) {
          var o = {};
          o[s] = 1;
          return Object.keys(#convertToFastObject(o))[0];
        }

        #getIsolateTag = function(name) {
          return intern("___dart_" + name + #isolateTag);
        };

        // To ensure that different programs loaded into the same context (page)
        // use distinct dispatch properies, we place an object on `Object` to
        // contain the names already in use.
        var tableProperty = "___dart_isolate_tags_";
        var usedProperties = Object[tableProperty] ||
            (Object[tableProperty] = Object.create(null));

        var rootProperty = "_${generateIsolateTagRoot()}";
        for (var i = 0; ; i++) {
          var property = intern(rootProperty + "_" + i + "_");
          if (!(property in usedProperties)) {
            usedProperties[property] = 1;
            #isolateTag = property;
            break;
          }
        }
        if (#initializeDispatchProperty) {
          #dispatchPropertyName = #getIsolateTag("dispatch_record");
        }
      }();
    ''',
    {'initializeDispatchProperty': backend.needToInitializeDispatchProperty,
     'convertToFastObject': convertToFastObject,
     'getIsolateTag': getIsolateTagAccess,
     'isolateTag': isolateTagAccess,
     'dispatchPropertyName': dispatchPropertyNameAccess});
  }

  static String generateIsolateTagRoot() {
    // TODO(sra): MD5 of contributing source code or URIs?
    return 'ZxYxX';
  }
}
