// requirements
// Quarks.install("wslib");
// SC3-plugins
// go to -> Quarks.gui


//cadeau til the flying saucer
(
~numberOfAudioFilesLoaded = 0; ~key; ~basepath; ~makeView; ~viewOn = 0;
//"C:/Users/na/Desktop/Supercollider SCD/folder new turn/LYDSERVER.scd".load; // for laptop
"X:/Supercollider SCD/folder new turn/LYDSERVER.scd".load;                    // for stationary
s.doWhenBooted{/*var ~basepath;
	~basepath = FileDialog.new({arg ok, path;
	if (ok, {
	PathName.new(path);
	});
	}, fileMode: 2);*/

	fork{
		var humansAreSlow = 0.00005,
		numberOfAudioFilesFound = 0, numberOfSkippedAudioFiles = 0;
		var fileSize, totalFileSize = 0, totalFileSizeLoaded = 0;

		var maxLoad = 800/*MB*/*1e6; /*4000 max tested on laptop, 8000 tested on desktop*/
		//var maxAmountFileLoad = 10;
		// dont mistake this from saying anything about how much memory scsynth eats

		//~basepath = PathName.new("C:/Users/na/Desktop/lydfiler");// <-------choose folder
		//~basepath = PathName.new("X:/lydfiler/clarinet");
		~basepath = PathName.new("X:/SALKIN_T5 SSD CONTENT/live projects/lyd bibliotek/DRUM Samples/MIX");

		0.1.wait; //start hang time

		// check all files in ~basepath
		for (0, ~basepath.files.size-1, {arg i;
			humansAreSlow.wait;
			// post window item seperation help
			for (0, 40, {
				"-".post;
				(humansAreSlow/8).wait;
			});
			"".postln;

			("file: "++ /*~basepath.files.at(i).folderName++*/"../"++~basepath.files.at(i).fileName).postln;
			fileSize = File.fileSize(~basepath.files.at(i).fullPath);
			("bytes: "++fileSize).postln;
			("KB: "++(fileSize/1e3)).postln;
			("MB: "++(fileSize/1e3/1e3)).postln;
			totalFileSize = totalFileSize + (fileSize/1e3/1e3);
			("indexed: "++totalFileSize++"MB").postln;
			("loaded so far: "++totalFileSizeLoaded++"MB").postln;

			if ( (~basepath.files.at(i).extension == "wav")
				/*implement && ~basepath.files.ar(i)."firstCharacter" != .
				to prevent files like D:\live projects\lyd bibliotek\DRUM Samples\X Drum LM8953\._Hat Open.wav
				from being loaded*/
				|| (~basepath.files.at(i).extension == "WAV")
				|| (~basepath.files.at(i).extension == "aiff")
                || (~basepath.files.at(i).extension == "aif"), {
					// update
					numberOfAudioFilesFound = numberOfAudioFilesFound+1;
					"\tfound a wav/aiff file".postln;

					case // totalFileSizeLoaded is not going to be higher than specified maxLoad;
					{(totalFileSizeLoaded+(fileSize/1e3/1e3)) <= (maxLoad/1e3/1e3)} {

						// GOTO load sequence
						~key = 'data'++~numberOfAudioFilesLoaded;
						//free buffer if already allocated
						if(topEnvironment.includesKey(~key.asSymbol), {
							topEnvironment.at(~key.asSymbol).free;
							"\tfree buffer".postln;
							humansAreSlow.wait;
						});
						s.sync;
						// populate buffer -> load into memory
						topEnvironment.put(
							~key.asSymbol,
							Buffer.read(s,
								~basepath.files.at(i).fullPath
							);
						);
						"\tpopulate buffer".postln;
						humansAreSlow.wait;
						s.sync;

						// update
						~numberOfAudioFilesLoaded = ~numberOfAudioFilesLoaded+1;
						totalFileSizeLoaded = totalFileSizeLoaded + (fileSize/1e3/1e3);
					} // case: totalFileSizeLoaded is going to be higher than specified maxLoad;
					{(totalFileSizeLoaded+fileSize) > (maxLoad/1e3/1e3)} {
						("file will exceed specified maxLoad: "++(maxLoad/1e3/1e3)++"MB"
							++"\n\t\tenough is enough, not loading").warn;
						numberOfSkippedAudioFiles = numberOfSkippedAudioFiles+1;
					};
			});
			// if not an audio file
			if (
				(~basepath.files.at(i).extension != "wav")
				&& (~basepath.files.at(i).extension != "WAV")
				&& (~basepath.files.at(i).extension != "aiff"),{
					"this is not a wav/aif file, will be skipped".error;
					humansAreSlow.wait;
			});
		});
		// post window item seperation help
		for (0, 40, {
			"-".post;
			(humansAreSlow/8).wait;
		});
		"\n\n".post;

		("\tfiles present in specified folder: "++~basepath.files.size).postln;
		("\tfolders present in specified folder: "++~basepath.folders.size).postln;
		("\n"++totalFileSizeLoaded++"MB loaded, maxLoad is"+(maxLoad/1e3/1e3)++"MB").postln;
		if (numberOfSkippedAudioFiles > 0,{
			("skipped" + numberOfSkippedAudioFiles + "wav/aiff file(s) due to maxLoad restrictions").postln;
		});
		("\nfound" + numberOfAudioFilesFound + "wav/aiff file(s)").postln;
		("loaded" + ~numberOfAudioFilesLoaded + "wav/aiff file(s)").postln;

		// build synths
		if (~numberOfAudioFilesLoaded > 0,{
			humansAreSlow.wait;
			"\nbuilding a mono, a stereo and two efx synthdefs".postln;


			~mono = SynthDef(\mono, {
				|
				bufnum, direction = 1, out = 0, effectBus, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
				attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, startPos = 0,
				gate = 1
				|
				var numChan, sig, key, frames, env, file;
				numChan = 1;
				frames = BufFrames.kr(bufnum);
				sig = PlayBufCF.ar(
					numChan,
					bufnum,
					rate*BufRateScale.kr(bufnum),
					1,
					startPos*frames, loop: loop
				);
				//env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
				env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
				//FreeSelfWhenDone.kr(env);
				sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
				Out.ar(out, (sig*env)*direction);
				Out.ar(effectBus, sig*(1 - direction));
			}).add;

			~stereo = SynthDef(\stereo, {
				|
				bufnum, direction = 1, out = 0, effectBus, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
				attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, startPos = 0,
				gate = 1
				|
				var numChan, sig, key, frames, env, file;
				numChan = 2;
				frames = BufFrames.kr(bufnum);
				sig = PlayBufCF.ar(
					numChan,
					bufnum,
					rate*BufRateScale.kr(bufnum),
					1,
					startPos*frames, loop: loop
				);
				//env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
				env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
				//FreeSelfWhenDone.kr(env);
				sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
				Out.ar(out, (sig*env)*direction);
				Out.ar(effectBus, sig*(1 - direction));
			}).add;

			SynthDef(\delay, {
				|
				out = 0,
				spread = 1, pan = 0, amp = 0.5,
				attack = 0.01, sustain = 0.1, release = 0.1, gate = 1
				|
				var in, sig, env;
				in = In.ar([20,21]); //InBus.ar(~fxBus,2);
				in = HPF.ar(in, 100);
				sig = CombC.ar(in*0.25, 0.2, 0.5, 7);
				env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
				Out.ar(out, Splay.ar(sig*env, spread: spread, center: pan, level: amp));
			}).add;

			SynthDef(\mingl, {
				|
				out = 0,
				spread = 1, pan = 0, amp = 0.5,
				attack = 0.1, sustain = 0.1, release = 0.1, gate = 1
				|
				var in, sig, env;
				in = In.ar([20,21]); //InBus.ar(~fxBus,2)
				in = HPF.ar(in, 200);
				sig = in;//SinOsc.ar(Amplitude.kr(in).linexp(0,1,0.8,500))*in;
				sig = Convolution2.ar(sig*0.8, SinOsc.ar([5e3,6e3,7e3,8e3,9e3])*sig*0.8, 1, 2048, 0.05);
				sig = sig.softclip;
				env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
				Out.ar(out, Splay.ar(LeakDC.ar(sig*env), spread: spread, center: pan, level: amp));
			}).add;

			SynthDef(\shift, {
				|
				out = 0,
				spread = 1, pan = 0, amp = 0.5,
				attack = 0.1, sustain = 0.1, release = 0.1, gate = 1
				|
				var in, sig, env;
				in = In.ar([20,21]); //InBus.ar(~fxBus,2)
				sig = PitchShift.ar(in, 0.5,2.5);
				env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
				Out.ar(out, Splay.ar(LeakDC.ar(sig*env), spread: spread, center: pan, level: amp));
			}).add;

		});

		humansAreSlow.wait;
		"\n\t\tdone".postln;



		if (~viewOn == 1, {
			~makeView = /*Routine(*/{
				0.25.wait;
				"\n\t\tview time --->".postln;
				0.25.wait;

				/*---      ---*/
				/*--- VIEW ---*/
				/*---      ---*/

				w = View(bounds: Rect(300,Window.screenBounds.height-480))
				.name_("                number of files loaded:"+~numberOfAudioFilesLoaded)
				.front;
				/*w = Window(
				bounds: Rect(300,800/*Window.screenBounds.height-780*/),
				// setting bounds with Rect on Window, doesnt work in 3.9.0
				scroll: true
				).front;*/


				a ={SoundFileView.new
					.gridOn_(true)
					.gridColor_(Color(0.1, 0.4, 0.4, 1))
					.peakColor_(Color(0.2, 0.8, 0.1, 1))
					.rmsColor_(Color(0.0,1.0,0))
					/*.fixedHeight_(100);*/
					/*.fixedWidth_(100)*/
				} ! ~numberOfAudioFilesLoaded;
				a.do({arg item, i;
					var result;
					~key = ('data'++i);
					("loading view for:"+topEnvironment[~key.asSymbol].path).postln;
					e = topEnvironment[~key.asSymbol];
					a[i].load(
						filename: topEnvironment[~key.asSymbol].path,
						startFrame: 0,
						frames: topEnvironment[~key.asSymbol].numFrames

					);
					result;
				});

				t = {TextField(bounds: Rect(0, 0, 450, 10))} ! ~numberOfAudioFilesLoaded;
				t.do({arg item, i;
					var result;
					~key = ('data'++i);
					t[i].string = (~basepath.files.at(i).fileName).asString;
					t[i].stringColor = Color.rand(0.6, 1.0);
					t[i].font = Font("Segoe UI Black", 12);
					t[i].align = \right;
					t[i].background = Color.black;

				});

				r = {TextField(bounds: Rect(0, 0, 450, 10))} ! ~numberOfAudioFilesLoaded;
				r.do({arg item, i;
					var result;
					~key = ('data'++i);
					r[i].string = (~key).asString;
					r[i].stringColor = Color.rand(0.6, 1.0);
					r[i].font = Font("Segoe UI Black", 12);
					r[i].align = \center;
					r[i].background = Color.black;

				});

				g = GridLayout.new.hSpacing_(2).vSpacing_(2);
				a.clump(8).do({arg item, i;
					item.do{arg jtem, j;
						g.add(jtem, i, j)
						.setMinRowHeight(i, 40)
						.setMinColumnWidth(j, 80); // makes no differnce=?
					};
				});
				t.clump(8).do({arg item, i;
					item.do{arg jtem, j;
						g.add(jtem, i, j).setAlignment(jtem, \top)
					};
				});
				r.clump(8).do({arg item, i;
					item.do{arg jtem, j;
						g.add(jtem, i, j).setAlignment(jtem, \center)
					};
				});

				w.layout = g;

				// view listener
				/*loop{
				// ring til view text field background

				0.05.wait;
				};*/ // måske bruge SkipJack her altså.. måske dette skal ske i \layere
			}/*)*/.fork(AppClock)/*.play(AppClock);*/


		});



	}/*.fork(AppClock)*/
})


~makeView.reset;
~makeView.play(AppClock);

~bus=Bus.audio(s,2);

~fxBus=Bus.audio(s,2);

Pdef(\layere).fadeTime = 10.0;
Pdef(\layere).stop;

(

Pdef(\layere, {
	var bus, effectbus, dir = 1.0;

	bus = 4; // stereo ud til summing
	effectbus = 20; // stereo

	Ndef(\summing, {var in, sig;
		in = In.ar([4,5]);
		sig = CompanderD.ar(in,0.2,0.3,1,0.01,0.1);
		sig = Limiter.ar(sig, 0.9);
		sig = sig.clip(-0.99, 0.99);
		sig * 0.9;
	}).playN([0,1]);

	Ppar([
		Pbind( // synths
			\out, bus,
			\effectBus, effectbus,
			\dur, Pseq([1,3,2],inf),
			//Pseq([1,Rest(1/3),1,2,Rest(0.5),1,Rest(1/3),1,2,Rest(1/3),1,Rest(1/3),1,Rest(1/3),1],inf),
			\amp, 0.8,//Pseq([0.9,0.5,0.7,0.8,0.3,0.8], inf)* 0.7,
			\loop, 0,
			\rate, 0.7,//Pseq([0.89, 0.8, 0.79], inf)*Pxrand([0.4,0.2,0.5,0.7,0.9,1.0,1.5], inf),
			\startPos, 0.0,//Pbrown(0,1,0.1,inf),
			\attack, 0.001,
			\decay, 1,
			\sustain, 3.1,
			\release, 0.9,
			\pan, Pxrand([-0.25, -0.15, 0.0, 0.15, 0.25], inf),
			\spread, 0.6,
			\direction, 0.95,//Pseq([1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0], inf), // dry wet
			\send, Pfunc({|envir|
				dir = envir.direction;
			}),
			\file, Pseq([1,2,3,4,5,6,7,234,234,234,234,234,234,234,234,Prand((1..313)),1,43,25,Prand((1..313)),Prand((1..313)),Prand((1..313))], inf),
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
}).count(n:32).play(TempoClock(128.57/60*4));
)




// TODO
// watch out for chars like >´< and >ø< (�) in file names,
/*the buffer doesnt have a problem but for SoundFileView its trouble*/
// mulighed for at "parse" midifil (~key, vel, timing[dur]) gennem Pdef->Pbind ??
// tjek regex solutionss "s[0-9]+.*.aif".pathMatch
// regarding mem allocated:
/*læs størrelse i ram numframes der er loaded via Buffer
hvis Buffer ikke kan sige noget om filens frame størrelse før efter den er loaded brug SoundFile til dette?*/


// dictionary monstro questionmark

// (
// ~lydfiler = Dictionary[
//     1 -> Buffer.read(s, "C:/Users/na/Desktop/lydfiler/e.wav"),
//     2 -> Buffer.read(s, "C:/Users/na/Desktop/lydfiler/t.wav"),
//     3 -> Buffer.read(s, "C:/Users/na/Desktop/lydfiler/03_bam108_arc_musical.wav")
// ];
// )


// control patterns
/*(
// the analyzer
SynthDef(\ampreport, {|in|
var input = In.ar(in, 1);
var trigger = LFPulse.kr(10);
var ampTrack = Amplitude.kr(input);
var send = SendReply.kr(trigger, '/current_amp', [ ampTrack ]);
}).add;

// a test sound (you will not hear this, because it’s only send to the analyzer)
SynthDef(\simpleSine, {|out = 0, freq = 400, amp = 0.2|
Out.ar(out, SinOsc.ar(freq, mul: amp));
}).add;
)

b = Bus.audio(s, 1);

x = Synth(\ampreport, [\in, b]);
y = Synth(\simpleSine, [\out, b]);

o = OSCFunc({|msg| Pdefn(\current_amp, msg[3]); }, '/current_amp');


(
e = Pbind(
\degree, Prand(Array.series(20, 0, 1), inf),
\dur, Pdefn(\current_amp)
).play
)

// play with the amplitude to see the effect
y.set(\amp, 2.9);

// clean up after yourself
e.stop;
o.free;
b.free;
x.free;
y.free; */


//tjek ud
/*Pbind(\dur, 0.17, \degree, Pwhite(-4, 6) +.x Pseq([[-4,-2,0,2], 1, [0, 2], 3])).trace.play
Pbind(\dur, 0.17, \degree, Pwhite(-4, 6) +.x Pseq([[-4,-2,0,2,4,6], 10, [0,2], 3])).trace.play
Pbind(\dur, 0.17, \degree, Pwhite(-4, 6) +.x Pseq([[-4,-2,0,2,4,6], 6, [0,3,9], 9])).trace.play
Pbind(\dur, 0.005, \degree, Pwhite(0, 3) +.x Pseq([[-4,-2,0,2,4,6], 6, [0,3,9], 9])).trace.play*/
// adverb .x on streams !!




~fed = Buffer.alloc(s, Server.default.sampleRate * 0.6, 1);
(
{
    var in, pos, snd;
    in = Impulse.ar(0);
    snd = LocalIn.ar(1) * 0.995; // <- fb coefficient
    pos = DelTapWr.ar(~fed, snd);
    snd = in + (DelTapRd.ar(~fed, pos, { rrand(0.05, 0.2) + (LFNoise2.kr(rrand(0.5, 1.5)) * 0.005) } ! 14).sum * 0.3);
    snd = (snd + 0.1).tanh;
    snd = LeakDC.ar(snd);
    LocalOut.ar(snd);
    snd = Splay.ar(DelTapRd.ar(~fed, pos, { rrand(0.05, 0.2) } ! 20));
    //snd = snd + NHHall.ar(snd, 5);
	snd = snd + JPverb.ar(snd, 10);
    snd = snd * -15.dbamp;
}.play;
)



















//////////// tjek dette for extern kåntrål

s.boot;

/*============================================
LOAD SOME PIANO SOUNDS HERE
===============================================*/

(
~chords = Array.new;
~folder = PathName.new("X:/lydfiler/clarinet"); // Load your path name here
~folder.entries.do({
	arg path;
	~chords = ~chords.add(Buffer.read(s,path.fullPath));
});
)

~chords[rand(7)].play; // test here


(
SynthDef(\pnoRhyth, {
	arg out=0, relTime=1, bufnum=0, rate=1, amp=1;
	var env, pno;
	env = EnvGen.ar(Env.perc(0.01, relTime),doneAction:2);
	pno = BufRd.ar(1, bufnum,Phasor.ar(0,BufRateScale.kr(bufnum)*rate,0,BufFrames.kr(bufnum)));
	pno = pno*env;
	pno = pno*amp;
	Out.ar(out, pno);
}).add;
)

Synth(\pnoRhyth, [\bufnum, ~chords[rand(7)], \relTime, 6.5, \out, 0, \amp, 1.5]); // Test again

/*=====================================================
PIANO PLAYERS - there are pno_1 & pno_2
======================================================*/
t = TempoClock.new(100/60).permanent_(true);

(
Pdefn(\rate, Pseq([0,3],inf).midiratio);
Pdefn(\amp, 1.5);
Pbindef(\pno_1,
	\instrument, \pnoRhyth,
	\dur, Pseq([Pseq([0.5],2), Pseq([0.25],2), Pseq([Rest(0.5)],2)],inf),
	\rate, Pdefn(\rate),
	\bufnum, ~chords[0], // Pindex(~chords,Pseq((0..7),inf), inf),
	\relTime, 4.3,
	\out, 0,
	\amp, Pdefn(\amp),
);
// Player N° 2 //
(
Pdefn(\rate, Pseq([0,3],inf).midiratio);
Pdefn(\amp, 1.5);
Pbindef(\pno_2,
	\instrument, \pnoRhyth,
	\dur, Pseq([
		Pseq([0.5],2),
		Pseq([0.25],4),
		Pseq([Rest(0.5)],2)
	],inf),
	\rate, Pdefn(\rate),
	\bufnum, ~chords[3], // Pindex(~chords,Pseq((0..7),inf), inf),
	\relTime, 7.2,
	\out, 0,
	\amp, Pdefn(\amp),
);
)
)

/*=====================================================
CONTROLS for PLAYERS
=======================================================*/

Pbindef(\pno_1).play(t,quant:4);
Pbindef(\pno_2).play(t,quant:4);

Pbindef(\pno_1).resume(t,quant:1);
Pbindef(\pno_2).resume(t,quant:1);

Pbindef(\pno_1).pause;
Pbindef(\pno_2).pause;


Pbindef(\pno_1).resume;
Pbindef(\pno_2).resume;

Pbindef(\pno_1).stop;Pbindef(\pno_2).stop;

Pbindef(\pno_1).clear;Pbindef(\pno_2).clear;

/*======================================================
AMP BOOST ---------- if needed
=======================================================*/

Pdefn(\amp, 1.8);

/*======================================================
BUTTON FOR CHANGING RATES

=======================================================*/


(
Window.closeAll;
w=Window("rate changer",Rect(900,200,300,150))
.front
.alwaysOnTop_(true);

w.view.decorator_(FlowLayout(w.bounds, 20@10,50@10));

~tex_1 = StaticText(w.view, 80@20)
.string_("Button_1")
.align_(\center)
.font_(Font("Monaco", 10))
.background_(Color.white);

~tex_2 = StaticText(w.view, 80@20)
.string_("Button_2")
.align_(\center)
.font_(Font("Monaco", 10))
.background_(Color.white);

w.view.decorator.nextLine;

~button_1 = Button(w.view, 80@80)
.states_([
	["Ebm_1", Color.black, Color.red],
])
.action_({ |button|
	switch (button.value,
		0, { Pdefn(\rate, Pseq([0,3],inf).midiratio) },
	)
});

~button_2 = Button(w.view, 80@80)
.states_([
    ["Eb_2", Color.black, Color.green],
	["F7_3", Color.white, Color.blue]
])
.action_({ |button|
	switch (button.value,
		0, { Pdefn(\rate, Pseq([Pseq([0],3),Pseq([2],1)],inf).midiratio) },
		1, { Pdefn(\rate, Pseq([Pseq([0],4),Pseq([Prand([2,4],inf)],2)],inf).midiratio) }
	)
});
);


/*=============================================================
Pdefn info
================================================================*/
Pdefn(\rate, Pseq([0,3],inf).midiratio);
Pdefn(\rate, Pseq([Pseq([0],3),Pseq([2],1)],inf).midiratio);
Pdefn(\rate, Pseq([0,3],inf).midiratio);
Pdefn(\rate, Pseq([Pseq([0],4),Pseq([Prand([2,4],inf)],2)],inf).midiratio);
/*=================================================================*/

t.tempo_(40/60); // Tempo change if needed




















//// swings


(
~swingify = Prout({ |ev|
    var now, nextTime = 0, thisShouldSwing, nextShouldSwing = false, adjust;
    while { ev.notNil } {
        // current time is what was "next" last time
        now = nextTime;
        nextTime = now + ev.delta;
        thisShouldSwing = nextShouldSwing;
        nextShouldSwing = ((nextTime absdif: nextTime.round(ev[\swingBase])) <= (ev[\swingThreshold] ? 0)) and: {
            (nextTime / ev[\swingBase]).round.asInteger.odd
        };
        adjust = ev[\swingBase] * ev[\swingAmount];
        // an odd number here means we're on an off-beat
        if(thisShouldSwing) {
            ev[\timingOffset] = (ev[\timingOffset] ? 0) + adjust;
            // if next note will not swing, this note needs to be shortened
            if(nextShouldSwing.not) {
                ev[\sustain] = ev.use { ~sustain.value } - adjust;
            };
        } {
            // if next note will swing, this note needs to be lengthened
            if(nextShouldSwing) {
                ev[\sustain] = ev.use { ~sustain.value } + adjust;
            };
        };
        ev = ev.yield;
    };
});
)


Pchain(~swingify, p, (swingBase: 0.25, swingAmount: 0.0)).play(TempoClock(148.57/60*4))

// note duration = twice swingBase, no swing (correct)
Pchain(~swingify, Pstretch(2, p), (swingBase: 0.25, swingAmount: 1/3)).play;

// hear the result of different swing amounts
(
Ppar([
    // 60% of a 16th-note
    Pchain(~swingify, p, (swingBase: 0.25, swingAmount: 0.6, pan: -1)),
    // 20% of a 16th-note
    Pchain(~swingify, p, (swingBase: 0.25, swingAmount: 0.2, pan: 1, octave: 4))
]).play;
)


(
q = Ppar([
    // walking bass (by an idiot bass player who only chooses notes randomly)
    Pbind(
        \octave, 3,
        \degree, Pwhite(0, 7, inf),
        \dur, 0.5
    ),
    Pseq([
        Pchain(
            ~swingify,
            Pbind(
                \degree, Pseries(-7, 1, 15) +.x Pseq([0, 9], 1),
                \dur, Pwhite(1, 3, inf) * 0.25
            ),
            (swingBase: 0.25, swingAmount: 0.2)
        ),
        Pfuncn({ q.stop; Event.silent(1) }, 1)
    ])
]).play;
)












t = TempoClock.new(128.57/60*4).permanent_(true);

t.tempo_(78.00/60*4); // Tempo change if needed


(
Pdef(\layere, {
	q = Ppar([
		Pseq([
			Pchain(
				~swingify,
				Pbind(
					\degree, Pseries(-7, 1, 15) +.x Pseq([0, 9], 1),
					\dur, Pwhite(1, 3, inf) * 0.25
				),
				(swingBase: 0.25, swingAmount: 0.2)
			),
			Pfuncn({ q.stop; Event.silent(1) }, 1)
		])
	]);

	Ppar([
		Pbind(
			\degree,3,
			\dur, 3,
		)
	])

}).play(t, quant:4);
)











//////////////////////////////////////////
/////////////////////////////////////////////
// OTHER  POs  INTERESTING sTUUFS




(
p = Pspawn(Pbind(
    \method, \par,        // embed patterns in parallel
        // generate the subpattern in a Pfunc (so there's a new pattern each time)
        // Pfunc returns the pattern without rendering the stream
        // -- important for Pspawn
        // See the Pspawn helpfile for other ways to embed patterns
    \pattern, Pfunc {
        Pbind(
            \degree, Pseries(rrand(-5, 7), #[-1, 1].choose, rrand(4, 7)),
            \pan, rrand(-1.0, 1.0),
            \dur, rrand(0.1, 0.3)    // duration is chosen once for each pattern
        )
    },
        // The \delta key is used automatically for the spawner.wait() call
    \delta, Pwhite(1, 4, inf) * 0.25

)).trace.play;
)





// Demonstrates how Pfxb isolates signals on different buses
// The fx synth is a simple volume control here
// but it could be more complex

(
SynthDef(\volumeCtl, { |out, amp = 1, gate = 1|
    var    sig = In.ar(out, 2) * amp;
    sig = sig * EnvGen.kr(Env(#[1, 1, 0], #[1, 1], -3, releaseNode: 1), gate, doneAction: Done.freeSelf);
    ReplaceOut.ar(out, sig)
}).add;

SynthDef(\EFF, { |out, amp = 1, pitch=100, gate = 1|
    var    sig = In.ar(out, 2) * amp;
	sig = PitchShift.ar(sig,0.2, pitch);
    sig = sig * EnvGen.kr(Env(#[1, 1, 0], #[1, 1], -3, releaseNode: 1), gate, doneAction: Done.freeSelf);
    ReplaceOut.ar(out, sig)
}).add;

~vbus1 = Bus.control(s, 1).set(0.5);
~vbus2 = Bus.control(s, 1).set(0.5);
~vbus3 = Bus.control(s, 1).set(0.5);
//~vbus4 = Bus.control(s, 1).set(0.5);

~window = Window.new("mixers", Rect(10, 100, 320, 600));
~window.view.decorator = FlowLayout(~window.view.bounds, 2@2);
EZSlider(~window, 310@20, "low part", \amp, { |ez| ~vbus1.set(ez.value) }, 0.5);
~window.view.decorator.nextLine;
EZSlider(~window, 310@20, "high part", \amp, { |ez| ~vbus2.set(ez.value) }, 0.5);
~window.view.decorator.nextLine;
EZSlider(~window, 310@20, "high part eff", \freq, { |ez| ~vbus3.set(ez.value) }, 0.5);

~window.front.onClose_({ ~vbus1.free; ~vbus2.free; ~vbus3.free; });
)

(
p = Ppar([
    Pfxb(Pbind(
        \degree, Pseq([0, 7, 4, 3, 9, 5, 1, 4], inf),
        \octave, 4,
        \dur, 0.5
    ), \volumeCtl, \amp, ~vbus1.asMap),    // map to control bus here
    Pfxb(Pbind(
        \degree, Pwhite(0, 11, inf),
        \dur, 0.25
    ), \EFF, \pitch, ~vbus3.asMap, \amp, ~vbus3.asMap)    // ... and here
]).play;
)

p.stop;



(
SynthDef(\playbuf, { |bufnum, start, dur = 1, amp = 0.2, out|
    var    sig = PlayBuf.ar(1, bufnum, BufRateScale.ir(bufnum), 0, start);
    sig = sig * amp * EnvGen.kr(Env.linen(0.01, dur, 0.01), doneAction: Done.freeSelf);
    Out.ar(out, sig ! 2)
}).add;
)

(
TempoClock.default.tempo = 1;
p = Pproto({
    ~buf = (type: \allocRead, path: Platform.resourceDir +/+ "sounds/a11wlk01.wav").yield;
}, Pbind(
    \instrument, \playbuf,
        // access resources in the protoevent by Pkey
    \bufnum, Pkey(\buf),
	\rate, 2,
    \dur, 0.1,//Pwhite(1, 4, inf) * 0.25,
        // upper bound of Pwhite is based on duration
        // so that start + (dur * samplerate) never goes past the buffer's end
    \start, Pwhite(0, 2208893 - (Pkey(\dur) * 44100), inf)
)).play;
)

// shows a buffer number allocated ('true' ContiguousBlock)
s.bufferAllocator.debug;

p.stop;

s.bufferAllocator.debug;    // after stop, the buffer is gone











////FURTHER INTERESTING
////FURTHER INTERESTING
////FURTHER INTERESTING
(
TempoClock.default.tempo = 1;

~bass = Pbind(
    \degree, Pwhite(0, 7, inf),
    \octave, 3,    // down 2 octaves
    \dur, Pwhite(1, 4, inf),
    \legato, 1,
    \amp, 0.2
).collect({ |event|
    ~lastBassEvent = event;
}).play(quant: Quant(quant: 1, timingOffset: 0.1));

// shorter form for the Quant object: #[1, 0, 0.1]

~chords = Pbind(
    \topNote, Pseries(7, Prand(#[-2, -1, 1, 2], inf), inf).fold(2, 14),
    \bassTriadNotes, Pfunc { ~lastBassEvent[\degree] } + #[0, 2, 4],
        // merge triad into topnote
        // raises triad notes to the highest octave lower than top note
        // div: is integer division, so x div: 7 * 7 means the next lower multiple of 7
    \merge, (Pkey(\topNote) - Pkey(\bassTriadNotes)) div: 7 * 7 + Pkey(\bassTriadNotes),
        // add topNote to the array if not already there
    \degree, Pfunc { |ev|
        if(ev[\merge].detect({ |item| item == ev[\topNote] }).isNil) {
            ev[\merge] ++ ev[\topNote]
        } {
            ev[\merge]
        }
    },
    \dur, Pwrand([Pseq([0.5, Pwhite(1, 3, 1), 0.5], 1), 1, 2, 3], #[1, 3, 2, 2].normalizeSum, inf),
    \amp, 0.05
).play(quant: 1);
)

~bass.stop;
~chords.stop;


f = { |topNote, triad|
    var    x;
    x = (topNote - triad).debug("initial transposition steps");
    x = (x div: 7).debug("octaves to transpose");
    x = (x * 7).debug("steps to transpose");
    x + triad
};

f.value(7, #[0, 2, 4]);
--> [ 7, 2, 4 ] (first inversion triad)





(
p = Penvir((), Ptpar([
    0.0, Pbind(
        \degree, Pwhite(0, 7, inf),
        \octave, 6,    // down 2 octaves
        \dur, Pwhite(1, 4, inf),
        \legato, 1,
        \amp, 0.2,
        \timingOffset, 0.1
    ).collect({ |event|
        ~lastBassEvent = event;
    }),
    0.1, Pbind(
        \topNote, Pseries(7, Prand(#[-2, -1, 1, 2], inf), inf).fold(2, 14),
        \bassTriadNotes, Pfunc { ~lastBassEvent[\degree] } + #[0, 2, 4],
        \merge, (Pkey(\topNote) - Pkey(\bassTriadNotes)) div: 7 * 7 + Pkey(\bassTriadNotes),
        \degree, Pfunc { |ev|
            if(ev[\merge].detect({ |item| item == ev[\topNote] }).isNil) {
                ev[\merge] ++ ev[\topNote]
            } {
                ev[\merge]
            }
        },
        \dur, Pwrand([Pseq([0.5, Pwhite(1, 3, 1), 0.5], 1), 1, 2, 3], #[1, 3, 2, 2].normalizeSum, inf),
        \amp, 0.05
    )
])).play;
)

p.stop;