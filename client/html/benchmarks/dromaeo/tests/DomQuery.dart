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
          final div = document.createElement('div');
          div.innerHTML = html;
          document.body.nodes.add(div);
        })
        .test('getElementById', () {
          for (int i = 0; i < num * 30; i++) {
            ret = document.queryOne('#testA' + num).tagName;
            ret = document.queryOne('#testB' + num).tagName;
            ret = document.queryOne('#testC' + num).tagName;
            ret = document.queryOne('#testD' + num).tagName;
            ret = document.queryOne('#testE' + num).tagName;
            ret = document.queryOne('#testF' + num).tagName;
          }
        })
        .test('getElementById (not in document)', () {
          for (int i = 0; i < num * 30; i++) {
            ret = document.queryOne('#testA');
            ret = document.queryOne('#testB');
            ret = document.queryOne('#testC');
            ret = document.queryOne('#testD');
            ret = document.queryOne('#testE');
            ret = document.queryOne('#testF');
          }
        })
        .test('getElementsByTagName(div)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.query('div');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName(p)', () {
          for (int i = 0; i < num; i++) {
            final elems = document.query('p');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName(a)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.query('a');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName(*)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.query('*');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByTagName (not in document)', () {
          for (int i = 0; i < num; i++) {
            var elems = document.query('strong');
            ret = elems.length == 0;
          }
        })
        .test('getElementsByName', () {
          for (int i = 0; i < num * 20; i++) {
            var elems = document.query('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
            elems = document.query('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
            elems = document.query('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
            elems = document.query('[name=test$num]');
            ret = elems[elems.length-1].nodeType;
          }
        })
        .test('getElementsByName (not in document)', () {
          for (int i = 0; i < num * 20; i++) {
            ret = document.query('[name=test]').length == 0;
            ret = document.query('[name=test]').length == 0;
            ret = document.query('[name=test]').length == 0;
            ret = document.query('[name=test]').length == 0;
            ret = document.query('[name=test]').length == 0;
          }
        })
        .end();
    });
  }
}

