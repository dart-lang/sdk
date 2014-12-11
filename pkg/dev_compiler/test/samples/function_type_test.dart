Function f = (int x) => x + 1;
dynamic a = f;
Function g = a;

typedef int Foo(int x);
Foo foo = g;

void main() {
  print(g(41));
}
