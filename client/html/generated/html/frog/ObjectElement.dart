
class _ObjectElementImpl extends _ElementImpl implements ObjectElement native "*HTMLObjectElement" {

  String align;

  String archive;

  String border;

  String code;

  String codeBase;

  String codeType;

  _DocumentImpl get contentDocument() => _FixHtmlDocumentReference(_contentDocument);

  _EventTargetImpl get _contentDocument() native "return this.contentDocument;";

  String data;

  bool declare;

  final _FormElementImpl form;

  String height;

  int hspace;

  String name;

  String standby;

  String type;

  String useMap;

  final String validationMessage;

  final _ValidityStateImpl validity;

  int vspace;

  String width;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}
