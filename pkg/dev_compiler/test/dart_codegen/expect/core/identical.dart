part of dart.core;

@patch bool identical(Object a, Object b) {
  return ((__x22) => DDC$RT.cast(__x22, dynamic, bool, "CastGeneral",
      """line 9, column 10 of dart:core/identical.dart: """, __x22 is bool,
      true))(Primitives.identicalImplementation(a, b));
}
@patch int identityHashCode(Object object) => ((__x23) => DDC$RT.cast(__x23,
    dynamic, int, "CastGeneral",
    """line 13, column 40 of dart:core/identical.dart: """, __x23 is int,
    true))(objectHashCode(object));
