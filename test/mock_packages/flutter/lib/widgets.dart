class BuildContext {}

class Center extends Widget {
  const Center(
      {int key, double widthFactor, double heightFactor, Widget child});
}

class Column extends Widget {
  Column({
    int key,
    List<Widget> children = const <Widget>[],
  });
}

class Container extends Widget {
  Container({
    Widget child,
    double width,
    double height,
  });
}

abstract class Diagnosticable {
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[];

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

class DiagnosticPropertiesBuilder {
  void add(DiagnosticsProperty property) {}
}

class DiagnosticsNode {}

class DiagnosticsProperty<T> {}

class Row extends Widget {}

class Scaffold extends Widget {
  const Scaffold({
    int key,
    Widget body,
    // ...
  });
}

class StringProperty extends DiagnosticsProperty<String> {
  StringProperty(
    String name,
    String value, {
    String description,
    String tooltip,
    bool showName = true,
    Object defaultValue,
    bool quoted,
    String ifEmpty,
  });
}

abstract class Widget {
  const Widget();
  Widget build(BuildContext context) => null;
}
