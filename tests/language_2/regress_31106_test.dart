// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final schema = const UserSchema();
  Expect.equals('users', schema.name);
  final user = const User(first: 'firstname');
  var map = schema._decode(user);
  Expect.equals('firstname', map['first']);
}

class User {
  final String first;

  const User({
    this.first,
  });
}

class Schema<T> {
  final String name;
  final Map<String, Object> Function(T) _decode;

  const Schema({
    this.name,
    Map<String, Object> Function(T) decode,
  })
      : _decode = decode;
}

class UserSchema extends Schema<User> {
  static Map<String, Object> _decode$(User user) {
    return {
      'first': user.first,
    };
  }

  const UserSchema() : super(name: 'users', decode: _decode$);
}
