
// (
// fork{
// 	var supportedExtensions = #[\wav, \wave, \aif, \aiff, \flac];
// 	var dir = "C:/Users/na/Desktop/lydfiler/andre lydfiler";
// 	var folders;
//
// 	PathName(dir).entries.do{ |entry|
//
// 		var entries, rootEntries;
//
// 		// entry.folderName.postln;
//
// 		if(entry.fullPath.isFile) {
// 			~rootEntries = entry.asArray.select { |item|
// 				supportedExtensions.includes(item.extension.asSymbol);
// 			};
// 		};
//
// 		entries = entry.entries.select { |item|
// 			("entries\t"++item).postln;
// 			supportedExtensions.includes(item.extension.asSymbol);
// 		};
//
// 		entries = entries.collect { |item|
// 			Buffer.readChannel(s, item.fullPath, channels: [0])
// 		};
//
// 		if (entries.isEmpty.not) {
// 			folders.add(entry.folderName.asSymbol -> entries)
// 		};
//
// 		if (~rootEntries.isEmpty.not) {
// 			folders.add('root' -> entries)
// 		}
// 	};
//
// 	"% folders loaded".format(folders.size).postln;
// }
// )




VTMingler {
	classvar <dir, <buffers;
	classvar makeBuffersFn;

	const <supportedExtensions = #[\wav, \wave, \aif, \aiff, \flac];

	*initClass {
		buffers = Dictionary.new;
		makeBuffersFn = #{ |server| VTMingler.prMakeBuffers(server) };
		this.prAddEventType;
	}

	*loadAll { |path, server|
		dir = path;
		if (dir.isNil) { Error("this is not a directory").throw };
		server = server ? Server.default;

		// create buffers on boot
		ServerBoot.add(makeBuffersFn, server);

		// if server is running create rightaway
		if (server.serverRunning) {
			this.prMakeBuffers(server);
		};

		this.prAddSynthDefinitions;
		"VTMingler synths build".postln;
	}

	*free { |server|
		this.prFreeBuffers;
		server = server ? Server.default;
		ServerBoot.remove(makeBuffersFn, server);
		"files freed".postln;
	}

	*get { |folder, index|
		if (buffers.isNil.not) {
			var bufList = buffers[folder.asSymbol];
			if (bufList.isNil.not) {
				index = index % bufList.size;
				^bufList[index]
			}
		};
		^nil
	}

	*folders {
		^buffers.keys
	}

	*files {
		^buffers.do { |folderName, buffers|
			"% %".format(folderName, buffers.size).postln
		}
	}

	*list {
		^buffers.keysValuesDo { |folderName, buffers|
			"% [%]".format(folderName, buffers.size).postln
		}
	}

	*prFreeBuffers {
		buffers.do { |folders|
			folders.do { |buf|
				if (buf.isNil.not) {
					buf.free
				}
			}
		};
		buffers.clear;
	}

	*prMakeBuffers { |server|
		this.prFreeBuffers;

		PathName(dir).entries.do { |subfolder|
			var entries;
			entries = subfolder.entries.select { |entry|
				supportedExtensions.includes(entry.extension.asSymbol)
			};
			// add mono-stereo allocating
			entries = entries.collect { |entry|
				Buffer.readChannel(server, entry.fullPath, channels: [0])
			};
			if (entries.isEmpty.not) {
				buffers.add(subfolder.folderName.asSymbol -> entries)
			}
		};

		"% folders loaded".format(buffers.size).postln;
	}

	*prAddSynthDefinitions {
		SynthDef(\VTMinglerMono, {
			|
			bufnum, out = 0, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
			gate = 1, cutoff = 22e3, bass = 0.0
			|
			var sig, key, frames, env, file;
			frames = BufFrames.kr(bufnum);
			sig = VTMBufferPlay.ar(
				1,
				bufnum,
				rate*BufRateScale.kr(bufnum),
				1,
				pos*frames,
				loop: loop
			);
			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
			FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
			sig = LPF.ar(sig, cutoff);
			sig = sig + (LPF.ar(sig, 100, bass));
			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
			Out.ar(out, (sig*env));
		}).add;

		SynthDef(\VTMinglerStereo, {
			|
			bufnum, out = 0, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
			gate = 1, cutoff = 22e3, bass = 0.0
			|
			var sig, key, frames, env, file;
			frames = BufFrames.kr(bufnum);
			sig = VTMBufferPlay.ar(
				2,
				bufnum,
				rate*BufRateScale.kr(bufnum),
				1,
				pos*frames,
				loop: loop
			);
			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
			FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
			sig = LPF.ar(sig, cutoff);
			sig = sig + (LPF.ar(sig, 100, bass));
			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
			Out.ar(out, (sig*env));
		}).add;

		/*  --------------------------------------------  */
		/*  for scaling assuming samples are tuned in 440 */
		/*  --------------------------------------------  */
		SynthDef(\VTMinglerMonoScale, {
			|
			bufnum, out = 0, loop = 0, spread = 1, pan = 0, amp = 0.5,
			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
			gate = 1, cutoff = 22e3, bass = 0.0, basefreq=440, freq
			|
			var sig, rate, frames, env, file;
			frames = BufFrames.kr(bufnum);
			rate = freq/basefreq;
			sig = VTMBufferPlay.ar(
				1,
				bufnum,
				rate*BufRateScale.kr(bufnum),
				1,
				pos*frames,
				loop: loop
			);
			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
			FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
			sig = LPF.ar(sig, cutoff);
			sig = sig + (LPF.ar(sig, 100, bass));
			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
			Out.ar(out, (sig*env));
		}).add;

		SynthDef(\VTMinglerStereoScale, {
			|
			bufnum, out = 0, loop = 0, spread = 1, pan = 0, amp = 0.5,
			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
			gate = 1, cutoff = 22e3, bass = 0.0, basefreq=440, freq
			|
			var sig, rate, frames, env, file;
			frames = BufFrames.kr(bufnum);
			rate = freq/basefreq;
			sig = VTMBufferPlay.ar(
				2,
				bufnum,
				rate*BufRateScale.kr(bufnum),
				1,
				pos*frames,
				loop: loop
			);
			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
			FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
			sig = LPF.ar(sig, cutoff);
			sig = sig + (LPF.ar(sig, 100, bass));
			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
			Out.ar(out, (sig*env));
		}).add;
	}

	*prAddEventType {
		Event.addEventType(\VTMingler, {
			var numChannels, scaling;

			if (~buf.isNil) {
				var folder = ~folder;
				if (folder.isNil.not) {
					var index = ~index ? 0;
					~buf = VTMingler.get(folder, index)
				} {
					var sample = ~sample;
					if (sample.isNil.not) {
						var pair, folder, index;
						pair = sample.split($:);
						folder = pair[0].asSymbol;
						index = if (pair.size == 2) { pair[1].asInt } { 0 };
						~buf = VTMingler.get(folder, index)
					}
				}
			};

			numChannels = ~buf.bufnum.numChannels;
			scaling = ~tuningOnOff;
			if(scaling.isNil) {scaling = 0};

			if(scaling == 1,
				{
					switch(numChannels,
						1, {
							~instrument = \VTMinglerMonoScale;
						},
						2, {
							~instrument = \VTMinglerStereoScale;
						},
						{
							~instrument = \VTMinglerMonoScale;
						}
					)
				},
				{
					switch(numChannels,
						1, {
							~instrument = \VTMinglerMono;
						},
						2, {
							~instrument = \VTMinglerStereo;
						},
						{
							~instrument = \VTMinglerMono;
						}
					)
				}
			);
			~type = \note;
			~bufnum = ~buf.bufnum;
			currentEnvironment.play
		});
	}
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






//
// VTMingler {
// 	classvar <dir, <buffers;
// 	classvar makeBuffersFn;
//
// 	const <supportedExtensions = #[\wav, \wave, \aif, \aiff, \flac];
//
// 	*initClass {
// 		buffers = Dictionary.new;
// 		makeBuffersFn = #{ |server| VTMingler.prMakeBuffers(server) };
// 		this.prAddEventType;
// 	}
//
// 	*loadAll { |argDir, server|
// 		dir = argDir;
// 		if (dir.isNil) { Error("no directory").throw };
// 		server = server ? Server.default;
//
// 		// create buffers on boot
// 		ServerBoot.add(makeBuffersFn, server);
//
// 		// if server is running create rightaway
// 		if (server.serverRunning) {
// 			this.prMakeBuffers(server);
// 		};
//
// 		this.prAddSynthDefinitions;
// 		"VTMingler synths build".postln;
// 	}
//
// 	*free { |server|
// 		this.prFreeBuffers;
// 		server = server ? Server.default;
// 		ServerBoot.remove(makeBuffersFn, server);
// 		"files freed".postln;
// 	}
//
// 	*get { |bank, index|
// 		if (buffers.isNil.not) {
// 			var bufList = buffers[bank.asSymbol];
// 			if (bufList.isNil.not) {
// 				index = index % bufList.size;
// 				^bufList[index]
// 			}
// 		};
// 		^nil
// 	}
//
// 	*list {
// 		^buffers.keys
// 	}
//
// 	*displayList {
// 		^buffers.keysValuesDo { |bankName, buffers|
// 			"% [%]".format(bankName, buffers.size).postln
// 		}
// 	}
//
// 	*prFreeBuffers {
// 		buffers.do { |banks|
// 			banks.do { |buf|
// 				if (buf.isNil.not) {
// 					buf.free
// 				}
// 			}
// 		};
// 		buffers.clear;
// 	}
//
// 	*prMakeBuffers { |server|
// 		this.prFreeBuffers;
//
// 		PathName(dir).entries.do { |subfolder|
// 			var entries;
// 			entries = subfolder.entries.select { |entry|
// 				supportedExtensions.includes(entry.extension.asSymbol)
// 			};
// 			entries = entries.collect { |entry|
// 				Buffer.readChannel(server, entry.fullPath, channels: [0])
// 			};
// 			if (entries.isEmpty.not) {
// 				buffers.add(subfolder.folderName.asSymbol -> entries)
// 			}
// 		};
//
// 		"% sample banks loaded".format(buffers.size).postln;
// 	}
//
// 	*prAddSynthDefinitions {
// 		SynthDef(\VTMinglerMono, {
// 			|
// 			bufnum, out = 0, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
// 			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
// 			gate = 1, cutoff = 22e3
// 			|
// 			var sig, key, frames, env, file;
// 			frames = BufFrames.kr(bufnum);
// 			sig = VTMBufferPlay.ar(
// 				1,
// 				bufnum,
// 				rate*BufRateScale.kr(bufnum),
// 				1,
// 				pos*frames,
// 				loop: loop
// 			);
// 			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
// 			FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
// 			sig = LPF.ar(sig, cutoff);
// 			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
// 			Out.ar(out, (sig*env));
// 		}).add;
//
// 		SynthDef(\VTMinglerStereo, {
// 			|
// 			bufnum, out = 0, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
// 			attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
// 			gate = 1, cutoff = 22e3
// 			|
// 			var sig, key, frames, env, file;
// 			frames = BufFrames.kr(bufnum);
// 			sig = VTMBufferPlay.ar(
// 				2,
// 				bufnum,
// 				rate*BufRateScale.kr(bufnum),
// 				1,
// 				pos*frames,
// 				loop: loop
// 			);
// 			env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
// 			FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
// 			sig = LPF.ar(sig, cutoff);
// 			sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
// 			Out.ar(out, (sig*env));
// 		}).add;
// 	}
//
// 	*prAddEventType {
// 		Event.addEventType(\VTMingler, {
// 			var numChannels;
// 			numChannels = ~bufnum.numChannels;
// 			switch(numChannels,
// 				1, {
// 					~instrument = \VTMinglerMono;
// 				},
// 				2, {
// 					~instrument = \VTMinglerStereo;
// 				},
// 				{
// 					~instrument = \VTMinglerMono;
// 				}
// 			);
// 			//~type = \note;
// 			//currentEnvironment.play
//
// 			if (~buf.isNil) {
// 				var bank = ~bank;
// 				if (bank.isNil.not) {
// 					var index = ~index ? 0;
// 					~buf = VTMingler.get(bank, index)
// 				} {
// 					var sample = ~sample;
// 					if (sample.isNil.not) {
// 						var pair, bank, index;
// 						pair = sample.split($:);
// 						bank = pair[0].asSymbol;
// 						index = if (pair.size == 2) { pair[1].asInt } { 0 };
// 						~buf = VTMingler.get(bank, index)
// 					}
// 				}
// 			};
// 			~type = \note;
// 			currentEnvironment.play
// 		});
// 	}
// }


/*VTMBufferPlay {
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
}*/























/*VTMingler {
classvar <buffers;

const <supportedHeaders = #[
"wav",
"wave",
"aiff",
"flac"
];

*new { arg server, path, maxLoadInMb = 1000;
^super.new.init(server, path, maxLoadInMb);
}

init { arg server, path, maxLoadInMb;
buffers = Dictionary.new;
this.prAddEventType;
"VTMingler Event Type added".postln;
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

// todo reject meta mac/win sheise like: \sounds\._an_example.wav
checkIfHeaderIsSupported {|path|
^supportedHeaders.indexOfEqual(
PathName(path).extension.toLower
).notNil;
}

loadBuffersToTopEnvir {|server, path, maxLoadInMb|
var key;
var array = PathName(path).files.collect({|file, i|
this.checkIfHeaderIsSupported(file.fullPath).if({
Buffer.read(server,
file.fullPath,
startFrame: 0,
numFrames: -1,
action: nil,
bufnum: nil
)
/*if(topEnvironment.includesKey(file.asSymbol), {
topEnvironment.at(file.asSymbol).free;
//"\tfree buffer".postln;
});
key = ("fil"++i);
// populate buffer
topEnvironment.put(
key.asSymbol, //file.asSymbol,
Buffer.read(server,
file.fullPath
);
);*/
})
});

this.addSynthDefinitions;

// reject nil items
^array.reject({|item| item.isNil});
}

addSynthDefinitions {
SynthDef(\VTMinglerMono, {
|
bufnum, out = 0, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
gate = 1, cutoff = 22e3
|
var sig, key, frames, env, file;
frames = BufFrames.kr(bufnum);
sig = VTMBufferPlay.ar(
1,
bufnum,
rate*BufRateScale.kr(bufnum),
1,
pos*frames /*BufDur.kr(bufnum) * pos * s.sampleRate*/,
loop: loop
);
env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
sig = LPF.ar(sig, cutoff);
sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
Out.ar(out, (sig*env));
}).add;

SynthDef(\VTMinglerStereo, {
|
bufnum, out = 0, loop = 0, rate = 1, spread = 1, pan = 0, amp = 0.5,
attack = 0.01, decay = 0.5, sustain = 0.5, release = 1.0, pos = 0,
gate = 1, cutoff = 22e3
|
var sig, key, frames, env, file;
frames = BufFrames.kr(bufnum);
sig = VTMBufferPlay.ar(
2,
bufnum,
rate*BufRateScale.kr(bufnum),
1,
pos*frames  /*BufDur.kr(bufnum) * pos * s.sampleRate*/,
loop: loop
);
env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate);
FreeSelf.kr(TDelay.kr(Done.kr(env),0.1));
sig = LPF.ar(sig, cutoff);
sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
Out.ar(out, (sig*env));
}).add;
}

prAddEventType {
Event.addEventType(\VTMingler, {
var numChannels;
numChannels = ~bufnum.numChannels;
switch(numChannels,
1, {
~instrument = \VTMinglerMono;
},
2, {
~instrument = \VTMinglerStereo;
},
{
~instrument = \VTMinglerMono;
}
);
~type = \note;
currentEnvironment.play
})
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
*/
