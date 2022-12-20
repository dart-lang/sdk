// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.native_generator;

import 'package:js_runtime/synced/embedded_names.dart' as embeddedNames;

import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/backend_usage.dart' show BackendUsage;

class NativeGenerator {
  static bool needsIsolateAffinityTagInitialization(BackendUsage backendUsage) {
    return backendUsage.needToInitializeIsolateAffinityTag;
  }

  /// Generates the code for isolate affinity tags.
  ///
  /// Independently Dart programs on the same page must not interfere and
  /// this code sets up the variables needed to guarantee that behavior.
  static jsAst.Statement generateIsolateAffinityTagInitialization(
      BackendUsage backendUsage,
      jsAst.Expression generateEmbeddedGlobalAccess(String global),
      jsAst.Expression internStringFunction) {
    assert(backendUsage.needToInitializeIsolateAffinityTag);

    jsAst.Expression getIsolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_ISOLATE_TAG);
    jsAst.Expression isolateTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ISOLATE_TAG);
    jsAst.Expression dispatchPropertyNameAccess =
        generateEmbeddedGlobalAccess(embeddedNames.DISPATCH_PROPERTY_NAME);

    return js.statement('''
      !function() {
        var intern = #internStringFunction;

        #getIsolateTag = function(name) {
          return intern("___dart_" + name + #isolateTag);
        };

        // To ensure that different programs loaded into the same context (page)
        // use distinct dispatch properties, we place an object on `Object` to
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
    ''', {
      'initializeDispatchProperty':
          backendUsage.needToInitializeDispatchProperty,
      'internStringFunction': internStringFunction,
      'getIsolateTag': getIsolateTagAccess,
      'isolateTag': isolateTagAccess,
      'dispatchPropertyName': dispatchPropertyNameAccess
    });
  }

  static String generateIsolateTagRoot() {
    // TODO(sra): MD5 of contributing source code or URIs?
    return 'ZxYxX';
  }
}
