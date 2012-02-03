
class _BeforeLoadEventJs extends _EventJs implements BeforeLoadEvent native "*BeforeLoadEvent" {

  String get url() native "return this.url;";
}
