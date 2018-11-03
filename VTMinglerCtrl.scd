//PROXY VERSION




~p = ProxySpace.new(s);


(


~p[\lfoDur] = {SinOsc.kr(0.1).abs};//{LFNoise1.kr(0.5).abs*SinOsc.kr(0.5).abs};
~p[\lfo2] = {Saw.kr(111.1, 100, 100)};
~p[\lfoRate] = {LFNoise0.kr(0.01).abs};
~p[\lfoRel] = {LFNoise0.kr(0.2).abs/10};
~p[\lfoSus] = {LFNoise0.kr(0.2).abs/10};
~p[\lfoAmp] = {LFNoise1.kr(0.5).abs};
~p[\lfoPan] = {LFNoise1.kr(4.5)};
~p[\lfoStartPos] = {LFNoise1.kr(0.5).abs};


Pbind(
	\out, 4,
	\dur,  0.95 + (Pkr(~p[\lfoDur])*2) * Pseq([4,5,6,7,12] * 0.2, inf),
	//Pseq([1,0.5,0.5,0.5,0.5,0.5,3,3,3,3,9], inf),
	//Pseq([3/4], inf) + (Pkr(~p[\lfoDur])*2),
	\amp, (Pkr(~p[\lfoAmp])*0.3)+0.7,
	\loop, 1,
	\rate, Pkr(~p[\lfoRate]) + 0.01,
	\startPos, 0.0,//Pkr(~p[\lfoStartPos]),
	\attack, 0.001,
	\sustain, Pkr(~p[\lfoSus]) + 0.71,
	\release, Pkr(~p[\lfoRel]) + 0.2,
	\pan, Pkr(~p[\lfoPan]),
	\spread, 0.6,
	\direction, 1.0,
	/*\send, Pfunc({|envir|
	nd = envir.dur;
	}),*/
	\file, Pseq([121,543,654,67,78,89], inf),
	//Prand((1..837), inf), //123
	\bufnum,Pfunc({|envir|
		~key = ('data'++(envir.file-1));
		topEnvironment[~key.asSymbol].path.postln;
		topEnvironment[~key.asSymbol]
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
		result;
	}),
).play(TempoClock(130/60*4))
)









// PDEF VERSION

Pdef(\layere).fadeTime = 10.0;
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
	}).playN([0,1]);

	Ppar([
		Pbind( // synths
			\out, bus,
			\effectBus, effectbus,
			\dur, Pseq([1,1,1,1,1,1,1,1,Rest(12)],inf),//Pseq([1,3,2],inf),
			//Pseq([1,Rest(1/3),1,2,Rest(0.5),1,Rest(1/3),1,2,Rest(1/3),1,Rest(1/3),1,Rest(1/3),1],inf),
			\amp, 0.9,//Pseq([0.9,0.5,0.7,0.8,0.3,0.8], inf)* 0.7,
			\loop, 0,
			\rate, Pseq([1,0.5,0.25], inf)*3,//Pseq([0.89, 0.8, 0.79], inf)*Pxrand([0.4,0.2,0.5,0.7,0.9,1.0,1.5], inf),
			\startPos, 0.2,//Pbrown(0,1,0.1,inf),
			\attack, 0.001,
			\decay, 0.3,
			\sustain, 0.81,
			\release, 0.81,
			\pan, Pxrand([-0.25, -0.15, 0.0, 0.15, 0.25], inf),
			\spread, 0.6,
			\direction, 1.0,//Pseq([1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0], inf), // dry wet
			\send, Pfunc({|envir|
				dir = envir.direction;
			}),
			\file,
			Pseq([100,110], inf), // 148
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
		Pbind( // efx
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
		)
	])/*.trace*/;
}).count(n:16).play(TempoClock(110/60*4));
)