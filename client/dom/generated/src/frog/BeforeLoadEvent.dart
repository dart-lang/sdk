
class BeforeLoadEventJS extends EventJS implements BeforeLoadEvent native "*BeforeLoadEvent" {

  String get url() native "return this.url;";
}
