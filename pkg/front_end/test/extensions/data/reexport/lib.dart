// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

export 'lib1.dart';
/*error: errors=['ClashingExtension' is exported from both 'org-dartlang-test:///a/b/c/lib1.dart' and 'org-dartlang-test:///a/b/c/lib2.dart'.]*/
export 'lib2.dart';
