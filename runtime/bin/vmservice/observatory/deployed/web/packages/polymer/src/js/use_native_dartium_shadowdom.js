// Prevent polyfilled JS Shadow DOM in Dartium
// We need this if we want Dart code to be able to interoperate with Polymer.js
// code that also uses Shadow DOM.
// TODO(jmesserly): we can remove this code once platform.js is correctly
// feature detecting Shadow DOM in Dartium.
if (navigator.userAgent.indexOf('(Dart)') !== -1) {
  window.Platform = window.Platform || {};
  Platform.flags = Platform.flags || {};
  Platform.flags.shadow = 'native';

  // Note: Dartium 34 hasn't turned on the unprefixed Shadow DOM
  // (this happens in Chrome 35), so unless "enable experimental platform
  // features" is enabled, things will break. So we expose them as unprefixed
  // names instead.
  var proto = Element.prototype;
  if (!proto.createShadowRoot) {
    proto.createShadowRoot = proto.webkitCreateShadowRoot;

    Object.defineProperty(proto, 'shadowRoot', {
      get: function() {
        return this.webkitShadowRoot;
      },
      set: function(value) {
        this.webkitShadowRoot = value;
      },
      configurable: true
    });
  }
}
