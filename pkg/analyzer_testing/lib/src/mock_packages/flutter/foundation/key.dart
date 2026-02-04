// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final foundationKeyLibrary = MockLibraryUnit('lib/src/foundation/key.dart', r'''
import 'package:meta/meta.dart';

@immutable
abstract class Key {
  const factory Key(String value) = ValueKey<String>;

  @protected
  const Key.empty();
}

abstract class LocalKey extends Key {
  const LocalKey() : super.empty();
}

class UniqueKey extends LocalKey {}

class ValueKey<T> extends LocalKey {
  final T value;

  const ValueKey(this.value);
}
''');
