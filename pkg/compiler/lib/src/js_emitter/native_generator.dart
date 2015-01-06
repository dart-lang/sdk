// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class NativeGenerator {
  final Function generateEmbeddedGlobalAccess;

  NativeGenerator(this.generateEmbeddedGlobalAccess);

  /**
   * Emits code that sets the `isolateTag embedded global to a unique string.
   */
  jsAst.Expression generateIsolateAffinityTagInitialization() {
    jsAst.Expression getIsolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_ISOLATE_TAG);
    jsAst.Expression isolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ISOLATE_TAG);

    return js('''
      !function() {
        // On V8, the 'intern' function converts a string to a symbol, which
        // makes property access much faster.
        function intern(s) {
          var o = {};
          o[s] = 1;
          return Object.keys(convertToFastObject(o))[0];
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
      }()
    ''',
    {'getIsolateTag': getIsolateTagAccess, 'isolateTag': isolateTagAccess});
  }

  jsAst.Expression generateDispatchPropertyNameInitialization() {
    jsAst.Expression dispatchPropertyNameAccess =
        generateEmbeddedGlobalAccess(embeddedNames.DISPATCH_PROPERTY_NAME);
    jsAst.Expression getIsolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_ISOLATE_TAG);
    return js('# = #("dispatch_record")',
        [dispatchPropertyNameAccess,
         getIsolateTagAccess]);
  }

  String generateIsolateTagRoot() {
    // TODO(sra): MD5 of contributing source code or URIs?
    return 'ZxYxX';
  }
}
