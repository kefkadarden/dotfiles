#!/usr/bin/env bash
# Visual preview of the proposed POWERLINE ARROW style (no config change).
RIGHT=$'\xee\x82\xb0'   # U+E0B0 right-pointing solid arrow
LEFT=$'\xee\x82\xb2'    # U+E0B2 left-pointing solid arrow
R=$'\e[0m'
fg(){ printf '\e[38;2;%s;%s;%sm' $1; }
bg(){ printf '\e[48;2;%s;%s;%sm' $1; }
CREAM="254 245 237"; DARK="1 22 39"; BLUE="81 107 235"; PINK="233 30 99"
GRAY="87 86 86"; GRAYTX="214 222 235"; WHITE="255 255 255"
TEAL="23 215 160"; ORANGE="255 146 72"; PURPLE="179 136 255"

left_bar(){ local sbg="$1" sym="$2"
  bg "$CREAM"; fg "$DARK"; printf '  pwsh '
  fg "$CREAM"; bg "$sbg"; printf '%s' "$RIGHT"
  bg "$sbg";  fg "$WHITE"; printf ' %s ' "$sym"
  fg "$sbg";  bg "$GRAY";  printf '%s' "$RIGHT"
  bg "$GRAY"; fg "$GRAYTX"; printf ' 57ms '
  printf '%s' "$R"; fg "$GRAY"; printf '%s%s\n' "$RIGHT" "$R"
}
git_pill(){ printf '   (far right) '
  fg "$1"; printf '%s' "$LEFT"
  bg "$1"; fg "$DARK"; printf ' %s ' "$2"
  printf '%s\n' "$R"
}
echo "LEFT BAR — success (blue) vs error (pink):"
left_bar "$BLUE" $'\xef\x80\x8c'
left_bar "$PINK" $'\xef\x81\x91'
echo
echo "GIT PILL — dynamic colour by state:"
git_pill "$TEAL"   $'\xee\xaf\xa8 \xee\x82\xa0 main \xe2\x89\xa1'
git_pill "$ORANGE" $'\xee\xaf\xa8 \xee\x82\xa0 main \xe2\x89\xa1  \xef\x81\x84~2'
git_pill "$PURPLE" $'\xee\xaf\xa8 \xee\x82\xa0 main \xe2\x87\xa11'
