@pragma('dart2js:noInline')
String confuse(String x) => x;

@pragma('dart2js:noInline')
sink(x) {}

main() {
  confuse('x');
  var m = confuse(null);
  // JSString.isEmpty gets inlined to 'm.length==0'
  sink(m. /*0:main*/ isEmpty);
}
