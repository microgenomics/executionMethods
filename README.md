![banner](https://raw.githubusercontent.com/microgenomics/tutorials/master/img/microgenomics.png)

#executionMethods
----------------

executionMethods Module is the second module from SEPA (Simulation, Execution, Parse and Analysis,  a multi pipe to test pathogen software detection), that take the softwares pathoscope, metaphlan, metamix, sigma and constrains, and execute them in an independent process (can be execute multiple times)

##Requirements

* Bash version 4 (comes with Linux and MacOSX)
* Pathogen detection software installed

##Usage

	bash executionMethods.bash --cfile [config file] --rfile [readsfile] -[dboption] [databases]
	
Where:
	
* --cfile: configuration file (see below the format)
* --rfile: reads file, if you have paired end reads use: --rfile readfile1,readfile2.
* --dboption: is the flag of some database and must be specific for the software that you use. See below for the databases flag option.

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

	bash executionMethods.bash --cfile config.conf --rfile reads.1.fa,reads.2.fa --dbPS /Users/castrolab01/Desktop/SEPA/DB/BowtieIndex/db_B

here we choose --dbPS flag, so in your config file PATHOSCOPE must be specify in METHODS. Also, if you want to filter the reads, pathoscope provide a function to do, so, you have to add the --PSfilterdb flag and we make the rest :D.

	bash executionMethods.bash --cfile config.conf --rfile singlereads.fa --dbM2 /Users/castrolab01/Desktop/metaphlan2/makingDBmarkers/indexedbowtie2/mpa_v20_m200 --dbmarker /Users/castrolab01/Desktop/metaphlan2/db_v20/mpa_v20_m200.pkl

in this case --dbM2 refers to metaphlan database and it is provided in full path as --dbmarker (remember that), both flags are necesary if you specify METAPHLAN in METHODS in the config file.

if you have a lot of reads, you can execute executeMethods multiple times in independent process (&), the softwares will adjust them to cores (that you specified in the config file with CORES and THREADS flag):

	for reads in `cat read_list.txt`
	do
		bash executionMethods.bash --cfile config.conf --rfile $reads --dbPS /Users/castrolab01/Desktop/SEPA/DB/BowtieIndex/db_B --dbM2 /Users/castrolab01/Desktop/metaphlan2/makingDBmarkers/indexedbowtie2/dbBmarkers --dbmarker /Users/castrolab01/Desktop/metaphlan2/test/dbBmarkers.pkl &
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
* Metamix: If you only use Metamix, ignore this warning. Some times metamix fails in last step and output file is not generated, so, this module implements a tolerance for ten execution (automatically re-runs until ten times if execution  fails, but there is not warranty that work after all runs), due to this, is not possible execute Metamix in an independent process making a query waiting if your config file is like this:

		METHOD=METAMIX,PATHOSCOPE,METAPHLAN
to solve this problem, move METAMIX to the final line, like this:
		
		METHOD=PATHOSCOPE,METAPHLAN,METAMIX
this will execute pathoscope in an independent process, next metaphlan in an independent process and finally metamix in the main process (not independent), but is the last execution so this will not generate a query waiting.
