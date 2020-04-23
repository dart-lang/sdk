// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error: LegacyClass1 is exported and declared in opt-out.
export 'export_from_opt_out_lib1.dart';

// Error: LegacyClass3 and LegacyClass4 are still exported and declared in
// opt-out.
export 'export_from_opt_out_lib2.dart' hide legacyMethod2;

// Error: LegacyClass2 is exported and declared in opt-out.
export 'export_from_opt_out_lib3.dart' show LegacyClass2;

// Error: legacyMethod1 is exported and declared in opt-out.
export 'export_from_opt_out_lib3.dart' show legacyMethod1;

// Error: LegacyExtension is exported and declared in opt-out.
export 'export_from_opt_out_lib3.dart' show LegacyExtension;

// Error: LegacyTypedef is exported and declared in opt-out.
export 'export_from_opt_out_lib3.dart' show LegacyTypedef;

// Ok: NnbdClass1 is declared in opt-in.
export 'export_from_opt_out_lib3.dart' show NnbdClass1;

// Ok: Only NnbdClass1 and NnbdClass2 are exported but are declared in opt-in.
export 'export_from_opt_out_lib3.dart'
    hide LegacyClass2, LegacyExtension, LegacyTypedef, legacyMethod1;

// Ok: All exported declaration are from opt-in.
export 'export_from_opt_out_lib4.dart';

// Ok: All exported declaration are from opt-in.
export 'export_from_opt_out_lib5.dart';

main() {}
