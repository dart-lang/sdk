void foo({(int, int) foo1, (int, int) foo2}) {
}
void bar({(int, int) foo1: (42, 42), (int, int) foo2: (42, 42)}) {
}
void baz({(int, int) foo1 = (42, 42), (int, int) foo2 = (42, 42)}) {
}
void qux({required (int, int) foo1, required (int, int) foo2}) {
}
void quux({(int, int)? foo1, (int, int)? foo2}) {
}
