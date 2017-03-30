// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.src.fasta.names;

import 'package:kernel/ast.dart' show Name;

export 'package:kernel/frontend/accessors.dart' show indexGetName, indexSetName;

final Name callName = new Name("call");

final Name plusName = new Name("+");

final Name minusName = new Name("-");

final Name multiplyName = new Name("*");

final Name divisionName = new Name("/");

final Name percentName = new Name("%");

final Name ampersandName = new Name("&");

final Name leftShiftName = new Name("<<");

final Name rightShiftName = new Name(">>");

final Name caretName = new Name("^");

final Name barName = new Name("|");

final Name mustacheName = new Name("~/");
