
class WebGLContextEventJs extends EventJs implements WebGLContextEvent native "*WebGLContextEvent" {

  String get statusMessage() native "return this.statusMessage;";
}
