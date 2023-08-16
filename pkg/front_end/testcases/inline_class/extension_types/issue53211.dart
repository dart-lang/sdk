// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET1(int id) {}

extension type ET2<T>(T id) {}

extension type ET3.new(int id) {}

extension type ET4<T>.new(T id) {}

extension type ET5.n(int id) {}

extension type ET6<T>.n(T id) {}

main() {
  ET1.new.expectStaticType<Exactly<ET1 Function(int)>>();
  ET2<String>.new.expectStaticType<Exactly<ET2<String> Function(String)>>();
  ET3.new.expectStaticType<Exactly<ET3 Function(int)>>();
  ET4<String>.new.expectStaticType<Exactly<ET4<String> Function(String)>>();
  ET5.n.expectStaticType<Exactly<ET5 Function(int)>>();
  ET6<String>.n.expectStaticType<Exactly<ET6<String> Function(String)>>();
}

extension StaticType<T> on T {
  T expectStaticType<R extends Exactly<T>>() {
    return this;
  }
}

typedef Exactly<T> = T Function(T);
