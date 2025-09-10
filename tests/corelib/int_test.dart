import "package:expect/expect.dart";

extension IntToBinary on int {
  String decimalToBinary() {
    if (this == 0) return "0";

    int number = this;
    String binary = "";
    while (number > 0) {
      int remainder = number % 2;
      binary = remainder.toString() + binary;
      number = number ~/ 2;
    }
    return binary;
  }
}

void main() {
 
  Expect.equals("0", 0.decimalToBinary());
  Expect.equals("1", 1.decimalToBinary());
  Expect.equals("10", 2.decimalToBinary());
  Expect.equals("1010", 10.decimalToBinary());
  Expect.equals("11001", 25.decimalToBinary());

 
  Expect.equals("11111111", 255.decimalToBinary());   
  Expect.equals("10000000000", 1024.decimalToBinary()); 

 
  Expect.equals("1111101000", 1000.decimalToBinary());
  Expect.equals("1111111111111111", 65535.decimalToBinary());
}
