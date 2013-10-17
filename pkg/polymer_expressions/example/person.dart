// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library person;

import 'package:observe/observe.dart';

class Person extends ChangeNotifier {
  String _firstName;
  String _lastName;
  List<String> _items;

  Person(this._firstName, this._lastName, this._items);

  String get firstName => _firstName;

  void set firstName(String value) {
    _firstName = notifyPropertyChange(#firstName, _firstName, value);
  }

  String get lastName => _lastName;

  void set lastName(String value) {
    _lastName = notifyPropertyChange(#lastName, _lastName, value);
  }

  String getFullName() => '$_firstName $_lastName';

  List<String> get items => _items;

  void set items(List<String> value) {
    _items = notifyPropertyChange(#items, _items, value);
  }

  String toString() => "Person(firstName: $_firstName, lastName: $_lastName)";
}
