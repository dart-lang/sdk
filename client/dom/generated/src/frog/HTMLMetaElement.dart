
class _HTMLMetaElementJs extends _HTMLElementJs implements HTMLMetaElement native "*HTMLMetaElement" {

  String get content() native "return this.content;";

  void set content(String value) native "this.content = value;";

  String get httpEquiv() native "return this.httpEquiv;";

  void set httpEquiv(String value) native "this.httpEquiv = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get scheme() native "return this.scheme;";

  void set scheme(String value) native "this.scheme = value;";
}
