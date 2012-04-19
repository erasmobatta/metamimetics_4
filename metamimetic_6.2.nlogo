globals [
  cooperation-rate
  satisfaction-rate
  fraction-best
  maxi
  mini
  conf
  anti
  life-distribution
  
  
  ]

turtles-own [
  cooperate?       ;; patch will cooperate
  rule             ;; patch will have one of four rules: 1=Maxi 2=mini 3=conformist 4=anticonformist  
  
  score            ;; score resulting from interaction of neighboring patches. It is dictated by the PD payoffs and the discount factor
  last-score
  inst-score
  satisfaction
  age
  
  rule?
  behavior?
  move?
 
  theta_1
  theta_2
  prob-reflexion?
  weighting-history
  likelihood-to-move
  
]
to setup
  clear-all
   
  ask patches [ 
    set pcolor 0
    if random-float 1 < density[ sprout 1 ]
  ]
  ask turtles [
    set rule (random 4) + 1 
      set shape "face happy"
      ifelse random-float 1.0 < (inicoop / 100)
        [set cooperate? true]
        [set cooperate? false]
      set score 0.0
      set rule? false
      set behavior? false
      set move? false
      ifelse random-init [
      set theta_1 random-float 1.0
      set theta_2 random-float 1.0
      set weighting-history random-float 1.0   
      set likelihood-to-move random-float 1.0
        ]  
      [
      set theta_1 Initial-prob-update-behavior
      set theta_2 Initial-prob-update-rule
      set weighting-history Initial-weighting-history
      set likelihood-to-move Initial-like-to-move 
      ]
      
        
  ]
  ;stabilization
  ask turtles[ establish-color ]
  init-age-USA2010
  set-life-distribution-USA2010 
  set-outputs
  
  reset-ticks
end
to go
    ask turtles [interact] 
    decision-stage
    learning-stage
    ask turtles [calculate-satisfaction]
    moving-stage
    
    set-outputs            
    update-plots
    reset-decisions 
    replacement
    update-views
  ask turtles [
    ifelse am-i-the-best? [set shape "face happy"][set shape "face sad"]
    ]  
  update-views
    tick
end
to learning-stage
    ask turtles [ 
   if rule?   
   [     
       select-rule
       ;establish-color
       select-behavior
   ]
   if behavior? [select-behavior]
   ]
    
end
to calculate-satisfaction
    if rule = 1 
    [
      let top [score] of max-one-of (turtle-set turtles-on neighbors self) [score]
      let bottom [score] of min-one-of (turtle-set turtles-on neighbors self) [score]
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set satisfaction 0.5]
      [set satisfaction (score - bottom) / (top - bottom)]
      ]
    if rule = 2
    [
      let top [-1 * score] of min-one-of (turtle-set turtles-on neighbors self) [score]
      let bottom [ -1 * score] of max-one-of (turtle-set turtles-on neighbors self) [score]
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set satisfaction 0.5]
      [set satisfaction ((-1 * score) - bottom) / (top - bottom)]  
      ]
    if rule = 3
    [
      let top-rule one-of majority-rules
      let top count (turtle-set turtles-on neighbors self) with [rule = top-rule]/ count (turtle-set turtles-on neighbors self) 
      let bottom-rule one-of minority-rules
      let bottom count (turtle-set turtles-on neighbors self) with [rule = bottom-rule]/ count (turtle-set turtles-on neighbors self)     
      let my-rule rule
      let my-group count (turtle-set turtles-on neighbors self) with [rule = my-rule]/ count (turtle-set turtles-on neighbors self)      
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set satisfaction 0.5]
      [set satisfaction (my-group - bottom) / (top - bottom)]  
      
      ]
    if rule = 4
    [
      let top-rule one-of majority-rules
      let bottom  -1 * count (turtle-set turtles-on neighbors self) with [rule = top-rule]/ count (turtle-set turtles-on neighbors self) 
      let bottom-rule one-of minority-rules
      let top -1 * count (turtle-set turtles-on neighbors self) with [rule = bottom-rule]/ count (turtle-set turtles-on neighbors self)     
      let my-rule rule
      let my-group -1 * count (turtle-set turtles-on neighbors self) with [rule = my-rule]/ count (turtle-set turtles-on neighbors self)      
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set satisfaction 0.5]
      [set satisfaction (my-group - bottom) / (top - bottom)]    
      
      ]
    if not any? (turtles-on neighbors) [set satisfaction 0]
end
to-report hypothetical-satisfaction [my-turtle hyp-neighbors]
    let test-h-s 0
    if [rule] of my-turtle = 1 
    [
      let top [score] of max-one-of (turtle-set turtles-on hyp-neighbors my-turtle) [score]
      let bottom [score] of min-one-of (turtle-set turtles-on hyp-neighbors my-turtle) [score]
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set test-h-s 0.5]
      [set test-h-s ([score] of my-turtle - bottom) / (top - bottom)]
      ]
    if [rule] of my-turtle = 2
    [
      let top [-1 * score] of min-one-of (turtle-set turtles-on hyp-neighbors my-turtle) [score]
      let bottom [ -1 * score] of max-one-of (turtle-set turtles-on hyp-neighbors my-turtle) [score]
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set test-h-s 0.5]
      [set test-h-s ((-1 * [score] of my-turtle) - bottom) / (top - bottom)]  
      ]
    if [rule] of my-turtle = 3
    [
      let top-rule one-of ([majority-rules] of my-turtle)
      let top count (turtle-set turtles-on hyp-neighbors my-turtle) with [rule = top-rule]/ count (turtle-set turtles-on hyp-neighbors my-turtle) 
      let bottom-rule one-of ([minority-rules] of my-turtle)
      let bottom count (turtle-set turtles-on hyp-neighbors my-turtle) with [rule = bottom-rule]/ count (turtle-set turtles-on hyp-neighbors my-turtle)     
      let my-rule [rule] of my-turtle
      let my-group count (turtle-set turtles-on hyp-neighbors my-turtle) with [rule = my-rule]/ count (turtle-set turtles-on hyp-neighbors my-turtle)      
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set test-h-s 0.5]
      [set test-h-s (my-group - bottom) / (top - bottom)]  
      
      ]
    if [rule] of my-turtle = 4
    [
      let top-rule one-of ([majority-rules] of my-turtle)
      let bottom  -1 * count (turtle-set turtles-on hyp-neighbors my-turtle) with [rule = top-rule]/ count (turtle-set turtles-on hyp-neighbors my-turtle) 
      let bottom-rule one-of ([minority-rules] of my-turtle)
      let top -1 * count (turtle-set turtles-on hyp-neighbors my-turtle) with [rule = bottom-rule]/ count (turtle-set turtles-on hyp-neighbors my-turtle)     
      let my-rule [rule] of my-turtle
      let my-group -1 * count (turtle-set turtles-on hyp-neighbors my-turtle) with [rule = my-rule]/ count (turtle-set turtles-on hyp-neighbors my-turtle)      
      ifelse abs(top - bottom) < strength-of-dilemma 
      [set test-h-s 0.5]
      [set test-h-s (my-group - bottom) / (top - bottom)]    
      
      ]
    if not any? (turtles-on hyp-neighbors) [set test-h-s 0]
    report test-h-s
end
to moving-stage
   ask turtles [if move? and not am-i-the-best? [move-agent]] 
end
to decision-stage
   ask turtles [ 
   ifelse random-float 1 < likelihood-to-move
   [if not am-i-the-best? [set move? true]]
   [ 
   ifelse random-float 1 < theta_2 
   [if not am-i-the-best? and not is-my-rule-the-best? [set rule? true]]
   [if random-float 1 < theta_1 and not am-i-the-best? [set behavior? true]]
   ]
   ]
   ask turtles [
     if move? and all? neighbors [any? turtles-here] and not conflict?
     [set move? false
      ifelse is-my-rule-the-best? [set behavior? true] [set rule? true] 
      ]
     if (rule? or behavior?) and all? neighbors [not any? turtles-here]
     [set move? true
      set rule? false
      set behavior? false ]
     if age < 12 [set rule? false]
     ]
end
to reset-decisions
  ask turtles [
  set move? false
  set rule? false
  set behavior? false
  ] 
end   
to replacement
  ask turtles [    
     let index1 floor age / 5
     let index2 floor (age + 1) / 5
     if index1 > 20 [set index1 20]
     if index2 > 20 [set index2 20]
     
     let ex1 item index1 life-distribution
     let ex2 item index2 life-distribution
     
     let prob-death 1 - (ex1 / (ex2 + 1))
     ifelse  random-float 1  < prob-death [replace][set age age + 1]
  ]
end   
to stabilization
  set counterfactual-reflection? true
    repeat 20 [
  ask turtles [interact]
  ask turtles [select-behavior]    
  ]
    ;repeat 20 [ask turtles[select-rule]]
    set counterfactual-reflection? false
    
end
to set-outputs
    set cooperation-rate count turtles with [cooperate?] / count turtles
    set fraction-best count turtles with [shape = "face happy"]/ count turtles
    set satisfaction-rate mean [satisfaction] of turtles
  set maxi count turtles with [rule = 1] / count turtles
  set mini count turtles with [rule = 2] / count turtles
  set conf count turtles with [rule = 3] / count turtles
  set anti count turtles with [rule = 4] / count turtles
end
to update-plots
  set-current-plot "cooperation"
  set-current-plot-pen "cooperation"
  plot cooperation-rate
  set-current-plot-pen "satisfaction"
  plot satisfaction-rate
  set-current-plot-pen "fraction-best"
  plot fraction-best 
  set-current-plot "population"
  set-current-plot-pen "maxi"
  plot maxi
  set-current-plot-pen "mini"
  plot mini
  set-current-plot-pen "conf"
  plot conf
  set-current-plot-pen "anti"
  plot anti
  set-current-plot "track"
  set-current-plot-pen "pen1"
  plot count turtles with [rule?]
  set-current-plot-pen "pen2"
  plot count turtles with [move?]
  
end
to update-views
  ask turtles [establish-color]
 end

to establish-color  ;; agent procedure
  if rule = 1 
    [set color red
      ]
  if rule = 2
    [set color green
      ]
  if rule = 3
    [set color blue
      ]
  if rule = 4  
    [set color white
      ]
    
end
to replace  
    ifelse random-float 1.0 < 0.5 [set cooperate? true][set cooperate? false]        
    set age 0
    set rule? false
    set behavior? false
    set move? false
    ;set theta_1 random-float 1.0
    ;set theta_2 random-float 1.0
    ;set weighting-history random-float 1.0
    ;set likelihood-to-move random-float 1.0
    set rule (random 4) + 1
 
end
to init-age-USA2010
  let census-dist (list 0.0654 0.0659 0.0670 0.0714 0.0699 0.0683 0.0647 0.0654 0.0677 0.0735 0.0722 0.0637 0.0545 0.0403 0.0301 0.0237 0.0186 0.0117 0.0047 0.0012 0.0002)
  ask turtles [
    let temp-init random 21
    while [random-float 1 > item temp-init census-dist][set temp-init random 21]
    set age (temp-init * 5) + random 5
    ]
end
to set-life-distribution-USA2010 ;;Life expectation for ages according data colected by the Centers for Disease Control
                                 ;and Prevention’s National Center for Health Statistics (NCHS) USA 2010
                                 ;Murphy, Xu, and Kochanek 'Deaths: preliminary data 2010' National Vital Stat. Reports 60-4
                                 ;Reported ages have an interval of 5 years starting from 0 until 100 years

  set life-distribution (list 78.7 74.3 69.3 64.4 59.5 54.8 50.0 45.3 40.6 36.0 31.5 27.2 23.1 19.2 15.5 12.2 9.2 6.6 4.7 3.3 2.4) 
end
to interact  ;; calculates the agent's payoff for Prisioner's Dilema. Each agents plays only with its neighbors
          
  let total-cooperators count (turtles-on neighbors) with [cooperate?]
  set inst-score 0
  ifelse cooperate?
  ;[set inst-score total-cooperators + 1]
  ;[set inst-score total-cooperators * strength-of-dilemma]
    [set inst-score total-cooperators * ( 1 - strength-of-dilemma)]                   ;; cooperator gets score of # of neighbors who cooperated
    [set inst-score total-cooperators + (count (turtles-on neighbors) - total-cooperators) * strength-of-dilemma ]  ;; non-cooperator get score of a multiple of the neighbors who cooperated
  set last-score score
  set score inst-score * ( 1 - weighting-history) + last-score * weighting-history   
end
to-report majority-rules  ;; reports a set with the number of the most frequent rules in agent's neighborhood (agent included)
                          ;; be careful when use in an ask cycle as the command is applied to "self"
  let mylist [rule] of (turtle-set turtles-on neighbors self)
  set mylist modes mylist
  report mylist
end
to-report minority-rules ;; reports a set with the number of the less frequent rules in agent's neighborhood (agent included)
                         ;; be careful when use in an ask cycle as the command is applied to "self"
  let mylist_1 [rule] of (turtle-set turtles-on neighbors self)
  let mylist []
  let j 1
  while [empty? mylist] [
  let i 1
  repeat 4 [
    if length filter [? = i] mylist_1 = j  [set mylist lput i mylist] 
    set i i + 1
    ]
  set j j + 1
  ] 
  report mylist
end
to-report majority-behavior
  let mylist [cooperate?] of (turtle-set turtles-on neighbors self)
  report one-of modes mylist
end
to-report am-i-the-best? ;; reports true if the agents is the best in its neighborhood (according with its rule) and false otherwise
  let test false
  ;; In the model, an isolated agent can not consider himself as the best
  if any? turtles-on neighbors [
  if (rule = 1) and (score >= [score] of max-one-of turtles-on neighbors [score] * 0.99) [set test true]
  if (rule = 2) and (score <= [score] of min-one-of turtles-on neighbors [score] * 1.01) [set test true]
  if (rule = 3) and (member? rule majority-rules) [set test true]
  if (rule = 4) and (member? rule minority-rules) and not all? (turtles-on neighbors) [rule = 4] [set test true]  
  ]
  report test
end
to-report best-elements ;; report a list with the agents with the best performance according agents
  
  let myset (turtle-set turtles-on neighbors self)
  if rule = 1 [set myset myset with [score >= [score] of max-one-of myset [score] * 0.99]]
  
  if rule = 2 [set myset myset with [score <= [score] of min-one-of myset [score] * 1.1]]
  if rule = 3 [
    let rules-list majority-rules
    set myset myset with [member? rule rules-list]
    ] 
  if rule = 4 [
    let rules-list minority-rules
    if not empty? rules-list [
    set myset myset with [member? rule rules-list]
    ]  
  ]
  report myset
end  
to-report is-my-rule-the-best? ;; reports true if the agent's rule is used by any of the best valuated agents in its neighborhood (according with its rule) and false otherwise
  let test false
  ifelse am-i-the-best? [set test true][
  if member? rule [rule] of best-elements [set test true] 
  ]
  report test
end
to select-rule
                 ;; the agent changes its rule if every more succesfull neighbor has a different rule (if them exist).
                 ;; The agent never change his rule nor behavior if is in the set of agents with best performance (according its rule)
       
     if not am-i-the-best? 
     [
     if not is-my-rule-the-best? [
       ifelse counterfactual-reflection?
       [copy-strategy agent-after-reflex]       
       [copy-strategy (one-of best-elements)]
       ]
     ] 
end
to-report agent-after-reflex
  let test-agent self
  let test-score score
  
    if rule = 1 [
      ask best-elements [
      let temp-score ([inst-score] of myself * (1 - weighting-history) + [last-score] of myself * weighting-history)   
      if test-score < temp-score [
        set test-agent self
        set test-score temp-score
        ]
      ]
      ]
    if rule = 2 [
      ask best-elements [
      let temp-score ([inst-score] of myself * (1 - weighting-history) + [last-score] of myself * weighting-history)   
      if test-score > temp-score [
        set test-agent self
        set test-score temp-score
        ]
      ]
      ]
    if rule = 3 [
      let test-rule one-of majority-rules
      foreach majority-rules [
        if count (turtles-on neighbors) with [rule = test-rule] < count (turtles-on neighbors) with [rule = ?] [set test-rule ?]
        ]
      set test-agent one-of (turtles-on neighbors) with [rule = test-rule]
      ]  
    if rule = 4 [
     
      let test-rule one-of minority-rules
      foreach minority-rules [
        if count (turtles-on neighbors) with [rule = test-rule] > count (turtles-on neighbors) with [rule = ?] [set test-rule ?]
        ]
      set test-agent one-of (turtles-on neighbors) with [rule = test-rule]
      
    ]  
  report test-agent
end
to-report patch-after-reflex
  let my-turtle self
  let test-patch patch-here
  let test-satisfaction satisfaction
    
      ask test-patch-set [
      let temp-satisfaction counterfactual-satisfaction my-turtle   
      if test-satisfaction < temp-satisfaction [
        set test-patch self
        set test-satisfaction temp-satisfaction
        ]
      ]
   report test-patch
end
to-report test-patch-set
  let best-set other best-elements
  let my-set (patch-set neighbors with [any? best-set]) 
  report my-set
end
to-report counterfactual-satisfaction [my-turtle]
  let my-patch self
  let s-test 0
  let d-test 0
  set d-test distance my-turtle
  if d-test = 1 [
    let test-neighbors nobody
    ask my-turtle [set test-neighbors (patch-set neighbors with [distance my-turtle + distance my-patch = 2] my-patch)]
    set s-test hypothetical-satisfaction my-turtle test-neighbors
    ]
  if d-test = sqrt(2)[
    let test-neighbors nobody
    ask my-turtle [set test-neighbors (patch-set neighbors with [distance my-turtle + distance my-patch = 1 + sqrt(2)] my-patch)]
    set s-test hypothetical-satisfaction my-turtle test-neighbors
    ]
  report s-test
end
to copy-strategy [temp-agent]
  
      set rule [rule] of temp-agent 
      set theta_1 [theta_1] of temp-agent 
      set theta_1 add-noise "theta_1" Transcription-error
            
      set theta_2 [theta_2] of temp-agent 
      set theta_2 add-noise "theta_2" Transcription-error
      
      set weighting-history [weighting-history] of temp-agent 
      set weighting-history add-noise "weighting-history" Transcription-error
      
      set likelihood-to-move [likelihood-to-move] of temp-agent 
      set likelihood-to-move add-noise "likelihood-to-move" Transcription-error
      
     
end
to-report add-noise [value noise-std]
      let epsilon random-normal 0.0 noise-std
      if ( epsilon <= -100 )
      [ set epsilon -99] 
      let noisy-value runresult value * 100 / ( 100 + epsilon )
      if (noisy-value > 1) [set noisy-value 1]
      if (noisy-value < 0) [set noisy-value 0]     
      report noisy-value
end
to select-behavior  ;; patch procedure
  if any? turtles-on neighbors
  [
  if (rule = 1) or (rule = 2) 
  [set cooperate? [cooperate?] of one-of best-elements]
                                                                ;;choose behavior (cooperate, not cooperate)
                                                                ;; of neighbor who performed best according
                                                                ;; the agent's rule 
  
  if rule = 3
  [set cooperate? majority-behavior]                                                              
  if rule = 4 
  [set cooperate? not majority-behavior]
  ]   
end
to move-agent
  ifelse conflict?
  [ if any? turtles-on neighbors
    [
      let target one-of other best-elements
      if target = nobody [set target one-of turtles-on neighbors]
      ifelse random-float 1 < (1 - satisfaction)*(1 - [satisfaction] of target) [interchange-agents target][move-to-empty]
    ]
    ]
  [move-to-empty]
end
to move-agent-test1
  ifelse conflict?
  [ if any? turtles-on neighbors
    [
      let target one-of other best-elements
      if target = nobody [set target one-of turtles-on neighbors]
      ifelse random-float 1 < ((1 - satisfaction)+(1 - [satisfaction] of target))* 0.5 [interchange-agents target][move-to-empty]
      ;ifelse random-float 1 < (1 - satisfaction)*(1 - [satisfaction] of target)*(1 - [satisfaction] of target) [interchange-agents target][move-to-empty]
      ;ifelse random-float 1 < (1 - satisfaction)*(1 - satisfaction)*(1 - [satisfaction] of target) [interchange-agents target][move-to-empty]
    ]
    ]
  [move-to-empty]
end
to move-to-empty
  if any? neighbors with [not any? turtles-here] 
  [move-to one-of neighbors with [not any? turtles-here]]
end
to interchange-agents [my-target]
   let my-patch patch-here
   let target-patch patch-here
   ask my-target [
     set target-patch patch-here
     move-to my-patch
     ]  
   move-to target-patch 
end
@#$#@#$#@
GRAPHICS-WINDOW
231
10
569
369
20
20
8.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
1
1
1
ticks

BUTTON
6
10
87
43
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

BUTTON
101
10
178
43
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

TEXTBOX
246
450
386
604
 Strategies colormap\n\nRed       Maxi\nGreen    mini\nYellow    Conformist\nWhite     Anti-conformist\n                      \n                       
11
0.0
0

SLIDER
4
116
179
149
strength-of-dilemma
strength-of-dilemma
0
0.5
0.07
0.01
1
NIL
HORIZONTAL

PLOT
573
10
991
130
cooperation
time
NIL
0.0
100.0
0.0
1.0
true
true
PENS
"cooperation" 1.0 0 -13791810 true
"satisfaction" 1.0 0 -6459832 true
"fraction-best" 1.0 0 -955883 true

PLOT
776
132
991
255
population
time
fraction
0.0
100.0
0.0
1.0
true
false
PENS
"maxi" 1.0 0 -2674135 true
"mini" 1.0 0 -10899396 true
"conf" 1.0 0 -13345367 true
"anti" 1.0 0 -16777216 true

SLIDER
5
151
177
184
inicoop
inicoop
0
100
56
1
1
NIL
HORIZONTAL

SLIDER
4
81
176
114
density
density
0
1
0.39
0.01
1
NIL
HORIZONTAL

SLIDER
8
201
182
234
Transcription-error
Transcription-error
0
1
0.06
0.01
1
NIL
HORIZONTAL

SLIDER
9
239
230
272
Initial-prob-update-rule
Initial-prob-update-rule
0
1.0
1
0.01
1
NIL
HORIZONTAL

SWITCH
15
404
154
437
random-init
random-init
0
1
-1000

SWITCH
13
448
223
481
Counterfactual-reflection?
Counterfactual-reflection?
1
1
-1000

SLIDER
10
283
231
316
Initial-prob-update-behavior
Initial-prob-update-behavior
0
1
1
0.01
1
NIL
HORIZONTAL

SLIDER
11
326
235
359
Initial-weighting-history
Initial-weighting-history
0
1
0.46
0.01
1
NIL
HORIZONTAL

SLIDER
12
363
235
396
Initial-like-to-move
Initial-like-to-move
0
1
0.15
0.01
1
NIL
HORIZONTAL

PLOT
575
266
930
386
distribution theta
1/theta
NIL
1.0
5.0
0.0
500.0
true
true
PENS
"default" 1.0 0 -16777216 true

PLOT
575
394
926
529
distribution lambda
lambda
NIL
0.0
1.0
0.0
500.0
true
false
PENS
"default" 1.0 0 -16777216 true

TEXTBOX
394
451
592
616
Hubnet clients represent:\n1. The agent actions: cooperate-green defect-red\n2. The payoffs : grayscale\nDo not close the hubnet clients nor tick reset
12
0.0
1

PLOT
571
134
771
254
track
time
NIL
1.0
100.0
0.0
1.0
true
false
PENS
"pen1" 1.0 0 -2674135 true
"pen2" 1.0 0 -13345367 true

SWITCH
15
489
147
522
conflict?
conflict?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

Agents play a Prissioner's Dilemma with payoff matrix


                                 Payoff Matrix
                                 -------------
                                    OPPONENT
          BEHAVIORS   Cooperate            Defect
                        -----------------------------
           Cooperate |(1-p, 1-p)            (0, 1)
      YOU            |
           Defect    |(1, 0)                (p, p)
    
            (x, y) = x: your score, y: your partner's score
            Note: higher the score (amount of the benefit), the better.

whit each one of their neighbours in a torus.  
The agents can have one of 4 valuation functions:

Maxi : The agent tries to maximize the score (payoff)  
mini : The agent tries to minimize the score  
Conformist: The agent tries to behaves as the majority   
Anti-conformist: The agent tries to behaves like the minority
   
## HOW TO USE IT

Decide what percentage of patches should cooperate at the initial stage of the simulation and change the INITIAL-COOPERATION slider to match what you would like.  Next, determine the DEFECTION-AWARD multiple (mentioned as alpha in the payoff matrix above) for defecting or not cooperating.  The Defection-Award multiple varies from range of 0 to 3.  Press SETUP and note that red patches (that will defect) and green patches (cooperate) are scattered across the space.  Press GO to make the patches interact with their eight neighboring patches.  First, they count the number of neighboring patches that are cooperating.  If a patch is cooperating, then its score is number of neighboring patches that also cooperated.   If a patch is defecting, then its score is the product of the number of neighboring patches who are cooperating and the Defection-Award multiple.


## HOW IT WORKS

Each patch will either cooperate (blue) or defect (red) in the initial start of the model.  At each cycle, each patch will interact with all of its 8 neighbors to determine the score for the interaction.  Should a patch have cooperated, its score will be the number of neighbors that also cooperated.  Should a patch defect, then the score for this patch will be the product of the Defection-Award multiple and the number of neighbors that cooperated (i.e. the patch has taken advantage of the patches that cooperated).

In the subsequent round, the patch will set its old-cooperate? to be the strategy it used in the previous round.  For the upcoming round, the patch will adopt the strategy of one of its neighbors that scored the highest in the previous round.

If a patch is green, then the patch cooperated in the previous and current round.  
If a patch is red, then the patch defected in the previous iteration as well as the current round.  
If a patch is green, then the patch cooperated in the previous round but defected in the current round.  
If a patch is yellow, then the patch defected in the previous round but cooperated in the current round.


## THINGS TO NOTICE

Notice the effect the Defection-Award multiple plays in determining the number of patches that will completely cooperate (red) or completely defect (blue). At what Defection-Award multiple value will a patch be indifferent to defecting or cooperating?  At what Defection-Award multiple value will there be a dynamic change between red, blue, green, and yellow - where in the end of the model no particular color dominates all of the patches (i.e. view is not all red or all blue)?

Note the Initial-Cooperation percentage.  Given that Defection-Award multiple is low (below 1), if the initial percentage of cooperating patches is high, will there be more defecting or cooperating patches eventually?  How about when the Defection-Award multiple is high?  Does the initial percentage of cooperation effect the outcome of the model, and, if so, how?


## THINGS TO TRY

Increase the Defection-Award multiple by moving the "Defection-Award" slider (just increase the "Defection-Award" slider while model is running), and observe how the histogram for each color of patch changes. In particular, pay attention to the red and blue bars.  Does the number of pure cooperation or defection decrease or increase with the increase of the Defection-Award multiple?  How about with a decrease of the Defection-Award multiple? (Just increase the "Defection-Award" slider while model is running.)

At each start of the model, either set the initial-cooperation percentage to be very high or very low (move the slider for "initial-cooperation"), and proportionally value the Defection-Award multiple (move the slider for "Defection-Award" in the same direction) with regards to the initial-cooperation percentage.  Which color dominates the world, when the initial-cooperation is high and the Defection-Award is high?  Which color dominates the world when initial-cooperation is low and the Defection-Award multiple is also low?


## EXTENDING THE MODEL

Alter the code so that the patches have a strategy to implement.  For example, instead of adopting to cooperated or defect based on the neighboring patch with the maximum score.  Instead, let each patch consider the history of cooperation or defection of it neighboring patches, and allow it to decide whether to cooperate or defect as a result.

Implement these four strategies:  
1.  Cooperate-all-the-time: regardless of neighboring patches' history, cooperate.  
2.  Tit-for-Tat:  only cooperate with neighboring patches, if they have never defected.  Otherwise, defect.  
3.  Tit-for-Tat-with-forgiveness: cooperate if on the previous round, the patch cooperated.  Otherwise, defect.  
4.  Defect-all-the-time: regardless of neighboring patches' history, defect.

How are the cooperating and defecting patches distributed?  Which strategy results with the highest score on average?  On what conditions will this strategy be a poor strategy to use?

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Wilensky, U. (2002).  NetLogo PD Basic Evolutionary model.  http://ccl.northwestern.edu/netlogo/models/PDBasicEvolutionary.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:  
- Copyright 2002 Uri Wilensky. All rights reserved. See http://ccl.northwestern.edu/netlogo/models/PDBasicEvolutionary for terms of use.

## COPYRIGHT NOTICE

Copyright 2002 Uri Wilensky. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:  
a) this copyright notice is included.  
b) this model will not be redistributed for profit without permission from Uri Wilensky. Contact Uri Wilensky for appropriate licenses for redistribution for profit.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
55
40
385
370
0
0
0
1
1
1
1
1
0
1
1
1
-20
20
-20
20

@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
