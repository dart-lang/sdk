// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

@JS('window')
external WindowContext get windowContext;

@JS('Error')
@staticInterop
abstract class WindowContext {}

extension WindowContextExtension on WindowContext {
  external bool? get $isInternalBuild;
  external bool? get $isFlutterApp;
  external String? get $dartAppId;
  external String? get $dartExtensionUri;
}

@JS('Array.from')
external JSArray _jsArrayFrom(JSAny any);

@JS('Object.values')
external JSArray _jsObjectValues(JSAny any);

@JS('Error')
@staticInterop
abstract class JsError {}

extension JsErrorExtension on JsError {
  external String get message;
  external String get stack;
}

@JS('Map')
@staticInterop
abstract class JsMap<K extends JSAny, V extends JSAny> {}

extension JsMapExtension<K extends JSAny, V extends JSAny> on JsMap<K, V> {
  external V? get(K key);
  external JSObject keys();
}

extension JSObjectExtension on JSObject {
  Iterable<Object?> get values => _jsObjectValues(this).toDartIterable();
}

extension JSArrayExtension on JSArray {
  Iterable<T> toDartIterable<T>() => toDart.map((e) => e.dartify() as T);

  List<T> toDartList<T>() => toDartIterable<T>().toList();
}

extension ModuleDependencyGraph on JsMap<JSString, JSArray> {
  Iterable<String> get modules => _jsArrayFrom(keys()).toDartIterable();

  List<String> parents(String key) => get(key.toJS)?.toDartList() ?? [];
}
