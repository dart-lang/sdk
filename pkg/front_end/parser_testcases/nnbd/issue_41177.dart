main(List<int>? a, bool? b) {
  a![0];
  a?[0];
  a!?[0];
  (a!)?[0];
  b!?[0]:0;
  (b!)?[0]:0;
}