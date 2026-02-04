// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsContainerLibrary = MockLibraryUnit(
  'lib/src/widgets/container.dart',
  r'''
import 'package:flutter/painting.dart';
import 'package:ui/ui.dart';

import 'framework.dart';

class Container extends StatelessWidget {
  final Widget? child;

  final AlignmentGeometry? alignment;

  final EdgeInsetsGeometry? padding;

  final Decoration? decoration;

  final Decoration? foregroundDecoration;

  final EdgeInsetsGeometry? margin;

  Container({
    super.key,
    this.alignment,
    this.padding,
    Color? color,
    this.decoration,
    this.foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    this.margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    this.child,
    Clip clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) => throw 0;
}

class DecoratedBox extends SingleChildRenderObjectWidget {
  const DecoratedBox({
    super.key,
    required Decoration decoration,
    DecorationPosition position = DecorationPosition.background,
    super.child,
  });
}
''',
);
