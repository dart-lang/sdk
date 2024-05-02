// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=macros

import 'package:json/json.dart';
import 'package:test/test.dart';

void main() {
  group('Can be encoded and decoded', () {
    test('without nullable fields', () {
      var userJson = {
        'name': 'John',
        'age': 35,
      };

      var user = User.fromJson(userJson);
      expect(user.name, 'John');
      expect(user.age, 35);
      expect(user.friends, null);
      expect(userJson, equals(user.toJson()));
    });

    test('with nullable fields', () {
      var userJson = {
        'name': 'John',
        'age': 35,
        'friends': [
          {
            'name': 'Jill',
            'age': 28,
          },
        ],
      };

      var user = User.fromJson(userJson);
      expect(user.name, 'John');
      expect(user.age, 35);
      expect(user.friends?.length, 1);

      var friend = user.friends!.single;
      expect(friend.name, 'Jill');
      expect(friend.age, 28);
      expect(userJson, equals(user.toJson()));
    });
  });
}

@JsonCodable()
class User {
  String name;

  int age;

  List<User>? friends;
}
