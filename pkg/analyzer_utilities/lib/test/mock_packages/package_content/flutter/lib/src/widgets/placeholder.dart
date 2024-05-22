// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';

class Placeholder extends StatelessWidget {
  const Placeholder(
      {super.key,
      this.color = const Color(0xFF455A64), // Blue Grey 700
      this.strokeWidth = 2.0,
      this.fallbackWidth = 400.0,
      this.fallbackHeight = 400.0,
      this.child});

  final Color color;

  final double strokeWidth;

  final double fallbackWidth;

  final double fallbackHeight;

  final Widget? child;

  @override
  Widget build(BuildContext context) => child!;
}
