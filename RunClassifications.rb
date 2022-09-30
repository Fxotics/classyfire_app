`bundle install`

require 'io/console'
require 'rest-client'
require 'json'
# require 'net/smtp'
require 'optparse'
# require 'smtp-tls.rb'

load 'lib/classyfire_api.rb'
load 'lib/send_mail.rb'

# Lycorine
# C1CN2CC3=CC4=C(C=C3[C@H]5[C@H]2C1=C[C@@H]([C@H]5O)O)OCO4
# Ran API ID: 5992036

# Clazolam
# CN1C(=O)CN2CCC3=CC=CC=C3C2C4=C1C=CC(=C4)Cl
puts "When finished, you will receive a email notification."
begin
  EMAIL_ADDRESS = ENV['GMAIL_USER'] || raise('Invalid email address')
  EMAIL_PASS = ENV['GMAIL_PASS'] || raise('Invalid password')
  DESTINATION_EMAIL = ""
rescue Exception => e
  puts "Exception encountered: #{e}"
  puts "Please provide a G-mail user authorized with SMTP authentication:"
  EMAIL_ADDRESS = STDIN.gets.chomp!
  puts "Password:"
  EMAIL_PASS = STDIN.noecho(&:gets).chomp!
  puts "Send to (leave it blank if you want to send to the same address):"
  DESTINATION_EMAIL = STDIN.gets.chomp!

  if DESTINATION_EMAIL == ''
    DESTINATION_EMAIL.replace EMAIL_ADDRESS
    puts "Will send to #{DESTINATION_EMAIL}"
    sleep 1
  end

end
  
  
module ClassyFire_Submits
# qry = ClassyFireAPI.retrieve_classification('/home/fsierra96/Documents/Uniandes/Investigation_Molecular_Libraries/Natural_Pro
#   ucts/NuBBE/nubbenp-interesting.smi','/home/fsierra96/Documents/Uniandes/Investigation_Molecular_Libraries/Natural_Products/NuBBE/NuBBE_results
#   txt')
  class HelloParser
    def self.parse(args)
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: ClassyFire API Implementation"

        opts.on('-m', '--method API METHOD', 'The API method you want to test:',
          'query: Submit a single query',
          'status: Get a query status',
          'chunks: Submit a query in chunks from a file',
          'directory: Submit queries from a directory',
          'retrieve: Retrieve a classification from an input file') do |method|
          options[:method] = method
        end

        opts.on('-i','--input INPUT','The input file/directory or SMILES/INChIKey to classify.') do |input|
          options[:input] = input
        end

        opts.on('-o','--output OUTPUT','Specify the output path to save the classification results.') do |output|
          options[:output]=output
        end
        
        # # opts.on('-t', '--times TIMES', OptionParser::OctalInteger, 'The number of times to say hello') do |times|
        # #   options[:times] = times
        # # end
      end

      begin
        opts.parse(args)
      rescue Exception => e
        puts "Exception encountered: #{e}"
        exit 1
      end

      options
    end
  end

  options = HelloParser.parse(ARGV)


  if options[:method]
    puts "Method is: #{options[:method]}"
  else
    puts "Error: Please select a method! \n ... EXITING THE APPLICATION"
    exit(1)
  end



  def ClassyFire_Submits.RetrieveClassification(input,output)

    puts "Make sure you have installed Anaconda & RDKit (or activated a virtual environment with the dependencies).\n Otherwise, you will receive an error)\n Continue? [Y/n]"
    cntinue = STDIN.gets.chomp!
    if cntinue.downcase == 'n'
      abort('Please try again when you are ready. Thank you for using this app! ')
    end
    system "python lib/TSV_smiles_converter.py -f #{input}"

    if RUBY_PLATFORM.include? 'mingw'
      input.gsub!(/\\/,File::SEPARATOR)
    end
    if output.nil?
      output = [input.split(File::SEPARATOR)[...-1], input.split(File::SEPARATOR)[-1].split('.')[0] + '_results.json'].join(File::SEPARATOR)
    else
      if RUBY_PLATFORM.include? 'mingw'
        output = output.gsub!(/\\/,File::SEPARATOR)
      end
      output += input.split(File::SEPARATOR)[-1].split('.')[0] + '_results.json'
    end

    puts "Read from #{input}"
    puts "Writing to: \n\t #{output}"
    # exit 1

    initial = Time.now
    qry = ClassyFireAPI.retrieve_classification(input,output)
    final = Time.now
    total_time = final - initial

    message = input + " Complete taking #{total_time} !!"
    begin
      SendEmail.send(message,EMAIL_ADDRESS,EMAIL_PASS,DESTINATION_EMAIL)
    rescue Exception => e
      puts "Exception encountered: #{e}"
      exit 1
    end
  end

  def ClassyFire_Submits.SubmitChunks(input,output)
    
    filename = File.basename(input,".*")
    initial = Time.now
    qry = ClassyFireAPI.submit_query_input_in_chunks(input)
    final = Time.now
    total_time = final - initial

    message = filename + " Complete after #{total_time} seconds!!"
    begin
      SendEmail.send(message,EMAIL_ADDRESS,EMAIL_PASS,DESTINATION_EMAIL)
    rescue Exception => e
      puts "Exception encountered:"
      print e
      exit 1
    end
  end

  if options[:method].eql? 'retrieve'
    ClassyFire_Submits.RetrieveClassification(options[:input],options[:output])
  elsif options[:method].eql? 'chunks'
    if options[:output].nil?
      options[:output] = ""
    end
    ClassyFire_Submits.SubmitChunks(options[:input],options[:output])
  end    

end