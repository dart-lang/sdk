// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class P<T extends Object> {
  final Object token;

  const P._(this.token);
}

class CP<T extends Object> extends P<T> {
  const factory CP(Type type) = CP<T>._;

  const CP._(Object token) : super._(token);
}

class Token<T extends Object> {
  const Token();
}

class VP<T extends Object> extends P<T> {
  const factory VP.forToken(
    Token<T> token,
    T useValue,
  ) = VP<T>._;

  const VP._(
    Object token,
    T useValue,
  ) : super._(token);
}

class M {
  final List<P<Object>> list;

  const M({this.list = const []});
}
