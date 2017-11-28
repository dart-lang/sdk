// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;
part '$foo';
part '$foo/bar';
part '$for/bar';
part '${true}';
part 'the${1}thing';
part 'part_$foo${'a'}.dart';
part 'part_${'a'}_$foo.dart';

main() {}
