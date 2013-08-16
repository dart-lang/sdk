// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_types;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported_content', () {
    test('supported', () {
      expect(ContentElement.supported, true);
    });
  });

  group('supported_datalist', () {
    test('supported', () {
      expect(DataListElement.supported, true);
    });
  });

  group('supported_details', () {
    test('supported', () {
      expect(DetailsElement.supported, true);
    });
  });

  group('supported_embed', () {
    test('supported', () {
      expect(EmbedElement.supported, true);
    });
  });

  group('supported_keygen', () {
    test('supported', () {
      expect(KeygenElement.supported, true);
    });
  });

  group('supported_meter', () {
    test('supported', () {
      expect(MeterElement.supported, true);
    });
  });

  group('supported_object', () {
    test('supported', () {
      expect(ObjectElement.supported, true);
    });
  });

  group('supported_output', () {
    test('supported', () {
      expect(OutputElement.supported, true);
    });
  });

  group('supported_progress', () {
    test('supported', () {
      expect(ProgressElement.supported, true);
    });
  });

  group('supported_shadow', () {
    test('supported', () {
      expect(ShadowElement.supported, true);
    });
  });

  group('supported_template', () {
    test('supported', () {
      expect(TemplateElement.supported, true);
    });
  });

  group('supported_track', () {
    test('supported', () {
      expect(TrackElement.supported, true);
    });
  });

  check(String name, bool fn(), [bool supported = true]) {
    test(name, () {
      var expectation = supported ? returnsNormally : throws;
      expect(() {
        expect(fn(), isTrue);
      }, expectation);
    });

  }

  group('constructors', () {
    check('a', () => new AnchorElement() is AnchorElement);
    check('area', () => new AreaElement() is AreaElement);
    check('audio', () => new AudioElement() is AudioElement);
    check('body', () => new BodyElement() is BodyElement);
    check('br', () => new BRElement() is BRElement);
    check('base', () => new BaseElement() is BaseElement);
    check('button', () => new ButtonElement() is ButtonElement);
    check('canvas', () => new CanvasElement() is CanvasElement);
    check('caption', () => new TableCaptionElement() is TableCaptionElement);
    check('content', () => new ContentElement() is ContentElement,
        ContentElement.supported);
    check('details', () => new DetailsElement() is DetailsElement,
        DetailsElement.supported);
    check('datalist', () => new DataListElement() is DataListElement,
        DataListElement.supported);
    check('dl', () => new DListElement() is DListElement);
    check('div', () => new DivElement() is DivElement);
    check('embed', () => new EmbedElement() is EmbedElement,
        EmbedElement.supported);
    check('fieldset', () => new FieldSetElement() is FieldSetElement);
    check('form', () => new FormElement() is FormElement);
    check('head', () => new HeadElement() is HeadElement);
    check('hr', () => new HRElement() is HRElement);
    check('html', () => new HtmlHtmlElement() is HtmlHtmlElement);
    check('h1', () => new HeadingElement.h1() is HeadingElement);
    check('h2', () => new HeadingElement.h2() is HeadingElement);
    check('h3', () => new HeadingElement.h3() is HeadingElement);
    check('h4', () => new HeadingElement.h4() is HeadingElement);
    check('h5', () => new HeadingElement.h5() is HeadingElement);
    check('h6', () => new HeadingElement.h6() is HeadingElement);
    check('iframe', () => new IFrameElement() is IFrameElement);
    check('img', () => new ImageElement() is ImageElement);
    check('input', () => new InputElement() is InputElement);
    check('keygen', () => new KeygenElement() is KeygenElement,
        KeygenElement.supported);
    check('li', () => new LIElement() is LIElement);
    check('label', () => new LabelElement() is LabelElement);
    check('legen', () => new LegendElement() is LegendElement);
    check('link', () => new LinkElement() is LinkElement);
    check('map', () => new MapElement() is MapElement);
    check('menu', () => new MenuElement() is MenuElement);
    check('meta', () => new MetaElement() is MetaElement);
    check('meter', () => new MeterElement() is MeterElement,
        MeterElement.supported);
    check('del', () => new Element.tag('del') is ModElement);
    check('ins', () => new Element.tag('ins') is ModElement);
    check('object', () => new ObjectElement() is ObjectElement,
        ObjectElement.supported);
    check('ol', () => new OListElement() is OListElement);
    check('optgroup', () => new OptGroupElement() is OptGroupElement);
    check('option', () => new OptionElement() is OptionElement);
    check('output', () => new OutputElement() is OutputElement,
        OutputElement.supported);
    check('p', () => new ParagraphElement() is ParagraphElement);
    check('param', () => new ParamElement() is ParamElement);
    check('pre', () => new PreElement() is PreElement);
    check('progress', () => new ProgressElement() is ProgressElement,
        ProgressElement.supported);
    check('q', () => new QuoteElement() is QuoteElement);
    check('script', () => new ScriptElement() is ScriptElement);
    check('select', () => new SelectElement() is SelectElement);
    check('shadow', () => new ShadowElement() is ShadowElement,
        ShadowElement.supported);
    check('source', () => new SourceElement() is SourceElement);
    check('span', () => new SpanElement() is SpanElement);
    check('style', () => new StyleElement() is StyleElement);
    check('table', () => new TableElement() is TableElement);
    check('template', () => new TemplateElement() is TemplateElement,
        TemplateElement.supported);
    check('textarea', () => new TextAreaElement() is TextAreaElement);
    check('title', () => new TitleElement() is TitleElement);
    check('td', () => new TableCellElement() is TableCellElement);
    check('col', () => new TableColElement() is TableColElement);
    check('colgroup', () => new Element.tag('colgroup') is TableColElement);
    check('tr', () => new TableRowElement() is TableRowElement);
    check('tbody', () => new Element.tag('tbody') is TableSectionElement);
    check('tfoot', () => new Element.tag('tfoot') is TableSectionElement);
    check('thead', () => new Element.tag('thead') is TableSectionElement);
    check('track', () => new TrackElement() is TrackElement,
        TrackElement.supported);
    group('ul', () {
      check('ul', () => new UListElement() is UListElement);

      test('accepts li', () {
        var ul = new UListElement();
        var li = new LIElement();
        ul.append(li);
      });
    });
    check('video', () => new VideoElement() is VideoElement);
    check('unknown', () => new Element.tag('someunknown') is UnknownElement);
  });
}
