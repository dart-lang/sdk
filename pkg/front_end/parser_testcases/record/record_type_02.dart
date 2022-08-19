void foo() {
  (int, int, {/*missing*/}) record1 = (1, 2);
  (int /* missing */ ) record2 = (1);
  ({int ok}) record3 = (ok: 1);
  (/*missing*/) record4 = ();
}
