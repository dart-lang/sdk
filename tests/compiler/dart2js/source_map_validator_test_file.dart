class HelloClass {
  void printHello() {
    () {
      print('Hello World!');
    }();
  }
}

void main() {
  () {
    HelloClass helloClass = new HelloClass();
    helloClass.printHello();
  }();
}