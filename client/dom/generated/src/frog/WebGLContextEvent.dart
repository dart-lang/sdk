
class WebGLContextEventJS extends EventJS implements WebGLContextEvent native "*WebGLContextEvent" {

  String get statusMessage() native "return this.statusMessage;";
}
