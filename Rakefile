require 'fileutils'

LAME_VER = '3.99.5'
LAME = "lame-#{LAME_VER}"
LAME_TARBALL = "#{LAME}.tar.gz"
BASE_URL = 'http://downloads.sourceforge.net/project/lame/lame/3.99'
LAME_URL = "#{BASE_URL}/#{LAME_TARBALL}"

task :lame do
  sh "wget #{LAME_URL}" unless File.exist? LAME_TARBALL
  sh "tar zxf #{LAME_TARBALL}" unless File.exist? LAME
end

LIBMP3LAME = "#{LAME}/libmp3lame"

EMCC_INCLUDES = [
  'include',
  "#{LAME}/include",
  LIBMP3LAME
].map {|include| "-I#{include}" }
 .join ' '

EMCC_COMPILE_OPTIONS = [
  '-O3',
  '-ffast-math',
  '-DHAVE_CONFIG_H',
  '-DSTDC_HEADERS',
  EMCC_INCLUDES
].join ' '

EMCC_LINK_OPTIONS = [
  '-s ALLOW_MEMORY_GROWTH=0',
  '-s ASM_JS=1',
  '-s EXPORTED_FUNCTIONS=@src/exports.json',
  '--pre-js src/pre.js',
  '--post-js src/post.js'
].join ' '

OUTPUT = 'output'
LAME_OUTPUT = "#{OUTPUT}/#{LAME}"
LIBMP3LAME_OUTPUT = "#{OUTPUT}/#{LIBMP3LAME}"
LIBMP3LAME_FILES = [
  'bitstream.c',
  'encoder.c',
  'fft.c',
  #'gain_analysis.c',
  'id3tag.c',
  'lame.c',
  #'mpglib_interface.c',
  'newmdct.c',
  'psymodel.c',
  'presets.c',
  'quantize.c',
  'quantize_pvt.c',
  'reservoir.c',
  'set_get.c',
  'tables.c',
  'takehiro.c',
  'util.c',
  #'vbrquantize.c',
  'VbrTag.c',
  #'vector/xmm_quantize_sub.c',
  'version.c'
]

def enum_sources(files, dir)
  files.map {|file| "#{dir}/#{file}" }.sort
end

def enum_targets(sources, dir)
  sources.map {|source| "#{dir}/#{File.basename(source).sub /c$/, 'o'}" }
end

LIBMP3LAME_SOURCES = enum_sources LIBMP3LAME_FILES, LIBMP3LAME

LIBMP3LAME_OUTPUTS = enum_targets LIBMP3LAME_SOURCES, LIBMP3LAME_OUTPUT

def compile_files(sources, targets)
  targets.each.zip(sources).each do |target, source|
    FileUtils.makedirs File.dirname(target)
    sh "emcc #{EMCC_COMPILE_OPTIONS} -o #{target} #{source}"
  end
end

task compile_lame: :lame do
  compile_files LIBMP3LAME_SOURCES, LIBMP3LAME_OUTPUTS
end

task build_lib: [:compile_lame] do
  FileUtils.makedirs 'lib'
  sources = LIBMP3LAME_OUTPUTS.join ' '
  sh "emcc -O1 #{EMCC_LINK_OPTIONS} -o lib/Mp3LameEncoder.js #{sources}"
  sh "emcc -O3 #{EMCC_LINK_OPTIONS} -o lib/Mp3LameEncoder.min.js #{sources}"
end

task :libclean do
  sh 'rm -rf lib'
end

task :clean do
  sh 'rm -rf output'
end

task distclean: :clean do
  sh "rm -rf #{LAME}"
  sh "rm -f #{LAME_TARBALL}"
end

task default: :build_lib
