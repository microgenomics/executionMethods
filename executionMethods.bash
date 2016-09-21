#make sure you have installed correctly the patogen detection software 
if [[ "$@" =~ "--debug" ]]; then
	set -ex
else
	set -e
fi

invalidband=1
cfileband=0
statusband=0
rfileband=0
dbpsband=0
dbm2band=0
dbmxband=0
mxnamesband=0
psfilterdb=0
dbmarkerband=0
sigmacfileband=0
csfileband=0
dbsgband=0
dbkrband=0
dbtaxatorband=0
priorband=0
PSFDB=""
TOCLEAN=""
SIGMACFILE=""
TMPNAME="TMP_FOLDER"

INITIALPATH=`pwd`

for i in "$@"
do
	case $i in
	"--cfile")
		cfileband=1
		invalidband=0
	;;
	"--rfile")
		rfileband=1
		invalidband=0
	;;
	"--dbPS")
		dbpsband=1
		invalidband=0
	;;
	"--PSfilterdb")
		psfilterdb=1
		invalidband=0
	;;
	"--dbM2")
		dbm2band=1
		invalidband=0
	;;
	"--dbmarker")
		dbmarkerband=1
		invalidband=0
	;;
	"--dbMX")
		dbmxband=1
		invalidband=0
	;;
	"--MXnames")
		mxnamesband=1
		invalidband=0
	;;
	"--sigmacfile")
		sigmacfileband=1
		invalidband=0
	;;
	"--dbSG")
		dbsgband=1
		invalidband=0
	;;
	"--dbKR")
		dbkrband=1
		invalidband=0
	;;
	"--dbTX")
		dbtaxatorband=0
		invalidband=0
	;;
	"--csfile")
		csfileband=1
		invalidband=0
	;;
	"--tprior")
		priorband=1
		invalidband=0
	;;
	"--help")
	invalidband=0
		echo "#########################################################################################"
		echo -e "\nUsage: bash executionMethods --cfile [config file] --rfile [readsfile] -[DB options] [databases]"
		echo -e "\nOptions aviable:"
		echo "--cfile configuration file check README for more information"
		echo "--rfile reads file, if you have paired end reads, use: --rfile readfile1.fa,readfile2.fa"
		
		echo "--PSfilterdb pathoscope filter databases prefix"
		echo "--dbmarker is the pkl file used by metaphlan, if you don't use metaphlan, don't use this flag (full path)"
		echo "--sigmacfile is the configuration file used by sigma, if in your cfile, SIGMA is in the METHODS flag, you must provide the sigmacfile"
		echo "--tprior thetaPrior option of pathoscope"
		
		echo -e "\nDB options:"
		echo "--dbPS pathoscope database folder and prefix: e.g /home/user/dbpathoscope_bt2/targetdb (bowtie2 index)"
		echo "--dbM2 metaphlan database folder and prefix: e.g /home/user/dbmarkers_bt2/targetdb (bowtie2 index)"
		echo "--dbMX metamix database folder and prefix: e.g /home/user/dbmetamix_nhi/targetdb (blast index)"
		echo "--MXnames metamix names translation, is a file with format 'ti name'"
		echo "--dbSG sigma database folder (master directory)"
		echo "--dbCS constrains database folder"
		echo "--dbKR kraken database folder"
		echo "note: you must provide sigma database folder in the sigma config file"
		echo -e "\n#########################################################################################"
		exit
	;;
	*)
		
		if [ $((cfileband)) -eq 1 ];then

			if ! [ -f $i ];then
				echo "$i file no exist"
				exit
			fi

			for parameter in `awk '{print}' $i`
			do
				Pname=`echo "$parameter" |awk 'BEGIN{FS="="}{print $1}'`		
				case $Pname in
					"METHOD")
						METHOD=$(echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g")			
					;;
					"CORES")
						CORES=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"THREADS")
						THREADS=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"PATHOSCOPEHOME")
						PATHOSCOPEHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"SIGMAHOME")
						SIGMAHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"BLASTHOME")
						BLASTHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"METAPHLAN2HOME")
						METAPHLAN2HOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`				
					;;
					"CONSTRAINSHOME")
						CONSTRAINSHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"SAMTOOLSHOME")
						SAMTOOLSHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;
					"BOWTIE2HOME")
						BOWTIE2HOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;
					"KRAKENHOME")
						KRAKENHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;
					"TAXATORHOME")
						TAXATORHOME=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;
					"TAXATORTK_TAXONOMY_NCBI")
						TAXATORTK_TAXONOMY_NCBI=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;
					"COORDFOLDER")
						COORDFOLDER=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;				
				esac
			done
			if [ "$COORDFOLDER" == "" ];then
				COORDFOLDER=$HOME
			fi
			statusband=$((statusband+1))
			cfileband=0
		fi
		
		if [ $((rfileband)) -eq 1 ]; then
			#first, we check if exist the pair end call.
			IRFILE=$i
			rfileband=0
			READS=`echo "$i" |awk 'BEGIN{FS=","}{if($2 == ""){print "single"}else{print "paired"}}'`
		fi
		
		if [ $((dbpsband)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBPS=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				PSIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $PSIXDIR
				#dbpath=`pwd`
				#DBPS=`echo "$dbpath/$DBPS"` #pathoscope use directory and name separately
				dbpsband=0
				statusband=$((statusband+1))
				cd $INITIALPATH

			else
					echo "$i file no exist"
					exit
			fi
		fi
		
		if [ $((dbm2band)) -eq 1 ]; then
				if [ ! -f $METAPHLAN2HOME/metaphlan2.py ]; then
					echo "metaphlan2.py no exist in $METAPHLAN2HOME"
					exit
				fi	
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBM2=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				M2IXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $M2IXDIR
				dbpath=`pwd`
				DBM2=`echo "$dbpath/$DBM2"`
				dbm2band=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbmxband)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBMX=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				MXIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $MXIXDIR
				dbpath=`pwd`
				DBMX=`echo "$dbpath/$DBMX"`
				dbmxband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((mxnamesband)) -eq 1 ]; then
			if [ -f "$i" ]; then
				MXNAMES=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				MXNIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $MXNIXDIR
				dbpath=`pwd`
				MXNAMES=`echo "$dbpath/$MXNAMES"`
				mxnamesband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((psfilterdb)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				PSFDB=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				PSFIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $PSFIXDIR
				dbpath=`pwd`
				PSFDB=`echo "$dbpath/$PSFDB"`
				psfilterdb=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbmarkerband)) -eq 1 ]; then
			if [ -f $i ]; then
				DBMARKER=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				M2MIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $M2MIXDIR
				dbpath=`pwd`
				DBMARKER=`echo "$dbpath/$DBMARKER"`
				dbmarkerband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi
		
		if [ $((sigmacfileband)) -eq 1 ]; then
			if [ -f $i ]; then
				SIGMACFILE=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				SGIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $SGIXDIR
				dbpath=`pwd`
				SIGMACFILE=`echo "$dbpath/$SIGMACFILE"`
				sigmacfileband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi

		fi

		if [ $((dbsgband)) -eq 1 ]; then
			if [ -d $i ]; then
				cd $i
				DBSG=`pwd`
				dbsgband=0
				cd $INITIALPATH

			else
				echo "$i master directory no exist"
				exit
			fi

		fi

		if [ $((csfileband)) -eq 1 ]; then
			if [ -f $i ]; then
				CSFILE=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				CSIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $CSIXDIR
				dbpath=`pwd`
				CSFILE=`echo "$dbpath/$CSFILE"`
				csfileband=1
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((dbtaxatorband)) -eq 1 ]; then
			ok=`ls -1 "$i"* |wc -l |awk '{print $1}'`
			if [ $((ok)) -ge 1 ]; then
				DBTX=`echo "$i" |rev |cut -d "/" -f 1 |rev`
				TXIXDIR=`echo "$i" |rev |cut -d "/" -f 2- |rev`
				cd $TXIXDIR
				dbpath=`pwd`
				DBTX=`echo "$dbpath/$DBTX"`
				dbtaxatorband=0
				cd $INITIALPATH

			else
				echo "$i file no exist"
				exit
			fi
		fi

		if [ $((priorband)) -eq 1 ]; then
				PRIOR=$i
				priorband=0

		fi

		if [ $((invalidband)) -eq 1 ]; then
			echo "some of your parameters are invalid"
			exit
		else
			invalid=1
		fi


		if [ $((dbkrband)) -eq 1 ]; then
			dbkrband=0
			if [ -d $i ]; then
				cd $i
				DBKR=`pwd`
				cd $INITIALPATH
			else
				echo "$i file no exist"
				exit
			fi
		fi

	;;
	esac
done

#################################################
declare pids
pindex=0
maxexe=$CORES
#################################################
lastpid=0

function coresControlFunction {

	request=$1
	if mkdir $COORDFOLDER/lockfolder_donttouch > /dev/null 2>&1; then
		if [ -f $COORDFOLDER/corescontrol ]; then
			i=`tail -n1 $COORDFOLDER/corescontrol`
		else
			touch $COORDFOLDER/corescontrol
			i=0
		fi

		if [ -f $COORDFOLDER/proccesscontrol ];then
			firstproc=`head -n1 $COORDFOLDER/proccesscontrol |awk '{print $1}'`
			firstcore=`head -n1 $COORDFOLDER/proccesscontrol |awk '{print $2}'`
		else
			firstproc="foo_proccess_foo"
			touch $COORDFOLDER/proccesscontrol
		fi

		if [ $((i)) -ge $((maxexe)) ]; then

			while [[ ( -d /proc/$firstproc ) && ( -z "grep zombie /proc/$firstproc/status" ) ]]; do
				#echo "waiting for proccess $firstproc"
 		          sleep 61
 		      done
 		      
 		      sed "1d" $COORDFOLDER/proccesscontrol >toreplace
 		      rm $COORDFOLDER/proccesscontrol
 		      mv toreplace $COORDFOLDER/proccesscontrol

 		      sed "1d" $COORDFOLDER/corescontrol >toreplace
 		      rm $COORDFOLDER/corescontrol
 		      mv toreplace $COORDFOLDER/corescontrol

			i=`echo "$i $firstcore" |awk '{print $1-$2}'`
			echo "$i" >>$COORDFOLDER/corescontrol

		else
			echo "$request $i" |awk -v maxexe=$maxexe '{if($1+$2>=maxexe){print maxexe}else{print $1+$2}}' >>$COORDFOLDER/corescontrol
		fi

	else
		sleep 60
		coresControlFunction $request
	fi

}

function coresunlockFunction {

	rm -rf $COORDFOLDER/lockfolder_donttouch
}

function fastalockFunction {
	if mkdir fastalock; then
		echo "fastalock created"
	else
		sleep 60
		fastalockFunction
	fi
}

function fastaunlockFunction {

	rm -rf fastalock
}

function readstoFastqFunction {
		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					NAMEPAIREND1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					NAMEPAIREND2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`

					fastalockFunction
					if [ -f fasta_to_fastq.pl ]; then
						if [ ! -f $TMPNAME/$NAMEPAIREND1.fastq ];then
							perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
							perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
						fi
					else
						fasta_to_fastqFunction 
						if [ ! -f $TMPNAME/$NAMEPAIREND1.fastq ];then
							perl fasta_to_fastq.pl $PAIREND1 > $TMPNAME/$NAMEPAIREND1.fastq
							perl fasta_to_fastq.pl $PAIREND2 > $TMPNAME/$NAMEPAIREND2.fastq
						fi
					fi
					fastaunlockFunction

					RFILE=`echo "$NAMEPAIREND1.fastq,$NAMEPAIREND2.fastq"`
				else
					echo "$PAIREND2 doesn't exist"
					exit
				fi
			else
				echo "$PAIREND1 doesn't exist"
				exit
			fi
		else
			fastalockFunction
			if [ -f fasta_to_fastq.pl ]; then
				if [ ! -f $TMPNAME/$SINGLE.fastq ];then
					perl fasta_to_fastq.pl $IRFILE > $TMPNAME/$SINGLE.fastq
					RFILE=$SINGLE.fastq
				fi
			else
				fasta_to_fastqFunction
				if [ ! -f $TMPNAME/$SINGLE.fastq ];then
					perl fasta_to_fastq.pl $IRFILE > $TMPNAME/$SINGLE.fastq
					RFILE=$SINGLE.fastq
				fi
			fi
			fastaunlockFunction
		fi
}

function pathoscopeFunction {

		echo "wake up pathoscope"
		FILE=$IRFILE
		readstoFastqFunction
		cd $TMPNAME
		coresControlFunction 1


		if [ "$PSFDB" == "" ];then
			{ time -p python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $PSIXDIR -targetIndexPrefixes $DBPS -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf1_$RFILE &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		else
			{ time python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $PSIXDIR -targetIndexPrefixes $DBPS -filterIndexPrefixes $PSFDB -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf1_$RFILE &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		fi
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 pathoscopeF1" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction

		cd ..
		
		TOCLEAN=$RFILE
		IRFILE=$FILE

 
}

function metaphlanFunction {

		FILE=$IRFILE

		echo "wake up metaphlan"
		readstoFastqFunction
		cd $TMPNAME

		coresControlFunction 1
		if [ -f "bowtieout$RFILE.bz2" ];then
			rm -f bowtieout$RFILE.bz2
		fi

		{ time -p python ${METAPHLAN2HOME}/metaphlan2.py $RFILE --input_type fastq --mpa_pkl $DBMARKER --bowtie2db $DBM2 --bowtie2out bowtieout$RFILE.bz2 --nproc $CORES > ../metaphlan_$RFILE.dat ; } 2>&1 |grep "real" |awk '{print $2}' > TimeM2_$RFILE &
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 metaphlanF1" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction
		
		cd ..

		TOCLEAN=$RFILE
		IRFILE=$FILE

}

function metamixFunction {

		echo "wake up metamix"
		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					
					P1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					P2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
					
					if mkdir $TMPNAME/metamix_$P1.$P2; then #we make new folder because is easier to clean after execution
						echo "folder metamix_$P1.$P2 created"
					else
						echo "Metamix: cleaning previous run"
						rm -r $TMPNAME/metamix_$P1.$P2
						mkdir $TMPNAME/metamix_$P1.$P2
					fi

					cd $TMPNAME
					cd metamix_$P1.$P2
					
					coresControlFunction 1
					{ time -p ${BLASTHOME}/bin/blastn -query ../../$PAIREND1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$P1.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$P1 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 metamixF1_1" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction


					coresControlFunction 1
					{ time -p ${BLASTHOME}/bin/blastn -query ../../$PAIREND2 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$P2.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$P2 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 metamixF1_2" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction

			        cd ..
					cd ..
									
				else
					echo "$PAIREND2 no exist"
					exit
				fi
			else
				echo "$PAIREND1 no exist"
				exit
			fi
		else
			SINGLE=`echo "$IRFILE" |rev |cut -d "/" -f 1 |rev`

			if mkdir $TMPNAME/metamix_$SINGLE; then #we make new folder because is easier to clean after execution
				echo "folder metamix_$SINGLE created"
			else
				echo "Metamix: cleaning previous run"
				rm -r $TMPNAME/metamix_$SINGLE
				mkdir $TMPNAME/metamix_$SINGLE
			fi

			cd $TMPNAME
			cd metamix_$SINGLE

			coresControlFunction $CORES

			{ time -p ${BLASTHOME}/bin/blastn -query $IRFILE -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS > blastOut$SINGLE.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$SINGLE &
			lastpid=$!
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES metamixF1" >> $COORDFOLDER/proccesscontrol
			coresunlockFunction
			cd ..
			cd ..
		fi
	
}

function sigmaFunction {

	echo "wake up sigma"
	cd $TMPNAME

	coresControlFunction 1

	if [ "$RTYPE" == "PAIRED" ];then
		SGTOCLEAN=sigma_$RFILE
		if mkdir $SGTOCLEAN ;then
			cd $SGTOCLEAN
		else
			echo "sigma: cleaning previous run"
			rm -rf $SGTOCLEAN
			mkdir $SGTOCLEAN
			cd $SGTOCLEAN
		fi
	else
		SGTOCLEAN=sigma_$RFILE
		if mkdir $SGTOCLEAN ;then
			cd $SGTOCLEAN
		else
			echo "sigma: cleaning previous run"
			rm -rf $SGTOCLEAN
			mkdir $SGTOCLEAN
			cd $SGTOCLEAN
		fi
	fi
	mv ../$SIGMACFILE .
	{ time -p ${SIGMAHOME}/bin/sigma-align-reads -c $SIGMACFILE -w . 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > TimeSGf1_$RFILE &
	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid 1 sigmaF1" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction
	cd ..
	cd ..

}

function krakenFunction {

	echo "wake up kraken"
	cd $TMPNAME
	if [ "$READS" == "paired" ]; then
		PAIREND1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print "../"$1}'`
		PAIREND2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print "../"$2}'`
		#next, check the files (tolerance to missing files)
		if [ -f "$PAIREND1" ];then
			if [ -f "$PAIREND2" ];then
					
				P1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
				P2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
								
				coresControlFunction 1
				{ time -p ${KRAKENHOME}/kraken --db $DBKR --paired $PAIREND1 $PAIREND2 --threads $THREADS --preload > kraken_$P1.$P2.kraken ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf1_$P1.$P2 &
				lastpid=$!
				pids[${pindex}]=$lastpid
				pindex=$((pindex+1))
				echo "$lastpid 1 krakenF1" >> $COORDFOLDER/proccesscontrol
				coresunlockFunction
		
			else
				echo "$PAIREND2 no exist"
				exit
			fi
		else
			echo "$PAIREND1 no exist"
			exit
		fi
	else
		coresControlFunction 1
		SINGLE=`echo "$IRFILE" |rev |cut -d "/" -f 1 |rev`
		{ time -p ${KRAKENHOME}/kraken --db $DBKR ../$IRFILE --threads $THREADS --preload > kraken_$SINGLE.kraken ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf1_$SINGLE &
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 krakenF1" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction
	fi

	cd ..
}

function taxatorFunction {

		echo "wake up taxator-tk"
		if [ "$READS" == "paired" ]; then
			PAIREND1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
			PAIREND2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}'`
			#next, check the files (tolerance to missing files)
			if [ -f "$PAIREND1" ];then
				if [ -f "$PAIREND2" ];then
					
					P1=`echo "$PAIREND1" |rev |cut -d "/" -f 1 |rev`
					P2=`echo "$PAIREND2" |rev |cut -d "/" -f 1 |rev`
					
					if mkdir $TMPNAME/taxator_$P1.$P2; then #we make new folder because is easier to clean after execution
						echo "folder taxator_$P1.$P2 created"
					else
						echo "Taxator: cleaning previous run"
						rm -r $TMPNAME/taxator_$P1.$P2
						mkdir $TMPNAME/taxator_$P1.$P2
					fi

					cd $TMPNAME
					cd taxator_$P1.$P2
					
					coresControlFunction 1
					{ time -p ${BLASTHOME}/bin/blastn -query ../../$PAIREND1 -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$P1.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeTXf1_$P1 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 taxatorF1_1" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction


					coresControlFunction 1
					{ time -p ${BLASTHOME}/bin/blastn -query ../../$PAIREND2 -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$P2.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeTXf1_$P2 &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 taxatorF1_2" >> $COORDFOLDER/proccesscontrol
					coresunlockFunction

			        cd ..
					cd ..
									
				else
					echo "$PAIREND2 no exist"
					exit
				fi
			else
				echo "$PAIREND1 no exist"
				exit
			fi
		else
			SINGLE=`echo "$IRFILE" |rev |cut -d "/" -f 1 |rev`

			if mkdir $TMPNAME/taxator_$SINGLE; then #we make new folder because is easier to clean after execution
				echo "folder taxator_$SINGLE created"
			else
				echo "Taxator: cleaning previous run"
				rm -r $TMPNAME/taxator_$SINGLE
				mkdir $TMPNAME/taxator_$SINGLE
			fi

			cd $TMPNAME
			cd taxator_$SINGLE

			coresControlFunction $CORES

			{ time -p ${BLASTHOME}/bin/blastn -query $IRFILE -outfmt '6 qseqid qstart qend qlen sseqid sstart send bitscore evalue nident length' -db $DBTX -num_threads $THREADS > blastOut$SINGLE.tab ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf1_$SINGLE &
			lastpid=$!
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES taxatorF1" >> $COORDFOLDER/proccesscontrol
			coresunlockFunction
			cd ..
			cd ..
		fi

}

function pathoscopeFunction2 {
	echo "executing pathoscope ID module"
	cd $TMPNAME

	coresControlFunction 1
	if [ "$PRIOR" == "" ];then
		{ time -p python ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf2_$RFILE &

	else
		{ time -p python ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE -thetaPrior $PRIOR 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > TimePSf2_$RFILE &
	fi
	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid 1 pathoscopeF2" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction
	cd ..

}

function metamixFunction2 {


	cd $TMPNAME

	coresControlFunction 12 #parallel tempering requires 12 cores

		if [ "$READS" == "paired" ]; then
			cat TimeMXf1_$P1 TimeMXf1_$P2 |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeMXf1_$P1.$P2
			rm -f TimeMXf1_$P1 TimeMXf1_$P2
			cd metamix_$P1.$P2
			BACKUPNAME=`echo "metamix_$P1.$P2"`
			metamixCodeFunction
			echo "call to metamix R function"
			cat blastOut$P1.tab blastOut$P2.tab > blastOut$P1.$P2.tab
			rm blastOut$P1.tab blastOut$P2.tab
			executionpath=`pwd`

			{ time -p executeMetamix blastOut$P1.$P2.tab $executionpath 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf2_$P1.$P2 &

			cd ..

		else
			cd metamix_$SINGLE
			metamixCodeFunction
			echo "execute metamix R function"
			executionpath=`pwd`

			{ time -p executeMetamix blastOut$SINGLE.tab $executionpath 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf2_$SINGLE &

			cd ..
		fi
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 metamixF2" >> $COORDFOLDER/proccesscontrol

		coresunlockFunction
		cd ..

}
function sigmaFunction2 {
	cd $TMPNAME 
	cd $SGTOCLEAN

	coresControlFunction $CORES

	echo "executing sigma wrapper module"	
    { time -p ${SIGMAHOME}/bin/sigma -c $SIGMACFILE -t $THREADS -w . 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeSGf2_$RFILE &
	#${SIGMAHOME}/bin/sigma -c $SIGMACFILE -t $THREADS -w .

	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid $CORES sigmaF2" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction

	cd ..
	cd ..

}

function constrainsFunction {

	echo "wake up constrains"

	readstoFastqFunction

	cd $TMPNAME
	coresControlFunction $CORES

	#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`	CSTOCLEAN=constrains_$RFILE
	newcsname=`echo metaphlan_$RFILE.dat |awk -F "," '{print $1"."$2}'`
	if [ -f "../$newcsname" ];then
		CSERROR=0
		CSTOCLEAN=`echo "$RFILE" |awk 'BEGIN{FS=","}{print "constrains_"$1"."$2}'`

		if [ "$READS" == "paired" ]; then
			F1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
			F2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
			echo "sample: $RFILE
			fq1: $F1
			fq2: $F2
			metaphlan: ../$newcsname" > cs_config_$RFILE.conf
		else
			echo "sample: $RFILE 
			fq: $RFILE
			metaphlan: ../$newcsname" > cs_config_$RFILE.conf
			CSTOCLEAN=constrains_$RFILE
		fi
			{ time -p python ${CONSTRAINSHOME}/ConStrains.py -c cs_config_$RFILE.conf -o $CSTOCLEAN -t $THREADS -d ${CONSTRAINSHOME}/db/ref_db -g ${CONSTRAINSHOME}/db/gsize.db --bowtie2=${BOWTIE2HOME}/bin/bowtie2-build --samtools=${SAMTOOLSHOME}/bin/samtools -m ${METAPHLAN2HOME}/metaphlan2.py 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > TimeCS_$RFILE &
			lastpid=$!	
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES constrains" >> $COORDFOLDER/proccesscontrol
	else
			echo "Constrains: no $newcsname file found, impossible continue"
			CSERROR=1
	fi
	coresunlockFunction

	cd ..

			
}

function krakenFunction2 {

	cd $TMPNAME

	if [ "$READS" == "paired" ]; then
		coresControlFunction 1
		{ time -p ${KRAKENHOME}/kraken-translate --mpa-format --db $DBKR kraken_$P1.$P2.kraken > kraken_trans_$P1.$P2.kraken ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf2_$P1.$P2 &
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 krakenF2" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction

	else
		coresControlFunction 1
		{ time -p ${KRAKENHOME}/kraken-translate --mpa-format --db $DBKR kraken_$SINGLE.kraken > kraken_trans_$SINGLE.kraken  ; } 2>&1 |grep "real" |awk '{print $2}' > TimeKRf2_$SINGLE &
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 krakenF2" >> $COORDFOLDER/proccesscontrol
		coresunlockFunction

	fi

	cd ..

}

function taxatorFunction2 {

	cd $TMPNAME

	coresControlFunction $THREADS

	if [ "$READS" == "paired" ]; then
		cat TimeTXf1_$P1 TimeTXf1_$P2 |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeTXf1_$P1.$P2
		rm -f TimeTXf1_$P1 TimeTXf1_$P2
		cd taxator_$P1.$P2
		BACKUPNAME=`echo "taxator_$P1.$P2"`
		cat blastOut$P1.tab blastOut$P2.tab > blastOut$P1.$P2.tab
		rm blastOut$P1.tab blastOut$P2.tab

		awk '{print $0"\t"}' blastOut$P1.$P2.tab >  blastOut$P1.$P2.tab.tmp && rm -f blastOut$P1.$P2.tab && mv blastOut$P1.$P2.tab.tmp blastOut$P1.$P2.tab
		../$PAIREND1


		${TAXATORHOME}/bin/taxator -g db_B.tax -q 1.fa -v 1.fa.fai -f db_B.fna -i db_B.fna.fai -p16 < blastOut$P1.$P2.tab > my.predictions.gff3
		${TAXATORHOME}/bin/binner -n "testID" < my.predictions.gff3 > my.tax

		cd ..
	else
		cd metamix_$SINGLE
		metamixCodeFunction
		echo "execute metamix R function"
		executionpath=`pwd`
		{ time -p executeMetamix blastOut$SINGLE.tab $executionpath 1>null ; } 2>&1 |grep "real" |awk '{print $2}' > ../TimeMXf2_$SINGLE &
		cd ..
	fi
	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid 1 metamixF2" >> $COORDFOLDER/proccesscontrol
	coresunlockFunction
	cd ..

}

function lastStepFunction {

	rm -f $TMPNAME/fasta_to_fastq.pl

	if [ "$READS" == "paired" ]; then
		rm -f $TMPNAME/$NAMEPAIREND1.fastq $TMPNAME/$NAMEPAIREND2.fastq
	else
		rm -f $TMPNAME/$TOCLEAN.fastq
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then
		cat $TMPNAME/TimePSf1_$RFILE $TMPNAME/TimePSf2_$RFILE |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimePS_$RFILE
		newpatname=`echo "TimePS_$RFILE" |awk -F "," '{print $1"."$2}'`
		mv TimePS_$RFILE $newpatname

		rm -f updated_pathoscope_$TOCLEAN.sam
		rm -f $TMPNAME/$SAMFILE
		newpatname=`echo "pathoscope_$RFILE.sam-sam-report.tsv" |awk -F "," '{print $1"."$2}'`
		mv pathoscope_$RFILE.sam-sam-report.tsv $newpatname

	fi
	
	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		mv $TMPNAME/TimeM2_$RFILE .
		newmetname=`echo "TimeM2_$RFILE" |awk -F "," '{print $1"."$2}'`
		mv TimeM2_$RFILE $newmetname

		rm -f $TMPNAME/bowtieout$TOCLEAN.bz2
		newmetname=`echo "metaphlan_$RFILE.dat" |awk -F "," '{print $1"."$2}'`
		mv metaphlan_$RFILE.dat $newmetname
	fi
	
	if [[ "$METHOD" =~ "METAMIX" ]]; then
		if [ "$READS" == "paired" ]; then
			cat $TMPNAME/TimeMXf1_$P1.$P2 $TMPNAME/TimeMXf2_$P1.$P2 |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeMX_$P1.$P2
			rm -rf $TMPNAME/metamix_$P1.$P2
		else
			cat $TMPNAME/TimeMXf1_$SINGLE $TMPNAME/TimeMXf2_$SINGLE |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeMX_$SINGLE
			rm -rf $TMPNAME/metamix_$SINGLE
		fi
	fi
	
	if [[ "$METHOD" =~ "SIGMA" ]]; then
		cat $TMPNAME/$SGTOCLEAN/TimeSGf1_$RFILE $TMPNAME/TimeSGf2_$RFILE |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' >TimeSG_$RFILE
		newsigname=`echo "TimeSG_$RFILE" |awk -F "," '{print $1"."$2}'`
		mv TimeSG_$RFILE $newsigname
		rm -f $TMPNAME/$SGTOCLEAN/TimeSGf1_$RFILE $TMPNAME/TimeSGf2_$RFILE

		mv $TMPNAME/$SGTOCLEAN/*.gvector.txt $SGTOCLEAN.gvector.txt
		rm -rf $TMPNAME/$SGTOCLEAN
		newsigname=`echo "$SGTOCLEAN.gvector.txt" |awk -F "," '{print $1"."$2}'`
		mv $SGTOCLEAN.gvector.txt $newsigname
	fi

	if [[ "$METHOD" =~ "CONSTRAINS" ]] && [ "$CSERROR" -eq 0 ]; then
		newsigname=`echo "TimeCS_$RFILE" |awk -F "," '{print $1"."$2}'`		
		mv $TMPNAME/TimeCS_$RFILE $newsigname
		mv $TMPNAME/$CSTOCLEAN/results/Overall_rel_ab.profiles $CSTOCLEAN.profiles
		rm -rf $TMPNAME/$CSTOCLEAN
		rm -rf $TMPNAME/cs_config_$RFILE.conf

	fi

	if [[ "$METHOD" =~ "KRAKEN" ]]; then
		if [ "$READS" == "paired" ]; then
			cat $TMPNAME/TimeKRf1_$P1.$P2 cat $TMPNAME/TimeKRf2_$P1.$P2 |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' >TimeKR_$P1.$P2
			rm -f $TMPNAME/TimeKRf1_$P1.$P2 cat $TMPNAME/TimeKRf2_$P1.$P2
			mv $TMPNAME/kraken_trans_$P1.$P2.kraken .
			awk '{print $2}' kraken_trans_$P1.$P2.kraken |sort |uniq -c > $P1.$P2.kraken.tmp
			rm -f kraken_trans_$P1.$P2.kraken
			mv $P1.$P2.kraken.tmp kraken_$P1.$P2.kraken
		else
			cat $TMPNAME/TimeKRf1_$SINGLE cat $TMPNAME/TimeKRf2_$SINGLE |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' >TimeKR_$SINGLE
			rm -f $TMPNAME/kraken_$SINGLE.kraken $TMPNAME/TimeKRf1_$SINGLE cat $TMPNAME/TimeKRf2_$SINGLE
			mv $TMPNAME/kraken_trans_$SINGLE.kraken .
			awk '{print $2}' kraken_trans_$SINGLE.kraken |sort |uniq -c > $SINGLE.kraken.tmp
			rm kraken_trans_$SINGLE.kraken
			mv $SINGLE.kraken.tmp kraken_$SINGLE.kraken
		fi
	fi

	if [[ "$METHOD" =~ "TAXATOR" ]]; then
		if [ "$READS" == "paired" ]; then
			cat $TMPNAME/TimeTXf1_$P1.$P2 $TMPNAME/TimeTXf2_$P1.$P2 |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeTX_$P1.$P2
			rm -rf $TMPNAME/taxator_$P1.$P2
		else
			cat $TMPNAME/TimeTXf1_$SINGLE $TMPNAME/TimeTXf2_$SINGLE |awk 'BEGIN{sum=0}{sum+=$1}END{print sum}' > TimeTX_$SINGLE
			rm -rf $TMPNAME/taxator_$SINGLE
		fi
	fi	
	echo "Done :D"
}

function criticalvariablesFunction {

	pass=0
	errormessage=""

	if [ "$IRFILE" == "" ];then
		errormessage=`echo -e "$errormessage You must provide a read file\n"`
		pass=$((pass+1))
	fi

	if [ "$CORES" == "" ] || [ "$THREADS" == "" ]
	then
		errormessage=`echo -e "$errormessage cores or threads are null, you must specify in the config file\n"`
		pass=$((pass+1))
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then

		if [ "$DBPS" == "" ];then
			errormessage=`echo -e "$errormessage You must provide a database (bowtie2 index), for pathoscope (--dbPS)\n"`
			pass=$((pass+1))
		fi
		if [ "$PATHOSCOPEHOME" == "" ];then
			errormessage=`echo -e "$errormessage no PATHOSCOPEHOME\n"`
			pass=$((pass+1))
		fi
		if ! [ -f $PATHOSCOPEHOME/pathoscope2.py ];then
			errormessage=`echo -e "$errormessage pathoscope2.py no exist in $PATHOSCOPEHOME\n"`
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		if [ "$DBM2" == "" ] || [ "$DBMARKER" == "" ];then
			errormessage=`echo -e "$errormessage METAPHLAN is specify in the config file, but you must provide a database (bowtie2 index), and pkl file in the command line (--dbM2 and --dbmarker)\n"`
			pass=$((pass+1))
		fi
		if [ "$METAPHLAN2HOME" == "" ];then
			errormessage=`echo -e "$errormessage no METAPHLAN2HOME\n"`
			pass=$((pass+1))
		fi	
	
		if ! [ -f $METAPHLAN2HOME/metaphlan2.py ]; then
			errormessage=`echo -e "$errormessage metaphlan2.py no exist in $METAPHLAN2HOME\n"`
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "METAMIX" ]]; then

		if [ "$DBMX" == "" ];then
			errormessage=`echo -e "$errormessage You must provide a database (blast index), for metamix (--dbMX)\n"`
			pass=$((pass+1))
		fi

		if [ "$MXNAMES" == "" ];then
			errormessage=`echo -e "$errormessage You must provide the names of your blast database (--MXnames), this file have ti - name format (183214 Foo)\n"`
			pass=$((pass+1))
		fi

		if [ "$BLASTHOME" == "" ];then
			errormessage=`echo -e "$errormessage You must provide BLASTHOME in config file (e.g /usr/local/ncbi/blast/bin)\n"`
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "SIGMA" ]]; then

		if [ "$SIGMAHOME" == "" ];then
			errormessage=`echo -e "$errormessage no SIGMAHOME\n"`
			pass=$((pass+1))
		fi

		if ! [  -f $SIGMAHOME/bin/sigma ];then
			errormessage=`echo -e "$errormessage sigma no exist in $SIGMAHOME/bin\n"`
			pass=$((pass+1))
		fi

		
		if [ "$SIGMACFILE" == "" ];then

			if [ "$BOWTIE2HOME" == "" ];then
				errormessage=`echo -e "$errormessage you must provide a bowtie2 home in config file (BOWTIE2HOME flag), to generate sigma config file\n"`
				pass=$((pass+1))
			fi
			
			if [ "$SAMTOOLSHOME" == "" ];then
				errormessage=`echo -e "$errormessage you must provide a samtools binary folder (home/bin) (SAMTOOLSHOME flag), to generate sigma config file\n"`
				pass=$((pass+1))
			fi

			if [ "$DBSG" == "" ]; then
				errormessage=`echo -e "$errormessage you must provide a sigma database path, to generate sigma config file\n"`
				pass=$((pass+1))
			fi

			if [ "$READS" == "paired" ]; then
				RTYPE="PAIRED"
			else
				RTYPE="SINGLE"
			fi

			if [ $((pass)) -eq 0 ];then
				sigmaCfileFunction
				SIGMACFILE=`echo "sigma_$RFILE""_config.cfg"`

			else
				echo "$errormessage"
				exit
			fi

		else

			DBSG=`grep -1 "Reference_Genome_Directory" $SIGMACFILE |cut -d "=" -f 2`
			PR1=`grep -1 "Paired_End_Reads_1" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`
			PR2=`grep -1 "Paired_End_Reads_2" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`
			SR=`grep -1 "Single_End_Reads" $SIGMACFILE |cut -d "=" -f 2 |rev |cut -d "/" -f 1 |rev`

			if [ -d $DBSG ];then
					errormessage=`echo -e "$errormessage you must provide a database folder in sigma config file\n"`
					pass=$((pass+1))
			fi
			if [ "$SR" == "" ];then
				if [ "$PR1" == "" ] || [ "$PR2" == "" ]; then
					errormessage=`echo -e "$errormessage you must provide a read file in sigma config file\n"`
					pass=$((pass+1))
				else
					RTYPE="PAIRED"
				fi
			else
				RTYPE="SINGLE"
			fi
		fi
	fi

	if [[ "$METHOD" =~ "KRAKEN" ]]; then
		if [ "$DBKR" == "" ];then
			errormessage=`echo -e "$errormessage you must provide a database (folder) for kraken (--dbKR)\n"`
			pass=$((pass+1))
		fi
		if [ "$KRAKENHOME" == "" ];then
			errormessage=`echo -e "$errormessage no KRAKENHOME\n"`
			pass=$((pass+1))
		fi
		status=`command -v $KRAKENHOME/kraken >/dev/null 2>&1 || { echo "NOT_INSTALLED" >&2; }`
		if [  "$status" == "NOT_INSTALLED" ];then
			errormessage=`echo -e "$errormessage kraken no exist in $KRAKENHOME\n"`
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "TAXATOR" ]]; then
		if [ "TAXATORTK_TAXONOMY_NCBI" == "" ];then
			errormessage=`echo -e "$errormessage you must provide a TAXATORTK_TAXONOMY_NCBI path for taxator-tk in the config file (TAXATORTK_TAXONOMY_NCBI=/path/to/your/ncbi taxonomi)\n"`
			pass=$((pass+1))
		fi
		if [ "$DBTX" == "" ];then
			errormessage=`echo -e "$errormessage You must provide a database (blast index), for taxator (--dbTX)\n"`
			pass=$((pass+1))
		fi
	fi

	if [ $((pass)) -eq 0 ];then
		echo "all parameters ok"
	else
		echo "$errormessage"
		exit
	fi

}

function sigmaCfileFunction {

	if [ "$READS" == "paired" ]; then
		F1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}'`
		SIZE=`tail -n1 $F1 |wc |awk '{print $3}'`
		F1=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $1}' |rev |cut -d "/" -f 1 |rev`
		F1=`echo "$F1.fastq"`
		F2=`echo "$IRFILE" |awk 'BEGIN{FS=","}{print $2}' |rev |cut -d "/" -f 1 |rev`
		F2=`echo "$F2.fastq"`
		
		readstoFastqFunction
		cd $TMPNAME	
		FASTQFOLDER=`pwd`
		cd ..
		RFILE=`echo "$F1,$F2"`
		#RFILE=`echo "$F1,$F2"`
		
		echo "[Program_Info]
		Bowtie_Directory=$BOWTIE2HOME/bin
		Samtools_Directory=$SAMTOOLSHOME/bin
		[Data_Info]
		Reference_Genome_Directory=$DBSG
		Paired_End_Reads_1=$FASTQFOLDER/$F1
		Paired_End_Reads_2=$FASTQFOLDER/$F2
		[Bowtie_Search]
		Maximum_Mismatch_Count=3
		Minimum_Fragment_Length=0
		Maximum_Fragment_Length=2000
		Bowtie_Threads_Number=$THREADS
		[Model_Probability]
		Mismatch_Probability=0.05
		Minimum_Relative_Abundance = 0.01
		[Statistics]
		Bootstrap_Iteration_Number=10
		Minumum_Coverage_Length=$SIZE
		Minimum_Average_Coverage_Depth=3
		" > $TMPNAME/sigma_$RFILE""_config.cfg
		
	else
		SIZE=`tail -n1 $IRFILE |wc |awk '{print $3}'`
		readstoFastqFunction
		RFILE=`echo "$IRFILE" |rev |cut -d "/" -f 1 |rev`
		RFILE=`echo "$IRFILE.fastq"`
		cd $TMPNAME	
		FASTQFOLDER=`pwd`
		cd ..

		echo "[Program_Info]
		Bowtie_Directory=$BOWTIE2HOME
		Samtools_Directory=$SAMTOOLSHOME
		[Data_Info]
		Reference_Genome_Directory=$DBSG
		Single_End_Reads=$FASTQFOLDER/$RFILE
		[Bowtie_Search]
		Maximum_Mismatch_Count=3
		Minimum_Fragment_Length=0
		Maximum_Fragment_Length=2000
		Bowtie_Threads_Number=$THREADS
		[Model_Probability]
		Mismatch_Probability=0.05
		Minimum_Relative_Abundance = 0.01
		[Statistics]
		Bootstrap_Iteration_Number=10
		Minumum_Coverage_Length=$SIZE
		Minimum_Average_Coverage_Depth=3
		" > $TMPNAME/sigma_$RFILE""_config.cfg

	fi

}

function fasta_to_fastqFunction {
	echo '#!/usr/bin/perl
			use strict;

			my $file = $ARGV[0];
			open FILE, $file;

			my ($header, $sequence, $sequence_length, $sequence_quality);
			while(<FILE>) {
			        chomp $_;
			        if ($_ =~ /^>(.+)/) {
			                if($header ne "") {
			                        print "\@".$header."\n";
			                        print $sequence."\n";
			                        print "+"."\n";
			                        print $sequence_quality."\n";
			                }
			                $header = $1;
					$sequence = "";
					$sequence_length = "";
					$sequence_quality = "";
			        }
				else { 
					$sequence .= $_;
					$sequence_length = length($_); 
					for(my $i=0; $i<$sequence_length; $i++) {$sequence_quality .= "I"} 
				}
			}
			close FILE;
			print "\@".$header."\n";
			print $sequence."\n";
			print "+"."\n";
			print $sequence_quality."\n";' > fasta_to_fastq.pl
}

function metamixCodeFunction {
	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	blastab<-c(args[6])
	print("execute Step1")
	Step1<-generative.prob.nucl(blast.output.file=blastab,blast.default=FALSE,outDir=".")
	' > step1.R

	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	Step1<-c(args[6])
	print("execute Step2")
	Step2 <- reduce.space(step1=Step1)
	' > step2.R

	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	Step2<-c(args[6])
	print("execute Step3")
	Step3<-parallel.temper(step2=Step2)
	' > step3.R

	echo 'library(metaMix)
	library(methods)
	args<-commandArgs()
	Step2<-c(args[6])
	Step3<-c(args[7])
	names<-c(args[8])
	print("execute Step4")
	step4<-bayes.model.aver(step2=Step2, step3=Step3, taxon.name.map=names)
	' > step4.R
	
}

function executeMetamix {
	#$1 blast output (fmt 6)
	#$2 $executionpath
	Rscript $2/step1.R $2/$1
	Rscript $2/step2.R $2/step1.RData
	mpirun -np 1 --quiet Rscript $2/step3.R $2/step2.RData
	Rscript $2/step4.R $2/step2.RData $2/step3.RData $MXNAMES
	mv $2/presentSpecies_assignedReads.tsv $2/../../$BACKUPNAME.assignedReads.tsv
}
#begin the code

if [ $((statusband)) -ge 1 ]; then
	cd $INITIALPATH
	#Check some parameters before do something
	if [ -d "$TMPNAME" ]; then
		echo "$TMPNAME exist, working in."
	else
		mkdir $TMPNAME
	fi

	criticalvariablesFunction


			for g in $METHOD
			do
				case $g in
					"PATHOSCOPE")
						pathoscopeFunction
				   	;;
					"METAPHLAN")
						metaphlanFunction
					;;
					"METAMIX")
						metamixFunction	
					;;
					"SIGMA")
					#REMEMBER HAVE DATABASE IN SIGMA FORMAT (each fasta in each directory)
						sigmaFunction
					;;
					"CONSTRAINS")
						#waiting for metaphlan work
					;;
					"KRAKEN")
						krakenFunction
					;;
				esac
			done
		
			###SECOND PART###
			echo "waiting for mapping work"
			for pid in "${pids[@]}"
			do
			   wait $pid
			done
			unset pids
			declare pids
			pindex=0
			#to sure we are in $INITIALPATH
			cd $INITIALPATH
			for g in $METHOD
			do
				case $g in
					"PATHOSCOPE")
						pathoscopeFunction2
				   	;;
					"METAPHLAN")
						echo "metaphlan done"
					;;
					"METAMIX")
						metamixFunction2
					;;
					"SIGMA")
					#REMEMBER HAVE DATABASE IN SIGMA FORMAT (each fasta in each directory, and each name folder must be the gi number of fasta that contain)
						sigmaFunction2
					;;
					"CONSTRAINS")
						constrainsFunction
					;;
					"KRAKEN")
						krakenFunction2
					;;
				esac
			done
			echo "waiting for classification work"
			for pid in "${pids[@]}"
			do
			   wait $pid
			done
			unset pids
			lastStepFunction
else
	echo "Invalid or Missing Parameters, print --help to see the options"
	echo "Usage: bash executionMethods --cfile [config file] --rfile [readsfile] -[dboption] [databases]"
	exit
fi
