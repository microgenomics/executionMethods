#make sure you have installed correctly the patogen detection software 
set -ex

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
					"GENOMESIZEBALANCE")
						GENOMESIZEBALANCE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`
					;;
					"COMMUNITYCOMPLEX")
						COMMUNITYCOMPLEX=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"SPECIES")
						SPECIES=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"ABUNDANCE")
						ABUNDANCE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"DOMINANCE")
					DOMINANCE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"READSIZE")
						READSIZE=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
					;;
					"METHOD")
						METHOD=`echo "$parameter" | awk 'BEGIN{FS="="}{print $2}' | sed "s/,/ /g"`					
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
				esac
			done
			statusband=$((statusband+1))
			cfileband=0
		fi
		
		if [ $((tifamilyband)) -eq 1 ]; then
			TIFAMILYFILE=$i
			tifamilyband=0
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

	;;
	esac
done

#################################################
declare -A pids
pindex=0
maxexe=$CORES
#################################################
lastpid=0
function coresControlFunction {
	request=$1
if mkdir /tmp/lockfolder; then
	if [ -f /tmp/corescontrol ]; then
		i=`tail -n1 /tmp/corescontrol`
	else
		i=0
	fi

	if [ -f /tmp/proccesscontrol ];then
		firstproc=`head -n1 /tmp/proccesscontrol |awk '{print $1}'`
		firstcore=`head -n1 /tmp/proccesscontrol |awk '{print $2}'`
	fi

	if [ $((i)) -ge $((maxexe)) ]; then

		while kill -0 "$firstproc"; do
			echo "waiting for proccess $firstproc"
            sleep 61
        done
        
        sed "1d" /tmp/proccesscontrol >toreplace
        rm /tmp/proccesscontrol
        mv toreplace /tmp/proccesscontrol

		i=`echo $i $firstcore |awk '{print $1-$2}'`
		echo "$i" >>/tmp/corescontrol

	else
		echo "$request $i" |awk -v maxexe=$maxexe '{if($1+$2>=maxexe){print maxexe}else{print $1+$2}}' >>/tmp/corescontrol
	fi

else
	sleep 60
	coresControlFunction $request
fi
}
function coresunlockFunction {
	rm -r /tmp/lockfolder
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
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $PSIXDIR -targetIndexPrefixes $DBPS -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		else
			python ${PATHOSCOPEHOME}/pathoscope2.py MAP -U $RFILE -indexDir $PSIXDIR -targetIndexPrefixes $DBPS -filterIndexPrefixes $PSFDB -outDir . -outAlign pathoscope_$RFILE.sam  -expTag MAPPED_$RFILE -numThreads $THREADS &
			lastpid=$!
			SAMFILE=pathoscope_$RFILE.sam
		fi
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 pathoscopeF1" >> /tmp/proccesscontrol
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

		python ${METAPHLAN2HOME}/metaphlan2.py $RFILE --input_type fastq --mpa_pkl $DBMARKER --bowtie2db $DBM2 --bowtie2out bowtieout$RFILE.bz2 --nproc $CORES > ../metaphlan_$RFILE.dat &
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 metaphlanF1" >> /tmp/proccesscontrol
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
						cp $PAIREND1 $TMPNAME/metamix_$P1.$P2/$P1
						cp $PAIREND2 $TMPNAME/metamix_$P1.$P2/$P2
					else
						echo "Metamix: cleaning previous run"
						rm -r $TMPNAME/metamix_$P1.$P2
						mkdir $TMPNAME/metamix_$P1.$P2
						cp $PAIREND1 $TMPNAME/metamix_$P1.$P2/$P1
						cp $PAIREND2 $TMPNAME/metamix_$P1.$P2/$P2
					fi

					cd $TMPNAME
					cd metamix_$P1.$P2
					
					coresControlFunction 1
					${BLASTHOME}/blastn -query $P1 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS -out blastOut$P1.tab &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 metamixF1_1" >> /tmp/proccesscontrol
					coresunlockFunction


					coresControlFunction 1
					${BLASTHOME}/blastn -query $P2 -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $THREADS -out blastOut$P2.tab &
					lastpid=$!
					pids[${pindex}]=$lastpid
					pindex=$((pindex+1))
					echo "$lastpid 1 metamixF1_2" >> /tmp/proccesscontrol
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
				cp $IRFILE $TMPNAME/metamix_$SINGLE/$SINGLE
			else
				echo "Metamix: cleaning previous run"
				rm -r $TMPNAME/metamix_$SINGLE
				mkdir $TMPNAME/metamix_$SINGLE
				cp $IRFILE $TMPNAME/metamix_$SINGLE/$SINGLE
			fi

			cd $TMPNAME
			cd metamix_$SINGLE

			coresControlFunction $CORES

			blastn -query $SINGLE -outfmt "6 qacc qlen sseqid slen mismatch bitscore length pident evalue staxids" -db $DBMX -num_threads $CORES -out blastOut$SINGLE.tab &
			lastpid=$!
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES metamixF1" >> /tmp/proccesscontrol
			coresunlockFunction
			cd ..
			cd ..
			#echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol
		fi
	
}

function sigmaFunction {

	echo "wake up sigma"
	cd $TMPNAME

	#if [ -f /tmp/corescontrol ];then
	#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	#else
	#	i=0
	#fi	
	coresControlFunction $CORES
	#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`
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
	${SIGMAHOME}/./sigma-align-reads -c $SIGMACFILE -p $CORES -w . &
	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid $CORES sigmaF1" >> /tmp/proccesscontrol
	coresunlockFunction
	cd ..
	cd ..
    #echo "$i $lastpid $AVIABLE" >> /tmp/corescontrol

}

function pathoscopeFunction2 {
	echo "executing pathoscope ID module"
	cd $TMPNAME

	#if [ -f /tmp/corescontrol ];then
	#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	#else
	#	i=0
	#fi
	coresControlFunction 1
	if [ "$PRIOR" == "" ];then
		python ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE &

	else
		python ${PATHOSCOPEHOME}/pathoscope2.py ID -alignFile $SAMFILE -fileType sam -outDir ../ -expTag $SAMFILE -thetaPrior $PRIOR &
	fi
	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid 1 pathoscopeF2" >> /tmp/proccesscontrol
	coresunlockFunction
	cd ..

}

function metamixFunction2 {


	cd $TMPNAME
	#trys=

	coresControlFunction 1

		if [ "$READS" == "paired" ]; then
			cd metamix_$P1.$P2
			BACKUPNAME=`echo "metamix_$P1.$P2"`
			metamixCodeFunction
			echo "call to metamix R function"
			cat blastOut$P1.tab blastOut$P2.tab > blastOut$P1.$P2.tab
			rm blastOut$P1.tab blastOut$P2.tab
			executionpath=`pwd`

			executeMetamix blastOut$P1.$P2.tab $executionpath &

			#while [ $((trys)) -ge 1 ]
			#do
			#	if  ;then
			#		
			#		
			#		echo "metamix execution successful"
			#		break

			#	else
			#		trys=$((trys-1))
			#		echo "metamix execution failed, ($trys retryings left)"
			#	fi
			#done

			cd ..

		else
			cd metamix_$SINGLE
			metamixCodeFunction
			echo "execute metamix R function"
			executionpath=`pwd`

			executeMetamix blastOut$SINGLE.tab $executionpath &

			
			#while [ $((trys)) -ge 1 ]
			#do
			#	if Rscript ../MetaMix.R blastOut$SINGLE.tab $MXNAMES ;then
			#		mv presentSpecies_assignedReads.tsv ../../metamix_$SINGLE.tsv
			#		echo "metamix execution successful"
			#		break
			#	else
			#		trys=$((trys-1))
			#		echo "metamix execution failed, ($trys retryings left)"
			#	fi
			#done

			cd ..
		fi
		lastpid=$!
		pids[${pindex}]=$lastpid
		pindex=$((pindex+1))
		echo "$lastpid 1 metamixF2" >> /tmp/proccesscontrol

		#if [ $((trys)) -eq 0 ];then
		#	foldererror=`pwd`
		#	echo "error: Metamix execution not finished in $foldererror"
		#fi

		coresunlockFunction
		cd ..

}
function sigmaFunction2 {
	cd $TMPNAME 
	cd $SGTOCLEAN

	coresControlFunction 1

	echo "executing sigma wrapper module"	
	${SIGMAHOME}/./sigma -c $SIGMACFILE -t $THREADS -w . &

	lastpid=$!
	pids[${pindex}]=$lastpid
	pindex=$((pindex+1))
	echo "$lastpid $CORES sigmaF2" >> /tmp/proccesscontrol
	coresControlFunction 1

	cd ..
	cd ..

}

function constrainsFunction {

	echo "wake up constrains"
	#if [ -f /tmp/corescontrol ];then
	#	i=`tail -n 1 /tmp/corescontrol |awk '{print $1}'`
	#else
	#	i=0
	#fi
	readstoFastqFunction

	cd $TMPNAME
	coresControlFunction $CORES

	#AVIABLE=`awk -v avi=$i -v total=$CORES '{print (total-avi)}'`	CSTOCLEAN=constrains_$RFILE
	if [ -f "../metaphlan_$RFILE.dat" ];then
		CSERROR=0
		CSTOCLEAN=constrains_$RFILE

		if [ "$READS" == "paired" ]; then
			F1=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $1}'`
			F2=`echo "$RFILE" |awk 'BEGIN{FS=","}{print $2}'`
			echo "sample: $RFILE
			fq1: $F1
			fq2: $F2
			metaphlan: ../metaphlan_$RFILE.dat" > cs_config_$RFILE.conf
		else
			echo "sample: $RFILE 
			fq: $RFILE
			metaphlan: ../metaphlan_$RFILE.dat" > cs_config_$RFILE.conf
			CSTOCLEAN=constrains_$RFILE
		fi
			python ${CONSTRAINSHOME}/ConStrains.py -c cs_config_$RFILE.conf -o $CSTOCLEAN -t $THREADS -d ${CONSTRAINSHOME}/db/ref_db -g ${CONSTRAINSHOME}/db/gsize.db --bowtie2=${BOWTIE2HOME}/bowtie2-build --samtools=${SAMTOOLSHOME}/samtools -m ${METAPHLAN2HOME}/metaphlan2.py &
			lastpid=$!	
			pids[${pindex}]=$lastpid
			pindex=$((pindex+1))
			echo "$lastpid $CORES constrains" >> /tmp/proccesscontrol
	else
			echo "Constrains: no metaphlan2 file found, impossible continue"
			CSERROR=1
	fi
	coresControlFunction 1

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
		rm -f updated_pathoscope_$TOCLEAN.sam
		rm -f $TMPNAME/$SAMFILE
	fi
	
	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		rm -f $TMPNAME/bowtieout$TOCLEAN.bz2
	fi
	
	if [[ "$METHOD" =~ "METAMIX" ]]; then
		
		if [ "$READS" == "paired" ]; then
			rm -rf $TMPNAME/metamix_$P1.$P2
		else
			rm -rf $TMPNAME/metamix_$SINGLE
		fi
	fi
	
	if [[ "$METHOD" =~ "SIGMA" ]]; then
		mv $TMPNAME/$SGTOCLEAN/*.gvector.txt $SGTOCLEAN.gvector.txt
		rm -rf $TMPNAME/$SGTOCLEAN
	fi

	if [[ "$METHOD" =~ "CONSTRAINS" ]] && [ "$CSERROR" -eq 0 ]; then
		mv $TMPNAME/$CSTOCLEAN/results/Overall_rel_ab.profiles $CSTOCLEAN.profiles
		rm -rf $TMPNAME/$CSTOCLEAN
		rm -rf $TMPNAME/cs_config_$RFILE.conf
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

	if [[ "$METHOD" =~ "METAPHLAN" ]]; then
		if [ "$DBM2" == "" ] || [ "$DBMARKER" == "" ];then
			errormessage=`echo -e "$errormessage METAPHLAN is specify in the config file, but you must provide a database (bowtie2 index), and pkl file in the command line (--dbM2 and --dbmarker)\n"`
			pass=$((pass+1))
		fi
	fi

	if [[ "$METHOD" =~ "PATHOSCOPE" ]]; then

		if [ "$DBPS" == "" ];then
			errormessage=`echo -e "$errormessage You must provide a database (bowtie2 index), for pathoscope (--dbPS)\n"`
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

#	if [[ "$METHOD" =~ "CONSTRAINS" ]]; then
#		if [[ ! "$METHOD" =~ "METAPHLAN" ]]; then
#			errormessage=`echo -e "$errormessage METAPHLAN is needed to CONSTRAINS work\n"`
#			pass=$((pass+1))
#		fi
#	fi

	if [[ "$METHOD" =~ "SIGMA" ]]; then

		if [ "$SIGMACFILE" == "" ];then

			if [ "$BOWTIE2HOME" == "" ];then
				errormessage=`echo -e "$errormessage you must provide a bowtie2 home in config file (BOWTIE2HOME flag), to generate sigma config file\n"`
				pass=$((pass+1))
			fi
			
			if [ "$SAMTOOLSHOME" == "" ];then
				errormessage=`echo -e "$errormessage you must provide a samtools home/bin (SAMTOOLSHOME flag), to generate sigma config file\n"`
				pass=$((pass+1))
			fi

			if [ "$DBSG" == "" ]; then
				errormessage=`echo -e "$errormessage you must provide a samtools home/bin (SAMTOOLSHOME flag), to generate sigma config file\n"`
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
Bowtie_Directory=$BOWTIE2HOME
Samtools_Directory=$SAMTOOLSHOME
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
	if eval "mpirun -np 1 -quiet Rscript $2/step3.R $2/step2.RData"; then #this is just to return the control to master script (mpirun is a child)
		Rscript step4.R $2/step2.RData $2/step3.RData $MXNAMES
	else
		Rscript step4.R $2/step2.RData $2/step3.RData $MXNAMES
	fi
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
				esac
			done
		
			###SECOND PART###
			echo "waiting for mapping work"
			for pid in "${pids[@]}"
			do
			   wait $pid
			done
			unset pids
			declare -A pids
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
				esac
			done
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
