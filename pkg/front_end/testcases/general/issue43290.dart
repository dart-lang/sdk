class Class {
  final int length;

  const Class({this.length});

  method1a() {
    const Class(length: this.length);
  }

  method1b() {
    const Class(length: length);
  }

  method2a() {
    const a = this.length;
  }

  method2b() {
    const a = length;
  }
}

main() {}
