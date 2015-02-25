library c;

import 'a/a.dart' as DDC$a$;
import 'package:dev_compiler/runtime/dart_logging_runtime.dart' as DDC$RT;
import 'b.dart';

void bar() {
  f3(((__x0) => DDC$RT.cast(__x0, dynamic, DDC$a$.A, "CastGeneral",
      """line 10, column 6 of test/dart_codegen/types/c.dart: """,
      __x0 is DDC$a$.A, true))(f4(3)));
  f1(DDC$RT.wrap((dynamic f(dynamic __u2)) {
    dynamic c(dynamic x0) => ((__x1) => DDC$RT.cast(__x1, dynamic, DDC$a$.A,
        "CastResult",
        """line 11, column 6 of test/dart_codegen/types/c.dart: """,
        __x1 is DDC$a$.A, true))(f(x0));
    return f == null ? null : c;
  }, f4, __t5, __t3, "Wrap",
      """line 11, column 6 of test/dart_codegen/types/c.dart: """, f4 is __t3));
  f2(DDC$RT.wrap((DDC$a$.A f(DDC$a$.A __u7)) {
    DDC$a$.A c(DDC$a$.A x0) => f(DDC$RT.cast(x0, dynamic, DDC$a$.A, "CastParam",
        """line 12, column 6 of test/dart_codegen/types/c.dart: """,
        x0 is DDC$a$.A, true));
    return f == null ? null : c;
  }, f3, __t3, __t5, "Wrap",
      """line 12, column 6 of test/dart_codegen/types/c.dart: """, f3 is __t5));
}
typedef DDC$a$.A __t3(DDC$a$.A __u4);
typedef dynamic __t5(dynamic __u6);
