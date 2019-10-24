class Class<T> {
  method(T o) {
    if (o is Class) {
      o.method(null);
    }
  }
}

method<T>(T o) {
  if (o is Class) {
    o.method(null);
  }
}

main() {
  new Class().method(new Class());
  method(new Class());
}
