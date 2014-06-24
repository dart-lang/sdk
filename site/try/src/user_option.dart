// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.userOption;

/// Persistent user-configurable option.
///
/// Options included in [options] in settings.dart will automatically be
/// included in the settings UI unless [isHidden] is true.
///
/// The value of an option is persisted in [storage] which is normally the
/// browser's "localStorage", and [name] is a key in "localStorage".  This
/// means that hidden options can be controlled by opening the JavaScript
/// console and evaluate:
///
///   localStorage['name'] = value // or
///   localStorage.name = value
///
/// An option can be reset to the default value using:
///
///   delete localStorage['name'] // or
///   delete localStorage.name
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
