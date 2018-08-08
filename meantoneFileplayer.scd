(
~numberOfAudioFilesLoaded = 0; ~key; ~basepath; ~makeView; ~viewOn = 0;
"C:/Users/na/Desktop/Supercollider SCD/folder new turn/LYDSERVER.scd".load;
//"X:/Supercollider SCD/folder new turn/LYDSERVER.scd".load;
s.doWhenBooted{/*var ~basepath;
	~basepath = FileDialog.new({arg ok, path;
	if (ok, {
	PathName.new(path);
	});
	}, fileMode: 2);*/

	fork{
		var humansAreSlow = 0.0000015,
		numberOfAudioFilesFound = 0, numberOfSkippedAudioFiles = 0;
		var fileSize, totalFileSize = 0, totalFileSizeLoaded = 0;

		var maxLoad = 2000/*MB*/*1e6; /*4000 max tested on laptop, 8000 tested on desktop*/
		//var maxAmountFileLoad = 10;
		// dont mistake this from saying anything about how much memory scsynth eats

		~basepath = PathName.new("C:/Users/na/Desktop/lydfiler/resynthesis/gamalan/snippets");
		// <-------choose folder

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


			~mono = SynthDef(\file_mono, {
				arg out=0, bufnum, basefreq=440, freq, amp=0.5, pan=0, attack = 0.2, decay = 0.2, sustain = 0.5, release = 0.1, gate=1, startPos = 0;
				var sig, env, rate, frames;
				frames = BufFrames.kr(bufnum);
				rate = freq/basefreq;
				sig = PlayBufCF.ar(1, bufnum, rate*BufRateScale.kr(bufnum), 1, startPos*frames, loop: 0, lag: 0.8, n: 1);
				env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
				sig = sig * env;
				Out.ar(out, Splay.ar(sig, 1, amp, pan));
			}).add;

			~stereo = SynthDef(\file_stereo, {
				arg out=0, bufnum, basefreq=440, freq, amp=0.5, pan=0, attack = 0.2, decay = 0.2, sustain = 0.5, release = 0.1, gate=1, startPos = 0;
				var sig, env, rate, frames;
				frames = BufFrames.kr(bufnum);
				rate = freq/basefreq;
				sig = PlayBufCF.ar(2, bufnum, rate*BufRateScale.kr(bufnum), 1, startPos*frames, loop: 0, lag: 0.8, n: 1);
				env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
				sig = sig * env;
				Out.ar(out, Splay.ar(sig, 1, amp, pan));
			}).add;

			humansAreSlow.wait;
			"\n\t\tdone".postln;
			/*(humansAreSlow*2).wait;
			"\n\t\tinit MIDIClient\n".postln;
			MIDIClient.init;*/
		}, {"\n\t\tno files loaded no synths build!!!"});
	}
})




m = MIDIOut(2); // MOTU


(
Event.addEventType(\magi, {
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \noteOn).play;
	currentEnvironment.copy.put(\type, \midi).put(\midicmd, \control).play;
});
)



Scale.directory

(
// a = Scale.dorian;
// a.tuning_(\mean4);


// parth_01 && johnston tuning

a = Scale.major;
b = Scale.minor;
h = Scale.dorian;
v = Scale.mixolydian;
/*a.tuning_(\mean4);
b.tuning_(\mean4);
h.tuning_(\mean4);
v.tuning_(\mean4);*/
)



Pdef(\emu).stop
(
Pdef(\emu, {
	Ppar([
		/*c=*/Pbind(
			\out, 0,
			\amp, Pexprand(-20.dbamp, -17.dbamp),
			//\startPos, 0.0,
			\pan, Pxrand((-10..10)/10, inf),
			\scale,
			Pseq([a],inf),
			\root, Pstep([-4,0,-7], 64, inf),
			\octave, Pseq([5,5,6,5,6], inf),
			\degree,
			Pseq([0,6,4], inf),
			//Pseq([[1,3,5],[3,5,7],[1,3,5],4,2,6,5],inf),
			//Pseq([[2,6,4],[8,4,6],[1,3,5],9,5,3,6,9,10,14,16],inf),
			//Pseq(1+[[2,5,4],[0,3,2],[-2,0,4]], inf),
			/*Pseq([[2,4,5],6,[2,4,5],6,[2,4,5],8,[0,3,5],7,4,6,9,12,14,6,4,5,
				[0,2,3],4,[0,2,6],4,[0,2,3],4,[0,2,6],4,[0,2,3],4,[0,2,6],2,5,2,4,7,10,12,4,2,3
			],inf),*/
			\dur, Pseq([8,12,17],inf),
			//Pseq([4,5,7,3,1,1,1,1],inf),
			/*Pseq(
				[
					Pseq([3,1,2], 32),
					Pseq([5,3,1,2,5,1,3], 4),
					Pseq([3,1,2,4], 16),
					Pseq([5,3,1,2,Rest(0.5),2.5,5,1,3,Rest(0.5),2.5,Rest(0.5),2.5], 8)
			], inf),*/
			\attack, 0.01,
			\decay, 0.01,
			\sustain, 9,//4,
			\release, 0.2,
			\file, Pseq([1,2],inf),
			\bufnum,Pfunc({|envir|
				~key = ('data'++(envir.file-1));
				//topEnvironment[~key.asSymbol].path.postln;
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
			});
		)/*,
		o=Pbind(
			\type, \magi,
			//\scale, a,
			//\root, 0, //Pstep([0,10], 3, inf),
			//\octave, Pseq([6,5], inf),
			\degree, Pseq([0,1,2,3,4,5,6,7,8], inf),//Pseq([[3,5,1], 7,5,3,9,8,4,5,2,15,18, [9,6,11],8,4,5], inf),
			\dur, Pseq([3,5,1],inf),
			\ctlNum, 1,
			\control, Pseq([0,0,0,30,60,120,70,90], inf),
		)*/
		/*.trace(\ctlNum, prefix: " ctlNum ")
		.trace(\control, prefix: " control ")
		.trace(\degree, prefix: "degree ")
		.trace(\dur, prefix: " dur ")*/
	]);

	//Ppar([o <> (type: \midi, midiout: m), c]); // sum in paralllel
}).play(TempoClock(112/60*4));
)



















































































Pdef(\emu).stop
(
Pdef(\emu, {
	Ppar([
		c=Pbind(
			\out, 2,
			\pan, Pxrand((-10..10)/10, inf),
			\scale, a,//Pstep([a,b,v], 64, inf),
			\root, 0,//Pstep([-4,0,-7], 64, inf),
			\octave, Pseq([5], inf),
			//
			\degree, 4,//Pstep([4,[7,9,3],4,[5,2]],Pseq([70,30,70,30], inf), inf),
			//Pseq([[3,5,1], 7,5,3,9,8,4,5,2,15,18, [9,6,11],8,4,5], inf),
			\dur, Pseq([2],inf),
			/*Pseq(
				[
					Pseq([3,1,2], 32),
					Pseq([5,3,1,2,5,1,3], 4),
					Pseq([3,1,2,4], 16),
					Pseq([5,3,1,2,Rest(0.5),2.5,5,1,3,Rest(0.5),2.5,Rest(0.5),2.5], 8)
			], inf),*/
			\attack, 0.01,
			\decay, 0.01,
			\sustain, 7,//4,
			\release, 1,//3.1,
			\amp, Pexprand(-28.dbamp, -26.dbamp),
			\file, Prand((1..58), inf),//Pseq([22,12,8], inf),//Pstep((1..48), 16, inf),
			\bufnum,Pfunc({|envir|
				~key = ('data'++(envir.file-1));
				//topEnvironment[~key.asSymbol].path.postln;
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
			});
		),
		o=Pbind(
			\type, \magi,
			//\scale, a,
			//\root, 0, //Pstep([0,10], 3, inf),
			//\octave, Pseq([6,5], inf),
			\degree, Pseq([0,1,2,3,4,5,6,7,8], inf),//Pseq([[3,5,1], 7,5,3,9,8,4,5,2,15,18, [9,6,11],8,4,5], inf),
			\dur, Pseq([3,5,1],inf),
			\ctlNum, 1,
			\control, Pseq([0,0,0,30,60,120,70,90], inf),
		)
		.trace(\ctlNum, prefix: " ctlNum ")
		.trace(\control, prefix: " control ")
		.trace(\degree, prefix: "degree ")
		.trace(\dur, prefix: " dur ")
	]);

	Ppar([o <> (type: \midi, midiout: m), c]); // sum in paralllel
}).play(TempoClock(112/60*4));
)

































(
Pdef(\pattis, {
	Pbind(\instrument, \trest,
		\scale, a,
		\octave, Pseq([[6,6,5,4,3], [5,4,3], [4,3,5], [4,3,5]], inf),
		//\degree, Pseq([ [3,5,1], [6,8,3] ], inf),
		\degree, Pseq([ [7,1,11], [1,8,3] ], inf),
		\dur, Prand([64], inf),
		\attack, 0.01,
		\decay, 0.01,
		\sustain, 64,
		\release, 0.2,
		\amp, Pexprand(-42.dbamp, -36.dbamp),
	).trace
}
).play(TempoClock(62/60*4));
)















(
TempoClock.default.tempo = 128/60;

// Pmul does only one thing here: take ~amp from each event
// and replace it with ~amp * 0.4
p = Pmul(\amp, 0.4, Pfsm([
	#[0, 3, 1],        // starting places
	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([78, 81, 78, 76, 78, 76, 72, 71, 69, 66], 1)-50,
		\dur, Pseq(#[0.25, 1.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25], 1),
		\sustain, Pseq(#[0.3, 1.2, 0.3, 0.2, 0.3, 0.2, 0.3, 0.2, 0.3, 0.2],1 ),
		\amp, Pseq(#[1, 0.5, 0.75, 0.5, 0.75, 0.5, 0.75, 0.5, 0.75, 0.5], 1),
		//\mw, Pseq([0, 0.03, Pseq(#[0], inf)], 1)
	), #[1, 2, 3, 4, 7],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([64, 66, 69, 71, 72, 73], 1)-50,
		\dur, Pseq(#[0.25], 6),
		\sustain, Pseq(#[0.3, 0.2, 0.2, 0.2, 0.3, 0.2], 1),
		\amp, Pseq(#[1, 0.5, 0.5, 0.5, 0.5, 0.5], 1),
		//\mw, 0
	), #[1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([69, 71, 69, 66, 64, 69, 71, 69], 1)-50,
		\dur, Pseq(#[0.125, 0.625, 0.25, 0.25, 0.25, 0.25, 0.25, 0.75], 1),
		\sustain, Pseq(#[0.2, 0.64, 0.2, 0.2, 0.2, 0.3, 0.3, 0.75], 1),
		\amp, Pseq(#[0.5, 0.75, 0.5, 0.5, 0.5, 1, 0.5, 0.5], 1),
		//\mw, 0
	), #[0, 1, 1, 1, 1, 3, 3, 3, 3, 5],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([72, 73, 76, 72, 71, 69, 66, 71, 69], 1)-50,
		\dur, Pseq(#[0.25, 0.25, 0.25, 0.083, 0.083, 0.084, 0.25, 0.25, 0.25], 1),
		\sustain, Pseq(#[0.3, 0.2, 0.2, 0.1, 0.07, 0.07, 0.2, 0.3, 0.2], 1),
		\amp, Pseq(#[1, 0.5, 0.5, 1, 0.3, 0.3, 0.75, 0.75, 0.5], 1),
		//\mw, 0
	), #[1, 1, 1, 1, 3, 3, 4, 4, 4],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([64, 66, 69, 71, 72, 73, 71, 69, 66, 71, 69, 66, 64, 69], 1)-50,
		\dur, Pseq(#[0.25, 0.25, 0.25, 0.25, 0.125, 0.375, 0.166, 0.166, 0.168,
			0.5, 0.166, 0.166, 0.168, 0.5], 1),
		\sustain, Pseq(#[0.3, 0.2, 0.2, 0.2, 0.14, 0.4, 0.2, 0.2, 0.2, 0.6, 0.2, 0.2, 0.2, 0.5],1),
		\amp, Pseq(#[0.5, 0.5, 0.6, 0.8, 1, 0.5, 0.5, 0.5, 0.5, 1,
			0.5, 0.5, 0.5, 0.45], 1),
		//\mw, 0
	), #[0, 1, 1, 1, 1, 3, 3, 5],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([72, 73, 76, 78, 81, 78, 83, 81, 84, 85], 1)-50,
		\dur, Pseq(#[0.25, 0.25, 0.25, 0.25, 0.5, 0.5, 0.5, 0.5, 0.125, 1.125], 1),
		\sustain, Pseq(#[0.3, 0.2, 0.2, 0.2, 0.95, 0.25, 0.95, 0.25, 0.2, 1.13], 1),
		\amp, Pseq(#[0.7, 0.5, 0.5, 0.5, 0.7, 0.5, 0.8, 0.5, 1, 0.5], 1),
		//\mw, Pseq([Pseq(#[0], 9), 0.03], 1)
	), #[6, 6, 6, 8, 9, 10, 10, 10, 10, 11, 11, 13, 13],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([83, 81, 78, 83, 81, 78, 76, 72, 73, 78, 72, 72, 71], 1)-50,
		\dur, Pseq(#[0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25,
			0.25, 2], 1),
		\sustain, Pseq(#[0.3, 0.3, 0.2, 0.3, 0.3, 0.3, 0.2, 0.3, 0.2, 0.3, 0.2, 0.3, 2], 1),
		\amp, Pseq(#[0.5, 0.5, 0.5, 0.8, 0.5, 0.5, 0.5, 0.8, 0.5, 0.8, 0.5,
			1, 0.4], 1),
		//\mw, Pseq([Pseq([0], 12), 0.03], 1)
	), #[0, 7, 7, 7, 7, 7, 3, 3, 3, 3],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([69, 71, 72, 71, 69, 66, 64, 69, 71], 1)-50,
		\dur, Pseq(#[0.25, 0.25, 0.25, 0.25, 0.166, 0.167, 0.167, 0.25, 0.25], 1),
		\sustain, Pseq(#[0.2, 0.2, 0.3, 0.2, 0.2, 0.2, 0.14, 0.3, 0.2], 1),
		//\amp, Pseq(#[0.5, 0.5, 0.8, 0.5, 0.5, 0.5, 0.5, 0.8, 0.5], 1)
	), #[3, 3, 3, 4, 4, 5],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([84, 85, 84, 84, 88, 84, 83, 81, 83, 81, 78, 76, 81, 83], 1)-50,
		\dur, Pseq(#[0.125, 0.535, 0.67, 1.92, 0.25, 0.166, 0.167, 0.167,
			0.25, 0.25, 0.25, 0.25, 0.25, 0.25], 1),
		\sustain, Pseq(#[0.2, 3.12, 0.2, 0.2, 0.2, 0.2, 0.2, 0.15, 0.3, 0.2, 0.2, 0.2,
			0.3, 0.2], 1),
		\amp, Pseq(#[1, 0.8, 0.8, 0.8, 1, 1, 0.8, 0.8, 1, 0.8, 0.8, 0.8,
			1, 0.8], 1),
		//\mw, Pseq([0, 0.005, 0.005, 0.06, Pseq(#[0], 10)], 1)
	), #[10, 10, 10, 11, 11, 11, 11, 12, 12, 12],

	// same as #4, 8va
	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq(([64, 66, 69, 71, 72, 73, 71, 69, 66, 71, 69, 66, 64, 69]+12), 1)-50,
		\dur, Pseq(#[0.25, 0.25, 0.25, 0.25, 0.125, 0.375, 0.166, 0.166, 0.168,
			0.5, 0.166, 0.166, 0.168, 0.5], 1),
		\sustain, Pseq(#[0.3, 0.2, 0.2, 0.2, 0.14, 0.4, 0.2, 0.2, 0.2, 0.6, 0.2, 0.2, 0.2, 0.5],1),
		\amp, Pseq(#[0.5, 0.5, 0.6, 0.8, 1, 0.5, 0.5, 0.5, 0.5, 1,
			0.5, 0.5, 0.5, 0.45], 1),
		//\mw, 0
	), #[11, 11, 11, 11, 11, 12, 12],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([81, 84, 83, 81, 78, 76, 81, 83], 1)-50,
		\dur, Pseq(#[0.25], 8),
		\sustain, Pseq(#[0.2, 0.3, 0.3, 0.2, 0.3, 0.2, 0.3, 0.2], 1),
		\amp, Pseq(#[0.5, 1, 0.5, 0.5, 0.6, 0.5, 0.8, 0.5], 1),
		//\mw, 0
	), #[0, 9, 9, 11, 11, 12, 12, 12, 12, 12],

	// same as #1, 8va
	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq(([64, 66, 69, 71, 72, 73]+12), 1)-50,
		\dur, Pseq(#[0.25], 6),
		\sustain, Pseq(#[0.3, 0.2, 0.2, 0.2, 0.3, 0.2], 1),
		\amp, Pseq(#[1, 0.5, 0.5, 0.5, 0.5, 0.5], 1),
		//\mw, 0
	), #[6, 6, 8, 9, 9, 9, 9, 10, 10, 10, 10, 13, 13, 13],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([78, 81, 83, 78, 83, 84, 78, 84, 85], 1)-50,
		\dur, Pseq(#[0.25, 0.25, 0.5, 0.25, 0.25, 0.5, 0.25, 0.25, 1.75], 1),
		\sustain, Pseq(#[0.2, 0.3, 0.2, 0.2, 0.3, 0.2, 0.2, 0.3, 1.75], 1),
		\amp, Pseq(#[0.4, 0.8, 0.5, 0.4, 0.8, 0.5, 0.4, 1, 0.8], 1),
		//\mw, Pseq([Pseq([0], 8), 0.03], 1)
	), #[8, 13, 13],

	PmonoArtic(\trest,
		\scale, a,
		\octave, 5,
		\degree, Pseq([88, 84, 83, 81, 83, 81, 78, 76, 81, 83], 1)-50,
		\dur, Pseq(#[0.25, 0.166, 0.167, 0.167,
			0.25, 0.25, 0.25, 0.25, 0.25, 0.25], 1),
		\sustain, Pseq(#[0.2, 0.2, 0.2, 0.15, 0.3, 0.2, 0.2, 0.2,
			0.3, 0.2], 1),
		\amp, Pseq(#[1, 1, 0.8, 0.8, 1, 0.8, 0.8, 0.8,
			1, 0.8], 1),
		//\mw, 0
	), #[10]
], inf)).play;
)

p.stop;



// melankolien slår ind
Pdef(\pattis).stop
(
Pdef(\pattis, {
	Pbind(\instrument, \trest,
		\out, 2,
		\scale, a,
		\octave, Pseq([[4,3,3], [4,3,3,2], [4,3], [4,3,2]], inf),
		\degree, Pseq([ [2,4,0], [1,7,5,3] ], inf),
		\dur, Pseq([68,68+Prand([0,2,4], 1)], inf),
		\attack, 0.1,
		\decay, 0.1,
		\sustain, 65.5,
		\release, 0.2,
		\amp, Pexprand(-35.dbamp, -31.dbamp),
		//\legato, 1
	).trace
}
).play(TempoClock(112/60*4));
)


(
Pdef(\pattis, {
	Pbind(\instrument, \trest,
		\out, 2,
		\scale, a,
		\octave, Pseq([[4,3,3], [4,3,3,2], [4,3], [4,3,2]], inf),
		\degree, Pseq([ [0.5,1,2.5,4], [1.5,7,5,3,6] ], inf),
		\dur, Pseq([34,34+Prand([0,1,2,3], 1)], inf),
		\attack, 0.1,
		\decay, 0.1,
		\sustain, 32,
		\release, 0.2,
		\amp, Pexprand(-35.dbamp, -31.dbamp),
		//\legato, 1
	).trace
}
).play(TempoClock(56/60*4));
)