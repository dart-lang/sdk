library d;

import 'a/a.dart' as DDC$a$;
import 'package:dev_compiler/runtime/dart_logging_runtime.dart' as DEVC$RT;
import 'b.dart';

void foo() {
  var x = f3(((__x0) => DEVC$RT.cast(__x0, dynamic, DDC$a$.A, "DynamicCast",
      """line 10, column 14 of test/dart_codegen/types/d.dart: """,
      __x0 is DDC$a$.A, true))(f4("""hello""")));
  var y = f1(DEVC$RT.cast(f4, __t1, DDC$a$.A2A, "CompositeCast",
      """line 11, column 14 of test/dart_codegen/types/d.dart: """,
      f4 is DDC$a$.A2A, false));
  var z = f2(f3);
}
typedef dynamic __t1(dynamic __u2);
