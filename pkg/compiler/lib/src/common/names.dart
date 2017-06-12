// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library containing identifier, names, and selectors commonly used through
/// the compiler.
library dart2js.common.names;

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
}

/// [Name]s commonly used.
class Names {
  /// The name of the call operator.
  static const Name call = const PublicName(Identifiers.call);

  /// The name of the current element property used on iterators in for-each
  /// loops.
  static const Name current = const PublicName(Identifiers.current);

  /// The name of the dynamic type.
  static const Name dynamic_ = const PublicName('dynamic');

  /// The name of the iterator property used in for-each loops.
  static const Name iterator = const PublicName(Identifiers.iterator);

  /// The name of the move next method used on iterators in for-each loops.
  static const Name moveNext = const PublicName('moveNext');

  /// The name of the no such method handler on 'Object'.
  static const Name noSuchMethod_ = const PublicName(Identifiers.noSuchMethod_);

  /// The name of the to-string method on 'Object'.
  static const Name toString_ = const PublicName('toString');

  static const Name INDEX_NAME = const PublicName("[]");
  static const Name INDEX_SET_NAME = const PublicName("[]=");
  static const Name CALL_NAME = Names.call;

  static const Name length = const PublicName(Identifiers.length);

  static const Name runtimeType_ = const PublicName(Identifiers.runtimeType_);
}

/// [Selector]s commonly used.
class Selectors {
  /// The selector for calling the cancel method on 'StreamIterator'.
  static final Selector cancel =
      new Selector.call(const PublicName('cancel'), CallStructure.NO_ARGS);

  /// The selector for getting the current element property used in for-each
  /// loops.
  static final Selector current = new Selector.getter(Names.current);

  /// The selector for getting the iterator property used in for-each loops.
  static final Selector iterator = new Selector.getter(Names.iterator);

  /// The selector for calling the move next method used in for-each loops.
  static final Selector moveNext =
      new Selector.call(Names.moveNext, CallStructure.NO_ARGS);

  /// The selector for calling the no such method handler on 'Object'.
  static final Selector noSuchMethod_ =
      new Selector.call(Names.noSuchMethod_, CallStructure.ONE_ARG);

  /// The selector for tearing off noSuchMethod.
  static final Selector noSuchMethodGetter =
      new Selector.getter(Names.noSuchMethod_);

  /// The selector for calling the to-string method on 'Object'.
  static final Selector toString_ =
      new Selector.call(Names.toString_, CallStructure.NO_ARGS);

  /// The selector for tearing off toString.
  static final Selector toStringGetter = new Selector.getter(Names.toString_);

  static final Selector hashCode_ =
      new Selector.getter(const PublicName('hashCode'));

  static final Selector compareTo =
      new Selector.call(const PublicName("compareTo"), CallStructure.ONE_ARG);

  static final Selector equals = new Selector.binaryOperator('==');

  static final Selector length = new Selector.getter(Names.length);

  static final Selector codeUnitAt =
      new Selector.call(const PublicName('codeUnitAt'), CallStructure.ONE_ARG);

  static final Selector index = new Selector.index();

  static final Selector runtimeType_ = new Selector.getter(Names.runtimeType_);

  /// List of all the selectors held in static fields.
  ///
  /// These objects are shared between different runs in batch-mode and must
  /// thus remain in the [Selector.canonicalizedValues] map.
  static final List<Selector> ALL = <Selector>[
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
    runtimeType_
  ];
}

/// [Uri]s commonly used.
class Uris {
  /// The URI for 'dart:async'.
  static final Uri dart_async = new Uri(scheme: 'dart', path: 'async');

  /// The URI for 'dart:collection'.
  static final Uri dart_collection =
      new Uri(scheme: 'dart', path: 'collection');

  /// The URI for 'dart:core'.
  static final Uri dart_core = new Uri(scheme: 'dart', path: 'core');

  /// The URI for 'dart:html'.
  static final Uri dart_html = new Uri(scheme: 'dart', path: 'html');

  /// The URI for 'dart:html_common'.
  static final Uri dart_html_common =
      new Uri(scheme: 'dart', path: 'html_common');

  /// The URI for 'dart:indexed_db'.
  static final Uri dart_indexed_db =
      new Uri(scheme: 'dart', path: 'indexed_db');

  /// The URI for 'dart:isolate'.
  static final Uri dart_isolate = new Uri(scheme: 'dart', path: 'isolate');

  /// The URI for 'dart:math'.
  static final Uri dart_math = new Uri(scheme: 'dart', path: 'math');

  /// The URI for 'dart:mirrors'.
  static final Uri dart_mirrors = new Uri(scheme: 'dart', path: 'mirrors');

  /// The URI for 'dart:_internal'.
  static final Uri dart__internal = new Uri(scheme: 'dart', path: '_internal');

  /// The URI for 'dart:_native_typed_data'.
  static final Uri dart__native_typed_data =
      new Uri(scheme: 'dart', path: '_native_typed_data');

  /// The URI for 'dart:typed_data'.
  static final Uri dart_typed_data =
      new Uri(scheme: 'dart', path: 'typed_data');

  /// The URI for 'dart:svg'.
  static final Uri dart_svg = new Uri(scheme: 'dart', path: 'svg');

  /// The URI for 'dart:web_audio'.
  static final Uri dart_web_audio = new Uri(scheme: 'dart', path: 'web_audio');

  /// The URI for 'dart:web_gl'.
  static final Uri dart_web_gl = new Uri(scheme: 'dart', path: 'web_gl');

  /// The URI for 'dart:web_sql'.
  static final Uri dart_web_sql = new Uri(scheme: 'dart', path: 'web_sql');

  /// The URI for 'dart:_js_helper'.
  static final Uri dart__js_helper =
      new Uri(scheme: 'dart', path: '_js_helper');

  /// The URI for 'dart:_interceptors'.
  static final Uri dart__interceptors =
      new Uri(scheme: 'dart', path: '_interceptors');

  /// The URI for 'dart:_foreign_helper'.
  static final Uri dart__foreign_helper =
      new Uri(scheme: 'dart', path: '_foreign_helper');

  /// The URI for 'dart:_js_mirrors'.
  static final Uri dart__js_mirrors =
      new Uri(scheme: 'dart', path: '_js_mirrors');

  /// The URI for 'dart:_js_names'.
  static final Uri dart__js_names = new Uri(scheme: 'dart', path: '_js_names');

  /// The URI for 'dart:_js_embedded_names'.
  static final Uri dart__js_embedded_names =
      new Uri(scheme: 'dart', path: '_js_embedded_names');

  /// The URI for 'dart:_isolate_helper'.
  static final Uri dart__isolate_helper =
      new Uri(scheme: 'dart', path: '_isolate_helper');

  /// The URI for 'package:js'.
  static final Uri package_js = new Uri(scheme: 'package', path: 'js/js.dart');
}
