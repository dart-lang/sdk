// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/entities.dart' show Entity;
import 'source_span.dart';
import 'spannable.dart';

abstract class SpannableWithEntity implements Spannable {
  Entity? get sourceEntity;
  SourceSpan? get sourceSpan;
}
