require 'cora'
require 'siri_objects'
require 'pp'
require 'rexml/document'
require 'date'

class SiriProxy::Plugin::DominiekTV < SiriProxy::Plugin
	def initialize(config)
		xmlfile = '/tmp/jxmltv/xmltv.xml'
		@tvguide = TVGuide.new(xmlfile)
	end

	class TVGuide
		def initialize(xmlfile)
			@xmlfile = xmlfile
			refresh()
		end

		def refresh()
			@programs = []
			
			xml = File.read(@xmlfile)
			doc = REXML::Document.new(xml)
			
			doc.elements.each('/tv/programme') do |p|
				channel = p.attributes['channel'].gsub('.be', '').upcase
				title = p.elements['title'].text
				description = p.elements['desc'].text
				ds = DateTime.parse(p.attributes['start'])
				de = DateTime.parse(p.attributes['stop'])
						
				@programs << Program.new(title, ds, de, channel, description)
			end	
		end

		def get_programs()
			return @programs
		end

		class Program
			attr_accessor :title, :start_time, :end_time, :channel, :description

			def initialize(title, start_time, end_time, channel, description)
				@title = title
				@start_time = start_time
				@end_time = end_time
				@channel = channel
				@description = description
			end
		end
	end

	listen_for /what's on tv/i do   
		def relevant?(program)
			now = DateTime.now
			ds = program.start_time
			de = program.end_time			

			#programs today
			if (ds.year == now.year) && (ds.month == now.month) && (ds.day == now.day)
				#programs that are running
				if (ds < now) && (de > now)
					return true
				end
			end
			return false
	  	end
		
		programs = @tvguide.get_programs().select { |program| relevant?(program) }
		i = 0
		max = programs.length - 1

		if (not programs.empty?())
			say "This is on TV right now." #say something to the user!
			programs.each	{ |program|
				if (i == 0)
					speech = "You can watch " + program.title + " on " + program.channel
					txt = program.title + " (" + program.channel + ")"
				elsif (i == max)
					speech = " or " + program.title + " on " + program.channel
					txt = program.title + " (" + program.channel + ")"
				else
					speech = "" + program.title + " on " + program.channel
					txt = program.title + " (" + program.channel + ")"
				end

				say txt, spoken: speech
				
				i += 1
	     		}
		else
			say "Sorry, I don't have any data." #say something to the user!
		end

    		request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  	end

	listen_for /what is (.*) about/i do |title|
		matches = @tvguide.get_programs().select { |program| program.title.upcase == title.upcase }
		
		if (matches.length > 0)
			description = matches[0].description
			
			say description, spoken: "Here's what the TV guide says about " + title + "."
		else
			say "I couldn't find the show '" + title + "'."
		end
		
		request_completed #always complete your request! Otherwise the phone will "spin" at the user!
	end
end
