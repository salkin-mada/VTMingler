
// TODO
// watch out for chars like >´< and >ø< (�) in file names,
   /*the buffer doesnt have a problem but for SoundFileView its trouble*/
// mulighed for at "parse" midifil (~key, vel, timing[dur]) gennem Pdef->Pbind ??
// tjek regex solutionss "s[0-9]+.*.aif".pathMatch
// regarding mem allocated:
   /*læs størrelse i ram numframes der er loaded via Buffer
   hvis Buffer ikke kan sige noget om filens frame størrelse før efter den er loaded brug SoundFile til dette?*/

//cadeau til the flying saucer
(
~numberOfAudioFilesLoaded = 0;
~key;
~basepath;
"C:/Users/na/Desktop/Supercollider SCD/folder new turn/LYDSERVER.scd".load;
s.doWhenBooted{/*var ~basepath;
    ~basepath = FileDialog.new({arg ok, path;
    if (ok, {
    PathName.new(path);
    });
    }, fileMode: 2);*/

    /*fork*/{
        var humansAreSlow = 0.000015,
        numberOfAudioFilesFound = 0, numberOfSkippedAudioFiles = 0;
        var fileSize, totalFileSize = 0, totalFileSizeLoaded = 0;

        var maxLoad = 2500/*4000 max tested*//*MB*/*1e6;
        //var maxAmountFileLoad = 10;
        // dont mistake this from saying anything about how much memory scsynth eats

        ~basepath = PathName.new("C:/Users/na/Desktop/lydfiler");// <-------choose folder

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
                || (~basepath.files.at(i).extension == "WAV")
                || (~basepath.files.at(i).extension == "aiff"), {
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
                bufnum, direction = 1, out = 0, effectBus, rate = 1, spread = 1, pan = 0, amp = 0.5,
                attack = 0.2, sustain = 0.5, release = 1.0, startPos = 0,
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
                    startPos*frames, loop: 1
                );
                env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
                //env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), doneAction: 2);
                //FreeSelfWhenDone.kr(env);
                sig = Splay.ar(sig, spread: spread, center: pan, level: amp);
                Out.ar(out, (sig*env)*direction);
                Out.ar(effectBus, sig*(1 - direction));
            }).add;

            ~stereo = SynthDef(\stereo, {
                |
                bufnum, direction = 1, out = 0, effectBus, rate = 1, spread = 1, pan = 0, amp = 0.5,
                attack = 0.2, sustain = 0.5, release = 1.0, startPos = 0,
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
                    startPos*frames, loop: 1
                );
                env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
                //env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), doneAction: 2);
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
                in = In.ar([20,21], 2);
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
                in = In.ar([20,21], 2);
                in = HPF.ar(in, 200);
                sig = in;//SinOsc.ar(Amplitude.kr(in).linexp(0,1,0.8,500))*in;
                sig = Convolution2.ar(sig*0.8, SinOsc.ar([5e3,6e3,7e3,8e3,9e3])*sig*0.8, 1, 2048, 0.05);
                sig = sig.softclip;
                env = EnvGen.ar(Env([0,1,1,0], [attack,sustain,release], 'lin'), doneAction: 2);
                Out.ar(out, Splay.ar(sig*env, spread: spread, center: pan, level: amp));
            }).add;

        });

        humansAreSlow.wait;
        "\n\t\tdone".postln;
        (humansAreSlow*2).wait;
        "\n\t\tview time --->".postln;
        (humansAreSlow*2).wait;

        /*---      ---*/
        /*--- VIEW ---*/
        /*---      ---*/

        w = View(bounds: Rect(300,Window.screenBounds.height-480)).front;
        /*w = Window(
        bounds: Rect(300,Window.screenBounds.height-480),
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
                frames: topEnvironment[~key.asSymbol].numFrames,
            /*block: 1e4*/);
            result;
        });

        t = {TextField(bounds: Rect(0, 0, 450, 10))} ! ~numberOfAudioFilesLoaded;
        t.do({arg item, i;
            var result;
            ~key = ('data'++i);
            t[i].string = (~basepath.files.at(i).fileName).asString;
            t[i].font = Font("Segoe UI Black", 18);
            t[i].align = \center;
            t[i].background = Color(0.6,0.4,1.0, 0.3);

        });

        g = GridLayout.new.hSpacing_(0).vSpacing_(0);
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

        w.layout = g;

        // view listener
        /*loop{
        // ring til view text field background

            0.05.wait;
        };*/ // måske bruge SkipJack her altså.. måske dette skal ske i \layere


    }.fork(AppClock)
})

Pdef(\layere).fadeTime = 10.0;
Pdef(\layere).stop;

(

Pdef(\layere, {
    var bus, effectbus, dir = 1.0;

    bus = 2; // stereo ud
    effectbus = 20; // stereo

    Ndef(\summing, {var in, sig;
        in = In.ar([2,3]);
        sig = Limiter.ar(in, 0.8);
        sig = sig.clip(-0.99, 0.99);
        sig;
    }).play;

    Ppar([
        Pbind( // synths
            \out, bus,
            \effectBus, effectbus,
            \dur, 15,//13,//12.7,//Pslide([0.2,12], inf, 1, 0.01),//Pseq([1], inf),
            \amp, Pseq([0.9,0.5,0.3,0.8], inf)* 0.7,
            \rate, 0.4,//Pseq([0.89, 0.8, 0.79], inf)*Pxrand([0.4,0.2,3,4], inf),
            \startPos, Pseq([0.3, 0.5, 0.7, 0.5, 0.29, 0.99, 0.01], inf),
            \attack, 4.02,//2.9,
            \sustain, 2.001,
            \release, 8.02,//6.5,
            \pan, Pxrand([-1.0, -0.5, 0.0, 0.5, 1.0], inf),
            \spread, 0.6,
            \direction, Pxrand([1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0], inf), // dry wet
            \send, Pfunc({|envir|
                dir = envir.direction;
            }),
            \file, Pxrand((1..32), inf),/*Pstep(
                Pxrand((1..49), inf), 12, inf
            ),*/// // eksempel  youyou.wav weird channel behavior CHECK IT OUT
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
            /*\callBackForView, Pfunc({|envir|
                if (Pdef(\layere).isPlaying == true, {

                });
            })*/
        ),
        Pbind( // efx
            \out, bus,
            \dur, 30, //13,//Pslide([0.2,12], inf, 1, 0.01),//Pseq([1], inf),
            \amp, 0.9,
            \attack, 0.01,//2.5,
            \sustain, 0.02,//2.0,
            \release, 8.1, //7.0,
            \pan, Pxrand([-1.0, -0.5, 0.0, 0.5, 1.0], inf),
            \spread, 0.3,
            \efx, Pseq([1,1,1,0], inf),
            \instrument, Pfunc({|envir|
                var result;
                ("\n\t\tdir:: (send from generator Pbind):\n\t\t"++dir).postln;
                if (dir < 1, {
                    "\t\tefx-on".postln;
                    "\t\t baby".postln;
                    switch(envir.efx,
                        0, {"\t\tdelay".postln; result = 'delay'},
                        1, {"\t\tmingl".postln; result = 'mingl'},
                        { result = 'nil'}
                    );
                    "\n".post;
                }, { result = 'nil' });
                result;
            }),
        )
    ])/*.trace*/;
}).play(TempoClock(132/60*4));
)

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