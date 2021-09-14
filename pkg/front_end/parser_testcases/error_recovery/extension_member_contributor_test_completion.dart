extension E<T extends num> on List<T> {
  bool a(int b, int c) {}
  int get b => 0;
  set c(int d) {}
}
void f(List<int> l) {
  l.a /* the user is typing here */
}
void g(List<int> l) {
  l.a /* the user is typing here */
  print(l.b);
}