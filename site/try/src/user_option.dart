// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.userOption;

class UserOption {
  final String name;

  final bool isHidden;

  static var storage;

  const UserOption(this.name, {this.isHidden: false});

  get value => storage[name];

  void set value(newValue) {
    storage[name] = newValue;
  }
}

class BooleanUserOption extends UserOption {
  const BooleanUserOption(String name, {bool isHidden: false})
      : super(name, isHidden: isHidden);

  bool get value => super.value == 'true';

  void set value(bool newValue) {
    super.value = '$newValue';
  }
}

class StringUserOption extends UserOption {
  const StringUserOption(String name, {bool isHidden: false})
      : super(name, isHidden: isHidden);

  String get value => super.value == null ? '' : super.value;

  void set value(String newValue) {
    super.value = newValue;
  }
}
