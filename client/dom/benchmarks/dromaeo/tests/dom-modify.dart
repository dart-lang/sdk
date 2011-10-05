#import("dart:dom");
#import('runner.dart');

void main() {
  final int num = 400;

  String str = 'null';
  // Very ugly way to build up the string, but let's mimic JS version as much as possible.
  for (int i = 0; i < 1024; i++) {
    str += new String.fromCharCodes([((25 * Math.random()) + 97).toInt()]);
  }

  List<Node> elems = new List<Node>();

  // Try to force real results.
  var ret;
  window.onload = (Event evt) {
    final htmlstr = document.body.innerHTML;

    new Suite(window, 'dom-modify')
      .test('createElement', () {
        for (int i = 0; i < num; i++) {
          ret = document.createElement('div');
          ret = document.createElement('span');
          ret = document.createElement('table');
          ret = document.createElement('tr');
          ret = document.createElement('select');
        }
      })
      .test('createTextNode', () {
        for (int i = 0; i < num; i++) {
          ret = document.createTextNode(str);
          ret = document.createTextNode(str + '2');
          ret = document.createTextNode(str + '3');
          ret = document.createTextNode(str + '4');
          ret = document.createTextNode(str + '5');
        }
      })
      .test('innerHTML', () {
        document.body.innerHTML = htmlstr;
      })
      .prep(() {
        elems = new List<Node>();
        final telems = document.body.childNodes;
        for (int i = 0; i < telems.length; i++) {
          elems.add(telems[i]);
        }
      })
      .test('cloneNode', () {
        for (int i = 0; i < elems.length; i++) {
          ret = elems[i].cloneNode(false);
          ret = elems[i].cloneNode(true);
          ret = elems[i].cloneNode(true);
          }
      })
      .test('appendChild', () {
        for (int i = 0; i < elems.length; i++)
          document.body.appendChild(elems[i]);
      })
      .test('insertBefore', () {
        for (int i = 0; i < elems.length; i++)
          document.body.insertBefore(elems[i], document.body.firstChild);
      })
      .end();
  };
}
