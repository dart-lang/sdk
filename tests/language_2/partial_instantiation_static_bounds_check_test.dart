topFn<T extends num>(T x) {
  print(T);
}

class C<T> {
  instanceFn<S extends T>(S x) {
    print(S);
  }
}

class D<T> extends C<T> {
  void foo() {
    void Function(int) k = instanceFn; //# 03: compile-time error
  }
}

void main() {
  localFn<T extends num>(T x) {
    print(T);
  }

  void Function(String) k0 = localFn; //# 01: compile-time error
  void Function(String) k1 = topFn; //# 02: compile-time error
}
