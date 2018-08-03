// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.native_generator;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;

import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/backend_usage.dart' show BackendUsage;

import 'model.dart';

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

  /// Encodes the collected native information so that it can be treated by
  /// the native info-handler below.
  ///
  /// The encoded information has the form:
  ///
  //    "%": "leafTag1|leafTag2|...;nonleafTag1|...;Class1|Class2|...",
  //
  // If there is no data following a semicolon, the semicolon can be omitted.
  static jsAst.Expression encodeNativeInfo(Class cls) {
    List<String> leafTags = cls.nativeLeafTags;
    List<String> nonLeafTags = cls.nativeNonLeafTags;
    List<Class> extensions = cls.nativeExtensions;

    String formatTags(Iterable<String> tags) {
      if (tags == null) return '';
      return (tags.toList()..sort()).join('|');
    }

    String leafStr = formatTags(leafTags);
    String nonLeafStr = formatTags(nonLeafTags);

    StringBuffer sb = new StringBuffer(leafStr);
    if (nonLeafStr != '') {
      sb..write(';')..write(nonLeafStr);
    }

    String encoding = sb.toString();

    if (cls.isNative || encoding != '' || extensions != null) {
      List<jsAst.Literal> parts = <jsAst.Literal>[js.stringPart(encoding)];
      if (extensions != null) {
        parts
          ..add(js.stringPart(';'))
          ..addAll(js.joinLiterals(
              extensions.map((Class cls) => cls.name), js.stringPart('|')));
      }
      return jsAst.concatenateStrings(parts, addQuotes: true);
    }
    return null;
  }

  /// Returns a JavaScript template that fills the embedded globals referenced
  /// by [interceptorsByTagAccess] and [leafTagsAccess].
  ///
  /// This code must be invoked for every class that has a native info before
  /// the program starts.
  ///
  /// The [infoAccess] parameter must evaluate to an expression that contains
  /// the info (as a JavaScript string).
  ///
  /// The [constructorAccess] parameter must evaluate to an expression that
  /// contains the constructor of the class. The constructor's prototype must
  /// be set up.
  ///
  /// The [subclassReadGenerator] function must evaluate to a JS expression
  /// that returns a reference to the constructor (with evaluated prototype)
  /// of the given JS expression.
  ///
  /// The [interceptorsByTagAccess] must point to the embedded global
  /// [embeddedNames.INTERCEPTORS_BY_TAG] and must be initialized with an empty
  /// JS Object (used as a map).
  ///
  /// Similarly, the [leafTagsAccess] must point to the embedded global
  /// [embeddedNames.LEAF_TAGS] and must be initialized with an empty JS Object
  /// (used as a map).
  ///
  /// Both variables are passed in (instead of creating the access here) to
  /// make sure the caller is aware of these globals.
  static jsAst.Statement buildNativeInfoHandler(
      jsAst.Expression infoAccess,
      jsAst.Expression constructorAccess,
      jsAst.Expression subclassReadGenerator(jsAst.Expression subclass),
      jsAst.Expression interceptorsByTagAccess,
      jsAst.Expression leafTagsAccess) {
    jsAst.Expression subclassRead =
        subclassReadGenerator(js('subclasses[i]', []));
    return js.statement('''
          // The native info looks like this:
          //
          // HtmlElement: {
          //     "%": "HTMLDivElement|HTMLAnchorElement;HTMLElement;FancyButton"
          //
          // The first two semicolon-separated parts contain dispatch tags, the
          // third contains the JavaScript names for classes.
          //
          // The tags indicate that JavaScript objects with the dispatch tags
          // (usually constructor names) HTMLDivElement, HTMLAnchorElement and
          // HTMLElement all map to the Dart native class named HtmlElement.
          // The first set is for effective leaf nodes in the hierarchy, the
          // second set is non-leaf nodes.
          //
          // The third part contains the JavaScript names of Dart classes that
          // extend the native class. Here, FancyButton extends HtmlElement, so
          // the runtime needs to know that window.HTMLElement.prototype is the
          // prototype that needs to be extended in creating the custom element.
          //
          // The information is used to build tables referenced by
          // getNativeInterceptor and custom element support.
          {
            var nativeSpec = #info.split(";");
            if (nativeSpec[0]) {
              var tags = nativeSpec[0].split("|");
              for (var i = 0; i < tags.length; i++) {
                #interceptorsByTagAccess[tags[i]] = #constructor;
                #leafTagsAccess[tags[i]] = true;
              }
            }
            if (nativeSpec[1]) {
              tags = nativeSpec[1].split("|");
              if (#allowNativesSubclassing) {
                if (nativeSpec[2]) {
                  var subclasses = nativeSpec[2].split("|");
                  for (var i = 0; i < subclasses.length; i++) {
                    var subclass = #subclassRead;
                    subclass.#nativeSuperclassTagName = tags[0];
                  }
                }
                for (i = 0; i < tags.length; i++) {
                  #interceptorsByTagAccess[tags[i]] = #constructor;
                  #leafTagsAccess[tags[i]] = false;
                }
              }
            }
          }
    ''', {
      'info': infoAccess,
      'constructor': constructorAccess,
      'subclassRead': subclassRead,
      'interceptorsByTagAccess': interceptorsByTagAccess,
      'leafTagsAccess': leafTagsAccess,
      'nativeSuperclassTagName': embeddedNames.NATIVE_SUPERCLASS_TAG_NAME,
      'allowNativesSubclassing': true
    });
  }
}
