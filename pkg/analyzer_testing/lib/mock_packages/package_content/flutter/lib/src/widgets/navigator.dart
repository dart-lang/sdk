// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

class Navigator extends StatefulWidget {
  static NavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
  }) {}
}

class NavigatorState extends State<Navigator>
//with TickerProviderStateMixin, RestorationMixin
{
  void pop<T extends Object?>([T? result]) {}
}
