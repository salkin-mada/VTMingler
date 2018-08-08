MIDIClient.init;
m = MIDIOut(2);


(
Event.addEventType(\midiNoteCtl, {
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \noteOn).play;
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \control).play;
});
)



Pdef(\layere).stop;

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
	}).playN([2,3,4,5]);

	Ppar([
		 c = Pbind( // synths
			\out, bus,
			\effectBus, effectbus,
			\dur, Pseq([1,1,1,Rest(1.5),0.5,0.5,0.5,Rest(3)],inf),//Pseq([1,1,1,1,1,1,1,1,1,1,1,Rest(1),1,Rest(1),2,1,1,2,1,Rest(2),1,1,1,Rest(1),1,4,2,1,2,1,8,9,2],inf),
			\amp, 0.8,//Pseq([0.9,0.5,0.7,0.8,0.3,0.8], inf)* 0.7,
			\loop, 0,
			\rate, 0.7,//0.8*Pseq([0.89, 0.8, 0.79], inf)*Pxrand([1,1.1,1.4,1.5,1.6,1.8,2,3], inf),
			\startPos, 0.0,//Pbrown(0,1,0.1,inf),
			\attack, 0.001,
			\decay, 0.2,
			\sustain, 0.02,
			\release, Pseq([0.2,0.02,0.4],inf),
			\pan, Pxrand([-0.25, -0.15, 0.0, 0.15, 0.25], inf),
			\spread, 0.6,
			\direction, 1.0,//Pseq([1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0], inf), // dry wet
			\send, Pfunc({|envir|
				dir = envir.direction;
			}),
			\file,
			Pseq(
				[//301
					Pstep([5,6,280],3),
					Pstep([280],12)
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
			\dur, 12,//Pseq([1,1,1,2,2], inf),
			\amp, 0.6,
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
			\type, \magi,
			//\scale, a,
			//\root, 0, //Pstep([0,10], 3, inf),
			\octave, Pseq([4], inf),
			\degree, Pseq([2], inf),//Pseq([[3,5,1], 7,5,3,9,8,4,5,2,15,18, [9,6,11],8,4,5], inf),
			\dur, Pseq([14],inf),
			\ctlNum, 1,
			\control, Pseq([0,0,0,30,60,120,70,90], inf),
		)
		.trace(\ctlNum, prefix: " ctlNum ")
		.trace(\control, prefix: " control ")
		.trace(\degree, prefix: "degree ")
		.trace(\dur, prefix: " dur ")
	])/*.trace*/;
	Ppar([o <> (type: \midi, midiout: m), c,k]); // sum in paralllel
}).count(n:16).play(TempoClock(130.60/60*4));
)
//130.60
