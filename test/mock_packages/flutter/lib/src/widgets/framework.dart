// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../foundation.dart';

typedef void VoidCallback();

abstract class BuildContext {
  Widget get widget;
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => null;

  T get widget => null;

  Widget build(BuildContext context) => null;

  void dispose() {}

  void setState(VoidCallback fn) {}
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({Key key}) : super(key: key);

  State createState() => null;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({Key key}) : super(key: key);

  Widget build(BuildContext context) => null;
}

class Widget {
  final Key key;

  const Widget({this.key});
}

abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  final Widget child;

  const SingleChildRenderObjectWidget({Key key, this.child}) : super(key: key);
}

abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget({Key key}) : super(key: key);
}
