void errors() {
  (int, int, {/*missing*/}) record1 = (1, 2);
  (int /* missing trailing comma */ ) record2 = (1, );
}

void ok() {
  (int, ) record1 = (1, );
  ({int ok}) record2 = (ok: 1);
  () record3 = ();
}
