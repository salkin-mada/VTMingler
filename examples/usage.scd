
t = VTMingler(s, "C:/Users/na/Desktop/live projects/lyd bibliotek/DRUM Samples/CR-909/samples/CR-909 FULL", 1000);
~omau = VTMingler(s, "X:/lydfiler/natur", 1000);
~omau[\root].at(0).values.at(0).numChannels
~omau[\root].at(0).keys

t[\root]
t[\root].size
t[\bassdrum].size
t[\snare].size
t.keys
t.size
VTMingler.supportedHeaders

t[\other].size
t[\smappi].size

t[\root].at(0).values.at(0)

q = VTMingler(s, "X:/lydfiler/a folder", 1000);
q[\root].at(0).values.at(7)
q[\root].size

topEnvironment.size
(
Pdef(\yaya,
	Pbind(
		\type, \VTMingler,
		\out, 2,
		//\bufnum, Pseq([topEnvironment[\fil1],topEnvironment[\fil3], topEnvironment[\fil2]], inf),
		\bufnum, Pseq([t[\root].at(0).values.at(20)], inf),
		/*\bufnum, Pseq(
		[
		t[\root].at(0).values.at(0),
		/*~tio[\root].at(0).values.at(8),
		~tio[\root].at(0).values.at(7)*/
		], inf),*/
		\dur, Pseq([4,Rest(3),1,3,2],inf),
		\amp, 0.4,
		\pos, Pseq([0.0,0.1,0.3,0.4], inf),
		\rate, 0.64,
		\attack, 0.1,
		\decay, 0.2,
		\sustain, 1.2,
		\release, 5.4,
		\spread, 0.89,
		\pan, Prand((-1.0..1.0)/2,inf)
	)
).play(TempoClock(130.60/60*4));
)









// JENNY HVALO? ?????
// q[\root].at(0).values.at(0) = X:\lydfiler\a folder\uuuhhh_buu_buu.wav
// (
// Pbind(
// 	\type, \VTMingler,
// 	\out, 0,
// 	//\bufnum, Pseq([~tio[\basepath].at(0).values.at(5)], inf),
// 	//\bufnum, Pseq((0..~tio[\basepath].at(0).size-1), inf),
// 	\bufnum, Pseq(
// 		[
// 			q[\root].at(0).values.at(0),
// 			/*~tio[\root].at(0).values.at(8),
// 			~tio[\root].at(0).values.at(7)*/
// 	], inf),
// 	\dur, Pseq([18,Rest(3),1,3,2],inf),
// 	\amp, 0.8,
// 	\startPos, 0.171,
// 	\rate, 0.84,
// 	\attack, 0.9,
// 	\decay, 0.9,
// 	\sustain, 4.2,
// 	\release, 2.4,
// 	\spread, 0.4,
// 	\pan, Prand((-1.0..1.0),inf)
// ).play(TempoClock(130.60/60*4));
// )




~p = ProxySpace.new(s);

(
~p[\lfoDur] = {SinOsc.kr(0.04).abs};//{LFNoise1.kr(0.5).abs*SinOsc.kr(0.5).abs};
~p[\lfoSaw] = {Saw.kr(0.3).abs.range(0.9,1.0)};
~p[\lfoRate] = {LFNoise0.kr(0.01).abs.range(0.9,1.0)};
~p[\lfoRel] = {LFNoise0.kr(0.2).abs/5};
~p[\lfoSus] = {LFNoise0.kr(0.2).abs.range(0.1,0.9)};
~p[\lfoAmp] = {LFNoise1.kr(0.5).abs};
~p[\lfoPan] = {LFNoise1.kr(4.5)};
~p[\lfoStartPos] = {LFNoise1.kr(0.3).abs.range(0.5,0.56)};
Pdef(\prox_t,
	Pbind(
		\type, \VTMingler,
		\bufnum, Pseq(
			[
				q[\root].at(0).values.at(0),
		], inf),
		\out, 0,
		\dur,  0.25 + (Pkr(~p[\lfoDur])),
		\amp, (Pkr(~p[\lfoAmp])*0.1)+0.3,
		\loop, 0,
		\rate, (Pstep([1, 1.3, 0.8, 1], 36, inf)) + Pkr(~p[\lfoRate]) + 0.91 * Pkr(~p[\lfoSaw]) ,
		\startPos, Pkr(~p[\lfoStartPos]),
		\attack, 0.2,
		\sustain, Pkr(~p[\lfoSus]) + 0.21,
		\release, Pkr(~p[\lfoRel]) + 0.2,
		\pan, Pkr(~p[\lfoPan])
	)
).play(TempoClock(130.60/60*4));
)








/// USAGE with midi
t = VTMingler(s, "C:/Users/na/Desktop/live projects/lyd bibliotek/DRUM Samples/CR-909/samples/CR-909 FULL", 1000);

MIDIClient.init;
m = MIDIOut(1); // select port


(
Event.addEventType(\magi, {
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \noteOn).play;
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \control).play;
});
)



t[\bassdrum].at(2)
t[\snare].size

~bpm = 158;
~clock = MIDIClockOut("2- MOTU Pro Audio Midi Out", "2- MOTU Pro Audio Midi Out", TempoClock(~bpm/60));


Pdef(\emu).stop; ~clock.stop; "patterns and clock stopped".post;

// fail fail -> ugen accumulation on server..

(
~clock.start; // MIDI CLOCK
Pdef(\emu, {
	Ppar([
		c=Pbind(
			\type, \VTMingler,
			\out, 2,
			\bufnum, Pseq(
				[
					t[\bassdrum].at(20),
					t[\hitom].at(0),
					t[\hihat].at(0),
					t[\hihat].at(2),
					t[\midtom].at(0),
					t[\bassdrum].at(20),
					t[\bassdrum].at(4),
					t[\snare].at(43),
					t[\snare].at(0),
					t[\perc].at(0),
					t[\hihat].at(0),
					t[\bassdrum].at(19),
					t[\bassdrum].at(18),
					t[\hihat].at(0),
					//t[\crashcymbal].at(0)
				],
				inf),
			\dur, Pseq(
				[
					4,3,2,1,1,1,1,Rest(6),
					/*Rest(3),
					6/8,Rest(6/8),6/8,Rest(6/8),6/8,Rest(6/8),6/8,Rest(6/8),
					1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
					6/8,Rest(6/8),6/8,Rest(6/8),6/8,Rest(6/8),6/8,Rest(6/8),
					6/8,Rest(6/8),6/8,Rest(6/8),6/8,Rest(6/8),6/8,Rest(6/8),*/
				]
				,inf),
			\amp, Pseq(
				[
					1.0, //bassdrum
					1.0, //hitom
					1.0, //hihat
					1.0, //hihat
					1.0, //midtom
					1.0, //bassdrum
					Prand([0.0,0.9]), //hitom
					0.0, //snare
					1.0, //snare
					1.0, //perc
					1.0, //hihat
					1.0, //bassdrum
					1.0, //bassdrum
					1.0, //hihat
				]*1.6
			, inf),
			\pos, Pseq([0.0/*,0.1,0.3,0.4*/], inf),
			\rate, Pseq(
				[
					0.9, //bassdrum
					20.3, //hitom
					1.35, //hihat
					2.38, //hihat
					9.2, //midtom
					0.9, //bassdrum
					3.84, //hitom
					1.7, //snare
					0.9, //snare
					8.6, //perc
					2.3, //hihat
					0.9, //bassdrum
					0.9, //bassdrum
					2.6, //hihat
				]
			, inf),
			\attack, 0.1,
			\decay, 0.2,
			\sustain, Prand((0..20)/10, inf),
			\release, 0.7,
			\spread, 0.89,
			\pan, Prand((-1.0..1.0)/2,inf)
		)
		.trace(\amp, prefix: " amp "),
		o=Pbind(
			\type, \magi,
			//\scale, a,
			//\root, 0, //Pstep([0,10], 3, inf),
			\octave, Pseq([3,4], inf),
			\degree, Pseq([0], inf),//Pseq([[3,5,1], 7,5,3,9,8,4,5,2,15,18, [9,6,11],8,4,5], inf),
			\dur, Pseq([4,3,2,1,1,1,1], inf),
			\ctlNum, 1,
			\control, Pseq([100,80,50,20], inf),
		)
		/*.trace(\ctlNum, prefix: " ctlNum ")
		.trace(\control, prefix: " control ")
		.trace(\degree, prefix: "degree ")
		.trace(\dur, prefix: " dur ")*/
	]);
	Ppar([o <> (type: \midi, midiout: m), c]); // sum in paralllel
}).play(TempoClock(~bpm/60*4)));
)
Pdef(\emu).stop