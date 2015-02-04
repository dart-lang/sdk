library d;

import 'a/a.dart' as DDC$a$;
import 'package:ddc/runtime/dart_logging_runtime.dart' as DDC$RT;
import 'b.dart';

void foo() {
  var x = f3(((__x0) => DDC$RT.cast(__x0, dynamic, DDC$a$.A, "CastGeneral",
      """line 6, column 14 of test/dart_codegen/types/d.dart: """,
      __x0 is DDC$a$.A, true))(f4("""hello""")));
  var y = f1(DDC$RT.wrap((dynamic f(dynamic __u2)) {
    dynamic c(dynamic x0) => ((__x1) => DDC$RT.cast(__x1, dynamic, DDC$a$.A,
        "CastResult",
        """line 7, column 14 of test/dart_codegen/types/d.dart: """,
        __x1 is DDC$a$.A, true))(f(x0));
    return f == null ? null : c;
  }, f4, __t5, __t3, "Wrap",
      """line 7, column 14 of test/dart_codegen/types/d.dart: """, f4 is __t3));
  var z = f2(DDC$RT.wrap((DDC$a$.A f(DDC$a$.A __u7)) {
    DDC$a$.A c(DDC$a$.A x0) => f(DDC$RT.cast(x0, dynamic, DDC$a$.A, "CastParam",
        """line 8, column 14 of test/dart_codegen/types/d.dart: """,
        x0 is DDC$a$.A, true));
    return f == null ? null : c;
  }, f3, __t3, __t5, "Wrap",
      """line 8, column 14 of test/dart_codegen/types/d.dart: """, f3 is __t5));
}
typedef DDC$a$.A __t3(DDC$a$.A __u4);
typedef dynamic __t5(dynamic __u6);
