
~tio = VTMBufferFolders(s, "C:/Users/na/Desktop/lydfiler/mona sigler generate spasm/choir");

~tio[\basepath]
~tio[\basepath].
~tio[\909].size
~tio.keys


(
Pbind(
	\instrument, \VTMingler,
	//\bufnum, Pseq([~tio[\basepath].at(0).values.at(5)], inf),
	//\bufnum, Pseq((0..~tio[\basepath].at(0).size-1), inf),
	\bufnum, Pxrand(~tio[\basepath].at(0).values, inf),
	\dur, Pseq([1,2,1,Rest(3),1,2,Rest(1),1],inf),
	\amp, 1.0,
	\startPos, 0.0,
	\rate, 0.2,
	\attack, 0.9,
	\decay, 0.9,
	\sustain, 1.2,
	\release, 2.4,
	\spread, 1,
	\pan, 0
).play(TempoClock(130.60/60*4));
)