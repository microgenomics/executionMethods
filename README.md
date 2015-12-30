![banner](https://raw.githubusercontent.com/microgenomics/tutorials/master/img/microgenomics.png)

#executionMethods
----------------

executionMethods Module is the second module from SEPA (Simulation, Execution, Parse and Analysis,  a multi pipe to test pathogen software detection), that take the softwares pathoscope, metaphlan, metamix, sigma and constrains, and execute them in an independent process (can be execute multiple times)

##Requirements

* Bash version 4 (comes with Linux and MacOSX)

##Usage
executeMethods can be executed in two cases, one if this module is executed by previous SEPA module (Simulation module), or two, using local flag:

	bash executionMethods.bash --cfile [config file] --rfile [readsfile] -[dboption] [databases] --local
	
Where:
	
* --cfile: configuration file (see below the format)
* --rfile: reads file, if you have paired end reads use: --rfile readfile1,readfile2.
* --dboption: is the flag of some database and must be specific for the software that you use. See below for the databases flag option.
* --local: this flag is to make all works in your local folder, if you use this module separately from SEPA modules, use this flag.

[dboption]:

* --dbPS pathoscope database folder and prefix: e.g /home/user/dbpathoscope_bt2/targetdb (bowtie2 index).
* --dbM2 metaphlan database folder and prefix: e.g /home/user/dbmarkers_bt2/targetdb (bowtie2 index).
* --dbMX metamix database folder and prefix: e.g /home/user/dbmetamix_nhi/targetdb (blast index).
* --dbCS constrains database folder.

#####Note: you must provide sigma database folder in the sigma configuration file.

Additionally, depending of the case, you have to use some of this flags:

* --PSfilterdb: pathoscope filter databases prefix (use just the prefix name and make sure that filter db is in the same folder that pathoscope database (--dbPS).
* --dbmarker: is the pkl file used by metaphlan, if you don't use metaphlan, don't use this flag and if you use metaphlan, provide pkl file with full path.
* --sigmacfile: is the configuration file used by sigma, if SIGMA is in the METHODS flag (in configuration file [cfile]), you must provide the full path to sigma configuration file.

##Configuration file
This file contain several parameters to steer the script (most of them just serves in no local mode), the minimal parameters are:

	# executionMethods configuration file #
	# add comments using the pound character

	CORES=3
	THREADS=20
	ABSENT=no
	METHOD=PATHOSCOPE,METAPHLAN
	PATHOSCOPEHOME=/Users/castrolab01/pathoscope
	METAPHLAN2HOME=/Users/castrolab01/Desktop/metaphlan2

	#ABSENT is a flag used to specify whether you are using a database where you know a target microbe is present or not. Default is no.
	#if flag is set to "yes", then you need to specify a NCBI's taxonomy ID for the taxon that is kept constant using tipermanent
	#tipermanent=478435
	#ABUNDANCE specify how many reads mapped or should map to the database. This flag will convert raw read counts to proportions
	#ABUNDANCE=100000
	#METHOD contain the software results that you want parse

##Examples

	bash executionMethods.bash --cfile config.conf --rfile reads.1.fa,reads.2.fa --dbPS /Users/castrolab01/Desktop/SEPA/DB/BowtieIndex/db_B --local

here we choose --dbPS flag, so in your config file PATHOSCOPE must be specify in METHODS. Also, if you want to filter the reads, pathoscope provide a function to do, so, you have to add the --PSfilterdb flag and we make the rest :D.

	bash executionMethods.bash --cfile config.conf --rfile singlereads.fa --dbM2 /Users/castrolab01/Desktop/metaphlan2/makingDBmarkers/indexedbowtie2/mpa_v20_m200 --local --dbmarker /Users/castrolab01/Desktop/metaphlan2/db_v20/mpa_v20_m200.pkl

in this case --dbM2 refers to metaphlan database and it is provided in full path as --dbmarker (remember that), both flags are necesary if you specify METAPHLAN in METHODS in the config file.

if you have a lot of reads, you can execute executeMethods multiple times in independent process (&), the softwares will adjust them to cores (that you specified in the config file with CORES and THREADS flag):

	for reads in `cat read_list.txt`
	do
		bash executionMethods.bash --cfile config.conf --rfile $reads --dbPS /Users/castrolab01/Desktop/SEPA/DB/BowtieIndex/db_B --dbM2 /Users/castrolab01/Desktop/metaphlan2/makingDBmarkers/indexedbowtie2/dbBmarkers --dbmarker /Users/castrolab01/Desktop/metaphlan2/test/dbBmarkers.pkl --local &
	done
	
here we executed the script on two softwares (pathoscope and metaphlan), and every loop will execute the software on the input read ($reads) taken from a list of reads.

##Output

executionMethods just move the files that are made by the softwares, executionMethods put the same name of reads input in output files with a little difference adding pre and subfix:

* Pathoscope: pathoscope\_readname_sam.tsv
* Metaphlan: metaphlan\_readname.dat
* Metamix: metamix\_readname.tsv
* Sigma: sigma_out.gvector
* Constrains: not aviable yet

##Warnings
* Be careful with sigma, this software doesn't provide some flag to differentiate the output files, so, try to don't execute executionMethods multi times, if sigma is in METHODS. Instead, you can tell to sigma use all cores aviables, then change the name files when sigma finish the align, and finally re-run sigma with new inputs, everything in a loop. something like this:
	
		for reads in `cat read_list.txt`
		do
			bash executionMethods.bash --cfile config.conf --rfile $reads --sigmacfile sigma_config.cfg --local
			mv sigma_out.gvector.txt sigma_$reads.txt #to make the difference where the out belongs
		done
* This is a first version, it's possible that you have an error in some part (or a lot of them, we apologize for that) and the script will continue improve self.