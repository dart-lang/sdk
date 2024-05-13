import 'package:json/json.dart';

@JsonCodable()
class Point {
  int x = 0, y = 0;
}

@JsonCodable()
class ColoredPoint extends Point {
  String color = '';
}

main() {
  final json = {'x': 12, 'y': 42, 'color': '#2acaea'};
  var p = ColoredPoint.fromJson(json);

  p.x = 100;
  print('JSON ${p.toJson()}'); // Prints: JSON {x: 100, y: 42, color: #2acaea}
}
