// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'text_serialization_tester.dart';

main(List<String> arguments) {
  internalMain(arguments: arguments, shards: shardCount, shard: 2);
}
