VTMBufferPlay {

	// stolen PlayBufCF
	*ar { arg numChannels, bufnum=0, rate=1.0, trigger=1.0, startPos=0.0, loop = 0.0,
		lag = 0.1, n = 2; // alternative for safemode

		var index, method = \ar, on;

		switch ( trigger.rate,
			\audio, {
				index = Stepper.ar( trigger, 0, 0, n-1 );
			},
			\control, {
				index = Stepper.kr( trigger, 0, 0, n-1 );
				method = \kr;
			},
			\demand, {
				trigger = TDuty.ar( trigger ); // audio rate precision for demand ugens
				index = Stepper.ar( trigger, 0, 0, n-1 );
			},
			{ ^PlayBuf.ar( numChannels, bufnum, rate, trigger, startPos, loop ); } // bypass
		);

		on = n.collect({ |i|
			//on = (index >= i) * (index <= i); // more optimized way?
			InRange.perform( method, index, i-0.5, i+0.5 );
		});

		switch ( rate.rate,
			\demand,  {
				rate = on.collect({ |on, i|
					Demand.perform( method, on, 0, rate );
				});
			},
			\control, {
				rate = on.collect({ |on, i|
					Gate.kr( rate, on ); // hold rate at crossfade
				});
			},
			\audio, {
				rate = on.collect({ |on, i|
					Gate.ar( rate, on );
				});
			},
			{
				rate = rate.asCollection;
			}
		);

		if( startPos.rate == \demand ) {
			startPos = Demand.perform( method, trigger, 0, startPos )
		};

		lag = 1/lag.asArray.wrapExtend(2);

		^Mix(
			on.collect({ |on, i|
				PlayBuf.ar( numChannels, bufnum, rate.wrapAt(i), on, startPos, loop )
				* Slew.perform( method, on, lag[0], lag[1] ).sqrt
			})
		);

	}
}

VTMBufferFiles {

	var supportedHeaders = #[
		"wav",
		"wave",
		"aiff",
		"flac",
		"raw",
		"ogg",
		"vorbis",
		"sdif"
	];

	*new { arg server, path, maxLoadInMb = 1000;
		^super.new.init(server, path, maxLoadInMb);
	}

	init { arg server, path, maxLoadInMb;
		^this.loadBuffersToTopEnvir(server, path, maxLoadInMb);
	}

	checkIfHeaderIsSupported { |path|
		^supportedHeaders.indexOfEqual(
			PathName(path).extension.toLower
		).notNil;
	}

	loadBuffersToTopEnvir { |server, path, maxLoadInMb|
		var array = PathName(path).files.collect({|file|
			this.checkIfHeaderIsSupported(file.fullPath).if({
				if(topEnvironment.includesKey(file.asSymbol), {
					topEnvironment.at(file.asSymbol).free;
					//"\tfree buffer".postln;
				});
				// populate buffer
				topEnvironment.put(
					file.asSymbol,
					Buffer.read(server,
						file.fullPath
					);
				);
			})
		});

		this.buildSynth;

		// reject nil items
		^array.reject({|item| item.isNil});
	}

	buildSynth {
		SynthDef(\VTMingler, {
			|
			bufnum, direction = 1, out = 0, effectBus, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, startPos = 0,
			gate = 1
			|
			var numChan, sig, key, frames, env, file;
			if(BufChannels.kr(bufnum) == 2, {numChan = 2},{numChan = 1});
			frames = BufFrames.kr(bufnum);
			sig = VTMBufferPlay.ar(
				numChan,
				bufnum,
				rate*BufRateScale.kr(bufnum),
				1,
				startPos*frames, loop: loop
			);
			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
			Out.ar(out, (sig*env)*direction);
			Out.ar(effectBus, sig*(1 - direction));
		}).add;

	}
}

VTMBufferFolders {

	var dict;

	*new { arg server, path, maxLoadInMb = 1000;

		^super.new.init(server, path, maxLoadInMb);

	}

	init { arg server, path, maxLoadInMb;

		dict = Dictionary.new;

		^this.loadDirTree(dict, server, path, maxLoadInMb);

	}

	loadRootFiles {|dict, server, path, maxLoadInMb|
		// If the root of the folder contains files, add them to the key \root

		if(PathName(path).files.size > 0,
			dict.add(\basepath -> VTMBufferFiles(server, path, maxLoadInMb) );
		)

	}

	loadDirTree {|dict, server, path, maxLoadInMb|

		PathName(path).folders.collect{|item|

			// Load folder of sounds into an array at dict key of the folder name
			item.isFolder.if{
				dict.add(item.folderName.asSymbol -> VTMBufferFiles.new(server, item.fullPath, maxLoadInMb));
			};

			item.isFile.if{ ("file! " ++ item).postln };

		};

		this.loadRootFiles(dict, server, path);

		dict.keysValuesDo{|k,v| "Key % contains % buffers now".format(k,v.size).postln};

		^dict;

	}

}

// VTMingler {
// 	/**new { arg server, path;
//
// 	^super.new.init(server, path);
//
// 	}
//
// 	init { arg server, path;
//
// 	var oiu;
//
// 	^this.buildSynths(oiu, server, path);
//
// 	}*/
//
// 	buildSynth {/*|oiu, server, path|*/
// 		SynthDef(\VTMingler, {
// 			|
// 			bufnum, direction = 1, out = 0, effectBus, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
// 			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, startPos = 0,
// 			gate = 1
// 			|
// 			var numChan, sig, key, frames, env, file;
// 			if(BufChannels.kr(bufnum) == 2, {numChan = 2},{numChan = 1});
// 			frames = BufFrames.kr(bufnum);
// 			sig = VTMBufferPlay.ar(
// 				numChan,
// 				bufnum,
// 				rate*BufRateScale.kr(bufnum),
// 				1,
// 				startPos*frames, loop: loop
// 			);
// 			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);
// 			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
// 			Out.ar(out, (sig*env)*direction);
// 			Out.ar(effectBus, sig*(1 - direction));
// 		}).add;
//
// 	}
// }