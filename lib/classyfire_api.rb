require 'json'
require 'csv'
require 'rest-client'
# require 'openbabel'
# require 'node_resource.rb'

module ClassyFireAPI
  URL = 'http://classyfire.wishartlab.com'
  # Submits a ClassyFire query in a JSON format.
  #
  # @param label [String] the label of the query.
  # @param input [String] the input of the query.
  # @param type [String] the type of the query.
  # @return [Hash] A Ruby Hash with the id (and other attributes) of the Query or nil
  # if there is an error. Use JSON.parse to get a the json object.
  def ClassyFireAPI.submit_query(label,input, type='STRUCTURE')
    begin
      q = RestClient.post URL+'/queries', {:label => label, :query_input => input, :query_type => type}.to_json, :accept => :json, :content_type => :json
    rescue RestClient::BadRequest => e
      e.response
    rescue  RestClient::InternalServerError => e
      e.response
    rescue RestClient::GatewayTimeout => e
      e.response
    rescue RestClient::RequestTimeout => e
      e.response
    rescue RestClient::UnprocessableEntity => e
      e.response
    end
    q
  end

  # Retrieves the classification results for a given query.
  #
  # @param query_id [Integer] the ID of the query.
  # @param format [String] the format of the query (either JSON, CSV, or SDF)
  # @return [Text] A text file displaying the classification results for
  # the query's entities in the specified format.
  def ClassyFireAPI.get_query(query_id,format="json")
    begin
      if format == "json"
        RestClient.get "#{URL}/queries/#{query_id}.json", :accept => :json
      elsif format == "sdf"
        RestClient.get "#{URL}/queries/#{query_id}.sdf", :accept => :sdf
      elsif format == "csv"
        RestClient.get "#{URL}/queries/#{query_id}.csv", :accept => :csv
      end
    rescue RestClient::ResourceNotFound => e
      e.response
    rescue  RestClient::InternalServerError => e
      e.response
    rescue RestClient::GatewayTimeout => e
      e.response
    rescue RestClient::RequestTimeout => e
      e.response
    end
  end

  # Return data for the TaxNode with ID chemontid.
  #
  # @param chemontid [String] the ChemOnt ID of the entity.
  # @return [Text] A text displaying the classification results for the entity in the specified format.
  # Use JSON.parse to get a the json object.
  def ClassyFireAPI.get_chemont_node(chemontid)
    chemont_id = chemontid.to_s.gsub("CHEMONTID:","C")
    begin
      RestClient.get "#{URL}/tax_nodes/#{chemont_id}.json", :accept => :json
    rescue RestClient::ResourceNotFound => e
      e.response
    rescue  RestClient::InternalServerError => e
      e.response
    rescue RestClient::GatewayTimeout => e
      e.response
    rescue RestClient::RequestTimeout => e
      e.response
    end
  end

  # Retrieves the classification results for a given sequence.
  #
  # @param fingerprint [String] the fingerprint (generated from the sequence using Digest::MD5).
  # @param format [String] the format of the query (Only JSON)
  # @return [Text] A text displaying the classification results for the entity in the specified format.
  # Use JSON.parse to get a the json object.
   def ClassyFireAPI.get_sequence_classification(fingerprint,format="json")
    begin
      if format == "json"
        RestClient.get "#{URL}/entities/#{fingerprint}.#{format}", :accept => :json
      end
    rescue RestClient::ResourceNotFound => e
      e.response
    rescue  RestClient::InternalServerError => e
      e.response
    rescue RestClient::GatewayTimeout => e
      e.response
    rescue RestClient::RequestTimeout => e
      e.response
    end
  end

  # Retrieves the classification results for a given chemical entity.
  #
  # @param the InChIKey [String] of the entity
  # @param The format [String] the format of the query (Only JSON)
  # @return [Text] A text file displaying the classification results for the entity in the specified format.
  def ClassyFireAPI.get_entity_classification(inchikey,format="json")
    inchikey_id = inchikey.to_s.gsub('InChIKey=','')
    begin
      if format == "json"
        RestClient.get "#{URL}/entities/#{inchikey_id}.#{format}", :accept => :json
      elsif format == "sdf"
        RestClient.get "#{URL}/entities/#{inchikey_id}.#{format}", :accept => :sdf
      elsif format == "csv"
        RestClient.get "#{URL}/entities/#{inchikey_id}.#{format}", :accept => :csv
      end
    rescue RestClient::ResourceNotFound => e
      e.response
    rescue  RestClient::InternalServerError => e
      e.response
    rescue RestClient::GatewayTimeout => e
      e.response
    rescue RestClient::RequestTimeout => e
      e.response
    end
  end


  # Retrieves the status of a query
  # @param query_id [Integer] the ID of the query
  # @return [String] the query status, 'Done' or 'In progress', 'string'
  def ClassyFireAPI.query_status(query_id)
    begin
      RestClient.get "#{URL}/queries/#{query_id}/status.json", :accept => :json
    rescue Exception=>e
      $stderr.puts e.message
      nil
    end
  end

  # Takes a tab-separated file and submit the contained structures in bulks of a given size
  #
  # For 'STRUCTURE' or 'IUPAC_NAME'query types, each line must contain either
  #   1) Only a structural represenation: SMILES, InChI for the 'STRUCTURE' query_type or a IUPAC name
  #     for the 'IUPAC NAME' query type.
  #   2) a tab-separated pair of an ID and the corresponding sructure representation: SMILES, InChI for the
  #     'STRUCTURE' query_type or a IUPAC name for the 'IUPAC NAME' query type.
  #
  # For 'FASTA' query type, just submit the query as a standard FASTA text.
  # @param input_file [Text] The path to the input file.
  # @param: slice_length [Integer] The maximum number of entries for each query input (the whole file
  # is fragmented into n part of #slice_length entries each).
  # @param: start [Integer] The starting index. Submit framgments from the index 'start'.
  def ClassyFireAPI.submit_query_input_in_chunks(input_file,slice_length=10, start=1, type='STRUCTURE')
    @start_time = Time.now
    absolute_path = File.expand_path(input_file)
    f             = File.open(absolute_path, 'r')
    input         = []

#######################################################################################################################################
#######################################################################################################################################    
############################# MY MODIFICATION ATT. FXOTICS ############################################################################
#######################################################################################################################################
f_name = File.basename(input_file,'.*')
dir = File.split(absolute_path)[0]
output = dir + "/" + f_name + '_IDs.csv'
logsfile = dir + "/" + f_name + 'logs.txt'
File.open(logsfile,"w") {|f| f.write "Time\tErrorMessage\tGroup\tSMILES\n"}
#######################################################################################################################################
#######################################################################################################################################

    lines = File.readlines(absolute_path)

    i = 0
    lines.uniq.each do |line|
      i += 1
      # sline = line.strip.split("\t")
      sline = line.strip.split
      if sline.length == 1
        input <<"#{sline[0]}"
      elsif sline.length >= 2
        #ID\tSMILES (OR INCHI, OR VALID IUPAC NAME)
        input <<"#{sline[0]}\t#{sline[1]}"
      end
      # input <<"#{sline[0]}"
    end
    # puts "=============",input.length, input[0]
    query_ids = []
    
#######################################################################################################################################
#######################################################################################################################################    
############################# MY MODIFICATION ATT. FXOTICS ############################################################################
#######################################################################################################################################
    pos = 0
#######################################################################################################################################
#######################################################################################################################################    
    
    
    subdivised_groups = input.uniq.each_slice(slice_length).to_a
    puts "nr of subdivised_groups: #{subdivised_groups.length}"
    # puts subdivised_groups[0]
    sleeping_time = 30
    initial_nr_of_jobs = 2
    i = start

    if i < initial_nr_of_jobs
      while i <=  initial_nr_of_jobs

        title = File.basename(absolute_path).split(".")[0] + "_part_#{i}"

        if i <= subdivised_groups.length
          puts "\n---------------------------------"
          begin
            puts "submitting #{title}"
            # puts subdivised_groups[i-1].join("\n")
            q       = submit_query(title,subdivised_groups[i-1].join("\n"),type)
            puts "Query ID: " + JSON.parse(q)['id'].to_s
            query_ids << JSON.parse(q)['id']
#######################################################################################################################################
#######################################################################################################################################    
############################# MY MODIFICATION ATT. FXOTICS ############################################################################
#######################################################################################################################################
            sleep(10)
          rescue Exception => e
            File.open(logsfile,'a') do |file|
              file.write "#{Time.now}\t#{e}\t#{title}\t#{subdivised_groups[i-1].join(",")}\n"
#######################################################################################################################################
#######################################################################################################################################
            end
            puts e.message
            puts e.backtrace.inspect
          end
          i = i + 1
        else
          break
        end
      end
      puts "Going to sleep at #{Time.now - @start_time} for #{sleeping_time} s."
      sleep(sleeping_time)
      puts "Waking up at #{Time.now - @start_time}"
      
#######################################################################################################################################
#######################################################################################################################################    
############################# MY MODIFICATION ATT. FXOTICS ############################################################################
#######################################################################################################################################      
      File.open(output, 'w+') do |f_output|
        f_output.write query_ids.slice(pos,query_ids.length()).join(',')+','
      end
      pos = query_ids.length()
#######################################################################################################################################
#######################################################################################################################################    

    end

    while i >= initial_nr_of_jobs && i < subdivised_groups.length
      k = 0
      for k in (i...(i + initial_nr_of_jobs))
        title     = File.basename(absolute_path).split(".")[0] + "_part_#{k}"
        begin
          puts "submitting #{title}"
          q = submit_query(title,subdivised_groups[k-1].join("\n"),type)
          puts "Query ID: " + JSON.parse(q)['id'].to_s
          query_ids << JSON.parse(q)['id']
          sleep(10)
        rescue Exception => e
          File.open(logsfile,'a') do |file|
            file.write "#{Time.now}\t#{e}\t#{title}\t#{subdivised_groups[i-1].join(",")}\n"
          end
          puts e.message
          puts e.backtrace.inspect
        end
        i = i + 1
      end
      if i >= initial_nr_of_jobs && i < subdivised_groups.length
        puts "Going to sleep at #{Time.now - @start_time} for #{sleeping_time} s."
        sleep(sleeping_time)
        puts "Waking up at #{Time.now - @start_time}"
#######################################################################################################################################
#######################################################################################################################################    
############################# MY MODIFICATION ATT. FXOTICS ############################################################################
#######################################################################################################################################      
        File.open(output, 'a') do |f_output|
          f_output.write query_ids.slice(pos,query_ids.length()).join(',')+','
        end
        pos = query_ids.length()
#######################################################################################################################################
#######################################################################################################################################    

      end
    end

    puts "Done at #{Time.now - @start_time}"
  end

  # Takes each file in a folder, and submit the contained structures in bluks of a given size.
  #
  # For 'STRUCTURE' or 'IUPAC_NAME'query types, each line must contain either
  #   1) Only a structural represenation: SMILES, InChI for the 'STRUCTURE' query_type or a IUPAC name
  #     for the 'IUPAC NAME' query type.
  #   2) a tab-separated pair of an ID and the corresponding sructure representation: SMILES, InChI for the
  #     'STRUCTURE' query_type or a IUPAC name for the 'IUPAC NAME' query type.
  #
  # For 'FASTA' query type, just submit the query as a standard FASTA text.
  # @param: input_file [String] The path to the folder.
  # @param: slice_length [Integer] The maximum number of entries for each query input (each file
  # is fragmented into n part of #slice_length entries each), 'integer'
  # @param type [String] the query_type 'STRUCTURE' (default) or 'IUPAC_NAME' or 'FASTA'
  def ClassyFireAPI.submit_queries_from_directory(folder,slice_length,type="STRUCTURE")
    if File.directory?(folder)
      Dir.foreach(folder) do |filename|
        puts "Filename: #{filename}"
        ClassyFireAPI.submit_query_input_in_chunks(folder+"/"+filename,slice_length, type) unless filename[0] == "." || File.directory?(filenmae)
      end
    else
      $stderr.puts "#{folder} is not a folder."
    end
  end


  # Reads a tab separated file, and use the structure representation
  #to retrieve the strutcure's classification from ClassyFire.
  #
  # @param input [String] path to the input file.
  # @return [String] path to the output file.
  def ClassyFireAPI.retrieve_classification(input,output)
    absolute_path = File.expand_path(input)
    f_input       = File.open(absolute_path, 'r')
    h             = Hash.new
    directory     = absolute_path.split('/')[0...-1].join("/")
    f_output      = File.new(output, 'w')
    res = String.new


    res += "{"
    res += '"id": 1,'
    res += '"label":"' + output + '",' + '"classification_status":"Done",' + '"entities":['

    f_input.each_line do |line|
      sline = line.strip.split("\t")
      if sline.length == 1
        h[sline[0]] = sline[0]
      elsif sline.length == 2
        h[sline[0]]  = sline[1]#line.strip                       ### MY MODIFICATION ATT. FXOTICS
      end
    end

    puts h.keys.uniq.length
    if h.keys.length > 0
      i = 1
      h.keys.uniq[0..-1].each do |key|
        puts i

        puts "#{key} :: #{h[key]}"
        begin
          qs = submit_query(key,h[key])
      	  sleep(5) 																				### MY MODIFICATION ATT. FXOTICS

          qs_decoded = JSON.parse(qs)
          qr = JSON.parse(get_query(qs_decoded["id"],format="json"))

          res += qr["entities"][0].to_json
          res += ","
          i += 1
        rescue Exception => e
          e.message
        end

      end
      key = h.keys[-1]
      puts "#{key} :: #{h[key]}"
      begin
        qs = submit_query(key,h[key])
        sleep(0.2)
        qs_decoded = JSON.parse(qs)
        qr = JSON.parse(get_query(qs_decoded["id"],format="json"))
        # puts qr["entities"]
        # sleep(0.2)
        # f_output.print qr["entities"][0],"\n"
        res += qr["entities"][0].to_json
        # res += ","
      rescue Exception => e
        e.message
      end
    end
    res += "]}"
    f_output.print res
  end

  # Reads a tab separated file, and use the structure representation
  # to retrieve the strutcure's classification from ClassyFire in a JSON format.
  #
  # @param input [String] path to the input file
  # @return [String] path to the output file
  def ClassyFireAPI.retrieve_entities_json(input,output)
    absolute_path = File.expand_path(input)
    f_input       = File.open(absolute_path, 'r')
    h             = Hash.new
    directory     = absolute_path.split('/')[0...-1].join("/")
    f_output      = File.new(output, 'w')
    puts
    res = String.new

    res += "{"
    res += '"id": 1,'
    res += '"label":"' + output + '",' + '"classification_status":"Done",' + '"entities":['

    f_input.each_line do |line|
      sline = line.strip.split("\t")
      h[sline[0]]  = sline[-1]
    end

    puts h.keys.uniq.length
    if h.keys.length > 0
      i = 1
      h.keys.uniq[0...-1].each do |key|
        puts i
        # puts "#{key} :: #{h[key]}"
        begin
          inchikey = %x(obabel -:"#{h[key]}" -oinchikey).strip.split("\t")[0]
          # puts inchikey
          qr = JSON.parse(ClassyFireAPI.get_entity_classification(inchikey,format="json"))
          qr['identifier'] = key
          res += qr.to_json
          res += ","
          puts "#{key} :: RETURN NIL" if qr.nil? || qr['direct_parent']['name'].nil?
        rescue Exception => e
          e.message
        end
        i += 1
      end
      key = h.keys[-1]
      # puts "#{key} :: #{h[key]}"
      begin
        inchikey = %x(obabel -:"#{h[key]}" -oinchikey).strip.split("\t")[0]
        # puts inchikey
        qr = JSON.parse(ClassyFireAPI.get_entity_classification(inchikey,format="json"))
        qr['identifier'] = key
        res += qr.to_json
        puts "#{key} :: RETURN NIL" if qr.nil? || qr['direct_parent']['name'].nil?
        # res += ","
      rescue Exception => e
        e.message
      end
    end
    res += "]}"
    f_output.print res
  end



  # Reads a tab separated file, and use the structure representation
  # to retrieve the strutcure's classification from ClassyFire in a SDF format.
  #
  # @param input [String] path to the input file
  # @return [String] path to the output file
  def ClassyFireAPI.retrieve_entities_sdf(input,output)
    absolute_path = File.expand_path(input)
    f_input       = File.open(absolute_path, 'r')
    h             = Hash.new
    directory     = absolute_path.split('/')[0...-1].join("/")
    f_output      = File.new(output, 'w')
    res = String.new

    f_input.each_line do |line|
      sline = line.strip.split("\t")
      h[sline[0]]  = sline[-1]
    end

    puts h.keys.uniq.length
    if h.keys.length > 0
      i = 1
      h.keys.uniq[0...-1].each do |key|
        puts i
        # puts "#{key} :: #{h[key]}"
        begin
          inchikey = %x(obabel -:"#{h[key]}" -oinchikey).strip.split("\t")[0]
          # puts inchikey
          qr = ClassyFireAPI.get_entity_classification(inchikey,format="sdf")
          if qr.include?("The page you were looking for doesn't exist")
            puts "The page you were looking for doesn't exist"
          elsif qr.empty?

          else
            input = qr.split("\n")[1..-1].join("\n")
            puts input
            f_output.puts "#{key}\n"
            f_output.puts input
          end
        rescue Exception => e
          e.message
        end
        i += 1
      end
      key = h.keys[-1]
      begin
        inchikey = %x(obabel -:"#{h[key]}" -oinchikey).strip.split("\t")[0]
        # puts inchikey
        qr = ClassyFireAPI.get_entity_classification(inchikey,format="sdf")
        if qr.include?("The page you were looking for doesn't exist")
          puts "The page you were looking for doesn't exist"
        elsif qr.empty?

        else
          input = qr.split("\n")[1..-1].join("\n")
          puts input
          f_output.puts "#{key}\n"
          f_output.puts input
        end
      rescue Exception => e
        e.message
      end
    end
  end
end

if __FILE__ == $0

end
