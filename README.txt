# ClassyFire App
An application that consumes the ClassyFire API, allows to query, retrieve and save classifications of compounds and sets of compounds.

'''
ClassyFire API access and use
-----------------------------------------------
This is an instructions manual on how to use ClassyFire API to obtain molecules' taxonomy and ontology

'''

###############################################
	Date: Mon 19 Apr 2021 12:51:53 AM -05
	Author: Felipe Sierra Hurtado
###############################################



© Created by Yannick Djoumbou and collaborators

	Djoumbou Feunang Y, Eisner R, Knox C, Chepelev L, Hastings J, Owen G, Fahy E, Steinbeck C, Subramanian S, Bolton E, Greiner R, and Wishart DS. ClassyFire: Automated Chemical Classification With A Comprehensive, Computable Taxonomy. Journal of Cheminformatics, 2016, 8:61.
	DOI: 10.1186/s13321-016-0174-y

ClassyFire application is available at: http://classyfire.wishartlab.com/

Likewise, ClassyFire API is accessible at: https://bitbucket.org/wishartlab/classyfire_api/



***********************************************
	REQUIREMENTS
		- Ruby >2.7.0 (Linux: sudo apt install ruby)
			-> gem package manager
			-> rest-client gem v 2.1.0 (Linux: sudo gem install rest-client -v 2.1.0) **this one is problematic often
				- 'gem install ffi'
				- may require to install Ruby+DevKit (MSYS2) for Windows (or standalone DevKit to add)
			-> mail gem (gem install mail)
			-> JSON gem (Linux: sudo gem install json)
		- Conda Environment
			- Python
			- RDKit

***********************************************

'''
	DATA PREPROCESSING
'''

	For better results and to avoid possible errors, open the SMILES or SDF molecules set in Mona (http://www.zbh.uni-hamburg.de/mona) 
	for duplicate removal and exporting the set to a standardized SMILES format (without headers and labels).


'''
	INSTRUCTIONS
'''

	ClassyFire API is written in Ruby and needs to be run with a Ruby console or script.

	1. Install required packages & libraries
		
		*** Be sure to create and activate a conda environment
		The programs cleans and transforms files passed to a format readable by the ClassyFire API.

			"conda activate <environment>"

	2. Download ClassyFire script (.rb) at: https://bitbucket.org/wishartlab/classyfire_api/src/master/lib/
	
	3. Open Terminal and run 'RunClassifications.rb' script on Ruby

		- "ruby RunClassifications.rb --help" for help

		3.a. RETRIEVE METHOD
			Submits queries for a file with multiple structures to classify.

			"ruby RunClassifications.rb -m retrieve -i <path_to_input_file> [optional -o <path_to_output_file>] "
