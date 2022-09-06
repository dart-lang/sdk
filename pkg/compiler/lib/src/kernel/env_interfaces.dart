// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../elements/entities.dart';
import '../ir/element_map.dart';
import '../js_model/env.dart';
import '../universe/member_usage.dart';

// TODO(48820): Delete once migration is complete
abstract class KLibraryData {
  JLibraryData convert();
}

abstract class KLibraryEnv {
  ir.Library get library;
  JLibraryEnv convert(IrToElementMap kElementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage);
}

abstract class KClassData {
  JClassData convert();
}

abstract class KClassEnv {
  ir.Class get cls;

  JClassEnv convert(
      IrToElementMap kElementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage,
      LibraryEntity Function(ir.Library library) getJLibrary);
}

abstract class KMemberData {
  ir.Member get node;
  JMemberData convert();
}

abstract class KTypeVariableData {
  ir.TypeParameter get node;
  JTypeVariableData copy();
}

abstract class KProgramEnv {
  JProgramEnv convert();
}
