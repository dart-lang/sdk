// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsBasicLibrary = MockLibraryUnit('lib/src/widgets/basic.dart', r'''
import 'package:flutter/rendering.dart';

import 'framework.dart';

export 'package:flutter/animation.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter/painting.dart';
export 'package:flutter/rendering.dart';

class Align extends SingleChildRenderObjectWidget {
  final AlignmentGeometry alignment;

  final double? widthFactor;

  final double? heightFactor;

  const Align({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    super.child,
  }) : assert(widthFactor == null || widthFactor >= 0.0),
       assert(heightFactor == null || heightFactor >= 0.0);
}

class AspectRatio extends SingleChildRenderObjectWidget {
  const AspectRatio({super.key, required double aspectRatio, super.child})
    : assert(aspectRatio > 0.0);
}

class Center extends Align {
  const Center({super.key, super.widthFactor, super.heightFactor, super.child});
}

class SizedBox extends SingleChildRenderObjectWidget {
  const SizedBox({super.key, this.width, this.height, super.child});

  const SizedBox.expand({super.key, super.child})
    : width = double.infinity,
      height = double.infinity;

  const SizedBox.shrink({super.key, super.child}) : width = 0.0, height = 0.0;

  SizedBox.fromSize({super.key, super.child, Size? size});

  final double? width;

  final double? height;
}

class ClipRect extends SingleChildRenderObjectWidget {
  const ClipRect({
    super.key,
    CustomClipper clipper,
    Clip clipBehavior = Clip.hardEdge,
    super.child,
  });
}

class ColoredBox extends SingleChildRenderObjectWidget {
  const ColoredBox({required Color color, super.child, super.key});
}

class Column extends Flex {
  const Column({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.spacing,
    super.children,
  }) : super(direction: Axis.vertical);
}

class Expanded extends Flexible {
  const Expanded({super.key, super.flex, required super.child})
    : super(fit: FlexFit.tight);
}

class Flexible extends ParentDataWidget<FlexParentData> {
  const Flexible({
    super.key,
    int flex = 1,
    FlexFit fit = FlexFit.loose,
    required super.child,
  });
}

class Flex extends MultiChildRenderObjectWidget {
  const Flex({
    super.key,
    required Axis direction,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    Clip clipBehavior = Clip.none,
    double spacing = 0.0,
    super.children,
  }) : assert(
         !identical(crossAxisAlignment, CrossAxisAlignment.baseline) ||
             textBaseline != null,
         'textBaseline is required if you specify the crossAxisAlignment with CrossAxisAlignment.baseline',
       );
}

class Padding extends SingleChildRenderObjectWidget {
  final EdgeInsetsGeometry padding;

  const Padding({super.key, required this.padding, super.child});
}

class Row extends Flex {
  const Row({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.spacing,
    super.children,
  }) : super(direction: Axis.horizontal);
}

class Stack extends MultiChildRenderObjectWidget {
  const Stack({
    super.key,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection? textDirection,
    StackFit fit = StackFit.loose,
    Clip clipBehavior = Clip.hardEdge,
    super.children,
  });
}

class Transform extends SingleChildRenderObjectWidget {
  const Transform({
    super.key,
    required Matrix4 transform,
    Offset? origin,
    AlignmentGeometry? alignment,
    bool transformHitTests = true,
    FilterQuality? filterQuality,
    super.child,
  });
}

class Builder extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const Builder({super.key, required this.builder});
}

class SliverPadding extends SingleChildRenderObjectWidget {
  const SliverPadding({super.key, required EdgeInsetsGeometry padding, Widget? sliver})
    : super(child: sliver);
}

class SliverToBoxAdapter extends SingleChildRenderObjectWidget {
  const SliverToBoxAdapter({super.key, super.child});
}

class RichText extends Widget {
  final TextSpan text;
  const RichText({required this.text});
}

class Wrap extends MultiChildRenderObjectWidget {
  const Wrap({List<Widget> children = const []})
      : super(children: children);
}
''');
