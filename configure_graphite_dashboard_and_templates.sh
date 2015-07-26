#!/bin/bash 

cat > /opt/graphite/conf/dashboard.conf <<EOF
[ui]
default_graph_width = 500
default_graph_height = 400
automatic_variants = true
refresh_interval = 60
autocomplete_delay = 375
merge_hover_delay = 750
EOF

cat > /opt/graphite/conf/graphTemplates.conf <<EOF
[default]
background = black
foreground = white
minorLine = grey
majorLine = rose
lineColors = blue,green,red,purple,brown,yellow,aqua,grey,magenta,pink,gold,rose
fontName = Sans
fontSize = 9
fontBold = False
fontItalic = False
EOF
