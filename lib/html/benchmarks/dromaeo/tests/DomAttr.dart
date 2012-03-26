class Main {
  static void main() {
    final int num = 10240;

    // Try to force real results.
    var ret;
    window.on.load.add((Event evt) {
      Element elem = document.query('#test1');
      Element a = document.query('a');

      new Suite('dom-attr')
        .test('getAttribute', void _() {
          for (int i = 0; i < num; i++)
            ret = elem.attributes['id'];
        })
        .test('element.property', () {
          for (int i = 0; i < num * 2; i++)
            ret = elem.id;
        })
        .test('setAttribute', () {
          for (int i = 0; i < num; i++)
            a.attributes['id'] = 'foo';
        })
        .test('element.property = value', () {
          for (int i = 0; i < num; i++)
            a.id = 'foo';
        })
        .end();
    });
  }
}
