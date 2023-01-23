typedef A<T> = C<T, int>;

class B<X, Y> {
  X x;

  B(this.x);
}

mixin Mixin {}

class C<X, Y> = B<X, Y> with Mixin;

var field = A((a, b) => 42);
