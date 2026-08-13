f() {
  var a, b, c;

  a?[b]:c;
  a ? [b] : c;
  a?[b].toString() : c;
  a ? [b].toString() : c;

  a ? <dynamic>[b] : <dynamic>[c];
  a ? ([b]) : ([c]);
}