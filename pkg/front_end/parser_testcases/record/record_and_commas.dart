main() {
  // OK.
  () emptyRecord1 = ();

  // Error: Empty with comma.
  (,) emptyRecord2 = ();
  () emptyRecord3 = (,);
  (,) emptyRecord4 = (,);

  // Error: More than one trailing comma.
  (int, ,) emptyRecord5 = (42, 42, ,);
  (int, int, ,) emptyRecord6 = (42, 42, ,);
  (int, , ,) emptyRecord7 = (42, 42, , ,);
  (int, int, , ,) emptyRecord8 = (42, 42, , ,);
}