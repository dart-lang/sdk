// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.task.general;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/model.dart';

/**
 * The content of a [Source].
 */
final ResultDescriptor<String> CONTENT =
    new ResultDescriptor<String>('CONTENT', null);

/**
 * The line information for a [Source].
 */
final ResultDescriptor<LineInfo> LINE_INFO =
    new ResultDescriptor<LineInfo>('LINE_INFO', null);

/**
 * The modification time of a [Source].
 */
final ResultDescriptor<int> MODIFICATION_TIME =
    new ResultDescriptor<int>('MODIFICATION_TIME', -1);
