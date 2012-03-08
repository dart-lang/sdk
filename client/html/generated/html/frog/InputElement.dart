
class _InputElementImpl extends _ElementImpl implements InputElement native "*HTMLInputElement" {

  _InputElementEventsImpl get on() =>
    new _InputElementEventsImpl(this);

  String accept;

  String align;

  String alt;

  String autocomplete;

  bool autofocus;

  bool checked;

  bool defaultChecked;

  String defaultValue;

  bool disabled;

  final _FileListImpl files;

  final _FormElementImpl form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  bool incremental;

  bool indeterminate;

  final _NodeListImpl labels;

  String max;

  int maxLength;

  String min;

  bool multiple;

  String name;

  String pattern;

  String placeholder;

  bool readOnly;

  bool required;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int size;

  String src;

  String step;

  String type;

  String useMap;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  Date valueAsDate;

  num valueAsNumber;

  bool webkitGrammar;

  bool webkitSpeech;

  bool webkitdirectory;

  final bool willValidate;

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;

  void stepDown([int n = null]) native;

  void stepUp([int n = null]) native;
}

class _InputElementEventsImpl extends _ElementEventsImpl implements InputElementEvents {
  _InputElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get speechChange() => _get('webkitSpeechChange');
}
