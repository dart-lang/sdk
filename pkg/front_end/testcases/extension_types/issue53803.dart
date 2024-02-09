// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

class Class<X> {}
extension type ExtensionType<X>(Object? foo) {}

extension type E1<X>(Class<Never> foo) implements Class<Function(X)> {} // Error.
extension type E2<X>(Class<Never> foo) implements Class<Function(Function(X))> {} // Ok.
extension type E3<X>(Class<Never> foo) implements Class<Function(Function(Function(X)))> {} // Error.
extension type E4<X>(Class<Never> foo) implements Class<X Function(X)> {} // Error.
extension type E5<X>(Class<Never> foo) implements Class<X Function(Function(X))> {} // Ok.
extension type E6<X>(Class<Never> foo) implements Class<X Function(Function(Function(X)))> {} // Error.

extension type E7<X>(Object? foo) implements ExtensionType<Function(X)> {} // Error.
extension type E8<X>(Object? foo) implements ExtensionType<Function(Function(X))> {} // Ok.
extension type E9<X>(Object? foo) implements ExtensionType<Function(Function(Function(X)))> {} // Error.
extension type E10<X>(Object? foo) implements ExtensionType<X Function(X)> {} // Error.
extension type E11<X>(Object? foo) implements ExtensionType<X Function(Function(X))> {} // Ok.
extension type E12<X>(Object? foo) implements ExtensionType<X Function(Function(Function(X)))> {} // Error.
