b = Buffer.readChannel(server: s, path: "C:/Users/na/Desktop/Svetahw dance/svetahw dance/06-181130_2138.wav", channels: [0,1]);
d = Buffer.alloc(s, s.sampleRate, 2);

(
SynthDef("grain-asr", {arg buffer, rate = 1, startPos = 0, gate = 1, att = 0.01, rel = 0.1, amp = 1, pan = 0;
	var env, snd;
	env = Env.asr(att, amp, rel).kr(gate: gate, doneAction: 2);
	snd = PlayBuf.ar(2, buffer, rate: rate, startPos: startPos * BufSamples.kr(buffer));
	snd = MultiTap.ar(`[0.1, 0.2, 0.3, 0.4], `[0.6, 0.8, 0.5, 0.4], snd, 0.5, bufnum: d.bufnum);
	snd = snd * env;
	Out.ar(0, Pan2.ar(snd, pan));
}).add;
)



(
Pbind(
	\instrument, "grain-asr",
	\buffer, b,
	\startPos, 0.02,
	\dur, 0.4,
	\att, 0.001,
	\rel, 4.2,
	\rate, Pwhite(0.3, 0.5),
	\amp, 0.95,
	\pan, Pwhite(-1.0, 1.0),
	\legato, 1
).play;
)
(
Pbind(
	\instrument, "grain-asr",
	\buffer, b,
	\startPos, Pwhite(0.0,0.9),
	\dur, 0.1,
	\att, 0.001,
	\rel, Pwhite(0.1,5.0),
	\rate, Pwhite(0.3, 0.5),
	\amp, 0.95,
	\pan, Pwhite(-1.0, 1.0),
	\legato, 1
).play;
)









////////////// another
b.free
d.free

b = Buffer.read(s, path: "X:/lydfiler/readAllAudioAndRunScale.wav");
t = Buffer.read(s, path: "X:/lydfiler/05 - Brim - LDN (digital only).wav");
d = Buffer.alloc(s, s.sampleRate, 2);

(
SynthDef(\taps, {arg buffer, rate = 1, startPos = 0, gate = 1, att = 0.01, dec = 0.1, sus = 0.5, rel = 0.1, amp = 1, pan = 0, timemast = 1, cutoff = 22e3, res = 0.1, freqshift = 0.0, pitctshift = 1, pitchdisp = 0, pitchtimedisp = 0;
	var env, snd, taps;
	env = EnvGen.kr(Env.adsr(att, dec, sus, rel), gate);
	snd = PlayBuf.ar(2, buffer, rate: rate*BufRateScale.kr(buffer), startPos: startPos * BufSamples.kr(buffer));
	snd = snd * env;
	snd = PitchShift.ar(snd, 0.2, pitctshift, pitchdisp, pitchtimedisp);
	taps = MultiTap.ar(
		(0..15).linlin(0.0,15.0,0.05,timemast),
		[0.60, 0.80, 0.50, 0.40, 0.60, 0.80, 0.50, 0.40, 0.36, 0.29, 0.24, 0.20, 0.18, 0.15, 0.12, 0.10],
		snd, 0.5, bufnum: d.bufnum);
	snd = DFM1.ar(taps, cutoff, res, 0.7);
	snd = FreqShift.ar(snd, freqshift);
	FreeSelf.kr(TDelay.kr(Done.kr(env),3));
	/*Formlet*/

	Out.ar(0, Pan2.ar(snd, pan));
}).add;
)

(
Pdef(\rainmaker,
	Pbind(
		\instrument, \taps,
		\buffer, t,
		\startPos, Prand([0.25, 0.45, 0.35], inf),
		\timemast, Prand([3.8, 13.3, 8.8, 6], inf),
		\dur, Pseq([1, Rest(7), 1, 3, Rest(2), 1, Rest(4)], inf),
		\att, 0.01,
		\dec, 0.01,
		\sus, 0.3,
		\rel, 0.01,
		\rate, 1,
		\amp, 0.50,
		\pan, Pwhite(-1.0, 1.0)*0.4,
		//\legato, 1.0,//Pwhite(1.0, 2.0),
		\cutoff, Pwhite(8e3, 9e3),
		\res, 0.1,
		\freqshift, 20,
		\pitctshift, 0.95,
		\pitchdisp, 0,
		\pitchtimedisp, 0
	).trace
).play(TempoClock(130.60/60))
)













//////////////// trying to do clean

b = Buffer.read(s, path: "X:/lydfiler/metal dryp ASF-1MKII test-edit_c2.wav");
d = Buffer.alloc(s, s.sampleRate, 1);

(
SynthDef(\taps, {arg buffer, rate = 1, startPos = 0, gate = 1, att = 0.01, dec = 0.1, sus = 0.5, rel = 0.1, amp = 1, pan = 0, timemast = 1, cutoff = 22e3, res = 0.1, freqshift = 0.0, pitctshift = 1, pitchdisp = 0, pitchtimedisp = 0;
	var env, snd, taps;
	env = EnvGen.kr(Env.adsr(att, dec, sus, rel), gate);
	snd = PlayBuf.ar(1, buffer, rate: rate*BufRateScale.kr(buffer), startPos: startPos * BufSamples.kr(buffer));
	snd = snd * env;
	snd = PitchShift.ar(snd, 0.2, pitctshift, pitchdisp, pitchtimedisp);
	taps = MultiTap.ar(
		(0..15).linlin(0.0,15.0,0.05,timemast),
		[0.60, 0.80, 0.50, 0.40, 0.60, 0.80, 0.50, 0.40, 0.36, 0.29, 0.24, 0.20, 0.18, 0.15, 0.12, 0.10],
		snd, 0.5, bufnum: d.bufnum);
	snd = DFM1.ar(taps, cutoff, res, 0.7);
	snd = FreqShift.ar(snd, freqshift);
	FreeSelf.kr(TDelay.kr(Done.kr(env),3));
	/*Formlet*/

	Out.ar(0, Pan2.ar(snd, pan));
}).add;
)

(
Pdef(\rainmaker,
	Pbind(
		\instrument, \taps,
		\buffer, b,
		\startPos, Prand([0.25, 0.45, 0.35], inf),
		\timemast, Prand([3.8, 13.3, 8.8, 6], inf),
		\dur, Pseq([1, Rest(7), 1, 3, Rest(2), 1, Rest(4)], inf),
		\att, 0.01,
		\dec, 0.01,
		\sus, 0.8,
		\rel, 0.01,
		\rate, 1,
		\amp, 0.50,
		\pan, Pwhite(-1.0, 1.0)*0.4,
		//\legato, 1.0,//Pwhite(1.0, 2.0),
		\cutoff, Pwhite(8e3, 9e3),
		\res, 0.1,
		\freqshift, 20,
		\pitctshift, 0.95,
		\pitchdisp, 0,
		\pitchtimedisp, 0
	).trace
).play(TempoClock(130.60/60))
)