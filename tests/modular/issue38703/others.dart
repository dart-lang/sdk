typedef FuncType<T> = Function();

class Key<T> {
  final FuncType<T> f;
  const Key(this.f);
}

someFunc<T>() {}
const someKey = Key(someFunc);
