// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

class AsyncSnapshot<T> {}

typedef AsyncWidgetBuilder<T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot);

class StreamBuilder<T> {
  const StreamBuilder(
      {Key key, this.initialData, Stream<T> stream, @required this.builder});
  final T initialData;
  final AsyncWidgetBuilder<T> builder;
}
