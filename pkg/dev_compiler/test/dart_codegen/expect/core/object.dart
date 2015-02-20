part of dart.core;

class Object {
  const Object();
  bool operator ==(other) => identical(this, other);
  @patch int get hashCode => ((__x30) => DDC$RT.cast(__x30, dynamic, int,
      "CastGeneral", """line 62, column 23 of dart:core/object.dart: """,
      __x30 is int, true))(Primitives.objectHashCode(this));
  @patch String toString() => ((__x31) => DDC$RT.cast(__x31, dynamic, String,
      "CastGeneral", """line 65, column 24 of dart:core/object.dart: """,
      __x31 is String, true))(Primitives.objectToString(this));
  @patch dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError(this, invocation.memberName,
        invocation.positionalArguments, invocation.namedArguments);
  }
  @patch Type get runtimeType => ((__x32) => DDC$RT.cast(__x32, dynamic, Type,
      "CastGeneral", """line 77, column 27 of dart:core/object.dart: """,
      __x32 is Type, true))(getRuntimeType(this));
}
