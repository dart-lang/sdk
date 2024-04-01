// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class InkResponse extends StatelessWidget {
  const InkResponse({
    super.key,
    this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.onHover,
  });

  final Widget? child;

  final ValueChanged<bool>? onHover;
}

class InkWell extends InkResponse {
  const InkWell({
    super.key,
    super.child,
    super.onHover,
  });
}
