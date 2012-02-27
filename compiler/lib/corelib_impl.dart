#!/usr/bin/env dart
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("corelib_impl");

#source("implementation/core.dart");
#source("implementation/array.dart");
#source("implementation/arrays.dart");
#source("implementation/bool.dart");
#source("implementation/collections.dart");
#source("implementation/date_implementation.dart");
#source("implementation/math_natives.dart");
#source("implementation/number.dart");
#source("implementation/regexp.dart");
#source("implementation/string.dart");
#source("implementation/string_base.dart");
#source("implementation/string_buffer.dart");
#source("implementation/time_zone_implementation.dart");
#source("src/implementation/dual_pivot_quicksort.dart");
#source("src/implementation/duration_implementation.dart");
#source("src/implementation/exceptions.dart");
#source("src/implementation/future_implementation.dart");
#source("src/implementation/hash_map_set.dart");
#source("src/implementation/linked_hash_map.dart");
#source("src/implementation/maps.dart");
#source("src/implementation/queue.dart");
#source("src/implementation/stopwatch_implementation.dart");
#source("src/implementation/splay_tree.dart");

#native("implementation/array.js");
#native("implementation/bool.js");
#native("implementation/core.js");
#native("implementation/date_implementation.js");
#native("implementation/isolate.js");
#native("implementation/math_natives.js");
#native("implementation/number.js");
#native("implementation/object.js");
#native("implementation/print.js");
#native("implementation/regexp.js");
#native("implementation/rtt.js");
#native("implementation/string.js");
