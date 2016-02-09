// Expectation for test: 
// // Method to test: generative_constructor(A#)
// class A {
//   var x, y, z;
//   A(x, y) {
//     this.x = x;
//     this.y = y;
//     this.z = this.x / 2;
//   }
// }
// 
// main() {
//   print(new A(123, 'sdf').y);
//   try {} finally {} // Do not inline into main.
// }

function(x, y) {
  return new V.A(x, y, x / 2);
}
