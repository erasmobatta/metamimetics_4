globals [
  cooperation-rate
  satisfaction-rate
  fraction-best
  
  mean-score
  mean-connectivity
  mean-theta1
  mean-theta2
  mean-alpha
  mean-mu
  mean-pc
  
  conflict-rate
   
  maxi
  mini
  conf
  anti
  
  best-maxi
  best-mini
  best-conf
  best-anti
    
  life-distribution
  
  rate-theta
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
  conflict?
  ;reflect?
 
  theta_1
  theta_2
  ;prob-reflection
  prob-conflict
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
      set conflict? false
      ;set reflect? false
      ifelse random-init [
      set theta_1 random-float 1.0
      set theta_2 random-float 1.0
      set weighting-history random-float 1.0   
      set likelihood-to-move random-float 1.0
     ; set prob-reflection random-float 1.0
      set prob-conflict random-float 1.0
        ]  
      [
      set theta_1 Initial-prob-update-behavior
      set theta_2 Initial-prob-update-rule
      set weighting-history Initial-weighting-history
      set likelihood-to-move Initial-like-to-move 
      ;set prob-reflection Initial-prob-reflection
      set prob-conflict Initial-prob-conflict
      ]
      
  ]
  stabilization
  update-views
  init-age-USA2007
  ifelse timescale [set-life-distribution-USA2007-months][set-life-distribution-USA2007] 
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
    do-plots
    reset-decisions 
    if replacement? [replacement]
    update-views
    tick
    if ticks = 7000 [stop]
end
to learning-stage
    ask turtles [ 
   if rule?   
   [     
       select-rule
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
   ask turtles [if move? [move-agent]] 
end
to decision-stage
   ask turtles [ 
   ifelse random-float 1 < likelihood-to-move
   [if not am-i-the-best? [
       set move? true
    if random-float 1.0 < prob-conflict [set conflict? true]
   ] 
     ]
   [ 
   ifelse random-float 1 < theta_2 
   [if not am-i-the-best? and not is-my-rule-the-best? [set rule? true]]
   [if random-float 1 < theta_1 and not am-i-the-best? [set behavior? true]]
   ]
   ]
   ask turtles [
     if move? and not conflict? and all? neighbors [any? turtles-here] [set conflict? true ]
     if not move? and all? neighbors [not any? turtles-here]
     [
      set move? true  
      set rule? false
      set behavior? false
       ]
      if age < 10 [set rule? false]
     ]
end
to reset-decisions
  ask turtles [
  set move? false
  set rule? false
  set behavior? false
  set conflict? false
  ] 
end   
to replacement  
  ask turtles [  
     let x age  
     if x >= length life-distribution [set x length life-distribution - 1]
     ifelse  random-float 1  < item x life-distribution [replace][set age age + 1]
  ]
end    
to stabilization
  ;set reflect? true
    repeat 10 [
  ask turtles [interact]
  ask turtles [select-behavior]    
  ]
    repeat 10 [ask turtles[select-rule]]
   ;set reflect? false
    
end
to set-outputs
    set cooperation-rate count turtles with [cooperate?] / count turtles
    set fraction-best count turtles with [shape = "face happy"]/ count turtles
    set satisfaction-rate mean [satisfaction] of turtles
    set mean-score mean [score] of turtles
    set mean-connectivity mean [count turtles-on neighbors] of turtles
    set mean-theta1 mean [theta_1] of turtles
    set mean-theta2 mean [theta_2] of turtles
    set mean-alpha mean [weighting-history] of turtles
    set mean-mu mean [likelihood-to-move] of turtles
    set mean-pc mean [prob-conflict] of turtles
    
    set conflict-rate count turtles with [conflict?] / (count turtles with [rule? or behavior? or (move? and not conflict?)] + 1)
     
  set maxi count turtles with [rule = 1] / count turtles
  set mini count turtles with [rule = 2] / count turtles
  set conf count turtles with [rule = 3] / count turtles
  set anti count turtles with [rule = 4] / count turtles
  set rate-theta mean [theta_2] of turtles / mean [theta_1] of turtles
  
  set best-maxi [score] of max-one-of turtles with [rule = 1] [score]
  set best-mini [score] of min-one-of turtles with [rule = 2] [score]
  set best-conf [count turtles-on neighbors] of max-one-of turtles with [rule = 3] [count turtles-on neighbors]
  set best-anti [count turtles-on neighbors] of min-one-of turtles with [rule = 4] [count turtles-on neighbors] 
end
to do-plots
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
  set-current-plot "distribution theta"
  set-current-plot-pen "theta_1"
  set-histogram-num-bars 100
  histogram [1 / theta_1] of turtles
  
  set-current-plot-pen "theta_2"
  set-histogram-num-bars 1000
  histogram [1 / theta_2] of turtles
 ; set-current-plot-pen "fight"
 ; set-histogram-num-bars 1000
 ; histogram [prob-conflict] of turtles
  
   
  set-current-plot "distribution alpha"
  set-current-plot-pen "alpha"
    plot mean [weighting-history] of turtles
  set-current-plot-pen "mu"
    plot mean [likelihood-to-move] of turtles
  set-current-plot-pen "fight"
    plot conflict-rate
      
  set-current-plot "track"
  set-current-plot-pen "pen1"
  plot mean-theta1
  set-current-plot-pen "pen2" 
  plot mean-theta2
  ;set-current-plot-pen "pen3" 
  ;plot conflict-rate
      
  plot-age-hist
  plot-rule-theta
 
 
  
end
to update-views
  ask turtles [
    establish-color
    ifelse am-i-the-best? [set shape "face happy"][set shape "face sad"]
    ]
      
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
  ;ifelse cooperate? [set size 1][set size 0.7]  
end
to replace  
    ifelse random-float 1.0 < 0.5 [set cooperate? true][set cooperate? false]        
    set age 0
    set rule? false
    set behavior? false
    set move? false
    if random-init
    [
    set theta_1 random-float 1.0
    set theta_2 random-float 1.0
    set weighting-history random-float 1.0
    set likelihood-to-move random-float 1.0
    set prob-conflict random-float 1.0
    ]
   
    set rule (random 4) + 1
    ;move-to one-of patches with [not any? turtles-here]
end
to init-age-USA2010
  let census-dist (list 0.0654 0.0659 0.0670 0.0714 0.0699 0.0683 0.0647 0.0654 0.0677 0.0735 0.0722 0.0637 0.0545 0.0403 0.0301 0.0237 0.0186 0.0117 0.0047 0.0012 0.0002)
   
    ask turtles [
    let temp-init random 21
    while [random-float 1 > item temp-init census-dist][set temp-init random 21]
    set age (temp-init * 5) + random 5
    if timescale [ set age age * 12 + random 12]
    ]
    
end
to init-age-USA2007
  let census-dist (list 0.069 0.067 0.069 0.071 0.069 0.07 0.065 0.07 0.074 0.076 0.07 0.061 0.047 0.036 0.028 0.025 0.019 0.013)
   
    ask turtles [
    let temp-init random 18
    while [random-float 1 > item temp-init census-dist][set temp-init random 18]
    set age (temp-init * 5) + random 5
    if timescale [ set age age * 8 + random 8]
    ]
    
end
to set-life-distribution-USA2010 ;;Life expectation for ages according data colected by the Centers for Disease Control
                                 ;and Prevention’s National Center for Health Statistics (NCHS) USA 2010
                                 ;Murphy, Xu, and Kochanek 'Deaths: preliminary data 2010' National Vital Stat. Reports 60-4
                                 ;Reported ages have an interval of 5 years starting from 0 until 100 years

  set life-distribution (list 78.7 74.3 69.3 64.4 59.5 54.8 50.0 45.3 40.6 36.0 31.5 27.2 23.1 19.2 15.5 12.2 9.2 6.6 4.7 3.3 2.4) 
end
to set-life-distribution-USA2007 ;;Life expectation for ages according data colected by the Centers for Disease Control
                                 ;and Prevention’s National Center for Health Statistics (NCHS) USA 2010
                                 ;Murphy, Xu, and Kochanek 'Deaths: preliminary data 2010' National Vital Stat. Reports 60-4
                                 ;Reported ages have an interval of 5 years starting from 0 until 100 years 

  set life-distribution (list 0.0067375 0.000464 0.0002865 0.0002165 0.000174 0.0001575 0.000147 0.000137 0.000124 0.000107 9.45e-05 9.8e-05 0.0001325 0.0002045 0.000305 0.000415 0.000521 0.000621 0.000709 0.000785 0.000863 0.0009375 0.000988 0.001006 0.001 0.000987 0.000978 0.000976 0.0009865 0.0010085 0.001035 0.0010655 0.001104 0.00115 0.001207 0.0012735 0.001354 0.0014505 0.001566 0.0017 0.00185 0.002016 0.0022 0.0024015 0.002621 0.0028585 0.0031155 0.003395 0.0036985 0.0040245 0.0043835 0.0047625 0.005141 0.005511 0.005887 0.006297 0.006758 0.00727 0.007839 0.008471 0.009184 0.0099695 0.0108055 0.011686 0.0126375 0.0137105 0.014928 0.016282 0.0177855 0.0194565 0.021371 0.0235095 0.0257935 0.028209 0.030833 0.0338595 0.037323 0.04111 0.0452255 0.049783 0.055009 0.0609785 0.0676135 0.074947 0.083097 0.092204 0.102388 0.113735 0.126297 0.140086 0.155102 0.171327 0.188734 0.20729 0.226949 0.246645 0.266066 0.284872 0.302715 0.319238 0.33667 0.355063 0.374468 0.394942 0.416545 0.43934 0.463392 0.488773 0.515555 0.543816 0.57364 0.605114 0.638328 0.67338 0.710373 0.749416 0.789422 0.828894 0.870338 0.913855)
    
end
to set-life-distribution-USA2007-months
  set life-distribution (list
    0.00673750000000000  0.00482226617500628  0.00345146583489569  0.00247033572538884  0.00176810633164411  0.00126549600844554  0.000905760088479763  0.000648284413706369  0.000464000000000000  0.000436861538878166  0.000411310353773705  0.000387253607987293  0.000364603894658299  0.000343278919184046  0.000323201200213741  0.000304297788130701  0.000286500000000000  0.000276640834245358  0.000267120946499014  0.000257928661374858  0.000249052705265372  0.000240482192515447  0.000232206612071993  0.000224215814592964  0.000216500000000000  0.000210665936904966  0.000204989085321234  0.000199465208842909  0.000194090185223262  0.000188860003298461  0.000183770759994205  0.000178818657413011  0.000174000000000000  0.000171846488418622  0.000169719629780527  0.000167619094215472  0.000165544555935857  0.000163495693186191  0.000161472188193192  0.000159473727116499  0.000157500000000000  0.000156147543092883  0.000154806699771072  0.000153477370308384  0.000152159455834989  0.000150852858330055  0.000149557480614456  0.000148273226343548  0.000147000000000000  0.000145711134230601  0.000144433568971212  0.000143167205141286  0.000141911944528993  0.000140667689783603  0.000139434344407940  0.000138211812750893  0.000137000000000000  0.000135303243264230  0.000133627501005982  0.000131972512959150  0.000130338022081049  0.000128723774512488  0.000127129519538343  0.000125555009548622  0.000124000000000000  0.000121735416714837  0.000119512190989798  0.000117329567521341  0.000115186804799855  0.000113083174857750  0.000111017963022137  0.000108990467672034  0.000107000000000000  0.000105351271499624  0.000103727947725117  0.000102129637223249  0.000100555954572566  9.90065202904512e-05  9.74809607416110e-05  9.59789080479782e-05  9.45000000000000e-05  9.49305707329649e-05  9.53631032771054e-05  9.57976065710296e-05  9.62340895940726e-05  9.66725613664824e-05  9.71130309496059e-05  9.75555074460760e-05  9.80000000000000e-05  0.000101765319635228  0.000105675308984286  0.000109735526493238  0.000113951744172698  0.000118329955803329  0.000122876385456614  0.000127597496342998  0.000132500000000000  0.000139886420567755  0.000147684608749123  0.000155917519176334  0.000164609386123635  0.000173785794842949  0.000183473756876245  0.000193701789566313  0.000204500000000000  0.000214978054456681  0.000225992977496234  0.000237572276885149  0.000249744869817180  0.000262541155128775  0.000275993089214640  0.000290134265833019  0.000305000000000000  0.000316970154486588  0.000329410094541809  0.000342338257561832  0.000355773804544404  0.000369736648487610  0.000384247483903184  0.000399327817488115  0.000415000000000000  0.000426969448044210  0.000439284119429343  0.000451953971102009  0.000464989247187502  0.000478400487272628  0.000492198534927410  0.000506394546472590  0.000521000000000000  0.000532561120764876  0.000544378785701230  0.000556458687588618  0.000568806645530799  0.000581428607758910  0.000594330654496827  0.000607519000890119  0.000621000000000000  0.000631372889140177  0.000641919042095354  0.000652641352982027  0.000663542764258642  0.000674626267533073  0.000685894904383592  0.000697351767193550  0.000709000000000000  0.000718082202343384  0.000727280746575918  0.000736597123022816  0.000746032841100175  0.000755589429559530  0.000765268436735528  0.000775071430796794  0.000785000000000000  0.000794350730229612  0.000803812844097221  0.000813387668377794  0.000823076545650525  0.000832880834487084  0.000842801909642120  0.000852841162246024  0.000863000000000000  0.000871978658514245  0.000881050731059447  0.000890217189515887  0.000899479015875301  0.000908837202346070  0.000918292751459519  0.000927846676177320  0.000937500000000000  0.000943668557671521  0.000949877703187038  0.000956127703606238  0.000962418827746008  0.000968751346191991  0.000975125531310229  0.000981541657258879  0.000988000000000000  0.000990232267613204  0.000992469578767599  0.000994711944858463  0.000996959377306819  0.000999211887559494  0.00100146948708918  0.00100373218739448  0.00100600000000000  0.00100524803566562  0.00100449663340913  0.00100374579281040  0.00100299551344959  0.00100224579490718  0.00100149663676399  0.00100074803860112  0.00100000000000000  0.000998365682010934  0.000996734035017158  0.000995105054653415  0.000993478736561584  0.000991855076390666  0.000990234069796774  0.000988615712443119  0.000987000000000000  0.000985870486221567  0.000984742265048378  0.000983615335001187  0.000982489694602442  0.000981365342376280  0.000980242276848529  0.000979120496546703  0.000978000000000000  0.000977749776042945  0.000977499616106369  0.000977249520173893  0.000976999488229140  0.000976749520255739  0.000976499616237324  0.000976249776157530  0.000976000000000000  0.000977306363660315  0.000978614475871872  0.000979924338975085  0.000981235955313502  0.000982549327233805  0.000983864457085817  0.000985181347222510  0.000986500000000000  0.000989223537113762  0.000991954593390636  0.000994693189589588  0.000997439346526896  0.00100019308507631  0.00100295442616919  0.00100572339079472  0.00100850000000000  0.00101177503320670  0.00101506070185466  0.00101835704048172  0.00102166408373790  0.00102498186638573  0.00102831042330063  0.00103164978947129  0.00103500000000000  0.00103876423383917  0.00104254215797438  0.00104633382219642  0.00105013927647717  0.00105395857097027  0.00105779175601175  0.00106163888212072  0.00106550000000000  0.00107023809720152  0.00107499726391510  0.00107977759383326  0.00108457918106517  0.00108940212013850  0.00109424650600125  0.00109911243402365  0.00110400000000000  0.00110964783272621  0.00111532455858150  0.00112103032537706  0.00112676528168026  0.00113252957681851  0.00113832336088315  0.00114414678473333  0.00115000000000000  0.00115697511797729  0.00116399254227702  0.00117105252950056  0.00117815533780567  0.00118530122691591  0.00119249045813015  0.00119972329433211  0.00120700000000000  0.00121511877143291  0.00122329215301460  0.00123152051207507  0.00123980421841515  0.00124814364432308  0.00125653916459126  0.00126499115653311  0.00127350000000000  0.00128329473854583  0.00129316481034897  0.00130311079481229  0.00131313327579496  0.00132323284164674  0.00133341008524249  0.00134366560401698  0.00135400000000000  0.00136570232244174  0.00137750578546733  0.00138941126321245  0.00140141963736777  0.00141353179724418  0.00142574863983871  0.00143807106990095  0.00145050000000000  0.00146445822048664  0.00147855076149665  0.00149277891560190  0.00150714398781271  0.00152164729569758  0.00153629016950403  0.00155107395228058  0.00156600000000000  0.00158215454507561  0.00159847573723079  0.00161496529556372  0.00163162495690646  0.00164845647600789  0.00166546162571852  0.00168264219717725  0.00170000000000000  0.00171806374070662  0.00173631942184167  0.00175476908291227  0.00177341478509682  0.00179225861147522  0.00181130266726164  0.00183054908003966  0.00185000000000000  0.00186997834947776  0.00189017244730572  0.00191058462337357  0.00193121723273173  0.00195207265586308  0.00197315329895758  0.00199446159418989  0.00201600000000000  0.00203813077588541  0.00206050449385479  0.00208312382082125  0.00210599145297411  0.00212911011610028  0.00215248256590920  0.00217611158836128  0.00220000000000000  0.00222423243503663  0.00224873178412226  0.00227350098724660  0.00229854301678259  0.00232386087784308  0.00234945760864149  0.00237533628085636  0.00240150000000000  0.00242789915924855  0.00245458851862579  0.00248157126823764  0.00250885063325819  0.00253642987431511  0.00256431228787948  0.00259250120665972  0.00262100000000000  0.00264957317308165  0.00267845784033345  0.00270765739754969  0.00273717527754435  0.00276701495055469  0.00279717992464920  0.00282767374614006  0.00285850000000000  0.00288942809599410  0.00292069082453038  0.00295229180623063  0.00298423470089067  0.00301652320790416  0.00304916106669111  0.00308215205713089  0.00311550000000000  0.00314913847838094  0.00318314015600046  0.00321750895437027  0.00325224883734317  0.00328736381157023  0.00332285792696288  0.00335873527715999  0.00339500000000000  0.00343153165238261  0.00346845640097312  0.00350577847565489  0.00354350215182663  0.00358163175089220  0.00362017164075556  0.00365912623632124  0.00369850000000000  0.00373775999614775  0.00377743674159861  0.00381753466019359  0.00385805822273330  0.00389901194747639  0.00394040040064334  0.00398222819692557  0.00402450000000000  0.00406771546525913  0.00411139498231042  0.00415554353418633  0.00420016615742759  0.00424526794265777  0.00429085403516407  0.00433692963548427  0.00438350000000000  0.00442917416568330  0.00447532423633087  0.00452195517066568  0.00456907197907847  0.00461667972416603  0.00466478352127526  0.00471338853905271  0.00476250000000000  0.00480824474447527  0.00485442887617302  0.00490105661549352  0.00494813222337479  0.00499566000168201  0.00504364429360060  0.00509208948403312  0.00514100000000000  0.00518585601885603  0.00523110341340309  0.00527674559845453  0.00532278601861845  0.00536922814855771  0.00541607549325212  0.00546333158826302  0.00551100000000000  0.00555665411528014  0.00560268643746320  0.00564910009968321  0.00569589826102960  0.00574308410676232  0.00579066084852854  0.00583863172458132  0.00588700000000000  0.00593675317251640  0.00598692682714175  0.00603752451752291  0.00608854982733984  0.00614000637055953  0.00619189779169190  0.00624422776604793  0.00629700000000000  0.00635285956575791  0.00640921465177732  0.00646606965373024  0.00652342900628189  0.00658129718343665  0.00663967869888695  0.00669857810636541  0.00675800000000000  0.00681997394317172  0.00688251621567643  0.00694563202935337  0.00700932664383677  0.00707360536699409  0.00713847355536835  0.00720393661462453  0.00727000000000000  0.00733880237029074  0.00740825587760454  0.00747836668422070  0.00754914101073758  0.00762058513662448  0.00769270540077883  0.00776550820208860  0.00783900000000000  0.00791534623463626  0.00799243602681087  0.00807027661824068  0.00814887532117163  0.00822823951906572  0.00830837666729458  0.00838929429383976  0.00847100000000000  0.00855700588960946  0.00864388499525570  0.00873164618268325  0.00882029840765040  0.00890985071684304  0.00900031224879789  0.00909169223483504  0.00918400000000000  0.00927869849578310  0.00937437345118113  0.00947103493471073  0.00956869311870749  0.00966735828039647  0.00976704080297376  0.00986775117669912  0.00996950000000000  0.0100703557740612  0.0101722318487555  0.0102751385458854  0.0103790862916733  0.0104840856178175  0.0105901471625599  0.0106972816717632  0.0108055000000000  0.0109118275667330  0.0110192014109588  0.0111276318281878  0.0112371292152400  0.0113477040712412  0.0114593669986302  0.0115721287041751  0.0116860000000000  0.0118009044183696  0.0119169386523614  0.0120341138110638  0.0121524411127970  0.0122719318861872  0.0123925975712509  0.0125144497204904  0.0126375000000000  0.0127668919890193  0.0128976087880740  0.0130296639615404  0.0131630712126768  0.0132978443850456  0.0134339974639496  0.0135715445778836  0.0137105000000000  0.0138570835261734  0.0140052342256916  0.0141549688537275  0.0143063043445888  0.0144592578136336  0.0146138465592061  0.0147700880645929  0.0149280000000000  0.0150908913353734  0.0152555601082562  0.0154220257136891  0.0155903077583478  0.0157604260628521  0.0159324006641002  0.0161062518176290  0.0162820000000000  0.0164627560022848  0.0166455186826413  0.0168303103183759  0.0170171534341088  0.0172060708045189  0.0173970854571202  0.0175902206750686  0.0177855000000000  0.0179862617310665  0.0181892896493452  0.0183946093354307  0.0186022466586700  0.0188122277804221  0.0190245791573536  0.0192393275447727  0.0194565000000000  0.0196861021421066  0.0199184137717191  0.0201534668629406  0.0203912937671939  0.0206319272176743  0.0208754003338547  0.0211217466260442  0.0213710000000000  0.0216272929443274  0.0218866594965023  0.0221491365169435  0.0224147613081202  0.0226835716198535  0.0229556056546816  0.0232309020732889  0.0235095000000000  0.0237835540544652  0.0240608028014916  0.0243412834821286  0.0246250337715505  0.0249120917841171  0.0252024960784936  0.0254962856628299  0.0257935000000000  0.0260837454707169  0.0263772569748636  0.0266740712640020  0.0269742255032466  0.0272777572759186  0.0275847045882511  0.0278951058741489  0.0282090000000000  0.0285243792697264  0.0288432845093126  0.0291657551394328  0.0294918310214880  0.0298215524625335  0.0301549602202613  0.0304920955080381  0.0308330000000000  0.0311959975551335  0.0315632686880905  0.0319348637117923  0.0323108335314953  0.0326912296517644  0.0330761041835290  0.0334655098512215  0.0338595000000000  0.0342742169296514  0.0346940133829738  0.0351189515748393  0.0355490944821384  0.0359845058531131  0.0364252502168050  0.0368713928926181  0.0373230000000000  0.0377766037992581  0.0382357204567189  0.0387004169727153  0.0391707611618666  0.0396468216629746  0.0401286679490403  0.0406163703374027  0.0411100000000000  0.0416032218122255  0.0421023611081789  0.0426074888835315  0.0431186769857332  0.0436359981242316  0.0441595258808140  0.0446893347200733  0.0452255000000000  0.0457715466649822  0.0463241862246884  0.0468834982808515  0.0474495633963053  0.0480224631065886  0.0486022799316891  0.0491890973879301  0.0497830000000000  0.0504080793241280  0.0510410071941744  0.0516818821571085  0.0523308039972634  0.0529878737518721  0.0536531937267994  0.0543268675124703  0.0550090000000000  0.0557219906966361  0.0564442227125743  0.0571758158277541  0.0579168913746240  0.0586675722582648  0.0594279829767721  0.0601982496419048  0.0609785000000000  0.0617708847904797  0.0625735662208601  0.0633866780907730  0.0642103559385089  0.0650447370636097  0.0658899605497557  0.0667461672879493  0.0676135000000000  0.0684894253212580  0.0693766981569682  0.0702754655129099  0.0711858762993053  0.0721080813554923  0.0730422334749153  0.0739884874304407  0.0749470000000000  0.0759203392222766  0.0769063192339325  0.0779051042013269  0.0789168604228527  0.0799417563566256  0.0809799626485329  0.0820316521606455  0.0830970000000000  0.0841842596969737  0.0852857453425215  0.0864016430721301  0.0875321414567244  0.0886774315345333  0.0898377068433729  0.0910131634533509  0.0922040000000000  0.0934194216459591  0.0946508648287004  0.0958985407421266  0.0971626633640721  0.0984434494930007  0.0997411187851862  0.101055893792384  0.102388000000000  0.103742075514020  0.105114058600193  0.106504186085149  0.107912697927538  0.109339837259446  0.110785850428371  0.112250987039741  0.113735500000000  0.115234613746229  0.116753486864195  0.118292379796289  0.119851556417720  0.121431284081754  0.123031833665562  0.124653479616667  0.126296500000000  0.127943062724790  0.129611092147444  0.131300868135293  0.133012674204378  0.134746797567018  0.136503529179998  0.138283163793389  0.140086000000000  0.141880396203356  0.143697777271258  0.145538437622516  0.147402675447225  0.149290792755072  0.151203095424260  0.153139893251059  0.155101500000000  0.157042508745560  0.159007808132734  0.160997702145352  0.163012498571429  0.165052509050777  0.167118049123209  0.169209438277337  0.171327000000000  0.173411939621883  0.175522251620723  0.177658244762062  0.179820231568920  0.182008528367523  0.184223455333582  0.186465336539143  0.188734500000000  0.190959899307533  0.193211538661681  0.195489727463119  0.197794778760715  0.200127009294547  0.202486739539429  0.204874293748943  0.207290000000000  0.209651074112598  0.212039041326480  0.214454207959391  0.216896883818095  0.219367382238115  0.221866020123931  0.224393117989626  0.226949000000000  0.229322352754063  0.231720525195788  0.234143776880732  0.236592370078792  0.239066569802592  0.241566643836165  0.244092862763934  0.246645500000000  0.248993274868951  0.251363397791425  0.253756081494589  0.256171540730523  0.258609992295492  0.261071655049408  0.263556749935471  0.266065500000000  0.268346731391538  0.270647521939229  0.272968039342236  0.275308452737561  0.277668932712382  0.280049651316478  0.282450782074777  0.284872500000000  0.287043987016511  0.289232026546384  0.291436744763848  0.293658268804916  0.295896726774712  0.298152247754868  0.300424961810957  0.302715000000000  0.304732673204297  0.306763794718587  0.308808454179308  0.310866741820350  0.312938748477034  0.315024565590122  0.317124285209852  0.319238000000000  0.321366713666017  0.323509621826023  0.325666819130445  0.327838400860851  0.330024462934156  0.332225101906859  0.334440414979310  0.336670500000000  0.338916358763153  0.341177199182210  0.343453121196676  0.345744225412732  0.348050613107682  0.350372386234429  0.352709647425984  0.355062500000000  0.357432033733673  0.359817380711817  0.362218646465195  0.364635937228834  0.367069359946731  0.369519022276578  0.371985032594531  0.374467500000000  0.376967604688507  0.379484401141863  0.382018000801407  0.384568515852507  0.387136059229530  0.389720744620839  0.392322686473830  0.394942000000000  0.397579878543000  0.400235375883715  0.402908609700815  0.405599698458961  0.408308761414058  0.411035918618541  0.413781290926693  0.416545000000000  0.419328401214170  0.422130401432814  0.424951124936604  0.427790696836666  0.430649243080134  0.433526890455737  0.436423766599418  0.439340000000000  0.442276921037274  0.445233474944715  0.448209792965072  0.451206007218432  0.454222250708085  0.457258657326428  0.460315361860906  0.463392500000000  0.466491544573823  0.469611314725359  0.472751949061706  0.475913587116926  0.479096369358251  0.482300437192318  0.485525932971454  0.488773000000000  0.492043140541659  0.495335159990627  0.498649204727948  0.501985422114029  0.505343960495194  0.508724969210278  0.512128598597271  0.515555000000000  0.519005757073783  0.522479611051645  0.525976716527770  0.529497229131088  0.533041305532195  0.536609103450329  0.540200781660390  0.543816500000000  0.547458002638862  0.551123889498263  0.554814323859758  0.558529470098266  0.562269493689395  0.566034561216808  0.569824840379647  0.573640500000000  0.577483307530537  0.581351857960532  0.585246323741212  0.589166878479052  0.593113696943512  0.597086955074831  0.601086829991869  0.605113500000000  0.609168900817158  0.613251480462400  0.617361421085094  0.621498906055353  0.625664119972212  0.629857248671873  0.634078479235985  0.638328000000000  0.642607714262073  0.646916122164665  0.651253416086275  0.655619789695217  0.660015437958266  0.664440557149370  0.668895344858404  0.673380000000000  0.677896657325465  0.682443609868185  0.687021060831575  0.691629214782025  0.696268277658039  0.700938456779446  0.705639960856658  0.710373000000000  0.715139842398363  0.719938671916803  0.724769703199684  0.729633152331704  0.734529236847565  0.739458175741698  0.744420189478061  0.749415500000000  0.754303270156316  0.759222918886136  0.764174654105013  0.769158685084554  0.774175222461253  0.779224478245402  0.784306665830045  0.789422000000000  0.794251322588469  0.799110188762832  0.803998779257229  0.808917275911449  0.813865861677696  0.818844720627388  0.823854037958010  0.828894000000000  0.833964597192257  0.839066212772734  0.844199036490366  0.849363259254837  0.854559073143686  0.859786671409447  0.865046248486840  0.870338000000000  0.875662222782577  0.881019016070220  0.886408579110377  0.891831112369377  0.897286817539883  0.902775897548399  0.908298556562814  0.913855000000000

    )
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
       ifelse reflect?
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
      if random-float 1 < 0.1 [set rule one-of [rule] of turtles-on neighbors]
        
      let theta_1T theta_1
      set theta_1 [theta_1] of temp-agent
      set theta_1 add-noise "theta_1" Transcription-error
      set theta_1 theta_1T * (1 - influence) + theta_1 * influence 
            
      let theta_2T theta_2
      set theta_2 [theta_2] of temp-agent 
      set theta_2 add-noise "theta_2" Transcription-error 
      set theta_2 theta_2T * (1 - influence) + theta_2 * influence 
      
      let weighting-historyT weighting-history
      set weighting-history [weighting-history] of temp-agent 
      set weighting-history add-noise "weighting-history" Transcription-error
      set weighting-history weighting-historyT * (1 - influence) + weighting-history * influence 
            
      let likelihood-to-moveT likelihood-to-move
      set likelihood-to-move [likelihood-to-move] of temp-agent 
      set likelihood-to-move add-noise "likelihood-to-move" Transcription-error 
      set likelihood-to-move likelihood-to-moveT * (1 - influence) + likelihood-to-move * influence 
     
     let prob-conflictT prob-conflict
      set prob-conflict [prob-conflict] of temp-agent 
      set prob-conflict add-noise "prob-conflict" Transcription-error 
      set prob-conflict prob-conflictT * (1 - influence) + prob-conflict * influence
end
to-report add-noise [value noise-std]
      let epsilon random-normal 0.0 noise-std * 100
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
  [     
      ifelse any? turtles-on neighbors
      [
      let target one-of other best-elements
      if target = nobody [set target one-of turtles-on neighbors]
      ifelse random-float 1 < 0.05 + 0.9 * (1 - satisfaction)*(1 - [satisfaction] of target) [interchange-agents target][move-to-empty]
      ]
      [move-to-empty]
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
to-report age-histogram2
  let mylist []
  let i 0
  let gap 1
  if timescale [set gap 12]
  let oldest floor (max [age] of turtles) / gap
  while [i <= oldest]
  [
    ifelse any? turtles with [age >= i and age < i + gap]
    [set mylist lput (mean [theta_2] of turtles with[age >= i and age < i + gap]) mylist]
    [set mylist lput 0 mylist]
    set i i + 1
    ]
  report mylist
end
to-report age-histogram1
  let mylist []
  let i 0
  let gap 1
  if timescale [set gap 12]
  let oldest floor (max [age] of turtles) / gap
  while [i <= oldest]
  [
    ifelse any? turtles with [age >= i and age < i + gap]
    [set mylist lput (mean [theta_1] of turtles with[age >= i and age < i + gap]) mylist]
    [set mylist lput 0 mylist]
    set i i + 1
    ]
  report mylist
end
to-report age-influence
  let mylist []
  let i 0
  let gap 1
  if timescale [set gap 12]
  let oldest floor (max [age] of turtles) / gap
  while [i <= oldest]
  [
    ifelse any? turtles with [age >= i and age < i + gap]
    [set mylist lput ((count turtles with [age >= i and age < i + gap and rule?]) / count turtles with [age >= i and age < i + gap]) mylist]
    [set mylist lput 0 mylist]
    set i i + 1
    ]
  report mylist
end
to-report age-diversity1
  let mylist []
  let i 0
  let gap 1
  if timescale [set gap 12]
  let oldest floor (max [age] of turtles) / gap
  while [i <= oldest]
  [
    ifelse any? turtles with [age >= i and age < i + gap]
    [set mylist lput (length remove-duplicates [theta_1] of turtles with [age >= i and age < i + gap]) mylist]
    [set mylist lput 0 mylist]
    set i i + 1
    ]
  report mylist
end
to-report age-diversity2
  let mylist []
  let i 0
  let gap 1
  if timescale [set gap 12]
  let oldest floor (max [age] of turtles) / gap
  while [i <= oldest]
  [
    ifelse any? turtles with [age >= i and age < i + gap]
    [set mylist lput (length remove-duplicates [theta_2] of turtles with [age >= i and age < i + gap]) mylist]
    [set mylist lput 0 mylist]
    set i i + 1
    ]
  report mylist
end
to plot-age-hist
  let hist2 age-diversity2
  let hist1 age-diversity1
  set-current-plot "age_track"
  set-current-plot-pen "theta_1"
  plot-pen-reset
  foreach hist1 [ plot ? ]
  set-current-plot-pen "theta_2"
  plot-pen-reset
  foreach hist2 [ plot ? ]
end
to plot-rule-theta
  set-current-plot "rule_track"
  set-current-plot-pen "maxi"
  plot mean [satisfaction] of turtles with [rule = 1]
  ;plot best-maxi
 set-current-plot-pen "mini"
  plot mean [satisfaction] of turtles with [rule = 2]
   ; plot best-mini
 set-current-plot-pen "conf"
  plot mean [satisfaction] of turtles with [rule = 3]
   ; plot best-conf
 set-current-plot-pen "anti"
  plot mean [satisfaction] of turtles with [rule = 4]
   ;plot best-anti
end
@#$#@#$#@
GRAPHICS-WINDOW
235
15
573
374
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
90
10
167
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
600
395
780
485
 Strategies colormap\n\nRed       Maxi\nGreen    mini\nBlue    Conformist\nWhite     Anti-conformist\n                      \n                       
11
0.0
0

SLIDER
3
80
178
113
strength-of-dilemma
strength-of-dilemma
0
0.5
0.42
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
4
115
176
148
inicoop
inicoop
0
100
39
1
1
NIL
HORIZONTAL

SLIDER
3
45
175
78
density
density
0.1
1
1
0.01
1
NIL
HORIZONTAL

SLIDER
5
152
179
185
Transcription-error
Transcription-error
0
1
0.07
0.01
1
NIL
HORIZONTAL

SLIDER
4
189
225
222
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
5
410
125
443
random-init
random-init
0
1
-1000

SLIDER
0
225
221
258
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
0
262
224
295
Initial-weighting-history
Initial-weighting-history
0
1
0
0.01
1
NIL
HORIZONTAL

SLIDER
1
299
224
332
Initial-like-to-move
Initial-like-to-move
0
1
0.51
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
1 / theta
NIL
0.0
10.0
0.0
650.0
true
true
PENS
"theta_1" 1.0 0 -2674135 true
"theta_2" 1.0 0 -13840069 true
"fight" 1.0 0 -16777216 true

PLOT
935
260
1286
385
distribution alpha
NIL
count
0.0
100.0
0.0
1.0
true
true
PENS
"alpha" 1.0 0 -13345367 true
"mu" 1.0 0 -2674135 true
"fight" 1.0 0 -16777216 true

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
0.1
true
false
PENS
"pen1" 1.0 0 -2674135 true
"pen2" 1.0 0 -13345367 true
"pen3" 1.0 0 -16777216 true

SWITCH
5
450
160
483
replacement?
replacement?
0
1
-1000

SLIDER
5
370
170
403
influence
influence
0
1
0.83
0.01
1
NIL
HORIZONTAL

PLOT
995
10
1270
130
age_track
NIL
NIL
0.0
100.0
0.0
0.3
true
false
PENS
"theta_1" 1.0 0 -2674135 true
"theta_2" 1.0 0 -10899396 true

PLOT
995
130
1270
255
rule_track
NIL
NIL
0.0
100.0
0.8
0.1
true
false
PENS
"maxi" 1.0 0 -2674135 true
"mini" 1.0 0 -10899396 true
"conf" 1.0 0 -13345367 true
"anti" 1.0 0 -16777216 true

SWITCH
130
410
240
443
timescale
timescale
1
1
-1000

SLIDER
0
335
215
368
Initial-prob-conflict
Initial-prob-conflict
0
1
0.5
0.01
1
NIL
HORIZONTAL

SWITCH
165
450
272
483
reflect?
reflect?
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
<experiments>
  <experiment name="influence_test" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>mean [theta_1] of turtles</metric>
    <metric>mean [theta_2] of turtles</metric>
    <enumeratedValueSet variable="Initial-weighting-history">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Transcription-error">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conflict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timescale">
      <value value="&quot;years&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-init">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influence">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inicoop">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-like-to-move">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-prob-update-rule">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-of-dilemma">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-prob-update-behavior">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Counterfactual-reflection?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
