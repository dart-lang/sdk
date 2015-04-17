library c;

import 'a/a.dart' as DDC$a$;
import 'package:dev_compiler/runtime/dart_logging_runtime.dart' as DEVC$RT;
import 'b.dart';

void bar() {
  f3(((__x0) => DEVC$RT.cast(__x0, dynamic, DDC$a$.A, "DynamicCast",
      """line 10, column 6 of test/dart_codegen/types/c.dart: """,
      __x0 is DDC$a$.A, true))(f4(3)));
  f1(DEVC$RT.cast(f4, __CastType1, DDC$a$.A2A, "CompositeCast",
      """line 11, column 6 of test/dart_codegen/types/c.dart: """,
      f4 is DDC$a$.A2A, false));
  f2(f3);
}
typedef dynamic __CastType1(dynamic __u2);
