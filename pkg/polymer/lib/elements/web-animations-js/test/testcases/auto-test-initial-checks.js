timing_test(function() {
  at(0, function() {
    assert_styles("#background",{'backgroundColor':'rgba(0, 0, 0, 0)'});
  }, "#background");
  at(0, function() {
    assert_styles("#border",{'borderBottomColor':'rgb(0, 0, 0)','borderBottomLeftRadius':'0px','borderBottomRightRadius':'0px','borderBottomWidth':'3px','borderLeftColor':'rgb(0, 0, 0)','borderLeftWidth':'3px','borderRightColor':'rgb(0, 0, 0)','borderRightWidth':'3px','borderTopColor':'rgb(0, 0, 0)','borderTopLeftRadius':'0px','borderTopRightRadius':'0px','borderTopWidth':'3px'});
  }, "#border");
  at(0, function() {
    assert_styles("#table",{'borderSpacing':'2px 2px','verticalAlign':'0px'});
  }, "#table");
  at(0, function() {
    assert_styles("#opacity",{'opacity':'1'});
  }, "#opacity");
  at(0, function() {
    assert_styles("#outline",{'outlineWidth':'3px','outlineOffset':'0px'});
  }, "#outline");
  at(0, function() {
    assert_styles("#padding",{'paddingBottom':'0px','paddingLeft':'0px','paddingRight':'0px','paddingTop':'0px'});
  }, "#padding");
  at(0, function() {
    assert_styles("#transform",{'transform':'none'});
  }, "#transform");
  at(0, function() {
    assert_styles("#text",{'color':'rgb(0, 0, 0)','fontSize':'13px','fontWeight':'normal','letterSpacing':'normal','lineHeight':'15.600px','textIndent':'0px','textShadow':'rgba(0, 0, 0, 0) 0px 0px 0px','wordSpacing':'0px'});
  }, "#text");
  at(1, function() {
    assert_styles("#background",{'backgroundColor':'rgba(0, 128, 0, 0.498039)'});
  }, "#background");
  at(1, function() {
    assert_styles("#border",{'borderBottomColor':'rgb(0, 255, 0)','borderBottomLeftRadius':'25px','borderBottomRightRadius':'25px','borderBottomWidth':'6px','borderLeftColor':'rgb(0, 255, 0)','borderLeftWidth':'6px','borderRightColor':'rgb(0, 255, 0)','borderRightWidth':'6px','borderTopColor':'rgb(0, 255, 0)','borderTopLeftRadius':'25px','borderTopRightRadius':'25px','borderTopWidth':'6px'});
  }, "#border");
  at(1, function() {
    assert_styles("#table",{'borderSpacing':'6px 6px','verticalAlign':'5px'});
  }, "#table");
  at(1, function() {
    assert_styles("#opacity",{'opacity':'0.625'});
  }, "#opacity");
  at(1, function() {
    assert_styles("#outline",{'outlineColor':'rgb(0, 128, 0)','outlineWidth':'6px','outlineOffset':'5px'});
  }, "#outline");
  at(1, function() {
    assert_styles("#padding",{'paddingBottom':'25px','paddingLeft':'25px','paddingRight':'25px','paddingTop':'25px'});
  }, "#padding");
  at(1, function() {
    assert_styles("#transform",{'transform':'matrix(-1, 0.00000000000000012246063538223773, -0.00000000000000012246063538223773, -1, 0, 0)'});
  }, "#transform");
  at(1, function() {
    assert_styles("#text",{'color':'rgb(0, 64, 0)','fontSize':'23px','fontWeight':'bold','letterSpacing':'5px','lineHeight':'36.7999px','textIndent':'25px','textShadow':'rgba(0, 255, 0, 0.498039) 5px 5px 25px','wordSpacing':'100px'});
  }, "#text");
  at(2, function() {
    assert_styles("#background",{'backgroundColor':'rgb(0, 128, 0)'});
  }, "#background");
  at(2, function() {
    assert_styles("#border",{'borderBottomColor':'rgb(0, 255, 0)','borderBottomLeftRadius':'50px','borderBottomRightRadius':'50px','borderBottomWidth':'10px','borderLeftColor':'rgb(0, 255, 0)','borderLeftWidth':'10px','borderRightColor':'rgb(0, 255, 0)','borderRightWidth':'10px','borderTopColor':'rgb(0, 255, 0)','borderTopLeftRadius':'50px','borderTopRightRadius':'50px','borderTopWidth':'10px'});
  }, "#border");
  at(2, function() {
    assert_styles("#table",{'borderSpacing':'10px 10px','verticalAlign':'10px'});
  }, "#table");
  at(2, function() {
    assert_styles("#opacity",{'opacity':'0.25'});
  }, "#opacity");
  at(2, function() {
    assert_styles("#outline",{'outlineColor':'rgb(0, 128, 0)','outlineWidth':'10px','outlineOffset':'10px'});
  }, "#outline");
  at(2, function() {
    assert_styles("#padding",{'paddingBottom':'50px','paddingLeft':'50px','paddingRight':'50px','paddingTop':'50px'});
  }, "#padding");
  at(2, function() {
    assert_styles("#transform",{'transform':'matrix(1, -0.00000000000000024492127076447545, 0.00000000000000024492127076447545, 1, 0, 0)'});
  }, "#transform");
  at(2, function() {
    assert_styles("#text",{'color':'rgb(0, 128, 0)','fontSize':'30px','fontWeight':'900','letterSpacing':'5px','lineHeight':'60px','textIndent':'50px','textShadow':'rgb(0, 255, 0) 10px 10px 50px','wordSpacing':'100px'});
  }, "#text");
}, "Auto generated tests");
