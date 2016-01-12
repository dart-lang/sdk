foo(a, [b = "b"]) { print(b); return b; }
bar(a, {b: "b", c: "c"}) { print(c); return c; }
main() {
  foo(0);
  foo(1, 2);
  bar(3);
  bar(4, b: 5);
  bar(6, c: 7);
  bar(8, b: 9, c: 10);
}

