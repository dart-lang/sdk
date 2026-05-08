// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsAsyncLibrary = MockLibraryUnit('lib/src/widgets/async.dart', r'''
import 'framework.dart';

typedef AsyncWidgetBuilder<T> =
    Widget Function(BuildContext context, AsyncSnapshot<T> snapshot);

@immutable
class AsyncSnapshot<T> {}

class FutureBuilder<T> extends StatefulWidget {
  const FutureBuilder({super.key, required this.future, this.initialData, required this.builder});
}

class StreamBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  final T? initialData;

  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;

  const StreamBuilder({
    super.key,
    this.initialData,
    required super.stream,
    required this.builder,
  });
}

abstract class StreamBuilderBase<T, S> extends StatefulWidget {}
''');
