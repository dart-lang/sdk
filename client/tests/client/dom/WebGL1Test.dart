#library('WebGL1Test');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

// Test that WebGL is present in dart:dom API

main() {
  forLayoutTests();

  test('simple', () {
      var canvas = document.createElement("canvas");
      var gl = canvas.getContext("experimental-webgl");
      var shader = gl.createShader(WebGLRenderingContext.VERTEX_SHADER);
      gl.shaderSource(shader, "void main() { }");
      gl.compileShader(shader);
      var success =
          gl.getShaderParameter(shader, WebGLRenderingContext.COMPILE_STATUS);
      Expect.isTrue(success);
  });
}
