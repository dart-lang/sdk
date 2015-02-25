part of dart.core;

class Object {
  const Object();
  bool operator ==(other) => identical(this, other);
  int get hashCode => ((__x30) => DDC$RT.cast(__x30, dynamic, int,
      "CastGeneral", """line 73, column 23 of dart:core/object.dart: """,
      __x30 is int, true))(Primitives.objectHashCode(this));
  String toString() => ((__x31) => DDC$RT.cast(__x31, dynamic, String,
      "CastGeneral", """line 78, column 24 of dart:core/object.dart: """,
      __x31 is String, true))(Primitives.objectToString(this));
  dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError(this, invocation.memberName,
        invocation.positionalArguments, invocation.namedArguments);
  }
  Type get runtimeType => ((__x32) => DDC$RT.cast(__x32, dynamic, Type,
      "CastGeneral", """line 101, column 27 of dart:core/object.dart: """,
      __x32 is Type, true))(getRuntimeType(this));
}
