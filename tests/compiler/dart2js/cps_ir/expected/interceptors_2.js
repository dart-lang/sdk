// Expectation for test: 
// main() {
//   var l = ['hest', ['h', 'e', 's', 't']];
//   print(l.length);
//   for (int i  = 0; i < l.length; i++) {
//     var x = l[i];
//     for (int j = 0; j < x.length; j++) {
//       print(x[j]);
//     }
//   }
// }

function() {
  var l = ["hest", ["h", "e", "s", "t"]], i = 0, x, j;
  for (P.print(2); i < 2; ++i) {
    x = l[i];
    for (j = 0; j < x.length; ++j)
      P.print(x[j]);
  }
}
