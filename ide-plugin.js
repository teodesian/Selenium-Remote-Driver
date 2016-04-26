/*
 * Formatter for Selenium 2 / WebDriver perl-rc client.
 * To install...
    1. Open the Selenium IDE
    2. Options >> Options
    3. Formats Tab
    4. Click Add at the bottom
    5. In the name field call it 'Perl-Webdriver'
    6. Paste this entire source in the main textbox
    7. Click 'Save'
    8. Click 'Ok'
 */

var subScriptLoader = Components.classes["@mozilla.org/moz/jssubscript-loader;1"].getService(Components.interfaces.mozIJSSubScriptLoader);
subScriptLoader.loadSubScript('chrome://selenium-ide/content/formats/webdriver.js', this);

function testClassName(testName) {
  return testName.split(/[^0-9A-Za-z]+/).map(
      function(x) {
        return capitalize(x);
      }).join('');
}

function testMethodName(testName) {
  return "test_" + underscore(testName);
}

function nonBreakingSpace() {
  return "\"\\xa0\"";
}

function array(value) {
  var str = '[';
  for (var i = 0; i < value.length; i++) {
    str += string(value[i]);
    if (i < value.length - 1) str += ", ";
  }
  str += ']';
  return str;
}

notOperator = function() {
  return "not ";
};

Equals.prototype.toString = function() {
  return this.e2.toString() + " == " + this.e1.toString();
};

Equals.prototype.assert = function() {
  return statement("is(" + this.e2.toString() + "," + this.e1.toString() + ")");
};

Equals.prototype.verify = function() {
  return verify(this.assert());
};

NotEquals.prototype.toString = function() {
  return this.e1.toString() + " != " + this.e2.toString();
};

NotEquals.prototype.assert = function() {
  return statement("isnt(" + this.e2.toString() + "," + this.e1.toString() + ")");
};

NotEquals.prototype.verify = function() {
  return verify(this.assert());
};

function joinExpression(expression) {
  return "join(\",\"," + expression.toString() + ")";
}

function statement(expression) {
  expression.noBraces = true;
  var s = expression.toString();
  if(s.length == 0) {
    return null;
  }
  return s + ';';
}

function assignToVariable(type, variable, expression) {
  return variable + " = " + expression.toString();
}

function ifCondition(expression, callback) {
  return "if (" + expression.toString() + ") {\n" + callback() + "}";
}

function tryCatch(tryStatement, catchStatement, exception) {
  return "eval {\n" +
      indents(1) + tryStatement + "\n" +
      "};\n if ($@) {\n" +
      indents(1) + catchStatement + "\n" +
      "}";
}

function assertTrue(expression) {
  var exp = expression.toString();
  //var r = exp.match(/^(.+)\.([0-9A-Za-z_]+)\?$/);
  //if (r && r.length == 3) {
  //  return "ok(" + r[1] + ".should be_" + r[2];
  //} else {
    return statement("ok(" + exp + ")");
  //}
}

function assertFalse(expression) {
  //return expression.invert().toString() + ".should be_false";
  var exp = expression.toString();
  //var r = exp.match(/^(.+)\.([0-9A-Za-z_]+)\?$/);
  //if (r && r.length == 3) {
  //  return r[1] + ".should_not be_" + r[2];
  //} else {
    return statement("ok(!" + exp + ")");
  //}
}

function verify(stmt) {
  return stmt;
}

function verifyTrue(expression) {
  return verify(assertTrue(expression));
}

function verifyFalse(expression) {
  return verify(assertFalse(expression));
}

RegexpMatch.patternAsRegEx = function(pattern) {
  var str = pattern.replace(/\//g, "\\/");
  if (str.match(/\n/)) {
    str = str.replace(/\n/g, '\\n');
    return '/' + str + '/m';
  } else {
    return str = '/' + str + '/';
  }
};

RegexpMatch.prototype.patternAsRegEx = function() {
  return RegexpMatch.patternAsRegEx(this.pattern);
};

RegexpMatch.prototype.toString = function() {
  return this.expression + " =~ " + this.patternAsRegEx();
};

RegexpMatch.prototype.assert = function() {
  return statement("like(qr" + this.patternAsRegEx() + "," + this.expression + ")");
};

RegexpMatch.prototype.verify = function() {
  return verify(this.assert());
};

RegexpNotMatch.prototype.patternAsRegEx = function() {
  return RegexpMatch.patternAsRegEx(this.pattern);
};

RegexpNotMatch.prototype.toString = function() {
  return this.expression + " !~ " + this.patternAsRegEx();
};

RegexpNotMatch.prototype.assert = function() {
  return statement("unlike(qr" + this.patternAsRegEx() + "," + this.expression + ")");
};

RegexpNotMatch.prototype.verify = function() {
  return verify(this.assert());
};

function waitFor(expression) {
  if (expression.negative) {
    return "for(0..60) { my $ret = 1; eval { $ret = (" + expression.invert().toString() + ") }; if($@ || !$ret) { break }; sleep 1 }"
  } else {
    return "!60.times{ break if (" + expression.toString() + " rescue false); sleep 1 }"
  }
}

function assertOrVerifyFailure(line, isAssert) {
  return "assert_raise(Kernel) { " + line + "}";
}

function pause(milliseconds) {
  return "sleep " + (parseInt(milliseconds) / 1000);
}

function echo(message) {
  return "note " + xlateArgument(message);
}

function formatComment(comment) {
  return comment.comment.replace(/.+/mg, function(str) {
    return "# " + str;
  });
}

/**
 * Returns a string representing the suite for this formatter language.
 *
 * @param testSuite  the suite to format
 * @param filename   the file the formatted suite will be saved as
 */
function formatSuite(testSuite, filename) {
  formattedSuite = 'require "spec/ruby"\n' +
      'require "spec/runner"\n' +
      '\n' +
      "# output T/F as Green/Red\n" +
      "ENV['RSPEC_COLOR'] = 'true'\n" +
      '\n';

  for (var i = 0; i < testSuite.tests.length; ++i) {
    // have saved or loaded a suite
    if (typeof testSuite.tests[i].filename != 'undefined') {
      formattedSuite += 'require File.join(File.dirname(__FILE__),  "' + testSuite.tests[i].filename.replace(/\.\w+$/, '') + '")\n';
    } else {
      // didn't load / save as a suite
      var testFile = testSuite.tests[i].getTitle();
      formattedSuite += 'require "' + testFile + '"\n';
    }
  }
  return formattedSuite;
}

this.options = {
  receiver: "$driver",
  rcHost: "localhost",
  rcPort: "4444",
  environment: "firefox",
  showSelenese: 'false',
  header:
      "use strict;\n" +
      "use warnings;\n" +
      "use Selenium::Remote::Driver;\n" +
      "use Test::More;\n" +
      "\n" +
      'my ${receiver} = Selenium::Remote::Driver->new( remote_server_addr => "${rcHost}",\n' +
      '                                               port => ${rcPort},\n' +
      '                                               browser_name => "${environment}");\n' +
      "\n",
  footer:
      "${receiver}->quit();\n" +
      "done_testing();\n",
  indent: "0",
  initialIndents: "0"
};

this.configForm =
    '<description>Variable for Selenium instance</description>' +
        '<textbox id="options_receiver" />' +
        '<description>Selenium RC host</description>' +
        '<textbox id="options_rcHost" />' +
        '<description>Selenium RC port</description>' +
        '<textbox id="options_rcPort" />' +
        '<description>Environment</description>' +
        '<textbox id="options_environment" />' +
        '<description>Header</description>' +
        '<textbox id="options_header" multiline="true" flex="1" rows="4"/>' +
        '<description>Footer</description>' +
        '<textbox id="options_footer" multiline="true" flex="1" rows="4"/>' +
        '<description>Indent</description>' +
        '<menulist id="options_indent"><menupopup>' +
        '<menuitem label="Tab" value="tab"/>' +
        '<menuitem label="1 space" value="1"/>' +
        '<menuitem label="2 spaces" value="2"/>' +
        '<menuitem label="3 spaces" value="3"/>' +
        '<menuitem label="4 spaces" value="4"/>' +
        '<menuitem label="5 spaces" value="5"/>' +
        '<menuitem label="6 spaces" value="6"/>' +
        '<menuitem label="7 spaces" value="7"/>' +
        '<menuitem label="8 spaces" value="8"/>' +
        '</menupopup></menulist>' +
        '<checkbox id="options_showSelenese" label="Show Selenese"/>';

this.name = "Perl Test::More(WebDriver)";
this.testcaseExtension = ".t";
this.suiteExtension = ".t";
this.webdriver = true;

WDAPI.Driver = function() {
  this.ref = options.receiver;
};

WDAPI.Driver.searchContext = function(locatorType, locator) {
  var locatorString = xlateArgument(locator).replace(/([@%$])/,"\\$1");
  switch (locatorType) {
    case 'xpath':
      return locatorString + ', "xpath"';
    case 'css':
      return locatorString + ', "css"';
    case 'id':
      return locatorString + ', "id"';
    case 'link':
      return locatorString + ', "link"';
    case 'name':
      return locatorString + ', "name"';
    case 'tag_name':
      return locatorString + ', "tag_name"';
  }
  throw 'Error: unknown strategy [' + locatorType + '] for locator [' + locator + ']';
};

WDAPI.Driver.prototype.back = function() {
  return this.ref + "->navigate->back";
};

WDAPI.Driver.prototype.close = function() {
  return this.ref + "->close";
};

WDAPI.Driver.prototype.findElement = function(locatorType, locator) {
  return new WDAPI.Element(this.ref + "->find_element(" + WDAPI.Driver.searchContext(locatorType, locator) + ")");
};

WDAPI.Driver.prototype.findElements = function(locatorType, locator) {
  return new WDAPI.ElementList(this.ref + "->find_elements(" + WDAPI.Driver.searchContext(locatorType, locator) + ")");
};

WDAPI.Driver.prototype.getCurrentUrl = function() {
  return this.ref + "->get_current_url";
};

WDAPI.Driver.prototype.get = function(url) {
  return this.ref + "->get(" + url + ")";
};

WDAPI.Driver.prototype.getTitle = function() {
  return this.ref + "->get_title";
};

WDAPI.Driver.prototype.refresh = function() {
  return this.ref + "->refresh";
};

WDAPI.Driver.prototype.frame = function(locator) {
  return this.ref + "->switch_to_frame(" + xlateArgument(locator) + ")";
}

WDAPI.Element = function(ref) {
  this.ref = ref;
};

WDAPI.Element.prototype.clear = function() {
  return this.ref + "->clear";
};

WDAPI.Element.prototype.click = function() {
  return this.ref + "->click";
};

WDAPI.Element.prototype.getAttribute = function(attributeName) {
  return this.ref + "->attribute(" + xlateArgument(attributeName) + ")";
};

WDAPI.Element.prototype.getText = function() {
  return this.ref + "->get_text";
};

WDAPI.Element.prototype.isDisplayed = function() {
  return this.ref + "->is_displayed";
};

WDAPI.Element.prototype.isSelected = function() {
  return this.ref + "->is_selected";
};

WDAPI.Element.prototype.sendKeys = function(text) {
  return this.ref + "->send_keys(" + xlateArgument(text) + ")";
};

WDAPI.Element.prototype.submit = function() {
  return this.ref + "->submit";
};

WDAPI.ElementList = function(ref) {
  this.ref = ref;
};

WDAPI.ElementList.prototype.getItem = function(index) {
  return this.ref + "[" + index + "]";
};

WDAPI.ElementList.prototype.getSize = function() {
  return this.ref + "->size";
};

WDAPI.ElementList.prototype.isEmpty = function() {
  return this.ref + "->is_empty";
};


WDAPI.Utils = function() {
};

WDAPI.Utils.isElementPresent = function(how, what) {
  return this.ref + "->is_element_present(" + xlateArgument(what) + ", \"" + how + "\")";
};
