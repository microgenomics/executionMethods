![banner](https://raw.githubusercontent.com/microgenomics/tutorials/master/img/microgenomics.png)

#executionMethods
----------------

executionMethods Module is the second module from SEPA (Simulation, Execution, Parse and Analysis,  a multi pipe to test pathogen software detection), that take the softwares pathoscope, metaphlan, metamix, sigma and constrains, and execute them in an independent process that can be execute multiple times having parallel works (don't worry about your cores, this module have the intelligence to coordinate cpu usage). 

##Requirements

* Bash >= v4 (tested in Linux and MacOSX)
* Perl >= v5
* Pathogen detection software installed (tested on: 
	* Pathoscope v2
	* Metaphlan v2
	* Sigma v1.0.2
	* Metamix v0.2
	* Constrains v0.1.0
	* Kraken v0.10.5
	* Taxator v1.3.3
	* Centrifuge 1.0.3-beta

##Usage

	bash executionMethods.bash --cfile [config file] --rfile [readsfile] -[dboption] [databases]
	
Where:
	
* --cfile: configuration file (see below the format)
* --rfile: reads file in paired end, e.g: --rfile read.1.fa,read.2.fa
* --dboption: is the flag of some database and must be specific for the software that you use. See below for the databases flag option.

[dboption]:

* --dbPS pathoscope database folder and prefix: e.g /home/user/dbpathoscope_bt2/targetdb (bowtie2 index).
* --dbM2 metaphlan database folder and prefix: e.g /home/user/dbmarkers_bt2/targetdb (bowtie2 index).
* --dbMX metamix database folder and prefix: e.g /home/user/dbmetamix_nhi/targetdb (blast index).
* --MXnames is a file with tax id and names in format "ti | | sientific name |	" neccesary for metamix to translate results
* --dbSG: refer to folder of the database in sigma format (each fasta in a unique folder), and due to this implementation, each subfolder would be called as gi number from fasta that contain.

Additionally, depending of the case, you have to use some of this flags:

* --PSfilterdb: pathoscope filter databases prefix (use just the prefix name and make sure that filter db is in the same folder that pathoscope database (--dbPS).
* --dbmarker: is the pkl file used by metaphlan, if you don't use metaphlan, don't use this flag and if you use metaphlan, provide pkl file with full path.
* --sigmacfile: is the configuration file used by sigma, if SIGMA is in the METHODS flag (in configuration file [--cfile]) or if you don't have a sigma config file, you just give the flag --dbSG and the module do the rest.
* --csfile constrains file you can give the file to constrains or leave executionMethods create it for you based on the results for metaphlan.


##Configuration file
This file contain several parameters to steer the script, the minimal parameters are:

	# executionMethods configuration file #
	# add comments using the pound character

	CORES=3
	THREADS=20
	METHOD=PATHOSCOPE,METAPHLAN
	PATHOSCOPEHOME=/home/patriciocarlos/softwares/pathoscope
	METAPHLAN2HOME=/home/patriciocarlos/softwares/metaphlan2

	#CORES is the flag
	#METHOD contain the software results that you want parse
	
	#Note: for metamix, you don't need specify a home directory, but you must have installed.

aditionally, we provided a full configuration file for this module at the end of this README.

##Examples

	bash executionMethods.bash --cfile config.conf --rfile reads.1.fa,reads.2.fa --dbPS SEPA/DB/BowtieIndex/db_B

here we choose --dbPS flag, so in your config file PATHOSCOPE must be specify in METHODS. Also, if you want to filter the reads, pathoscope provide a function to do, so, you have to add the --PSfilterdb flag and we make the rest :D.

	bash executionMethods.bash --cfile config.conf --rfile read.1.fa,read.2.fa --dbM2 metaphlan2/db_v20/mpa_v20_m200 --dbmarker metaphlan2/db_v20/mpa_v20_m200.pkl

in this case --dbM2 refers to metaphlan database, --dbmarker the markers of database, both flags are necesary if you specify METAPHLAN in METHODS in the config file.

if you have a lot of reads, you can execute executeMethods multiple times in independent process (&), the softwares will adjust them to cores (that you specified in the config file with CORES and THREADS flag):

	for reads in $(cat read_list.txt)
	do
		bash executionMethods.bash --cfile config.conf --rfile $reads --dbPS SEPA/DB/BowtieIndex/db_B --dbM2 SEPA/DB/BowtieIndex/dbBmarkers --dbmarker SEPA/DB/BowtieIndex/dbBmarkers.pkl &
	done
	
here we executed the script on two softwares (pathoscope and metaphlan), and every loop will execute the softwares on the input read ($reads) taken from a list of reads, in parallel process.

##Output

executionMethods just move the files that are made by the softwares, next, put the same name of reads input in output files with a little difference adding pre and subfix:

* PathoScope2: pathoscope\_readname_sam.tsv
* MetaPhlan2: metaphlan\_readname.dat
* Metamix: metamix\_readname.tsv
* Sigma: sigma\_readname.gvector
* Constrains: constrains\_readname.profiles
* Kraken: kraken\_trans\_readname.kraken
* Taxator: taxator\_readname.tax
* Centrifuge: centrifuge\_readname.tsv

##Warnings
* Some extra files will generate in your HOME folder (corescontrol and proccesscontrol), don't touch this files while the programs runs, will be delete later, you can change this folder adding COORDFOLDER=your_folder in the config file.

##Full Configuration File
	METHOD=PATHOSCOPE,METAPHLAN,SIGMA,METAMIX,CONSTRAINS,KRAKEN,TAXATOR,CENTRIFUGE
	CORES=8
	THREADS=16
	PATHOSCOPEHOME=/Users/castrolab04/programs/pathoscope
	SIGMAHOME=/Users/castrolab04/programs/sigma/bin
	METAPHLAN2HOME=/Users/castrolab04/programs/metaphlan2
	CONSTRAINSHOME=/Users/castrolab04/programs/constrains
	KRAKENHOME=/Users/castrolab04/programs/kraken
	CENTRIFUGEHOME=/Users/castrolab04/programs/centrifuge
	CENTRIFUGEDB=/Users/castrolab04/SEPA/DB/CentrifugeIndex/db_B
	TAXATORHOME=/Users/castrolab04/programs/taxator-tk-1.3.3
	TAXATORTK_TAXONOMY_NCBI=/Users/castrolab04/SEPA/DB/TaxatorIndex
	BLASTHOME=/usr/local/ncbi/blast/bin
	SAMTOOLSHOME=/usr/local/bin
	BOWTIE2HOME=/usr/local/bin
	PYTHONBIN=/usr/local/bin/python	#with biopython
	MUMERPATH=/Users/castrolab04/programs/MUMmer3.23
	COORDFOLDER=/Users/castrolab04/SEPA/mycoords #some folder to put the coordination files

