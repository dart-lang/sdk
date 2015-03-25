part of dart.math;
 class _JenkinsSmiHash {static int combine(int hash, int value) {
  hash = 0x1fffffff & (hash + value);
   hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
   return hash ^ (hash >> 6);
  }
 static int finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
   hash = hash ^ (hash >> 11);
   return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
 static int hash2(a, b) => finish(combine(combine(0, DEVC$RT.cast(a, dynamic, int, "DynamicCast", """line 37, column 55 of dart:math/jenkins_smi_hash.dart: """, a is int, true)), DEVC$RT.cast(b, dynamic, int, "DynamicCast", """line 37, column 59 of dart:math/jenkins_smi_hash.dart: """, b is int, true)));
 static int hash4(a, b, c, d) => finish(combine(combine(combine(combine(0, DEVC$RT.cast(a, dynamic, int, "DynamicCast", """line 40, column 49 of dart:math/jenkins_smi_hash.dart: """, a is int, true)), DEVC$RT.cast(b, dynamic, int, "DynamicCast", """line 40, column 53 of dart:math/jenkins_smi_hash.dart: """, b is int, true)), DEVC$RT.cast(c, dynamic, int, "DynamicCast", """line 40, column 57 of dart:math/jenkins_smi_hash.dart: """, c is int, true)), DEVC$RT.cast(d, dynamic, int, "DynamicCast", """line 40, column 61 of dart:math/jenkins_smi_hash.dart: """, d is int, true)));
}
