
~tio = VTMingler(s, "X:/lydfiler/IMPACT", 1000);

~tio[\basepath]
~tio[\basepath].size
~tio.keys
~tio.size
VTMingler.supportedHeaders
~tio.supportedHeaders


// CLASSIC Patt style
(
Pbind(
	\instrument, \VTMingler,
	\out, 0,
	//\bufnum, Pseq([~tio[\basepath].at(0).values.at(5)], inf),
	//\bufnum, Pseq((0..~tio[\basepath].at(0).size-1), inf),
	\bufnum, Pstep(
		[
			Pxrand(~tio[\Kinetic].at(0).values),
			Pxrand(~tio[\Light].at(0).values),
			Pxrand(~tio[\Deep].at(0).values),
			Pxrand(~tio[\Mixed].at(0).values),
			Pxrand(~tio[\Resonant].at(0).values)
		],
		repeats: inf),
	\dur, Pseq([1,2,1,Rest(3),1,2,Rest(1),1],inf),
	\amp, 1.0,
	\startPos, 0.0,
	\rate, 1.2,
	\attack, 0.9,
	\decay, 0.9,
	\sustain, 1.2,
	\release, 2.4,
	\spread, 0.4,
	\pan, Prand((-1.0..1.0),inf)
).play(TempoClock(130.60/60*4));
)


// OR more freely

~p = ProxySpace.new(s);

(
~p[\lfoDur] = {SinOsc.kr(0.1).abs};//{LFNoise1.kr(0.5).abs*SinOsc.kr(0.5).abs};
~p[\lfoSaw] = {Saw.kr(0.8).abs.range(0.5,1.0)};
~p[\lfoRate] = {LFNoise0.kr(0.01).abs};
~p[\lfoRel] = {LFNoise0.kr(0.2).abs/5};
~p[\lfoSus] = {LFNoise0.kr(0.2).abs/5};
~p[\lfoAmp] = {LFNoise1.kr(0.5).abs};
~p[\lfoPan] = {LFNoise1.kr(4.5)};
~p[\lfoStartPos] = {LFNoise1.kr(0.5).abs};

Pbind(
	\instrument, \VTMingler,
	\bufnum, Pstep(
		[
			Pxrand(~tio[\Kinetic].at(0).values),
			Pxrand(~tio[\Light].at(0).values),
			Pxrand(~tio[\Deep].at(0).values),
			Pxrand(~tio[\Mixed].at(0).values),
			Pxrand(~tio[\Resonant].at(0).values)
		],
		repeats: inf),
	\out, 0,
	\dur,  0.25 + (Pkr(~p[\lfoDur])),
	\amp, (Pkr(~p[\lfoAmp])*0.3)+0.2,
	\loop, 0,
	\rate, Pkr(~p[\lfoRate]) + 0.51 * Pkr(~p[\lfoSaw]) ,
	\startPos, 0.0,//Pkr(~p[\lfoStartPos]),
	\attack, 0.001,
	\sustain, Pkr(~p[\lfoSus]) + 0.91,
	\release, Pkr(~p[\lfoRel]) + 1.2,
	\pan, Pkr(~p[\lfoPan])
).play(TempoClock(130.60/60*4));
)