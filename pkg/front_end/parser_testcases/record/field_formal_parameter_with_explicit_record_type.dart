// https://github.com/dart-lang/sdk/issues/50007

class C {
  C(({int n, String s}) this.x);
  C({({int n, String s}) this.x});
  C({required ({int n, String s}) this.x});
  C(({int n, String s})? this.x);
  C({({int n, String s})? this.x});
  C({required ({int n, String s})? this.x});
}
