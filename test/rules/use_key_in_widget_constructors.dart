// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_key_in_widget_constructors`

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class NoConstructorWidget extends StatefulWidget { // LINT
}

class _PrivateWidget extends StatefulWidget { // OK
}

class MyWidget extends StatelessWidget {
  MyWidget(); // LINT
  MyWidget.withKey({Key key}) : super(key: key); // OK
  MyWidget.withUnusedKey({Key key}); // LINT
  factory MyWidget.fact() => null; // OK
  MyWidget._private(); // OK
  MyWidget.redirect() : this.withKey(key: Key('')); // OK
  MyWidget.superCall() : super(key: Key('')); // OK
}