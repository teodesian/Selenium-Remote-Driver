package Selenium::Remote::WDKeys;

# ABSTRACT: Representation of keystrokes used by Selenium::Remote::WebDriver

=head1 DESCRIPTION

The constant KEYS is defined here.

=head1 SYNOPSIS

   use Selenium::Remote::WDKeys;
   
   my $space_key = KEYS->{'space'};
   my $enter_key = KEYS->{'enter'};
   
=head1 CONSTANT KEYS

  null
  cancel
  help
  backspace
  tab
  clear
  return
  enter
  shift
  control
  alt
  pause
  escape
  space
  page_up
  page_down
  end
  home
  left_arrow
  up_arrow
  right_arrow
  down_arrow
  insert
  delete
  semicolon
  equals
  numpad_0
  numpad_1
  numpad_2
  numpad_3
  numpad_4
  numpad_5
  numpad_6
  numpad_7
  numpad_8
  numpad_9
  multiply
  add
  separator
  subtract
  decimal
  divide
  f1
  f2
  f3
  f4
  f5
  f6
  f7
  f8
  f9
  f10
  f11
  f12
  command_meta
  ZenkakuHankaku

=head1 FUNCTIONS

Functions of Selenium::Remote::WDKeys.

=head2 KEYS

  my $keys = KEYS();

A hash reference that contains constant keys. This function is exported by default.

=cut

use strict;
use warnings;

use base 'Exporter';

# http://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/element/:id/value
use constant KEYS => {
    'null'           => "\N{U+E000}",
    'cancel'         => "\N{U+E001}",
    'help'           => "\N{U+E002}",
    'backspace'      => "\N{U+E003}",
    'tab'            => "\N{U+E004}",
    'clear'          => "\N{U+E005}",
    'return'         => "\N{U+E006}",
    'enter'          => "\N{U+E007}",
    'shift'          => "\N{U+E008}",
    'control'        => "\N{U+E009}",
    'alt'            => "\N{U+E00A}",
    'pause'          => "\N{U+E00B}",
    'escape'         => "\N{U+E00C}",
    'space'          => "\N{U+E00D}",
    'page_up'        => "\N{U+E00E}",
    'page_down'      => "\N{U+E00f}",
    'end'            => "\N{U+E010}",
    'home'           => "\N{U+E011}",
    'left_arrow'     => "\N{U+E012}",
    'up_arrow'       => "\N{U+E013}",
    'right_arrow'    => "\N{U+E014}",
    'down_arrow'     => "\N{U+E015}",
    'insert'         => "\N{U+E016}",
    'delete'         => "\N{U+E017}",
    'semicolon'      => "\N{U+E018}",
    'equals'         => "\N{U+E019}",
    'numpad_0'       => "\N{U+E01A}",
    'numpad_1'       => "\N{U+E01B}",
    'numpad_2'       => "\N{U+E01C}",
    'numpad_3'       => "\N{U+E01D}",
    'numpad_4'       => "\N{U+E01E}",
    'numpad_5'       => "\N{U+E01f}",
    'numpad_6'       => "\N{U+E020}",
    'numpad_7'       => "\N{U+E021}",
    'numpad_8'       => "\N{U+E022}",
    'numpad_9'       => "\N{U+E023}",
    'multiply'       => "\N{U+E024}",
    'add'            => "\N{U+E025}",
    'separator'      => "\N{U+E026}",
    'subtract'       => "\N{U+E027}",
    'decimal'        => "\N{U+E028}",
    'divide'         => "\N{U+E029}",
    'f1'             => "\N{U+E031}",
    'f2'             => "\N{U+E032}",
    'f3'             => "\N{U+E033}",
    'f4'             => "\N{U+E034}",
    'f5'             => "\N{U+E035}",
    'f6'             => "\N{U+E036}",
    'f7'             => "\N{U+E037}",
    'f8'             => "\N{U+E038}",
    'f9'             => "\N{U+E039}",
    'f10'            => "\N{U+E03A}",
    'f11'            => "\N{U+E03B}",
    'f12'            => "\N{U+E03C}",
    'command_meta'   => "\N{U+E03D}",
    'ZenkakuHankaku' => "\N{U+E040}",    #Asian language keys, maybe altGr too?
      #There are other code points for say, left versus right meta/shift/alt etc, but I don't seriously believe anyone uses that level of sophistication on the web yet.
};

our @EXPORT = ('KEYS');

1;
