part of dart.core;

class Expando<T> {
  final String name;
  @patch Expando([String name]) : this.name = name;
  String toString() => "Expando:$name";
  @patch T operator [](Object object) {
    var values = Primitives.getProperty(object, _EXPANDO_PROPERTY_NAME);
    return ((__x21) => DDC$RT.cast(__x21, dynamic, T, "CastGeneral",
            """line 44, column 12 of dart:core/expando.dart: """, __x21 is T,
            false))(
        (values == null) ? null : Primitives.getProperty(values, _getKey()));
  }
  @patch void operator []=(Object object, T value) {
    var values = Primitives.getProperty(object, _EXPANDO_PROPERTY_NAME);
    if (values == null) {
      values = new Object();
      Primitives.setProperty(object, _EXPANDO_PROPERTY_NAME, values);
    }
    Primitives.setProperty(values, _getKey(), value);
  }
}
