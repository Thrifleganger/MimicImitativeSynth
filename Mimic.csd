; Imitative Synthesizer
; Written by Akash Murthy

; Imitative Synthesizer is an analysis tool and a simple synth built to mimic real world sounds and recreate them through
; additive synthesis. 

<Cabbage>
form caption("Imitative Synth") size(696, 650), pluginID("def1")

image bounds(0, 0, 696, 650) file("Assets/Mimic_background.png") 
button bounds(30, 292, 90, 40) channel("analyze") text("Analyze", "Analyze") identchannel("analyzeIdent") active(0)
;gentable bounds(14, 12, 379, 161) tablenumber(10) scrubberposition(80000,10) zoom(-1)
soundfiler bounds(30, 42, 500, 183) channel("beg", "end") identchannel("fileIdent") tablenumber(-1) 
button bounds(128, 292, 93, 40) channel("process") identchannel("processIdent") text("Process", "Process") active(0) 
numberbox bounds(54, 250, 53, 22) channel("startTimeBox") colour:0(11, 35, 48, 255) active(0)
numberbox bounds(452, 250, 53, 22) channel("endTimeBox") colour:0(11, 35, 48, 255) active(0)
hrange bounds(28, 224, 509, 36) channel("minSeek", "maxSeek") range(0, 1, 0:1, 1, 0.001) trackercolour(255, 165, 165, 255) 
button bounds(230, 292, 94, 40) channel("play") text("Play", "Play") identchannel("playIdent") active(0)
filebutton bounds(562, 154, 112, 36) channel("filename") text("Open File", "Open File") 
button bounds(564, 202, 109, 33) channel("samplePlay") text("Replay Selection", "Replay Selections") 
soundfiler bounds(32, 365, 381, 146) identchannel("snapshotView") tablenumber(-2)
keyboard bounds(0, 558, 696, 92) mouseoeverkeycolour(255, 255, 0, 128) 
rslider bounds(438, 372, 61, 79) channel("attack") range(0.01, 1, 0.2, 1, 0.001) text("Attack") colour(34, 0, 0, 255) fontcolour(219, 142, 142, 255) fontcolour:1(219, 142, 142, 255) outlinecolour(255, 194, 194, 255) textcolour(255, 183, 183, 255) trackercolour(70, 0, 0, 255) 
rslider bounds(510, 370, 62, 80) channel("decay") range(0.01, 1, 0.1, 1, 0.001) text("Decay") colour(34, 0, 0, 255) fontcolour(219, 142, 142, 255) fontcolour:1(219, 142, 142, 255) outlinecolour(255, 194, 194, 255) textcolour(255, 183, 183, 255) trackercolour(70, 0, 0, 255) 
rslider bounds(436, 458, 63, 69) channel("sustain") range(0.01, 1, 0.8, 1, 0.001) text("Sustain")  colour(34, 0, 0, 255) fontcolour(219, 142, 142, 255) fontcolour:1(219, 142, 142, 255) outlinecolour(255, 194, 194, 255) textcolour(255, 183, 183, 255) trackercolour(70, 0, 0, 255)
rslider bounds(512, 456, 61, 71) channel("release") range(0.01, 3, 0.5, 1, 0.001) text("Release")  colour(34, 0, 0, 255) fontcolour(219, 142, 142, 255) fontcolour:1(219, 142, 142, 255) outlinecolour(255, 194, 194, 255) textcolour(255, 183, 183, 255) trackercolour(70, 0, 0, 255)

rslider bounds(608, 374, 61, 79) channel("volumeMod") range(0.01, 5, 0.2, 1, 0.001) text("Volume") colour(255, 201, 201, 255) fontcolour(219, 142, 142, 255) fontcolour:1(219, 142, 142, 255) outlinecolour(48, 1, 1, 255) textcolour(255, 183, 183, 255) trackercolour(255, 154, 154, 255) 
rslider bounds(608, 458, 61, 73) channel("pitchMod") range(0.01, 5, 0.2, 1, 0.001) text("Pitch") colour(255, 201, 201, 255) fontcolour(219, 142, 142, 255) fontcolour:1(219, 142, 142, 255) outlinecolour(48, 1, 1, 255) textcolour(255, 183, 183, 255) trackercolour(255, 154, 154, 255) 

hslider bounds(30, 502, 393, 50) channel("snapshotSeek") range(0, 1, 0.5, 1, 0.001) trackercolour(236, 154, 149, 255) 
combobox bounds(582, 308, 89, 20) channel("waveformSelection") text("Sine", "Sawtooth", "Square") value(1)
rslider bounds(400, 284, 58, 58) channel("threshold") range(0.01, 0.2, 0.08, 1, 0.001) colour(120, 120, 120, 255) outlinecolour(166, 166, 166, 255) trackercolour(250, 152, 152, 255) 
combobox bounds(470, 306, 80, 20) channel("fftSelect") value(4) text("512", "1024", "2048", "4096", "8192") 
  
</Cabbage> 
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 -m0d --midi-key=4 --midi-velocity-amp=5
</CsOptions>
<CsInstruments>
; Initialize the global variables. 
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1


giSelection ftgen       11, 0, 32768, 2, 1

giSawRaw	ftgen		0, 0, 131072, 7, -1, 131072, 1					        ; Raw sawtooth shape
giSine		ftgen		0, 0, 131072, 10, 1                                     ; Sinusoid shape
giSaw		ftgen		0, 0, 131072, 30, giSawRaw, 1, (sr/2)/1000              ; Bandlimited sawtooth
giBuzz		ftgen		0, 0, 131072, 11, 80, 1, 0.7                            ; Bandlimited buzz

; Mics variables needed for gain and relinquish control
gkDone      init        0
giFileSelected init     0
gkAnalyzed  init        0
gkProcessed init        0
giFullDur   init        0

giMaxPartials = 600  ; Define the max number of partials to read

; Data structures for store analysis/processing data
giBinCount  init        0
giBinArr[]  init        10000
giWinArr[]  init        10000
giAmpArr[]  init        10000
giFreqArr[] init        10000
giBinPos[]  init        10000
giBinAmpEnv[][] init    giMaxPartials, 10000
giWinCount  init        0
giAmpCount  init        0
giFreqCount init        0
giAmpEnv[]  init        giMaxPartials

; Main instrument. Triggers other instruments on user interaction
instr 10

    ; On change of FFT size, instrument reinitializes variables and table construction
    kFFTSelect      init        4  
    kFFTSelect      chnget      "fftSelect"
    if changed:k(kFFTSelect) == 1 then
        reinit FFTChange
    endif
    
    FFTChange:      
        ; FFT parameters
        gifftsize = pow(2, i(kFFTSelect) + 8) 
        giNumOverlaps = 4
        gioverlap = gifftsize/giNumOverlaps
        giwinsize = gifftsize
        giwinshape = 1
    
        giAmp		ftgen		1, 0, gifftsize, 2, 0       ; Temp table for storing amplitude data of each window
        giFreq		ftgen		2, 0, gifftsize, 2, 0       ; Temp table for storing frequency data of each window
    rireturn
    
    
    kAnalyze    chnget      "analyze"
    kProcess    chnget      "process"
    kPlay       chnget      "play"
    gSSample    chnget      "filename"
    kSampPlay	chnget		"samplePlay"
    kMinSeek    chnget      "minSeek"
    kMaxSeek    chnget      "maxSeek"
    
    ; Tasks performed when a new source file is selected 
    kFileSel    changed     gSSample
    if kFileSel == 1 then
        reinit RELOAD_SAMPLE
        gkAnalyzed = 0
        gkProcessed = 0
    endif
    RELOAD_SAMPLE:
        Smessage    sprintf     "file(%s)", gSSample
                    chnset      Smessage, "fileIdent"
        if strcmp:i(gSSample, "") != 0 then
            giFullDur	filelen		gSSample
            giFileSelected = 1
            chnset      "active(1)", "analyzeIdent"
        endif
    rireturn 
    
    ; Activate/Deactivate control buttons
    SActive     sprintfk    "active(%d)", k(1)
    SInactive   sprintfk    "active(%d)", k(0)
    
    if gkAnalyzed == 0 then
        chnset      SInactive, "processIdent"
    else
        chnset      SActive, "processIdent"
    endif
    
    if gkProcessed == 0 then
        chnset      SInactive, "playIdent"
    else
        chnset      SActive, "playIdent"
    endif
    
    chnset          kMinSeek * giFullDur, "startTimeBox"
    chnset          kMaxSeek * giFullDur, "endTimeBox"
    
    ; When Analyze button is clicked
	if changed:k(kAnalyze) == 1 then
	    printks     "Analyzing sound sample\n", 0
	    gkDone      =       0
	    kFrame  =   0
	    event       "i", 2, 0, 0.1, kMinSeek, kMaxSeek
	endif
	
	; When process button is clicked
	if changed:k(kProcess) == 1 then
	    printks     "Processing essential partials. Please wait...\n", 0
	    event       "i", 3, 0.1, 0.1, kMinSeek, kMaxSeek
	endif
	
	; When play button is clicked
	if changed:k(kPlay) == 1 then
	    event       "i", 4, 0, 5
	endif
	
	; When Sample play button is clicked
	if changed:k(kSampPlay) == 1 then
	    
		if strcmpk:k(gSSample, "") == 0 then
			printks "Please open an audio file to play\n", 0
		else
			kMinTime    =           giFullDur * kMinSeek
    		kMaxTime    =           giFullDur * kMaxSeek
			kTimeDiff  	=           kMaxTime - kMinTime
			
			event       "i", 5, 0, kTimeDiff, kMinTime
		endif 
	endif

endin   

; Opcode for generating recursive additive synthesis
;       Inputs:
; aPointer - pointer variable for traversing amplitude envelope table. Range 0 - 1
; iTable[] - array of GEN02 tables which contain amplitude envelopes for each partial
; iSynths - Total number of partials present in iTable[]
; kWaveform - Waveform selection; currently supports Sine, Saw and Buzz
; iPitch - Pitch ratio value to be multiplied with the frequency
;       Output:
; aSig - Output signal of additive synthesis of all partials combined
opcode      "AdditiveSynth", a, ai[]ikpo

    aPointer, iTable[], iSynths, kWaveform, iPitch, iNum  xin
    aEnv        tablei         	aPointer, iTable[iNum], 1
    ; Determine waveform selection 
    ; Problem detected when using table numbers over 20.
    if kWaveform == 1 then
        aSig        poscil          aEnv, giFreqArr[iNum] * iPitch, giSine
    elseif kWaveform == 2 then
        aSig        poscil          aEnv, giFreqArr[iNum] * iPitch, giSaw
    elseif kWaveform == 3 then
        aSig        poscil          aEnv, giFreqArr[iNum] * iPitch, giBuzz
    endif
    ;aMix        =               0
    if iNum < iSynths-1 then
        aMix    AdditiveSynth   aPointer, iTable, iSynths, kWaveform, iPitch, iNum+1
    endif
    xout        aSig + aMix

endop

; Analysis Instrument
instr 2
        
    kThreshold  chnget      "threshold"     ; Threshold value for analysis
    kFrame      init        0
    aPointer    init        0
    iMinSeek    =			p4
    iMaxSeek    =			p5
    
    ; If a valid source file is not selected, end the instrument
    if strcmp(gSSample, "") == 0 then
        prints "Please select a valid file for analysis\n"
        goto exit
    endif
    
    ; Get the duration of time range selected
    iMinTime    =           giFullDur * iMinSeek
    iMaxTime    =           giFullDur * iMaxSeek
    giTimeDiff 	=           iMaxTime - iMinTime
    
    prints "Time range selected - Start: %.2f\t End: %.2f\t Duration: %.2f\n", iMinTime, iMaxTime, giTimeDiff 
    
    ; Create a GEN01 table from the selected region
    giSelection ftgen       11, 0, -ceil(giTimeDiff * sr), 1, gSSample, iMinTime, 0, 1
    
    ; Do non-realtime analysis of source table
    kKCount = 0
    while kKCount < (ftlen(giSelection))/ksmps do 
        aPointer    phasor      kr
        aL          tablei      (aPointer + kKCount) * ksmps, giSelection       ; Read source table
        aMono       =           aL
        fMono	    pvsanal		aMono, gifftsize, gioverlap, giwinsize, giwinshape      ; Perform PV analysis
        gkDone 	    pvsftw		fMono, giAmp, giFreq                            ; Gather amp and freq data for each window in analysis
        
        kKCount += 1
        
        if changed:k(gkDone) == 1 then
            kIndex  =   0
            kFrame  +=  1
            fileWriteLoop:
            kAmpData        table       kIndex, giAmp                           ; Extract individual data value from amp table
            kFreqData       table       kIndex, giFreq                          ; Extract individual data value from freq table
            fprintks        "fulldata.txt", "%d,%d,%f,%f\n", kIndex, kFrame, kAmpData, kFreqData    ; Write all data to fulldata.txt
            if kAmpData > kThreshold then
                fprintks        "maxdata.txt", "%d,%d,%f,%f\n", kIndex, kFrame, kAmpData, kFreqData ; Write data above threshold to maxdata.txt
            endif
            loop_lt         kIndex, 1, gifftsize/2 + 1, fileWriteLoop
        endif  
    od
    
    gkAnalyzed = 1
    prints "Sample range analyzed\n" 
    exit:
    turnoff

endin



;Processing instrument
instr 3

    iLine       init        1
    iCount      init        0
    iCol        init        1
    iPresent    init        0
    giBinCount  init        0
    
    ; Determines number of analysis windows generated
    giNumWindows	=   giTimeDiff * sr * 2 / (gifftsize/(giNumOverlaps))
    iNumWindows	    =   ceil(giNumWindows)
    
    prints  "Selecting unique partials...\n"
    
    ; Step 1: Gather all unique bins present in maxdata.txt
    ; For each line in maxdata.txt, until the end of file or max partial limit is reached, do the following
    while iLine != -1 && giBinCount < giMaxPartials do
        SLine, iLine    readfi      "maxdata.txt"
        iIndex0         =           0
        iIndex1         =           1
        ; For each character of a line of data, do the following
        while iIndex1 < strlen:i(SLine) do
            iASCII      strchar     SLine, iIndex1
            ; If character is comma(44) or newline(10)...
            if iASCII == 44 || iASCII == 10 then
                SValue      strsub      SLine, iIndex0, iIndex1 ; Extract value
                iValue      strtod      SValue                  ; Convert to floating point number
                ; If value belongs to first column(bin number) then...
                if iCol == 1 then
                    iCheck = 0
                    iPresent = 0
                    ; Check if value is already present in bin array
                    while iCheck < giBinCount do
                        if giBinArr[iCheck] == iValue then
                            iPresent = 1
                        endif
                        iCheck += 1
                    od
                    ; If value not present previously, add value and position 
                    if iPresent == 0 then
                        giBinArr[giBinCount] = iValue
                        giBinPos[giBinCount] = iCount
                        giBinCount += 1
                    endif
                ; If value belongs to second column(window/frame number), and bin was previously not added, do..
                elseif iCol == 2 && iPresent == 0 then
                    giWinArr[giBinCount - 1] = iValue
                ; If value belongs to third column(amplitude), and bin was previously not added, do..
                elseif iCol == 3 && iPresent == 0 then
                    giAmpArr[giBinCount - 1] = iValue
                ; If value belongs to fourth column(frequency), and bin was previously not added, do..
                elseif iCol == 4 && iPresent == 0 then
                    giFreqArr[giBinCount - 1] = iValue
                endif
                
                iCol    =       (iCol % 4) + 1          ; Constrain the column value to range between 1 and 4 inclusive
                
                iIndex0     =           iIndex1 + 1     
                if iASCII == 10 then
                    iCount += 1
                endif
            endif
            iIndex1     +=      1
        od
    od 
  
    iCount          =       0
    iLine           =       1
    iCol            =       1
    iGotValue       =       0
    iAvailable[]    init    giBinCount + 1
    iEnvCounter[]   init 	giBinCount + 1
    
    prints  "Generating amplitude envelopes...\n"
    
    ; Step 2: Generate amplitude envelopes for all partials
    ; For each line in fulldata.txt, until the end of file, do the following
	while iLine != -1 do
		SLine, iLine    readfi      "fulldata.txt"
		iIndex0         =           0
		iIndex1         =           1
		; For each character of a line of data, do the following
		while iIndex1 < strlen:i(SLine) do
			iASCII      strchar     SLine, iIndex1
			; If character is comma(44) or newline(10)...
			if iASCII == 44 || iASCII == 10 then
				SValue      strsub      SLine, iIndex0, iIndex1 ; Extract value
				iValue      strtod      SValue                  ; Convert to floating point number
				; If value belongs to first column(bin number) then...
				if iCol == 1 then
					iBinCounter = 0
					iGotValue = 0
					iAvailable[]	init  giBinCount
					;For all recorded bins, do...
					while iBinCounter < giBinCount do 
					    ; If value is among the recorded bins...    
						if iValue == giBinArr[iBinCounter] && iGotValue == 0 then
							iAvailable[iBinCounter] = 1     ; Mark the bin number as available for amplitude gathering
							iGotValue = 1                   ; Mark that value in current line is important and move to next column
						endif
						iBinCounter += 1
					od
				; If value belongs to second column(window/frame number), do..
				elseif iCol == 2 then
				    ; Ignore frame numbers 1,2,3 and 4, since they always contain zero values ( Investigate why? )
				    ; Quirks and problems with pvsftw
					if iValue == 1 || iValue == 2 || iValue == 3 || iValue == 4 then
						iGotValue = 0
					endif
				; If value belongs to third column(amplitude), and bin amplitude to be recorded, do..
				elseif iCol == 3 && iGotValue == 1 then
					iBinCounter = 0
					iReceivedValue = 0
					; While traversing through all recorded bins and till the chosen value is read, do...
					while iBinCounter < giBinCount && iReceivedValue == 0 do
						if iAvailable[iBinCounter] == 1 then
							giBinAmpEnv[iBinCounter][iEnvCounter[iBinCounter]] = iValue
							iEnvCounter[iBinCounter] = iEnvCounter[iBinCounter] + 1     ; iEnvCounter holds index of next location for
							                                                            ; amplitude envelope values to be written
							iReceivedValue = 1
						endif
						iBinCounter += 1
					od
				endif
                
				iCol    =       (iCol % 4) + 1
                
				iIndex0     =           iIndex1 + 1
				if iASCII == 10 then
					iCount += 1
				endif
			endif
			iIndex1     +=      1
		od
	od      ;Finished reading file fully
    
    prints  "Writing amplitude data to table...\n"
    
    iLine = 1
    iBinCounter = 0
    iAmpCounter = 0
    while iBinCounter < giBinCount do 
        ;Create function table for storing amp envelope
        giAmpEnv[iBinCounter]  ftgen     0, 0, -iNumWindows, -2, 0
        while iAmpCounter < giNumWindows-3 do       ; Compensating for excluding first 4 windows
            ; Copy data from 2-D array to GEN02 table array
            tablew      giBinAmpEnv[iBinCounter][iAmpCounter], iAmpCounter, giAmpEnv[iBinCounter]
            iAmpCounter += 1
        od
        iBinCounter += 1
        iAmpCounter = 0
    od
    
    prints	"Writing debug info to file.\n"
    prints  "Diagnostics - Number of bins: %d\t Number of windows: %d\n", giBinCount, iNumWindows
    
    fprints     "debug.txt", "File: "
    fprints     "debug.txt", gSSample
    fprints     "debug.txt", "\nFFT size: %d\n", gifftsize
    fprints     "debug.txt", "Number of significant bins (giBinCount): %d\n", giBinCount
    fprints     "debug.txt", "\nWriting table data: \n\n"
    iTemp = 0 
    iBinCounter = 0 
    while iBinCounter < giBinCount do
        fprints     "debug.txt", "Table giAmpEnv[%d]: (freq: %f)\n", iBinCounter, giFreqArr[iBinCounter] 
        while iTemp < giNumWindows-3 do
            iVal    tablei   iTemp, giAmpEnv[iBinCounter]
            fprints     "debug.txt", "%f\n", iVal
            iTemp += 1
        od
        iBinCounter += 1
        iTemp = 0
    od
    
    gkProcessed = 1
    event_i     "i", 6, 0, 0.1      ; Trigger instrument to display selection is Snapshot display
    prints "Done processing. Play away!\n"
    turnoff
    
endin

; Imitative synth. Tries to recreate original source. 
instr 4
	aGlobalEnv		linseg			0, 0.05, 0.1, giTimeDiff-0.1, 1, 0.05, 0    ; Avoid clipping
    aPointer        linseg          0, giTimeDiff, 1
    
    aSig            AdditiveSynth   aPointer, giAmpEnv, giBinCount, chnget:k("waveformSelection")
    aSig			*=				aGlobalEnv
    outs    aSig, aSig
    
endin


; Sample player
instr 5

    iMinTime 	= 			p4
    iTimeDiff	=			p3
    
    ; GEN01 table for selection area
    giSelection ftgen       11, 0, -ceil(iTimeDiff * sr), 1, gSSample, iMinTime, 0, 1
    
    aPointer	linseg		0, iTimeDiff, 1             
    aOut		tablei		aPointer, giSelection, 1    ; Playback selection area
    			outs		aOut, aOut
endin


; Aux instrument to generate snapshot file
instr 6
    
    kKCount     init        0
    
    ; Non-real time generation of file through additive synthesis
    while kKCount < (ftlen(giSelection))/ksmps do 
        aPhasor     phasor      kr
        aPointer    =           ((aPhasor + kKCount) * ksmps)/(ftlen(giSelection))
        aSig        AdditiveSynth   aPointer, giAmpEnv, giBinCount, chnget:k("waveformSelection")
	    fout    	"Render.wav", 4, aSig
        kKCount += 1   
    od

    ; Reset file param, so that snapshot window refreshes for different samples chosen
    Smessage    sprintf    "file(%s)", ""
                chnset      Smessage, "snapshotView"
    event       "i", 7, 0.1, 0.1
    turnoff
endin

; Delayed reflection of file on snapshot display
instr 7
    Smessage    sprintf    "file(%s)", "Render.wav"
                chnset      Smessage, "snapshotView"
endin


; Snapshot synthesizer. This instrument is triggered by MIDI
instr 1

kSnapSeek   chnget      "snapshotSeek"
iAttack     chnget      "attack"
iDecay      chnget      "decay"
iSustain    chnget      "sustain"
iRelease    chnget      "release"
kPRate      chnget      "pitchMod"
kTRate      chnget      "volumeMod"
iKeyAmp     =           p5
iMidiNote   =           p4
iPitch      =           semitone(iMidiNote - 60)

iPDepth     =           10  ; 10 cents as pitch modulation depth
iTDepth     =           2   ; 2 db as volume modulation depth

if gkProcessed != 1 then
    printks     "Source not processed yet.\n", 1
else
    kSelWindow      =           ceil((k(giNumWindows) - 3) * kSnapSeek)
    kEnvelope       madsr       iAttack, iDecay, iSustain, iRelease
    ; Modified implementation of Additive Synth opcode for static sound.
    aSynth          AdditiveSynth       a(kSnapSeek), giAmpEnv, giBinCount, chnget:k("waveformSelection"), iPitch
    aSynth          *=          kEnvelope * iKeyAmp
    
    ; Pitch modulation section (Vibrato)
    kPitchLFO  	    poscil		iPDepth, kPRate
    fftinL		    pvsanal 	aSynth, gifftsize, gioverlap, giwinsize, giwinshape
    fscaleL		    pvscale		fftinL, cent(kPitchLFO), 0
    aSynVib		    pvsynth		fscaleL

    ; Volume modulation section (Tremolo)
    kVolLFO		    poscil		1, kTRate
    aTremelo	    =			(kVolLFO * iTDepth) - iTDepth
    aSynVib		    *=			ampdbfs(aTremelo)
                    outs        aSynVib, aSynVib
endif

endin
 
</CsInstruments>
<CsScore>
f 0 z
i 10 0 [60*60*24*7] 
</CsScore>
</CsoundSynthesizer>

