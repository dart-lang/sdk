part of dart.core;
 class Expando<T> {final String name;
 external Expando([String name]);
 String toString() => "Expando:$name";
 external T operator [](Object object);
 external void operator []=(Object object, T value);
}
