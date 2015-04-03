library c;

import 'a/a.dart' as DDC$a$;
import 'package:dev_compiler/runtime/dart_logging_runtime.dart' as DEVC$RT;
import 'b.dart';

void bar() {
  f3(((__x0) => DEVC$RT.cast(__x0, dynamic, DDC$a$.A, "DynamicCast",
      """line 10, column 6 of test/dart_codegen/types/c.dart: """,
      __x0 is DDC$a$.A, true))(f4(3)));
  f1(DEVC$RT.cast(f4, __t3, __t1, "CompositeCast",
      """line 11, column 6 of test/dart_codegen/types/c.dart: """, f4 is __t1,
      false));
  f2(f3);
}
typedef DDC$a$.A __t1(DDC$a$.A __u2);
typedef dynamic __t3(dynamic __u4);
