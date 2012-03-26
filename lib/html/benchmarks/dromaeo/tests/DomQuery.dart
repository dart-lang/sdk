class Main {
  static void main() {
    final int num = 40;

    // Try to force real results.
    var ret;
    window.on.load.add((Event evt) {
      String html = document.body.innerHTML;

      new Suite('dom-query')
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
        .test('getElementById', () {
          for (int i = 0; i < num * 30; i++) {
            ret = document.query('#testA' + num).tagName;
            ret = document.query('#testB' + num).tagName;
            ret = document.query('#testC' + num).tagName;
            ret = document.query('#testD' + num).tagName;
            ret = document.query('#testE' + num).tagName;
            ret = document.query('#testF' + num).tagName;
          }
        })
        .test('getElementById (not in document)', () {
          for (int i = 0; i < num * 30; i++) {
            ret = document.query('#testA');
            ret = document.query('#testB');
            ret = document.query('#testC');
            ret = document.query('#testD');
            ret = document.query('#testE');
            ret = document.query('#testF');
          }
        })
        .test('getElementsByTagName(div)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.queryAll('div');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName(p)', () {
          for (int i = 0; i < num; i++) {
            final elems = document.queryAll('p');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName(a)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.queryAll('a');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName(*)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.queryAll('*');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName (not in document)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.queryAll('strong');
            ret = elems.length == 0;
          }
        })
        .test('getElementsByName', () {
          for (int i = 0; i < num * 20; i++) {
            var elems = document.queryAll('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
            elems = document.queryAll('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
            elems = document.queryAll('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
            elems = document.queryAll('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByName (not in document)', () {
          for (int i = 0; i < num * 20; i++) {
            ret = document.queryAll('[name=test]').length == 0;
            ret = document.queryAll('[name=test]').length == 0;
            ret = document.queryAll('[name=test]').length == 0;
            ret = document.queryAll('[name=test]').length == 0;
            ret = document.queryAll('[name=test]').length == 0;
          }
        })
        .end();
    });
  }
}

