#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Translates a buildbot shard name to the corresponding column group name
// on the buildbot site, such that it's easier to find the right column.
//
// Example: `dart bin/shard2group.dart precomp-linux-debug-x64-be`
// prints `vm-precomp(5): precomp-linux-debug-x64-be`.

library gardening.shard2group;

import 'dart:io';
part 'package:gardening/src/shard_data.dart';

main(List<String> args) async {
  if (args.length == 0) {
    print('Usage: dart shard2group.dart <shard-name1> [<shard-name2> ...]');
    print('Run bin/create_shard_groups.dart to refresh shard data');
    exit(1);
  }

  for (String arg in args) {
    for (String group in shardGroups.keys) {
      List<String> shardGroup = shardGroups[group];
      for (int i = 0; i < shardGroup.length; i++) {
        String shard = shardGroup[i];
        if (shard.contains(arg)) {
          print("$group(${i+1}): $shard");
        }
      }
    }
  }
}
