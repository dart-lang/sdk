// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirror_renamer;

// TODO(zarah): Remove this hack! LibraryElementX should not be created outside
// the library loader!
import '../elements/modelx.dart' show LibraryElementX;
import '../dart2jslib.dart' show Script, Compiler;
import '../tree/tree.dart';
import '../elements/elements.dart';

part 'renamer.dart';