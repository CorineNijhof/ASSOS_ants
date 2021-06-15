breed [ants ant]      ; two types of turtles: ants and larvae
breed [larvae larva]

globals [
  minutes                  ; number of elapsed minutes (since start of hour)
  nr_larvae
  mean_weight_small
  mean_weight_medium
  mean_weight_large
  mean_weight_prepupae
  mean_weight_pupae
  size_small
  size_medium
  size_large
  size_prepupae
  size_pupae
]

patches-own [
  pheromones
  ;state                    ; contents of a cell: small/medium/large/prepupae/pupae
  ;brood_here               ; type of brood in cell: 0=nothing, 1/2/3/4/5
  ;neighboring_brood        ; number of nearby cells that contain brood
  ;probability              ; random number determining changes in cell contents
]

ants-own [
  target_larva  ; instance of larvae that ant is picking up
  turn_stdev
  steps_carrying      ; how long the ant is carrying a larva (0 if not carrying anything)
  type_carrying       ; the type of the larva the ant is carrying (0 if not carrying anything)
  tired               ; how tired the ant is, higher = more tired
]

larvae-own [
  def_color
  brood_type    ; type: 1=small/2=medium/3=large/4=prepupae/5=pupae
  weight
  carried       ; whether larva is currently being carried 1=yes/0=no
  carrier
  care_domain   ; space the larva needs to be taken care of, circular range
  enough_room   ; whether the larva has an empty care_domain 1=yes/0=no
  ; ...............
]

TO SETUP ;-----------------------------------------------------------------------------------------
  clear-all                    ; clears display, turtles, and patches

  ; setup time
  set hours 0
  set minutes 0

  ; setup patches
  ask patches [
    set pcolor white           ; set all patches white and empty
    set pheromones 0
  ]

  ; set weights
  set mean_weight_small 0.40522
  set mean_weight_medium 2.62807
  set mean_weight_large 7.41487
  set mean_weight_prepupae 5.92974
  set mean_weight_pupae 5.83200

  ; set sizes
  set size_small 0.5
  set size_medium 1.30
  set size_large 1.5
  set size_prepupae 1.25
  set size_pupae 1

  ; ant population
  create-ants nr_ants
  set-default-shape ants "bug"
  ;set-default-shape ants "default"
  ask ants [
    set steps_carrying 0
    set type_carrying 0
    set turn_stdev 2
    set color black
    set size 1
    setxy random-xcor random-ycor
  ]

  ; larvae population
  set nr_larvae (nr_small + nr_medium + nr_large + nr_prepupae + nr_pupae)
  create-larvae nr_larvae
  set-default-shape larvae "egg"
  let counter 0
  ask larvae [
    ; set carrier parameters
    set carried 0
    set carrier nobody

    ; set brood types
    ifelse (counter < nr_small) [ ;; small larvae
      set brood_type 1
    ]
    [
      ifelse (counter < nr_small + nr_medium) [ ;; medium larvae
        set brood_type 2
      ]
      [
        ifelse (counter < nr_small + nr_medium + nr_large) [ ;; large larvae
          set brood_type 3
        ]
        [
          ifelse (counter < nr_small + nr_medium + nr_large + nr_prepupae) [ ;; prepupae
            set brood_type 4
          ]
          [                      ;; pupae
            set brood_type 5
          ]
        ]
      ]
    ]

    ; set initial coordinates
    if initial_placing = "random" [
      setxy random-xcor random-ycor
    ]
    if initial_placing = "center" [
      setxy (random-float 6 + 8.5) (random-float 6 + 14.5)
    ]
    if initial_placing = "bottom" [
      setxy (random-float 13 + ) (random-float 6 + 5)
    ]

    ; setup larvae per type
    ask larvae with [brood_type = 1] [       ;; small larvae
      set care_domain cd_small
      set weight random-normal mean_weight_small 0.001
      if weight < 0 [ set weight 0.1]
      set def_color blue
      set color def_color
      set size size_small
      if initial_placing = "sorted bottom" [
        setxy random-xcor 2
      ]
    ]
    ask larvae with [brood_type = 2] [       ;; medium larvae
      set care_domain cd_medium
      set weight random-normal mean_weight_medium 0.001
      set def_color sky
      set color def_color
      set size size_medium
      if initial_placing = "sorted bottom" [
        setxy random-xcor 8
      ]
    ]
    ask larvae with [brood_type = 3] [       ;; large larvae
      set care_domain cd_large
      set weight random-normal mean_weight_large 0.001
      set def_color cyan
      set color def_color
      set size size_large
      if initial_placing = "sorted bottom" [
        setxy random-xcor 10
      ]
    ]
    ask larvae with [brood_type = 4] [       ;; prepupae
      set care_domain cd_prepupae
      set weight random-normal mean_weight_prepupae 0.001
      set def_color orange
      set color def_color
      set size size_prepupae
      if initial_placing = "sorted bottom" [
        setxy random-xcor 4
      ]
    ]
    ask larvae with [brood_type = 5] [       ;; pupae
      set care_domain cd_pupae
      set weight random-normal mean_weight_pupae 0.001
      set def_color red
      set color def_color
      set size size_pupae
      if initial_placing = "sorted bottom" [
        setxy random-xcor 6
      ]
    ]


    set counter counter + 1
    set enough_room 0
  ]


  clear-output
  ; display color key in command window
  show "|------ KEY TO COLORS ------|"
  show "|dark blue   - small larvae |"   ; color blue
  show "|middle blue - medium larvae|"   ; color sky
  show "|light blue  - large larvae |"   ; color cyan
  show "|orange      - prepupae     |"   ; color orange
  show "|red         - pupae        |"   ; color red

  reset-ticks
end


TO GO ;--------------------------------------------------------------------------------------------


  set minutes minutes + 1
  if minutes = 60 [       ; every 60 minutes: increment hours and reset minutes
    set hours hours + 1
    set minutes 0
  ]

  ask larvae [

    ;show count(larvae in-radius care_domain)
    ifelse (count((larvae with [carried = 0]) in-radius care_domain) + count larvae-here > 1) [
      set enough_room 0
      set color def_color
    ]
    [
      set enough_room 1
      ;if carried = 0 [ set color green ]
    ]

    if carried = 1 [
      let car_corx 0
      let car_cory 0
      ask carrier [
        set car_corx xcor
        set car_cory ycor
      ]
      setxy car_corx car_cory
    ]
  ]

  ask patches [
    set pheromones (count larvae-here) / 10
  ]
  diffuse pheromones pheromone_diffusion
  ask patches [
    set pcolor scale-color yellow pheromones 1 0
  ]

  ask ants [
    check_boundaries

    ifelse steps_carrying = 0 [
      select-target
      ifelse target_larva = nobody [
        turn-toward-pheromones
      ]
      [
        pick-up
      ]
    ]
    [
      set steps_carrying steps_carrying + 1
    ]
    ;right random-normal 0 turn_stdev
    forward 0.05

    if target_larva != nobody [
      drop
    ]

  ]
  tick
end

; select the larva target
to select-target
  set target_larva min-one-of (larvae with [(carried = 0) and (enough_room = 0)]) in-cone vision FOV [distance myself]
  if target_larva != nobody [
    set heading towards target_larva
  ]
end

; turn towards the patch with the most highest amount of pheromones in the smell range of the ant
to turn-toward-pheromones
  let target_patch max-one-of (patches in-radius scent_range) [pheromones]
  if [pheromones] of target_patch != 0 and (xcor != [pxcor] of target_patch or ycor != [pycor] of target_patch) [
    set heading towards target_patch
  ]
end

; make sure ants don't get stuck at walls
to check_boundaries
  if (xcor > 23) or (xcor < 0) or (ycor > 35) or (ycor < 0) [
    set heading towardsxy (max-pxcor / 2) (max-pycor / 2)
  ]
end

to pick-up
  if distance target_larva < pickup_range [
    set type_carrying ([brood_type] of target_larva)
    set steps_carrying 1

    let carrying_ant self
    ask target_larva [
      set carrier carrying_ant
      set carried 1
      set color def_color
    ]
  ]
end

to drop
  set tired steps_carrying * sqrt([weight] of target_larva)

  if (([enough_room] of target_larva) = 1) or (tired > max_tiredness) [
    set steps_carrying 0
    set tired 0
    ask target_larva [
      set carrier nobody
      set carried 0
      ;if enough_room = 1 [ set color green ]
    ]
  ]
end



@#$#@#$#@
GRAPHICS-WINDOW
470
10
862
595
-1
-1
16.0
1
10
1
1
1
0
0
0
1
0
23
0
35
0
0
1
ticks
5.0

BUTTON
10
12
90
65
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
100
12
179
66
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
182
76
239
121
NIL
hours
0
1
11

MONITOR
244
76
294
121
NIL
minutes
0
1
11

BUTTON
190
13
283
67
48 hours
repeat 48 * 60 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
385
151
418
nr_small
nr_small
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
17
420
151
453
nr_medium
nr_medium
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
17
456
151
489
nr_large
nr_large
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
17
491
152
524
nr_prepupae
nr_prepupae
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
17
526
152
559
nr_pupae
nr_pupae
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
16
75
169
108
nr_ants
nr_ants
0
100
80.0
1
1
workers
HORIZONTAL

SLIDER
16
172
188
205
FOV
FOV
0
360
120.0
10
1
degrees
HORIZONTAL

SLIDER
16
136
189
169
vision
vision
0
35
6.0
1
1
patches
HORIZONTAL

SLIDER
16
246
188
279
speed
speed
0
1
0.5
0.01
1
patches/tick
HORIZONTAL

SLIDER
17
283
189
316
pickup_range
pickup_range
0
5
0.3
0.1
1
patches
HORIZONTAL

SLIDER
157
385
329
418
cd_small
cd_small
0
5
0.1
0.1
1
patches
HORIZONTAL

SLIDER
157
421
329
454
cd_medium
cd_medium
0
5
2.5
0.1
1
patches
HORIZONTAL

SLIDER
157
457
329
490
cd_large
cd_large
0
5
5.0
0.1
1
patches
HORIZONTAL

SLIDER
157
492
329
525
cd_prepupae
cd_prepupae
0
5
1.4
0.1
1
patches
HORIZONTAL

SLIDER
157
526
329
559
cd_pupae
cd_pupae
0
5
1.5
0.1
1
patches
HORIZONTAL

SLIDER
17
321
225
354
max_tiredness
max_tiredness
0
300
130.0
10
1
steps*weight
HORIZONTAL

TEXTBOX
307
10
468
130
Grid size: 23x35\n\nLarvae color code\ndark blue    - small larvae\nmiddle blue - medium larvae\nlight blue    - large larvae\norange       - prepupae     \nred            - pupae        
12
0.0
1

SLIDER
252
181
460
214
pheromone_diffusion
pheromone_diffusion
0
1
0.6
0.1
1
NIL
HORIZONTAL

CHOOSER
252
218
460
263
initial_placing
initial_placing
"sorted bottom" "random" "center" "bottom"
3

SLIDER
16
208
188
241
scent_range
scent_range
0
35
16.0
1
1
patches
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?



## HOW TO USE IT

The SETUP button resets the time, displays a color key, ...

The GO button runs the simulation according to the rules
described above.


## THINGS TO NOTICE

## CREDITS AND REFERENCES
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="cd_large">
      <value value="2.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_prepupae">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-large">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-medium">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_tiredness">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_small">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-ants">
      <value value="78"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-small">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_medium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_pupae">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-pupae">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-prepupae">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickup_range">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FOV">
      <value value="130"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="3" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [ycor] of larvae with [brood_type = 1]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 2]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 3]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 4]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 5]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 1]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 2]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 3]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 4]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 5]</metric>
    <enumeratedValueSet variable="cd_small">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_medium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_large">
      <value value="2.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_prepupae">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_pupae">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-large">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-medium">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_tiredness">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-ants">
      <value value="78"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-small">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-pupae">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-prepupae">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickup_range">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FOV">
      <value value="130"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="3" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [ycor] of larvae with [brood_type = 1]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 2]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 3]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 4]</metric>
    <metric>mean [ycor] of larvae with [brood_type = 5]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 1]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 2]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 3]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 4]</metric>
    <metric>standard-deviation [ycor] of larvae with [brood_type = 5]</metric>
    <enumeratedValueSet variable="cd_small">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_medium">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_large">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_prepupae">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cd_pupae">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-large">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-medium">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_tiredness">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-ants">
      <value value="78"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-small">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-pupae">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-prepupae">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickup_range">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FOV">
      <value value="130"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
