// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

typedef ValueWidgetBuilder<T> =
    Widget Function(BuildContext context, T value, Widget? child);

class ValueListenable<T> {}

class ValueListenableBuilder<T> extends StatefulWidget {
  const ValueListenableBuilder({
    Key? key,
    required ValueListenable<T> valueListenable,
    required ValueWidgetBuilder<T> builder,
    Widget? child,
  });

  final ValueListenable<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;
}
