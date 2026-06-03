// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbiSpecificIntegerMappingTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AbiSpecificIntegerMappingTest extends PubPackageResolutionTest {
  test_doubleMapping() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({})
@AbiSpecificIntegerMapping({})
// [diag.abiSpecificIntegerMappingExtra][column 2][length 25] Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a 'NativeType' integer with a fixed size.
final class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''');
  }

  test_invalidMapping() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: IntPtr(),
//                  ^^^^^^^^
// [diag.abiSpecificIntegerMappingUnsupported] Invalid mapping to 'IntPtr'; only mappings to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.
  Abi.androidIA32: UintPtr(),
//                 ^^^^^^^^^
// [diag.abiSpecificIntegerMappingUnsupported] Invalid mapping to 'UintPtr'; only mappings to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.
})
final class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''');
  }

  test_invalidMapping_identifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
const c = {
  Abi.androidArm: Uint32(),
  Abi.androidArm64: IntPtr(),
  Abi.androidIA32: UintPtr(),
};
@AbiSpecificIntegerMapping(c)
//                         ^
// [diag.abiSpecificIntegerMappingUnsupported] Invalid mapping to 'IntPtr'; only mappings to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.
// [diag.abiSpecificIntegerMappingUnsupported] Invalid mapping to 'UintPtr'; only mappings to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.
final class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''');
  }

  test_noMapping() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class UintPtr extends AbiSpecificInteger {
//          ^^^^^^^
// [diag.abiSpecificIntegerMappingMissing] Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a 'NativeType' integer with a fixed size.
  const UintPtr();
}
''');
  }

  test_singleMapping() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({})
final class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''');
  }

  test_validMapping() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
})
final class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}
''');
  }
}
