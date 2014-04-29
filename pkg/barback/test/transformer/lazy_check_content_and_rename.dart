// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.transformer.lazy_check_content_and_rename;

import 'dart:async';

import 'package:barback/barback.dart';

import 'declaring_check_content_and_rename.dart';

class LazyCheckContentAndRenameTransformer
    extends DeclaringCheckContentAndRenameTransformer
    implements LazyTransformer {
  LazyCheckContentAndRenameTransformer({String oldExtension,
        String oldContent, String newExtension, String newContent})
      : super(oldExtension: oldExtension, oldContent: oldContent,
              newExtension: newExtension, newContent: newContent);
}
