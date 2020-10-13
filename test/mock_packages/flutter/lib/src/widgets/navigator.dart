// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

class Navigator extends StatefulWidget {
  static NavigatorState of(
      BuildContext context, {
        bool rootNavigator = false,
        bool nullOk = false,
      }) => null;
}

class NavigatorState extends State<Navigator> {
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(
      String routeName, {
        Object? arguments,
      }) => null;
}
