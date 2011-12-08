class Main {
  static void main() {
    final int num = 40;

    // Try to force real results.
    var ret;
    window.on.load.add((Event evt) {
      String html = document.body.innerHTML;

      new Suite('dom-traverse')
        .prep(() {
          html = BenchUtil.replaceAll(html, 'id="test(\\w).*?"', (Match match) {
            final group = match.group(1);
            return 'id="test${group}${num}"';
          });
          html = BenchUtil.replaceAll(html, 'name="test.*?"', (Match match) {
            return 'name="test${num}"';
          });
          html = BenchUtil.replaceAll(html, 'class="foo.*?"', (Match match) {
            return 'class="foo test${num} bar"';
          });

          final div = new Element.tag('div');
          div.innerHTML = html;
          document.body.nodes.add(div);
        })
        .test('firstChild', () {
          final nodes = document.body.nodes;
          final nl = nodes.length;

          for (int i = 0; i < num; i++) {
            for (int j = 0; j < nl; j++) {
              Node cur = nodes[j];
              while (cur !== null) {
                cur = cur.nodes.first;
              }
              ret = cur;
            }
          }
        })
        .test('lastChild', () {
          final nodes = document.body.nodes;
          final nl = nodes.length;

          for (int i = 0; i < num; i++) {
            for (int j = 0; j < nl; j++) {
              Node cur = nodes[j];
              while (cur !== null) {
                cur = cur.nodes.last();
              }
              ret = cur;
            }
          }
        })
        .test('nextSibling', () {
          for (int i = 0; i < num * 2; i++) {
            Node cur = document.body.nodes.first;
            while (cur !== null) {
              cur = cur.nextNode;
            }
            ret = cur;
          }
        })
        .test('previousSibling', () {
          for (int i = 0; i < num * 2; i++) {
            Node cur = document.body.nodes.first;
            while (cur !== null) {
              cur = cur.previousNode;
            }
            ret = cur;
          }
        })
        .test('childNodes', () {
          for (int i = 0; i < num; i++) {
            final nodes = document.body.nodes;
            for (int j = 0; j < nodes.length; j++) {
              ret = nodes[j];
            }
          }
        })
        .end();
    });
  }
}
