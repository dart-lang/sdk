// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class P {
  final String name = '';

  @override
  operator ==(other) {
    return other != null && //OK: https://github.com/dart-lang/linter/issues/2864
        other is P &&
        name == other.name;
  }
}

class P2 {
  final String name = '';

  @override
  operator ==(Object other) {
    return other != null && //OK: https://github.com/dart-lang/linter/issues/2864
        other is P2 &&
        name == other.name;
  }
}

class BadPerson1 {
  final String name = 'I am a bad person';

  get age => 42;

  @override
  operator ==(Object? other) =>
          other != null && // LINT
          other is BadPerson1 &&
          name == other.name;
}

class BadPerson2 {
  final String name = 'I am a bad person';

  @override
  operator ==(Object? other) =>
          !(other == null) && // LINT
          other is BadPerson2 &&
          name == other.name;
}

class BadPerson3 {
  final String name = 'I am a bad person';

  @override
  operator ==(Object? other) =>
          other is BadPerson3
              &&
          name == other?.name; // LINT
}

class BadPerson4 {
  final String name = 'I am a bad person';

  String getName() => name;

  @override
  operator ==(Object? other) =>
      other is BadPerson4
          &&
          name == other?.getName(); // LINT
}

class BadPerson5 {
  String name;

  BadPerson5(this.name);

  @override
  operator ==(Object? other) {
    if (other is BadPerson5){
      final toCompare = other ?? new BadPerson5(""); // LINT
      return toCompare.name == name;
    }
    return false;
  }

}

class GoodPerson {
  final String name = 'I am a good person';

  @override
  operator ==(other) => other is GoodPerson && name == other.name; // OK
}
