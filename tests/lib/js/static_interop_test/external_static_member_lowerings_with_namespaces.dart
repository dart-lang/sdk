// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Like `external_static_member_lowerings_test.dart`, but uses the namespaces
// in the `@JS` annotations instead.

@JS('library-1.library2')
library external_static_member_lowerings_with_namespaces_test;

import 'dart:js_interop';

@JS('library*3.ExternalStatic')
@staticInterop
class ExternalStatic {
  external factory ExternalStatic(String initialValue);
  external factory ExternalStatic.named([
    String initialValue = 'uninitialized',
  ]);
  // External redirecting factories are not allowed.

  external static String field;
  @JS('field')
  external static String renamedField;
  @JS('nested-field.foo.field')
  external static String nestedField;
  external static final String finalField;

  external static String get getSet;
  external static set getSet(String val);
  @JS('getSet')
  external static String get renamedGetSet;
  @JS('getSet')
  external static set renamedGetSet(String val);
  @JS('nestedGetSet.1.getSet')
  external static String get nestedGetSet;
  @JS('nestedGetSet.1.getSet')
  external static set nestedGetSet(String val);

  external static String method();
  @JS('method')
  external static String renamedMethod();
  @JS('nested^method.method')
  external static String nestedMethod();
}

extension ExternalStaticExtension on ExternalStatic {
  external String? get initialValue;
}

@JS('External-Static')
@staticInterop
class ExternalStaticRenamed implements ExternalStatic {
  external factory ExternalStaticRenamed();
}

// Top-level fields.
@JS('library*3.field')
external String field;
@JS('library*3.field')
external String renamedField;
@JS('library*3.nested-field.foo.field')
external String nestedField;
@JS('library*3.finalField')
external final String finalField;

// Top-level getters and setters.
@JS('library*3.getSet')
external String get getSet;
@JS('library*3.getSet')
external set getSet(String val);
@JS('library*3.getSet')
external String get renamedGetSet;
@JS('library*3.getSet')
external set renamedGetSet(String val);
@JS('library*3.nestedGetSet.1.getSet')
external String get nestedGetSet;
@JS('library*3.nestedGetSet.1.getSet')
external set nestedGetSet(String val);

// Top-level methods.
@JS('library*3.method')
external String method();
@JS('library*3.method')
external String renamedMethod();
@JS('library*3.nested^method.method')
external String nestedMethod();
