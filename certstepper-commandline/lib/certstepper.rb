require "pathname"
require "fileutils"
require "json"
require "cert"
require "sigh"
require 'optparse'
require 'colorize'
require 'openssl'

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
     #    if ARGV.length==0 || ARGV == nil
     #      puts "error: Parameter does not match,there is not any parameter"
     #      return nil
     #    end
      
         #self.logMessage("#{ARGV}\n")


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

            check_xcode_select = `which xcode-select`.strip
            if !File.exists? check_xcode_select
              `xcode-select --install`
            end


             @options = {}
             option_parser = OptionParser.new do |opts|
               opts.banner = "certstepper File_Path [Options]命令行生成证书和配置文件!\n文件的内容：三行一个循环,依次是开发者账号、密码、唯一标识(bundle identifier)"
               @options[:cert_type] = ""
               @options[:profile_type] = "--adhoc" 
               @options[:force] = false

               opts.on('-t cert_type','--type cert_type','生成证书和配置文件的类型 development adhoc distribution') do |value|
                 if value.start_with? 'ad' 
                   @options[:cert_type] = "--adhoc"
                   @options[:profile_type] = "" 
                 elsif value.start_with? 'dev' 
                   @options[:cert_type] = "--development"
                   @options[:profile_type] = "--development" 
                 elsif value.start_with? 'dis'
                   @options[:cert_type] = ""
                   @options[:profile_type] = "" 
                 end
               end

              opts.on('-f', '--force', '强制重新获取证书,默认生成成功后不再重新获取') do 
                @options[:force] = true
              end
             end.parse!

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
          puts "总共要生成#{@@certs.length}个证书" 
          console_root_path = @@root_path.gsub /[\s]/ , "\\ "
          open_dir ="open #{console_root_path}"
          system("open #{console_root_path}")
          puts "Apple Cert Create Stepper\n"

          @@base_dir = "#{Dir.home}/Library/CertStepper"
          if !Dir.exist? @@base_dir
            Dir.mkdir @@base_dir 
          end

          failed_cert_array = []

          @@certs.each do |cert|
             puts "----------- begin  #{cert.profile_id} Cert ----------- \n"
              
             if !generateCertSuccessfully?(cert) || @options[:force] 
                  
               cert_path = @@base_dir + "/#{cert.profile_name}"
               final_path = console_root_path + "/#{cert.profile_name}"
               createDir final_path
               if !Dir.exist?  cert_path
                 Dir.mkdir cert_path 
               end

               keychain_entry = CredentialsManager::AccountManager.new(user:cert.email , password: cert.password)
               keychain_entry.add_to_keychain

    
               #createKeychain cert
               system "cert -u #{cert.email} -o #{cert_path}  #{@options[:cert_type]}"
               dealCert cert , cert_path , final_path
                

               system "produce -u #{cert.email} -a #{cert.profile_id} --app_name #{cert.profile_name} --skip_itc"
               system "sigh -a #{cert.profile_id} -u #{cert.email} -o #{final_path} #{@options[:profile_type]} -z"
               #system "sigh -a #{cert.profile_id} -u #{cert.email} -o #{cert_path} --adhoc"
               
               
               if !generateCertSuccessfully? cert
                 failed_cert_array << cert.email
               end

               deleteUnusefulFile cert_path

            end 

            
            if failed_cert_array.length > 0 
              failed_content = "以下账号的证书和配置文件创建失败:\n" + failed_cert_array.join("\n") + "请重新尝试执行命令，如果多次不成功，请检查账号密码的正确性!"
              puts failed_content.colorize(:red) 
            else
              puts "证书和配置文件全部创建成功!".colorize(:green)
            end

          end 

    end

    def self.deleteUnusefulFile(de_path)
      console_de_path = de_path.gsub /[\s]/ , "\\ "
      Dir.entries(de_path).each do |file_name|
        if file_name.end_with? '.pem' 
          file_path = "#{de_path}/#{file_name}"
          system "rm #{console_de_path}/#{file_name}" 
        end 
      end

    end

    def self.generateCertSuccessfully?(cert)
      cert_path = @@root_path + "/#{cert.profile_name}"
      is_p12_exist = false 
      is_provision_exist = false 
      if File.exists? cert_path 
        Dir.entries(cert_path).each do |file_name| 
          if file_name.end_with? ".p12"
            is_p12_exist = true
          elsif file_name.end_with? ".mobileprovision"
            is_provision_exist = true
          end
        end
      end 


      return is_p12_exist  && is_provision_exist
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
         line_content = line.gsub /[\s\n\t\r]/ ,""

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
              new_cert.profile_name = line_content
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
       if !Dir.exist?  filePath
         Dir.mkdir filePath 
       else 
         FileUtils.rm_r filePath
         Dir.mkdir filePath 
       end
    end

    def self.getUserInput 
          begin
            return $stdin.gets
           rescue  => e
             
          end
    end

    def self.createKeychain(cert)

      @@base_dir = "#{Dir.home}/Library/CertStepper"
      if !Dir.exist? @@base_dir
        Dir.mkdir @@base_dir 
      end
      @keychain_path = File.expand_path "#{@@base_dir}/#{cert.email}#{@options[:cert_type]}"
      if !Dir.exist? @keychain_path
        system "security create-keychain -p '' #{@keychain_path}"
      end
    end

    def self.dealCert(cert,de_path,final_path)
      console_de_path = de_path.gsub /[\s]/ , "\\ "
      console_final_path = final_path.gsub /[\s]/ , "\\ "
      Dir.entries(de_path).each do |file_name|
        if file_name.end_with? '.cer' 
          #system "security add-trusted-cert -r unspecified -k 123456 #{File.expand_path('~')}/Downloads/ios_development.cer"
          #system "security import #{console_de_path}/#{file_name} -k #{@keychain_path} -T `which codesign`"
          #system "security export -k #{@keychain_path} -t certs -f pkcs12 -P 123 -o #{console_de_path}/#{cert.profile_name}.p12"
          #system "security delete-keychain #{@keychain_path}"
          
          cert_name = File.basename(file_name,File.extname(file_name))


          cert_pem = "#{console_de_path}/#{cert_name}CERT.pem"
          key_pem = "#{console_de_path}/#{cert_name}.p12"
          merge_pem = "#{console_de_path}/#{cert_name}MER.pem"

          system "openssl x509 -in #{console_de_path}/#{file_name} -inform der -out #{cert_pem}"
          system "cat #{cert_pem} #{key_pem} > #{merge_pem}"
          system "openssl pkcs12 -export -in #{merge_pem} -out #{console_final_path}/#{cert.profile_name}.p12 -passout pass:123"

        end 
      end
    end


    def self.dealCertByChrome(root_path , profile_name)
      system "security create-keychain -P 123456"
      system "security add-trusted-cert -r unspecified -k 123456 #{File.expand_path('~')}/Downloads/ios_development.cer"
      system "security export -k 123456 -t certs -f pkcs12 -o #{root_path}/#{profile_name}/cert.p12"
      #system "security delete-keychain 123456"
    end


    def self.logMessage(message)
      puts message
      #file = File.open("#{File.expand_path('~')}/certstepper.log", "w+")
      #file.write message
      #file.close
    end

end
