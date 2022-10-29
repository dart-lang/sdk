test(dynamic x) {
  if (x case (1, 2)) {}
  if (x case (1, a: 2)) {}
  if (x case (a: 1, 2)) {}
  if (x case (a: 1, b: 2)) {}
}
