(int, int) foo((int, {bool b}) inputRecord, int x) {
  if (inputRecord.b) return (42, 42);
  return (1, 1, );
}

(int, int) bar((int, {bool b}) inputRecord) {
  if (inputRecord.b) return (42, 42);
  return (1, 1, );
}

class Baz {
  (int, int) foo(int x) => (42, 42);
}