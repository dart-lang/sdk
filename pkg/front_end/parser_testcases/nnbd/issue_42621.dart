Order method1(Map<String, dynamic> json) {
  return Order()
    ..x = json['x'] as List
    ..y = json['y'] as int;
}

Order method2(Map<String, dynamic> json) {
  return Order()
    ..x = json['x'] as List?
    ..y = json['y'] as int;
}

Order method3(Map<String, dynamic> json) {
  return Order()
    ..x = (json['x'] as List?)
    ..y = json['y'] as int;
}

Order method4(Map<String, dynamic> json) {
  return Order()
    ..x = json['x'] as List?;
}

class Order {
  List? x;
  int? y;
}