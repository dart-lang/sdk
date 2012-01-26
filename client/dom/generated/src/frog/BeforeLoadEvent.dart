
class BeforeLoadEventJs extends EventJs implements BeforeLoadEvent native "*BeforeLoadEvent" {

  String get url() native "return this.url;";
}
