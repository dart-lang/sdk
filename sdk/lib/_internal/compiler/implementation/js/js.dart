// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js;

import 'precedence.dart';
import '../util/characters.dart' as charCodes;
import '../util/util.dart';

// TODO(floitsch): remove this dependency (currently necessary for the
// CodeBuffer).
import '../dart2jslib.dart' as leg;

part 'nodes.dart';
part 'builder.dart';
part 'printer.dart';
part 'template.dart';
