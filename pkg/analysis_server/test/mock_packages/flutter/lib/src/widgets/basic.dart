// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';

export 'package:flutter/painting.dart';
export 'package:flutter/rendering.dart';

class AspectRatio extends SingleChildRenderObjectWidget {
  const AspectRatio({
    Key key,
    @required double aspectRatio,
    Widget child,
  });
}

class Center extends StatelessWidget {
  const Center({Key key, double heightFactor, Widget child});
}

class ClipRect extends SingleChildRenderObjectWidget {
  const ClipRect({Key key, Widget child}) : super(key: key, child: child);

  /// Does not actually exist in Flutter.
  const ClipRect.rect({Key key, Widget child}) : super(key: key, child: child);
}

class Column extends Flex {
  Column({
    Key key,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    List<Widget> children = const <Widget>[],
  });
}

class Expanded extends StatelessWidget {
  const Expanded({
    Key key,
    int flex = 1,
    @required Widget child,
  });
}

class Flex extends Widget {
  Flex({
    Key key,
    List<Widget> children = const <Widget>[],
  });
}

class Padding extends SingleChildRenderObjectWidget {
  final EdgeInsetsGeometry padding;

  const Padding({
    Key key,
    this.padding,
    Widget child,
  });
}

class Row extends Flex {
  Row({
    Key key,
    List<Widget> children = const <Widget>[],
  });
}

class Transform extends SingleChildRenderObjectWidget {
  const Transform({
    Key key,
    @required transform,
    origin,
    alignment,
    transformHitTests = true,
    Widget child,
  });
}
