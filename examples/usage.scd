
t = VTMingler(s, "X:/lydfiler/trommer/oter", 1000);
~omau = VTMingler(s, "X:/lydfiler/natur", 1000);
~omau[\root].at(0).values.at(0).numChannels
~omau[\root].at(0).keys

t[\root]
t[\root].size
t[\basepath].size
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
		\out, 0,
		\bufnum, Pseq([topEnvironment[\fil1],topEnvironment[\fil3], topEnvironment[\fil2]], inf),
		//\bufnum, Pseq([q[\root].at(0).values.at(5)], inf),
		/*\bufnum, Pseq(
		[
		t[\root].at(0).values.at(0),
		/*~tio[\root].at(0).values.at(8),
		~tio[\root].at(0).values.at(7)*/
		], inf),*/
		\dur, Pseq([18,Rest(3),1,3,2],inf),
		\amp, 0.4,
		\pos, Pseq([0.3,0.5,0.8], inf),
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