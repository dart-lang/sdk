void foo() {
  var point = (1, 2);
  var record1 = (...point, 3);
  var record2 = (...point, a: 3);
  var record3 = (1, ...point);
  var record4 = (...point, ...point);
  var record5 = (a: 1, ...point, b: 2);
}
