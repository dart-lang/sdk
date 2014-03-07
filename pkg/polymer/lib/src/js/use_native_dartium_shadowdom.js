// Prevent polyfilled JS Shadow DOM in Dartium
// We need this if we want Dart code to be able to interoperate with Polymer.js
// code that also uses Shadow DOM.
// TODO(jmesserly): we can remove this code once platform.js is correctly
// feature detecting Shadow DOM in Dartium.
if (navigator.userAgent.indexOf('(Dart)') !== -1) {
  window.Platform = window.Platform || {};
  Platform.flags = Platform.flags || {};
  Platform.flags.shadow = 'native';
}
