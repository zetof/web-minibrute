// For JBL TUNE510BT only
(
s.options.numInputBusChannels = 0;
s.options.sampleRate = 16000;
)

// Boot the server
s.reboot;

// Set OSC controls
(
OSCdef.new(\control, {
	arg msg;
	msg.postln;
	if(msg[1] == 'mg_sl_sub', { ~subOsc.set(\lvl, msg[2]); });
	if(msg[1] == 'mg_sl_saw', { ~saw.set(\lvl, msg[2]); });
	if(msg[1] == 'mg_sl_sqr', { ~square.set(\lvl, msg[2]); });
	if(msg[1] == 'mg_sl_tri', { ~triangle.set(\lvl, msg[2]); });
	if(msg[1] == 'mg_sl_noi', { ~noise.set(\lvl, msg[2]); });
	if(msg[1] == 'so_switch_wave', { ~subOsc.set(\type, msg[2]); });
	if(msg[1] == 'so_switch_oct', { ~subOsc.set(\div, 1 + msg[2]); });
}, "/control");

// Set MIDI controls for a monophonic synth
~playing = nil;
~current_note = -1;

// Initiate MIDI input
MIDIClient.init;
MIDIIn.connectAll;

// Note ON events
MIDIdef.noteOn(\LPK25On, {
	arg vel, note, chan, src;
	note.postln;
	~note.set(\note, note, \t_key, 1);
	if(~current_note != -1, { ~playing.set(\gate, -1.01) });
	~playing = Synth.new(\mixer, [\inBus, ~mixerBus], ~mixerGroup);
	~current_note = note;
});

// Note OFF events
MIDIdef.noteOff(\LPK25Off, {
	arg vel, note;
	if(~current_note == note, { ~playing.set(\gate, 0); ~current_note = -1 });
});


// Set groups and their precedence
~noteGroup = Group.new;
~synthsGroup = Group.after(~noteGroup);
~mixerGroup = Group.after(~synthsGroup);

// Set busses for message routing
~synthsBus = Bus.audio(s, 1);
~mixerBus = Bus.audio(s, 1);

// Set all synth definitions
SynthDef(\note, {
	arg note, outBus, t_key=1;
	var freq;
	freq = EnvGen.ar(Env.new([1, 1], [0]), gate:t_key, levelScale:note.midicps);
	Out.ar(outBus, freq);
}).add;

SynthDef(\saw, {
	arg inBus, outBus, lvl=0;
	var freq;
	freq = In.ar(inBus, 1);
	Out.ar(outBus, lvl * LFSaw.ar(freq));
}).add;

SynthDef(\triangle, {
	arg inBus, outBus, lvl=0;
	var freq;
	freq = In.ar(inBus, 1);
	Out.ar(outBus, lvl * LFTri.ar(freq));
}).add;

SynthDef(\square, {
	arg inBus, outBus, lvl=0;
	var freq;
	freq = In.ar(inBus, 1);
	Out.ar(outBus, lvl * LFPulse.ar(freq));
}).add;

SynthDef(\noise, {
	arg outBus, lvl=0;
	Out.ar(outBus, lvl * WhiteNoise.ar());
}).add;

SynthDef(\subOsc, {
	arg inBus, outBus, div=1, type=0, lvl=0;
	var freq;
	freq = In.ar(inBus, 1);
	Out.ar(outBus, lvl * Select.ar(type, [LFPar.ar(freq / div / 2), LFPulse.ar(freq / div / 2)]));
}).add;

SynthDef(\mixer, {
	arg inBus, outBus=0, lvl=1, atkTime=0.01, dcyTime=0.3, rlsTime=0.5, susLvl=0.5, peakLvl=1, gate=1;
	var env;
	env = EnvGen.ar(Env.adsr(atkTime, dcyTime, susLvl, rlsTime, peakLvl), gate, doneAction:2);
	Out.ar(outBus, lvl * env * In.ar(inBus, 1)!2);
}).add;

// Instantiate synths
~note = Synth.new(\note, [\outBus, ~synthsBus], ~noteGroup);
~saw = Synth.new(\saw, [\inBus, ~synthsBus, \outBus, ~mixerBus], ~synthsGroup);
~triangle = Synth.new(\triangle, [\inBus, ~synthsBus, \outBus, ~mixerBus], ~synthsGroup);
~square = Synth.new(\square, [\inBus, ~synthsBus, \outBus, ~mixerBus], ~synthsGroup);
~noise = Synth.new(\noise, [\outBus, ~mixerBus], ~synthsGroup);
~subOsc = Synth.new(\subOsc, [\inBus, ~synthsBus, \outBus, ~mixerBus], ~synthsGroup);
)