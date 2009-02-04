#!/usr/bin/env ruby
require 'avchd.rb'

target = '/tmp/mux'

avchd = Avchd.new target

# <Generate .m2ts -files>

video = avchd.create_video
video.create_item 1

avchd.save
