require "pathname"
require "fileutils"
require "json"

class String
    def strip_control_characters()
      chars.each_with_object("") do |char, str|
        str << char unless char.ascii_only? and (char.ord < 32 or char.ord == 127)
      end
    end
   
    def strip_control_and_extended_characters()
      chars.each_with_object("") do |char, str|
        str << char if char.ascii_only? and char.ord.between?(32,126)
      end
    end
end

module CertStepper

    class Cert
      attr_accessor :email
      attr_accessor :password
      attr_accessor :profile_id
      attr_accessor :profile_name
    end



    def self.startStep
      # if ARGV.length==0 || ARGV == nil
     #      puts "error: Parameter does not match,there is not any parameter"
     #      return nil
     #    end
      

         self.logMessage("#{ARGV}\n")

         begin
           if ARGV[0].start_with? "chrome-extension:"
             finished = false
             while !finished do 
               str = self.getUserInput[1..-1]
               str =str.strip_control_characters

               self.logMessage("#{str}\n")


               self.logMessage "start parse #{str.class}\n"
               my_hash = JSON.parse str
               self.logMessage("end parse#{my_hash}\n")

               start_path = my_hash["start_path"] 
               profile_name = my_hash["profile_name"]
               if start_path 
                 self.logMessage("#start work start_path:#{start_path} : #{profile_name} \n")
                 self.startWorkByChromeExtension start_path , profile_name
                 finished = true
               end
             end
           else 
             self.parseData ARGV[0]
             self.startWork
           end

         rescue => e 
           self.logMessage e.backtrace 
         end
         

    end

    def self.startWorkByChromeExtension(root_path,profile_name)
      console_root_path = root_path.gsub /[\s]/ , "\\ "
      system("open #{console_root_path}")
      self.createDir root_path + "/#{profile_name}"
      #self.dealCertByChrome root_path , profile_name
      mobileprovision_name = "#{profile_name}.mobileprovision"
      source_file = "#{File.expand_path('~')}/Downloads/#{mobileprovision_name}" 
      dest_file = "#{root_path}/#{profile_name}/#{mobileprovision_name}"
      if File.exist? source_file
         FileUtils.mv source_file , dest_file 
      end

    end

    def self.startWork
                  
          console_root_path = @@root_path.gsub /[\s]/ , "\\ "
          open_dir ="open #{console_root_path}"
          system("open #{console_root_path}")
          puts "Apple Cert Create Stepper\n"
          @@certs.each do |cert|
             puts "----------- begin  #{cert.profile_id} Cert ----------- \n"
             self.createDir @@root_path + "/#{cert.profile_name}"
             puts "1. copy email. <press enter>"
             self.getUserInput
             self.copyToClipboard cert.email
             puts "email coppied : #{cert.email}\n"
             puts "2. copy password. <press enter>"
             self.getUserInput
             self.copyToClipboard cert.password
             puts "password coppied : #{cert.password}\n"
             puts "3.import and export cert"
             self.dealCert cert
             puts "4. copy profile name. <press enter>"
             self.getUserInput
             self.copyToClipboard cert.profile_name
             puts "name coppied : #{cert.profile_name}\n"
             puts "\n5. copy profile id. <press enter>"
             self.getUserInput
             self.copyToClipboard  cert.profile_id
             puts "id coppied : #{cert.profile_id}"
             puts "\n6. copy profile name. <press enter>"
             self.getUserInput
             self.copyToClipboard cert.profile_name
             puts "name coppied : #{cert.profile_name}\n"
             puts "\n7. move profile to destination from download. <press enter>"
             self.getUserInput
             mobileprovision_name = "#{cert.profile_name}.mobileprovision"
             source_file = "#{File.expand_path('~')}/Downloads/#{mobileprovision_name}" 
             dest_file = "#{@@root_path}/#{cert.profile_name}/#{mobileprovision_name}"
             if File.exist? source_file
               FileUtils.mv source_file , dest_file 
               puts "#{mobileprovision_name} moved\n\n"
             else 
               puts "#{mobileprovision_name} doesn't exist. Please download and move by yourself !\n\n"
             end

          end 
    end
    
    def self.parseData(start_path)
      @@certs = Array.new
      index = 0
    	file_name = start_path
      @@root_path = Pathname.new(file_name).parent.to_s
      @@file_path 
      new_cert = nil
	    file = File.open(file_name , "r")
      line_array = file.readlines
      file_content= line_array.join
      file_content = file_content.gsub /[\r]/,"\n"
      file_content.each_line do |line|
      	 cert_prop_index = index%3
         line_content = line.gsub! /[\s\n\t\r]/ ,""
         if  line_content !=nil && !line_content.empty?
            case cert_prop_index
            when 0
            	new_cert = Cert.new
            	@@certs << new_cert
            	new_cert.email = line_content.strip
            when 1
            	new_cert.password = line_content.strip
            when 2
            	new_cert.profile_id = line_content.strip
            	line_content.strip.split(".").each do |comp|
                new_cert.profile_name = comp if comp =~ /\b\w?\d+\b/ 
              end
            end
            index+=1
         end 
      end
	    file.close

    end

    def self.copyToClipboard(content)
      system  ("echo #{content} | pbcopy")
    end
   
    def self.createDir(filePath)
       Dir.mkdir filePath if !Dir.exist?  filePath
    end

    def self.getUserInput 
          begin
            return $stdin.gets
           rescue  => e
             
          end
    end

    def self.dealCert(cert)
      system "security create-keychain -P 123456"
      system "security add-trusted-cert -r unspecified -k 123456 #{File.expand_path('~')}/Downloads/ios_development.cer"
      system "security export -k 123456 -t certs -f pkcs12 -o #{@@root_path}/#{cert.profile_name}/cert.p12"
      system "security delete-keychain 123456"
    end

    def self.dealCertByChrome(root_path , profile_name)
      system "security create-keychain -P 123456"
      system "security add-trusted-cert -r unspecified -k 123456 #{File.expand_path('~')}/Downloads/ios_development.cer"
      system "security export -k 123456 -t certs -f pkcs12 -o #{root_path}/#{profile_name}/cert.p12"
      system "security delete-keychain 123456"
    end


    def self.logMessage(message)
      file = File.open("#{File.expand_path('~')}/certstepper.log", "w+")
      file.write message
      file.close
    end

end
