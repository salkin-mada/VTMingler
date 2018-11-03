MIDIClient.init;
m = MIDIOut(1);


(
Event.addEventType(\midiNoteCtl, {
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \noteOn).play;
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \control).play;
});
)

Scale.directory
a = Scale.nikriz;

TempoClock.default.tempo = 135/60*4;

Pdef(\layere).stop;

s.latency // sheise + check for quant and sheduler

(
Pdef(\layere, {
	var bus, effectbus, dir = 1.0;

	bus = 18; // stereo ud til summing
	effectbus = 20; // stereo

	Ndef(\summing, {var in, sig;
		in = In.ar([18,19]);
		sig = CompanderD.ar(in,0.2,0.3,1,0.01,0.1);
		sig = Limiter.ar(sig, 0.9);
		sig = sig.clip(-0.99, 0.99);
		sig * 0.9;
	}).playN([0,1,2,3]);

	Ppar([
		 c = Pbind( // synths
			\out, bus,
			\effectBus, effectbus,
			\dur, Pseq([8],inf),
			\amp, 0.9,//Pseq([0.9,0.5,0.7,0.8,0.3,0.8], inf)* 0.7,
			\loop, 0,
			\rate, Pseq([0.8],inf)*Pseq([0.81, 0.8, 0.79], inf)*Pxrand([1,1.1,0.9], inf),
			\startPos, 0.0,//Pbrown(0,1,0.1,inf),
			\attack, 0.01,
			\decay, 1,
			\sustain, 1,
			\release, Pseq([0.2,0.02,0.4],inf),
			\pan, Pxrand([-0.25, -0.15, 0.0, 0.15, 0.25], inf),
			\spread, 0.6,
			\direction, 1.0,//Pseq([1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0], inf), // dry wet
			\send, Pfunc({|envir|
				dir = envir.direction;
			}),
			\file,
			Pseq(
				[//22
					2
					/*Pstep([180,7,2,3,180,110,122,180,7,135], 8),
					Pstep([1,2,3], 3),
					Pstep([130,180], 10),
					Pstep([1,2,3,7], 6),
					Pstep([130,180], 20),
					Pstep([1,2,3,4,5,130,120,180,135], 6),*/
				], inf),
			// eksempel på file behaviourur --_>  youyou.wav weird channel behavior CHECK IT OUT
			\bufnum,Pfunc({|envir|
				~key = ('data'++(envir.file-1));
				topEnvironment[~key.asSymbol].path.postln;
				topEnvironment[~key.asSymbol]
				//topEnvironment[envir.file]
			}),
			\instrument, Pfunc({|envir|
				var result, numChannels;
				~key = ('data'++envir.file);
				numChannels = topEnvironment[~key.asSymbol].numChannels;
				//var numChannels = topEnvironment[envir.file].numChannels;

				switch(numChannels,
					1, {
						result = ~mono; // 'mono'
					},
					2, {
						result = ~stereo; // 'stereo'
					},
					{
						result = ~mono; // 'mono'
					}
				);

				/*if (envir.direction < 1,{
				"\t\tefx-on".postln;
				"\t\t baby".postln;
				Synth.after(1/*result??*/, \efx,
				[
				\attack, 0.001,
				\sustain, 0.1,
				\release, 6.1,//envir.release,
				\amp, 0.1
				]
				);
				});*/
				result;
			}),
		),
		// look into Pfx and Pfxb
		k = Pbind( // efx
			\out, bus,
			\dur, 8,//Pseq([1,1,1,2,2], inf),
			\amp, 0.4,
			\attack, 0.2,//2.5,
			\sustain, 0.0002,//2.0,
			\release, 4.2, //7.0,
			\pan, Pxrand([-1.0, -0.5, 0.0, 0.5, 1.0], inf),
			\spread, 0.3,
			\efx, 2,
			\instrument, Pfunc({|envir|
				var result;
				("\n\t\tdir:: (send from generator Pbind):\n\t\t"++dir).postln;
				if (dir < 1, {
					"\t\tefx-on".postln;
					"\t\t baby".postln;
					switch(envir.efx,
						0, {"\t\tdelay".postln; result = 'delay'},
						1, {"\t\tmingl".postln; result = 'mingl'},
						2, {"\t\tshift".postln; result = 'shift'},
						{ result = 'nil'}
					);
					"\n".post;
				}, { result = 'nil' });
				result;
			}),
		),
		o=Pbind(
			\type, \midiNoteCtl,
			\scale, a,
			\root, 0,
			\octave, Prand([2,1.1,1.3,1], inf),
			\degree, Pseq([0,1,2,3,4,5,6,7,8], inf),
			\dur, Pseq([8], inf),
			\ctlNum, 1,
			\control, Pstep([0,0,0,0,0,0,0,40], 1, inf),
		)
		.trace(\ctlNum, prefix: " ctlNum ")
		.trace(\control, prefix: " control ")
		.trace(\degree, prefix: "degree ")
		.trace(\dur, prefix: " dur ")
	])/*.trace*/;

	Ppar([o <> (type: \midi, midiout: m), c, k]); // sum in paralllel
}).count(n:0).play(TempoClock(135/60*4));
)