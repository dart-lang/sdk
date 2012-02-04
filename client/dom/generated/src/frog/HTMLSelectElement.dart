
class _HTMLSelectElementJs extends _HTMLElementJs implements HTMLSelectElement native "*HTMLSelectElement" {

  bool autofocus;

  bool disabled;

  final _HTMLFormElementJs form;

  final _NodeListJs labels;

  int length;

  bool multiple;

  String name;

  final _HTMLOptionsCollectionJs options;

  bool required;

  int selectedIndex;

  int size;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  String value;

  final bool willValidate;

  void add(_HTMLElementJs element, _HTMLElementJs before) native;

  bool checkValidity() native;

  _NodeJs item(int index) native;

  _NodeJs namedItem(String name) native;

  void remove(var index_OR_option) native;

  void setCustomValidity(String error) native;
}
