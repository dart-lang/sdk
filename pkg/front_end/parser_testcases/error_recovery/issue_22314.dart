const annotation = null;

class Annotation {
  final String message;
  const Annotation(this.message);
}

class A<E> {}

class C {
  m() => new A<@annotation @Annotation("test") C>();
}
