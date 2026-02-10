void foo() {
  var pair = (1, 2);

  // Spread positional-only record.
  var r1 = (...pair, 3);

  // Spread named-only record.
  var named = (a: 1, b: 2);
  var r2 = (...named);

  // Spread mixed record.
  var mixed = (1, a: 2);
  var r3 = (...mixed);

  // Spread with additional fields.
  var r4 = (...pair, color: 'red');

  // Multiple spreads.
  var r5 = (...pair, ...(3, 4));

  // Spread nested record.
  var r6 = (...(1, 2), ...(a: 3, b: 4));

  // Spread with trailing comma.
  var r7 = (...pair, );

  // Const spread.
  var r8 = const (...(1, 2), 3);
}
