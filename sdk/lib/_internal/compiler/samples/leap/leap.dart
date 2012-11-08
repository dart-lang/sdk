// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leap;

import 'dart:isolate';
import 'dart:uri';

import 'dart:html' as html;
import 'request_cache.dart';
import '../../lib/compiler/implementation/elements/elements.dart';
import '../../lib/compiler/implementation/dart2jslib.dart';
import '../../lib/compiler/implementation/tree/tree.dart';
import '../../lib/compiler/implementation/source_file.dart';
import '../../lib/compiler/implementation/library_map.dart';

part 'leap_leg.dart';
part 'leap_script.dart';
