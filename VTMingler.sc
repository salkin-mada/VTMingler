VTMingler {
	classvar <buffers;
	// todo make func that rejects meta mac sheise like: \sounds\._an_example.wav
	const <supportedHeaders = #[
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
		buffers = Dictionary.new;
		^this.loadDirTree(buffers, server, path, maxLoadInMb);
	}

	loadRootFiles {|buffers, server, path, maxLoadInMb|
		// If the root of the folder contains files, add them to the key \root
		if(PathName(path).files.size > 0,
			buffers.add(\root -> this.loadBuffersToTopEnvir(server, path, maxLoadInMb) );
		)

	}

	loadDirTree {|buffers, server, path, maxLoadInMb|
		PathName(path).folders.collect{|item|
			// Load folder of sounds into an array at buffers key of the folder name
			item.isFolder.if{
				buffers.add(item.folderName.asSymbol -> this.loadBuffersToTopEnvir(server, item.fullPath, maxLoadInMb));
			};
			item.isFile.if{ ("file! " ++ item).postln };
		};
		this.loadRootFiles(buffers, server, path);
		buffers.keysValuesDo{|k,v| "Key % contains % buffers now".format(k,v.size).postln};
		^buffers;

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
			bufnum, out = 0, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, startPos = 0,
			gate = 1
			|
			var numChan = 2, sig, key, frames, env, file;
			//if(BufChannels.kr(bufnum) == 2, {numChan = 2; "yo".postln;},{numChan = 1; "yaaw".postln;});
			//numChan = BufChannels.kr(bufnum);
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
			Out.ar(out, (sig*env));
		}).add;

	}

	/*

	*free { |server|
		this.freeBuffers;
		server = server ? Server.default;
		ServerBoot.remove(createBuffersFunc, server);
		"Sample(s) freed".postln;
	}

	*get { |bank, index|
		if (buffers.isNil.not) {
			var bufList = buffers[bank.asSymbol];
			if (bufList.isNil.not) {
				index = index % bufList.size;
				^bufList[index]
			}
		};
		^nil
	}

	*list {
		^buffers.keys
	}

	*displayList {
		^buffers.keysValuesDo { |bankName, buffers|
			"% [%]".format(bankName, buffers.size).postln
		}
	}

	*freeBuffers {
		buffers.do { |banks|
			banks.do { |buf|
				if (buf.isNil.not) {
					buf.free
				}
			}
		};
		buffers.clear;
	}

	*createBuffers { |server|
		this.freeBuffers;

		PathName(path).entries.do { |subfolder|
			var entries;
			entries = subfolder.entries.select { |entry|
				supportedHeaders.includes(entry.extension.asSymbol)
			};
			entries = entries.collect { |entry|
				Buffer.readChannel(server, entry.fullPath, channels: [0])
			};
			if (entries.isEmpty.not) {
				buffers.add(subfolder.folderName.asSymbol -> entries)
			}
		};

		"% samples loaded".format(buffers.size).postln;
	}*/

	/**addEventTypeFunc {
		Event.addEventType(\sample, {
			if (~buf.isNil) {
				var bank = ~bank;
				if (bank.isNil.not) {
					var index = ~index ? 0;
					~buf = SampleBank.get(bank, index)
				} {
					var sample = ~sample;
					if (sample.isNil.not) {
						var pair, bank, index;
						pair = sample.split($:);
						bank = pair[0].asSymbol;
						index = if (pair.size == 2) { pair[1].asInt } { 0 };
						~buf = SampleBank.get(bank, index)
					}
				}
			};
			~type = \note;
			currentEnvironment.play
		})
	}*/
}


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