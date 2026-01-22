// Bug found by DartFuzz (stripped down version):
// https://github.com/dart-lang/sdk/issues/36076

// Code does not do anything, but broke kernel binary flow graph builder.

foo() {
  try {
    for (var x in [1, 2]) {
      return;
    }
  } finally {
    for (var x in [3]) {
      break;
    }
  }
}

bar() {
  try {} catch (e) {
    try {} catch (e) {
      for (var x in [1, 2]) {
        if (x == 1) break;
        return;
      }
      try {
        try {} catch (e) {
          return;
        }
      } catch (e) {}
    } finally {
      try {} catch (e) {
        return;
      }
    }
  } finally {}
}

main() {
  foo();
  bar();
}
