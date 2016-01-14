foo(a) { try { print(a); } finally { return a; } }

main() {
  while (true) {
    l: while (true) {
      while (foo(true)) {
        if (foo(false)) break l;
      }
      print(1);
    }
    print(2);
  }
}

