// https://github.com/dart-lang/sdk/issues/50007

class C {
  ({num n, String s}) x;

  C(({int n, String s}) this.x);
}
