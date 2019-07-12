// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

class Container extends StatelessWidget {
  final Widget child;
  Container({
    Key key,
    double width,
    double height,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => child;
}
