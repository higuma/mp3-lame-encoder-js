  var NUM_CH = 2,
      HEAPU8 = Module.HEAPU8,
      malloc = Module._malloc,
      free = Module._free,
      lame_init = Module._lame_init,
      lame_set_mode = Module._lame_set_mode,
      lame_set_num_channels = Module._lame_set_num_channels,
      lame_set_in_samplerate = Module._lame_set_in_samplerate,
      lame_set_brate = Module._lame_set_brate,
      lame_init_params = Module._lame_init_params,
      lame_encode_buffer_ieee_float = Module._lame_encode_buffer_ieee_float,
      lame_encode_flush = Module._lame_encode_flush,
      lame_close = Module._lame_close;

  var Encoder = function(sampleRate, bitRate) {
    this.gfp = lame_init();
    lame_set_mode(this.gfp, 1/*JOINT_STEREO*/);
    lame_set_num_channels(this.gfp, NUM_CH);
    lame_set_in_samplerate(this.gfp, sampleRate);
    lame_set_brate(this.gfp, bitRate);
    lame_init_params(this.gfp);
    this.allocBuffers(8192);
    this.mp3Buffers = [];
  };

  Encoder.prototype.encode = function(buffers) {
    var length = buffers[0].length;
    if (length > this.srcLen) {
      this.freeBuffers();
      this.allocBuffers(length);
    }
    for (var ch = 0; ch < NUM_CH; ++ch)
      this.srcBuf[ch].set(buffers[ch]);
    var nBytes = lame_encode_buffer_ieee_float(
      this.gfp, this.srcPtr[0], this.srcPtr[1], length,
      this.dstPtr, this.dstSz);
    this.mp3Buffers.push(new Uint8Array(this.dstBuf.subarray(0, nBytes)));
  };

  Encoder.prototype.finish = function(mimeType) {
    var nBytes = lame_encode_flush(this.gfp, this.dstPtr, this.dstSz);
    this.mp3Buffers.push(new Uint8Array(this.dstBuf.subarray(0, nBytes)));
    var blob = new Blob(this.mp3Buffers, {type: mimeType || 'audio/mpeg'});
    this.cleanup();
    return blob;
  };

  Encoder.prototype.cancel = Encoder.prototype.cleanup = function() {
    lame_close(this.gfp);
    delete this.gfp;
    delete this.mp3Buffers;
    this.freeBuffers();
  };

  Encoder.prototype.allocBuffers = function(srcLen) {
    this.srcLen = srcLen;
    this.srcPtr = [];
    this.srcBuf = [];
    for (var ch = 0; ch < NUM_CH; ++ch) {
      this.srcPtr[ch] = malloc(this.srcLen * 4);
      this.srcBuf[ch] = new Float32Array(HEAPU8.buffer,
                                         this.srcPtr[ch], this.srcLen);
    }
    this.dstSz = Math.ceil(1.25 * this.srcLen) + 7200;  // see lame.h
    this.dstPtr = malloc(this.dstSz);
    this.dstBuf = new Uint8Array(HEAPU8.buffer, this.dstPtr, this.dstSz);
  };

  Encoder.prototype.freeBuffers = function() {
    delete this.dstBuf;
    delete this.srcBuf;
    free(this.dstPtr);
    for (var ch = 0; ch < NUM_CH; ++ch)
      free(this.srcPtr[ch]);
    delete this.dstPtr;
    delete this.srcPtr;
  };

  if (typeof Module.onReady === 'function') {
    if (Module.calledRun) {
      Module.onReady(Module);
    } else {
      Module.addOnPostRun(Module.onReady);
    }
  }

  self.Mp3LameEncoder = Encoder;
})(self);
