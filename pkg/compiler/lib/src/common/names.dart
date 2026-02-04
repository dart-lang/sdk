// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library containing identifier, names, and selectors commonly used through
/// the compiler.
library;

import '../elements/names.dart' show Name, PublicName;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;

/// [String]s commonly used.
class Identifiers {
  /// The name of the call operator.
  static const String call = 'call';

  /// The name of the current element property used on iterators in for-each
  /// loops.
  static const String current = 'current';

  /// The name of the from environment constructors on 'int', 'bool' and
  /// 'String'.
  static const String fromEnvironment = 'fromEnvironment';

  /// The name of the iterator property used in for-each loops.
  static const String iterator = 'iterator';

  /// The name of the `loadLibrary` getter defined on deferred prefixes.
  static const String loadLibrary = 'loadLibrary';

  /// The name of the main method.
  static const String main = 'main';

  /// The name of the no such method handler on 'Object'.
  static const String noSuchMethod_ = 'noSuchMethod';

  /// The name of the runtime type property on 'Object'.
  static const String runtimeType_ = 'runtimeType';

  /// The name of the getter returning the size of containers and strings.
  static const String length = 'length';

  /// The name of the signature function in closure classes.
  static const String signature = ':signature';

  /// The name of the 'JS' foreign function.
  static const String js = 'JS';

  /// The name of the 'JS_BUILTIN' foreign function.
  static const String jsBuiltin = 'JS_BUILTIN';

  /// The name of the 'JS_EMBEDDED_GLOBAL' foreign function.
  static const String jsEmbeddedGlobal = 'JS_EMBEDDED_GLOBAL';

  /// The name of the 'JS_INTERCEPTOR_CONSTANT' foreign function.
  static const String jsInterceptorConstant = 'JS_INTERCEPTOR_CONSTANT';

  /// The name of the 'JS_STRING_CONCAT' foreign function.
  static const String jsStringConcat = 'JS_STRING_CONCAT';

  /// The name of the 'DART_CLOSURE_TO_JS' foreign function.
  static const String dartClosureToJS = 'DART_CLOSURE_TO_JS';

  /// The name of the 'RAW_DART_FUNCTION_REF' foreign function.
  static const String rawDartFunctionRef = 'RAW_DART_FUNCTION_REF';
}

/// [Name]s commonly used.
class Names {
  /// The name of the call operator.
  static const Name call = PublicName(Identifiers.call);

  /// The name of the current element property used on iterators in for-each
  /// loops.
  static const Name current = PublicName(Identifiers.current);

  /// The name of the dynamic type.
  static const Name dynamic_ = PublicName('dynamic');

  static const Name equalsName = PublicName("==");

  /// The name of the iterator property used in for-each loops.
  static const Name iterator = PublicName(Identifiers.iterator);

  /// The name of the move next method used on iterators in for-each loops.
  static const Name moveNext = PublicName('moveNext');

  /// The name of the no such method handler on 'Object'.
  static const Name noSuchMethod_ = PublicName(Identifiers.noSuchMethod_);

  /// The name of the to-string method on 'Object'.
  static const Name toString_ = PublicName('toString');

  static const Name indexName = PublicName("[]");
  static const Name indexSetName = PublicName("[]=");
  static const Name callName = Names.call;

  static const Name length = PublicName(Identifiers.length);

  static const Name runtimeType_ = PublicName(Identifiers.runtimeType_);

  static const Name genericInstantiation = PublicName('instantiate');

  /// The name of the signature function in closure classes.
  static const Name signature = PublicName(Identifiers.signature);
}

/// [Selector]s commonly used.
class Selectors {
  /// The selector for calling the cancel method on 'StreamIterator'.
  static final Selector cancel = Selector.call(
    const PublicName('cancel'),
    CallStructure.noArgs,
  );

  /// The selector for getting the current element property used in for-each
  /// loops.
  static final Selector current = Selector.getter(Names.current);

  /// The selector for getting the iterator property used in for-each loops.
  static final Selector iterator = Selector.getter(Names.iterator);

  /// The selector for calling the move next method used in for-each loops.
  static final Selector moveNext = Selector.call(
    Names.moveNext,
    CallStructure.noArgs,
  );

  /// The selector for calling the no such method handler on 'Object'.
  static final Selector noSuchMethod_ = Selector.call(
    Names.noSuchMethod_,
    CallStructure.oneArg,
  );

  /// The selector for tearing off noSuchMethod.
  static final Selector noSuchMethodGetter = Selector.getter(
    Names.noSuchMethod_,
  );

  /// The selector for calling the to-string method on 'Object'.
  static final Selector toString_ = Selector.call(
    Names.toString_,
    CallStructure.noArgs,
  );

  /// The selector for tearing off toString.
  static final Selector toStringGetter = Selector.getter(Names.toString_);

  static final Selector hashCode_ = Selector.getter(
    const PublicName('hashCode'),
  );

  static final Selector compareTo = Selector.call(
    const PublicName("compareTo"),
    CallStructure.oneArg,
  );

  static final Selector equals = Selector.binaryOperator('==');

  static final Selector length = Selector.getter(Names.length);

  static final Selector codeUnitAt = Selector.call(
    const PublicName('codeUnitAt'),
    CallStructure.oneArg,
  );

  static final Selector index = Selector.index();

  static final Selector runtimeType_ = Selector.getter(Names.runtimeType_);

  /// List of all the selectors held in static fields.
  ///
  /// These objects are shared between different runs in batch-mode and must
  /// thus remain in the [Selector.canonicalizedValues] map.
  static final List<Selector> all = <Selector>[
    cancel,
    current,
    iterator,
    moveNext,
    noSuchMethod_,
    noSuchMethodGetter,
    toString_,
    toStringGetter,
    hashCode_,
    compareTo,
    equals,
    length,
    codeUnitAt,
    index,
    runtimeType_,
  ];

  static final List<Selector> objectSelectors = <Selector>[
    toStringGetter,
    toString_,
    hashCode_,
    equals,
    runtimeType_,
  ];
}

/// [Uri]s commonly used.
class Uris {
  /// The URI for 'dart:async'.
  static final Uri dartAsync = Uri(scheme: 'dart', path: 'async');

  /// The URI for 'dart:collection'.
  static final Uri dartCollection = Uri(scheme: 'dart', path: 'collection');

  /// The URI for 'dart:core'.
  static final Uri dartCore = Uri(scheme: 'dart', path: 'core');

  /// The URI for 'dart:html'.
  static final Uri dartHtml = Uri(scheme: 'dart', path: 'html');

  /// The URI for 'dart:html_common'.
  static final Uri dartHtmlCommon = Uri(scheme: 'dart', path: 'html_common');

  /// The URI for 'dart:indexed_db'.
  static final Uri dartIndexedDB = Uri(scheme: 'dart', path: 'indexed_db');

  /// The URI for 'dart:isolate'.
  static final Uri dartIsolate = Uri(scheme: 'dart', path: 'isolate');

  /// The URI for 'dart:math'.
  static final Uri dartMath = Uri(scheme: 'dart', path: 'math');

  /// The URI for 'dart:mirrors'.
  static final Uri dartMirrors = Uri(scheme: 'dart', path: 'mirrors');

  /// The URI for 'dart:_internal'.
  static final Uri dartInternal = Uri(scheme: 'dart', path: '_internal');

  /// The URI for 'dart:_native_typed_data'.
  static final Uri dartNativeTypedData = Uri(
    scheme: 'dart',
    path: '_native_typed_data',
  );

  /// The URI for 'dart:typed_data'.
  static final Uri dartTypedData = Uri(scheme: 'dart', path: 'typed_data');

  /// The URI for 'dart:svg'.
  static final Uri dartSvg = Uri(scheme: 'dart', path: 'svg');

  /// The URI for 'dart:web_audio'.
  static final Uri dartWebAudio = Uri(scheme: 'dart', path: 'web_audio');

  /// The URI for 'dart:web_gl'.
  static final Uri dartWebGL = Uri(scheme: 'dart', path: 'web_gl');

  /// The URI for 'dart:_js_helper'.
  static final Uri dartJSHelper = Uri(scheme: 'dart', path: '_js_helper');

  /// The URI for 'dart:_late_helper'.
  static final Uri dartLateHelper = Uri(scheme: 'dart', path: '_late_helper');

  /// The URI for 'dart:_rti'.
  static final Uri dartRti = Uri(scheme: 'dart', path: '_rti');

  /// The URI for 'dart:_interceptors'.
  static final Uri dartInterceptors = Uri(
    scheme: 'dart',
    path: '_interceptors',
  );

  /// The URI for 'dart:_foreign_helper'.
  static final Uri dartForeignHelper = Uri(
    scheme: 'dart',
    path: '_foreign_helper',
  );

  /// The URI for 'dart:_js_names'.
  static final Uri dartJSNames = Uri(scheme: 'dart', path: '_js_names');

  /// The URI for 'dart:_js_embedded_names'.
  static final Uri dartJSEmbeddedNames = Uri(
    scheme: 'dart',
    path: '_js_embedded_names',
  );

  /// The URI for 'dart:_js_shared_embedded_names'.
  static final Uri dartJSSharedEmbeddedNames = Uri(
    scheme: 'dart',
    path: '_js_shared_embedded_names',
  );

  /// The URI for 'dart:js_util'.
  static final Uri dartJSUtil = Uri(scheme: 'dart', path: 'js_util');

  /// The URI for 'package:js'.
  static final Uri packageJS = Uri(scheme: 'package', path: 'js/js.dart');

  /// The URI for 'dart:_js_annotations'.
  static final Uri dartJSAnnotations = Uri(
    scheme: 'dart',
    path: '_js_annotations',
  );

  /// The URI for 'dart:js_interop'.
  static final Uri dartJSInterop = Uri(scheme: 'dart', path: 'js_interop');

  /// The URI for 'package:meta/dart2js.dart'.
  static final Uri packageMetaDart2js = Uri(
    scheme: 'package',
    path: 'meta/dart2js.dart',
  );

  /// The URI for 'package:meta/meta.dart'.
  static final Uri packageMeta = Uri(scheme: 'package', path: 'meta/meta.dart');
}
